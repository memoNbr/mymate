#!/usr/bin/env bash
# bin/lib/herdr.sh - thin herdr CLI wrappers for the mymate conductor.
# JSON in, IDs parsed from JSON out. Everything here is read alongside the
# current `herdr --skill`; refresh it with `mymate skills fetch`.

MM_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

die() { printf 'mymate: %s\n' "$*" >&2; exit 1; }

mm_require_herdr() {
  command -v herdr >/dev/null 2>&1 || die "herdr CLI not found (needed for herdr control)"
}

mm_require_inside_herdr() {
  test "${HERDR_ENV:-}" = 1 || die "must run inside a herdr pane (HERDR_ENV=1); refusing to poke a session from outside"
}

# mm_hdr <args...> : run the herdr CLI; exit status preserved, stderr kept.
mm_hdr() { herdr "$@"; }

# mm_hdr_json <args...> : run a JSON-producing herdr command safely.
mm_hdr_json() {
  local out status
  out="$("$@" 2>/tmp/mymate-hdr.err)" || { cat /tmp/mymate-hdr.err >&2; return $?; }
  printf '%s\n' "$out"
}

# mm_jq <filter> < <json> : jq when available, raw pass-through otherwise.
mm_jq() {
  local jq=""
  if command -v jq >/dev/null 2>&1; then
    jq="$(command -v jq)"
  elif [ -n "${MM_JQ:-}" ] && [ -x "$MM_JQ" ]; then
    jq="$MM_JQ"
  else
    local p
    for p in "$LOCALAPPDATA"/Microsoft/WinGet/Packages/jqlang.jq_*/jq.exe /mingw64/bin/jq /usr/bin/jq /usr/local/bin/jq; do
      [ -x "$p" ] && { jq="$p"; break; }
    done
  fi
  if [ -n "$jq" ]; then
    "$jq" -r "$1"
  else
    cat
  fi
}

# mm_agents_json : the raw `herdr agent list` payload.
mm_agents_json() { mm_hdr_json herdr agent list; }

# mm_workspaces_json : the raw `herdr workspace list` payload.
mm_workspaces_json() { mm_hdr_json herdr workspace list; }

# mm_agent_get <target> : `herdr agent get` (JSON with agent_status, cwd, ...).
mm_agent_get() { mm_hdr_json herdr agent get "$1"; }

# mm_agent_prompt <target> <text> [--wait] [--timeout MS] : submit work/steer.
mm_agent_prompt() { herdr agent prompt "$@"; }

# mm_agent_read <target> [--lines N] [--source S]
mm_agent_read() { herdr agent read "$@"; }

# mm_agent_keys <target> <key...>
mm_agent_keys() { herdr agent send-keys "$@"; }

# mm_split_sibling : split a sibling pane preserving this pane's cwd, no focus.
# Prints the new pane id. Requires HERDR_ENV=1.
# Note: spawn via pane split instead of tab create - spawning on a freshly
# created tab currently segfaults Bun (opencode TUI crash). Move the pane to
# its own tab AFTER the agent has booted (see mm_dispatch_tab).
mm_split_sibling() {
  mm_require_inside_herdr
  local out
  out="$(herdr pane split --current --direction right --cwd "$PWD" --no-focus 2>/tmp/mymate-split.err)" \
    || { cat /tmp/mymate-split.err >&2; return 1; }
  local pane_id
  pane_id="$(printf '%s\n' "$out" | mm_jq '.result.pane.pane_id // empty')"
  [ -n "$pane_id" ] || die "could not read new pane id from: $out"
  printf '%s\n' "$pane_id"
}

# mm_split_focused : like mm_split_sibling but takes focus (the `open` command,
# so the captain is dropped straight into the conductor pane).
mm_split_focused() {
  mm_require_inside_herdr
  local out
  out="$(herdr pane split --current --direction right --cwd "${1:-$PWD}" --focus 2>/tmp/mymate-split.err)" \
    || { cat /tmp/mymate-split.err >&2; return 1; }
  local pane_id
  pane_id="$(printf '%s\n' "$out" | mm_jq '.result.pane.pane_id // empty')"
  [ -n "$pane_id" ] || die "could not read new pane id from: $out"
  printf '%s\n' "$pane_id"
}

# mm_agent_start <name> <kind> <pane_id> [-- agent-args...]
mm_agent_start() { herdr agent start "$@"; }

# mm_agent_focus <target> : bring an agent's pane forward.
mm_agent_focus() { herdr agent focus "$@"; }

# mm_agent_names : plain list of current agent names, one per line.
mm_agent_names() {
  mm_agents_json | mm_jq '.result.agents[].agent'
}