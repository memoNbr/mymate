# mymate — a tiny conductor for agents in herdr

mymate is a small, self-contained conductor for a crew of coding agents that
live in [herdr](https://herdr.dev) panes.

You talk to one agent — the conductor — and it watches, dispatches, and leads
the rest. There is no big runtime, no installed app: `mymate` is one bash
command plus one skill file (`mymate.skill.md`) that you load into your primary
agent. Everything else is plain shell over the herdr CLI.

## What you get

- `mymate open [name] [--kind KIND]` — like firstmate's open-in-herdr: pop a
  focused mymate conductor pane you can talk to directly, preloaded with the
  conductor contract. Reuses the pane if the conductor is already open.
- `mymate status` — observe the whole crew: every herdr workspace and every
  agent, with live state (`idle`, `working`, `blocked`, `done`, `unknown`).
- `mymate dispatch <name> <kind> "<brief>" [--skill FILE]` — open a sibling
  pane, start a worker agent in it, hand it a skill and the brief, and report
  when it settles.
- `mymate watch` — keep an eye on the crew; it prints when an agent changes
  state, turns `blocked`, or finishes.
- `watch-herdr.ps1` — optional Windows bridge that polls state changes,
  displays an immediate Herdr notification, and records transition alerts for
  the conductor to read and relay.
- `herdr-status-plugin\` — installed local Herdr event hook that receives
  `pane.agent_status_changed` directly and forwards it to the conductor inbox.
- `mymate talk <target> "<text>"` — steer one agent ("shipshape the login
  test", "pause and report findings") through its native prompt surface.
- `mymate read <target>`, `mymate keys <target> esc` — inspect or poke an
  agent's terminal without attaching.
- `mymate skills fetch` — download herdr's own current agent skill into
  `skills/herdr.skill.md`; `mymate skills add <url>` pulls any skill.md to
  base a worker on; `mymate skills new <name>` scaffolds a starter worker.

## Layout

- `bin/mymate` — the CLI (bash, works in Git Bash and any POSIX shell).
- `bin/lib/herdr.sh` — thin herdr CLI wrappers (JSON in, IDs parsed from JSON).
- `mymate.skill.md` — the conductor contract your primary agent loads.
- `skills/herdr.skill.md` — herdr's own current agent skill (run `mymate skills fetch`).
- `skills/starter.skill.md` — template for a worker agent's skill.

## Setup

Prerequisites: herdr installed and running, `jq` (optional but recommended),
and your worker kinds available via `herdr agent` (opencode, codex, claude,
and many more are supported by herdr itself).

Make the CLI reachable and load the conductor skill:

```sh
git clone https://github.com/<you>/mymate && cd mymate   # or just use this folder
chmod +x bin/mymate
alias mymate="$PWD/bin/mymate"        # add to ~/.bashrc to make it permanent
```

Open herdr, start a pane, and in it run your primary agent with
`mymate.skill.md` loaded (for opencode, run `opencode` in this folder; the
conductor skill is at `mymate.skill.md`). The conductor takes over from there.

## Safety posture

- `dispatch`, `talk`, and `keys` refuse to run outside a herdr pane
  (`HERDR_ENV=1`); `status` and `read` are read-only and allowed anywhere.
- `dispatch` always uses a sibling pane (`--no-focus`) and never touches a
  pane, tab, or workspace the captain did not ask about.
- IDs are parsed from herdr's JSON responses, never guessed from ordering.
- Everything is one bash file you can read end to end.

### Immediate Windows signal bridge

From a Herdr-managed PowerShell pane, run:

```powershell
.\watch-herdr.ps1
```

The installed event plugin receives native `pane.agent_status_changed` events
without polling and writes `herdr-event-alerts.jsonl`. It shows a request
notification for `blocked` and appends high-priority entries to the conductor
inbox. `watch-herdr.ps1` remains a reconciliation fallback: it polls
`mymate status --json`, maintains `herdr-state.json` and `herdr-blockers.json`,
and checks visible panes only for prompts that native lifecycle state misses.
Every blocked transition is also appended to
`herdr-conductor-inbox.jsonl`, a durable high-priority queue that the conductor
must read and relay before routing other work.
The watcher also writes effective states to
`%USERPROFILE%\.mymate\effective-colors.state`; `mymate probe`, `check`, and
`watch` use this override so visible permission prompts are shown as red even
when an integration incorrectly reports yellow/working.
It never answers permission prompts or sends agent input automatically; the
conductor must read the target and relay the captain's decision.

MIT — see LICENSE.