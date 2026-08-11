#!/bin/bash

# herdr-sessionizer
# Fuzzy-pick a project and open it as a workspace inside the single
# persistent, agent-aware herdr session.
# Port of tmux-sessionizer (ThePrimeagen) to herdr:
#   tmux session  ->  herdr workspace (project = workspace, all in one session)

selected=$(find ~/projects -mindepth 1 -maxdepth 2 -type d | fzf)

if [[ -z $selected ]]; then
  exit 0
fi

label=$(basename "$selected" | tr . _)

# The workspace API talks to the herdr server over its socket — make sure it's up.
if ! herdr status server >/dev/null 2>&1; then
  herdr server >/dev/null 2>&1 &
  for _ in $(seq 1 30); do
    herdr status server >/dev/null 2>&1 && break
    sleep 0.1
  done
fi

# Reuse an existing workspace with this label, else create one at the project dir.
existing=$(herdr workspace list 2>/dev/null \
  | jq -r --arg l "$label" '.result.workspaces[]? | select(.label==$l) | .workspace_id' \
  | head -n1)

if [[ -n $existing ]]; then
  herdr workspace focus "$existing" >/dev/null
else
  herdr workspace create --cwd "$selected" --label "$label" --focus >/dev/null
fi

# If we're not already inside a herdr pane, attach the client to land in it.
if [[ "${HERDR_ENV:-}" != "1" ]]; then
  exec herdr
fi
