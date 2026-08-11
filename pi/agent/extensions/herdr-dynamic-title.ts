/**
 * Dynamic terminal title — companion to Herdr's herdr-agent-state.ts.
 *
 * Pi otherwise sets its window title once at session start and never
 * touches it again. Claude Code's session title works the same way it did
 * before this: a background call to a small/fast model
 * summarizes the prompt into a short title. This uses the local oMLX model
 * so title generation never spends a provider quota or sends the prompt off
 * the machine. It re-runs every turn instead of only the first — Claude Code's
 * own terminal title is stuck on the first message (anthropics/claude-code#41136);
 * this one tracks whatever you're currently asking for.
 *
 * The generated title lands once the background call resolves; the raw
 * (first-line) prompt text shows immediately in the meantime so the title
 * never just sits frozen waiting on a model response. If the local model call
 * fails, is unavailable, or is slower than the timeout, the raw fallback is
 * what stays.
 *
 * The spinner frame is in Herdr's recognized leading-glyph set
 * (U+2800–U+28FF), so `terminal_title_stripped` stays clean — only the raw
 * `terminal_title` carries the spinner.
 *
 * Kept as a separate file rather than editing herdr-agent-state.ts, which
 * Herdr overwrites on integration updates.
 */

import path from "node:path";
import { uuidv7 } from "@earendil-works/pi-ai";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const BRAILLE_FRAMES = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];
const MAX_TASK_LEN = 48;
const TITLE_MODEL_PROVIDER = "omlx";
const TITLE_MODEL_ID = "mlx-community--Qwen2.5-7B-Instruct-4bit";
const TITLE_CALL_TIMEOUT_MS = 4000;

// A provider failure must never become the task title. In particular, the old
// remote title model returned "You've hit your limit …" as a successful text
// response when its quota was exhausted, which then overwrote the useful raw
// prompt fallback.
const INVALID_GENERATED_TITLE = [
	/you(?:'|’)ve hit (?:your )?limit/i,
	/too many requests/i,
	/quota(?: exceeded| exhausted| limit)/i,
	/rate[- ]limit(?:ed)?(?:\b|\s)/i,
	/resets?\s+(?:at|in)\s+\d/i,
	/\b(?:unauthorized|forbidden|payment required)\b/i,
];

function projectTitle(pi: ExtensionAPI): string {
	const cwd = path.basename(process.cwd());
	const session = pi.getSessionName();
	return session ? `π - ${session} - ${cwd}` : `π - ${cwd}`;
}

function clampTitle(text: string): string {
	const cleaned = text
		.replace(/\s+/g, " ")
		.trim()
		.replace(/^["'“”]+|["'“”]+$/g, "")
		.replace(/[.!?]+$/, "");
	return cleaned.length > MAX_TASK_LEN ? `${cleaned.slice(0, MAX_TASK_LEN - 1)}…` : cleaned;
}

// Immediate, free stand-in for a real summary — used the instant a prompt is
// submitted, before the background model call (if any) has a chance to land.
function taskFromPrompt(prompt: string): string | undefined {
	const line = prompt
		.split("\n")
		.map((l) => l.trim())
		.find((l) => l.length > 0);
	return line ? clampTitle(line) : undefined;
}

async function generateTitle(
	ctx: ExtensionContext,
	prompt: string,
	signal: AbortSignal,
): Promise<string | undefined> {
	const model = ctx.modelRegistry.find(TITLE_MODEL_PROVIDER, TITLE_MODEL_ID);
	if (!model || !ctx.modelRegistry.hasConfiguredAuth(model)) return undefined;

	const call = ctx.modelRegistry.complete(
		model,
		{
			messages: [
				{
					role: "user",
					content: [
						{
							type: "text",
							text: [
								"Output a 3-5 word terminal-window-title summary of the task below.",
								"Output the title text only: no numbering, no punctuation, no preamble, no explanation.",
								"",
								"Task:",
								taskFromPrompt(prompt) ?? prompt.slice(0, 200),
							].join("\n"),
						},
					],
					timestamp: Date.now(),
				},
			],
		},
		{ cacheRetention: "none", sessionId: uuidv7(), temperature: 0.2, maxTokens: 32 },
	);

	const timeout = new Promise<undefined>((resolve) => {
		const id = setTimeout(() => resolve(undefined), TITLE_CALL_TIMEOUT_MS);
		signal.addEventListener("abort", () => {
			clearTimeout(id);
			resolve(undefined);
		});
	});

	const response = await Promise.race([call, timeout]).catch(() => undefined);
	if (!response || signal.aborted) return undefined;

	const text = response.content
		.filter((c): c is { type: "text"; text: string } => c.type === "text")
		.map((c) => c.text)
		.join(" ")
		.trim();

	if (!text || INVALID_GENERATED_TITLE.some((pattern) => pattern.test(text))) {
		return undefined;
	}
	return clampTitle(text);
}

export default function (pi: ExtensionAPI) {
	let timer: ReturnType<typeof setInterval> | null = null;
	let frameIndex = 0;
	let currentTask: string | undefined;
	let genController: AbortController | null = null;

	function idleTitle(): string {
		return currentTask ?? projectTitle(pi);
	}

	function stop(ctx: ExtensionContext) {
		if (timer) {
			clearInterval(timer);
			timer = null;
		}
		frameIndex = 0;
		ctx.ui.setTitle(idleTitle());
	}

	function start(ctx: ExtensionContext) {
		stop(ctx);
		timer = setInterval(() => {
			const frame = BRAILLE_FRAMES[frameIndex % BRAILLE_FRAMES.length];
			ctx.ui.setTitle(`${frame} ${idleTitle()}`);
			frameIndex++;
		}, 80);
	}

	pi.on("session_start", async (_event, ctx) => {
		if (ctx.mode !== "tui") return;
		ctx.ui.setTitle(idleTitle());
	});

	pi.on("before_agent_start", async (event, ctx) => {
		if (ctx.mode !== "tui") return;
		const prompt = event.prompt?.trim();
		if (!prompt) return;

		currentTask = taskFromPrompt(prompt) ?? currentTask;

		genController?.abort();
		const controller = new AbortController();
		genController = controller;

		void generateTitle(ctx, prompt, controller.signal)
			.then((title) => {
				if (controller.signal.aborted || !title) return;
				currentTask = title;
				// The spinner loop picks up the new currentTask on its own next
				// tick while working; only need to push it ourselves when idle.
				if (!timer) ctx.ui.setTitle(idleTitle());
			})
			.catch(() => {});
	});

	pi.on("agent_start", async (_event, ctx) => {
		if (ctx.mode !== "tui") return;
		start(ctx);
	});

	pi.on("agent_settled", async (_event, ctx) => {
		if (ctx.mode !== "tui") return;
		stop(ctx);
	});

	pi.on("session_shutdown", async (_event, ctx) => {
		if (ctx.mode !== "tui") return;
		genController?.abort();
		stop(ctx);
	});
}
