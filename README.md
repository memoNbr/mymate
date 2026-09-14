# mymate — a tiny conductor for agents in herdr

mymate is a small, self-contained conductor for a crew of coding agents that
live in [herdr](https://herdr.dev) panes.

You talk to one agent — the conductor — and it watches, dispatches, and leads
the rest. There is no big runtime, no installed app: `mymate` is one bash
command plus one skill file (`mymate.skill.md`) that you load into your primary
agent. Everything else is plain shell over the herdr CLI.

## What you get

- `mymate status` — observe the whole crew: every herdr workspace and every
  agent, with live state (`idle`, `working`, `blocked`, `done`, `unknown`).
- `mymate dispatch <name> <kind> "<brief>" [--skill FILE]` — open a sibling
  pane, start a worker agent in it, hand it a skill and the brief, and report
  when it settles.
- `mymate watch` — keep an eye on the crew; it prints when an agent changes
  state, turns `blocked`, or finishes.
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

MIT — see LICENSE.