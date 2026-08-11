---
name: hr-attendance
description: Check in, check out, or see HR attendance/leave status via the pm CLI (`pm hr`). Use when the user asks to "check in", "check out", "clock in/out", or check their HR/attendance status. Pre-authorized — run checkin/checkout without asking for confirmation.
---

# HR attendance (pm hr)

Wraps the `pm hr` subcommands of the wesionary.team `pm` CLI for daily attendance.

## When to use
- User asks to **check in** / clock in → `pm hr checkin`
- User asks to **check out** / clock out → `pm hr checkout`
- User asks for **HR status**, "am I checked in?", attendance or leave balance → `pm hr status`

## Commands

| Intent | Command |
| --- | --- |
| Check in (default: working from home) | `pm hr checkin` |
| Check in from office | `pm hr checkin --location office` |
| Check out | `pm hr checkout` |
| Status (today's attendance + leave balances) | `pm hr status` |

Default check-in location is `home`. Only pass `--location office` when the user says they're at the office (or their equivalent phrasing).

## Rules
- **Do NOT ask for confirmation** before running `checkin` or `checkout` — the user has pre-authorized these. Just run the command and report the result.
- This pre-authorization covers only `checkin`, `checkout`, and `status`. For anything else (`leave`, `amend`, approvals, etc.) confirm intent first and check `pm hr <command> --help`.
- After running, report the CLI's confirmation back to the user concisely (checked-in time, location, or status summary). If it errors (e.g. not logged in), surface the error — the user may need `pm login`.

## Notes
- Requires the `pm` CLI on PATH and a logged-in session (`pm login`).
- Discover other options anytime with `pm hr --help` or `pm hr <command> --help`.
