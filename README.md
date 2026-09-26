# mymate

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="assets/mymate-logo-dark.png">
  <img src="assets/mymate-logo.png" width="358" height="120" alt="mymate">
</picture>

**Conductor for a crew of coding agents.** mymate observes the agents running in
[herdr](https://herdr.dev) panes, keeps the captain informed, and hands work to
the agent that best owns it — instead of one agent doing everything.

## Start here

- Fresh-clone setup: [`INSTALL.md`](INSTALL.md)
- Architecture, ordering rules, and mission list: [`docs/IMPLEMENTATION.md`](docs/IMPLEMENTATION.md)
- Published landing page: [`index.html`](index.html)
- Field notes and briefs: [`briefs/`](briefs/), [`lessons/`](lessons/),
  [`learning-records/`](learning-records/), and [`reference/`](reference/)

```sh
mymate install         # idempotent bootstrap; --force only for stale files
mymate doctor          # check herdr, PATH, plugin, skill, and state directory
mymate status          # crew board: workspaces, agents, and states
mymate probe           # fast colour board: yellow=busy, red=blocked, green=ready
mymate watch           # live watcher, notifies on colour changes
mymate read <target>   # read one agent's recent output
mymate dispatch <name> <kind> "<brief>"
mymate talk <target> "<text>"
```

## The conductor tooling

- `mymate open [name] [--kind KIND]` — open a focused conductor pane with the
  conductor contract loaded.
- `mymate status` — observe every Herdr workspace and agent with live state.
- `mymate dispatch <name> <kind> "<brief>" [--skill FILE]` — create a visible
  crew pane, start a worker, hand it a skill and brief, and report settlement.
- `mymate watch` — observe state transitions and settle on a requested state.
- `mymate talk <target> "<text>"` — steer an agent through its native prompt.
- `mymate read <target>` and `mymate key <target> <key>` — inspect or control a
  terminal without attaching.
- `mymate skills …` — list, fetch, add, or scaffold worker skills.
- `herdr-status-plugin/` — the Windows native event hook for
  `pane.agent_status_changed`.
- `watch-herdr.ps1` — the Windows reconciliation and visible-prompt fallback.

## What is in this repository

| path | what it is |
| --- | --- |
| `bin/` | the `mymate` CLI (`mymate`, `mymate.cmd`, `mymate.ps1`, `lib/`) |
| `INSTALL.md` | manual fresh-clone setup and platform limitations |
| `VERSION` | the CLI/plugin release version reported by `mymate --version` |
| `templates/` | non-destructive seed template for a missing `conductor-policy.md` |
| `herdr-status-plugin/` | native Herdr event bridge and state-file writer |
| `conductor-policy.md` | standing crew, permission, and placement rules |
| `mymate.skill.md` | the conductor contract loaded by the primary agent |
| `skills/` | worker skills handed to crew agents at dispatch |
| `docs/IMPLEMENTATION.md` | architecture, orderings, mission list, and known limits |
| `watch-herdr.ps1` | reconciliation / visible-prompt fallback watcher |
| `herdr-server-failsafe.ps1` | restarts a dead Herdr server |
| `backup-herdr-session.ps1` | snapshots `session.json` before risky operations |
| `index.html`, `style.css`, `script.js`, `assets/site.css` | the published landing page and its stylesheet |
| `briefs/`, `lessons/`, `learning-records/`, `reference/` | field notes, briefs, and reference material |
| `MISSION.md`, `NOTES.md`, `RESOURCES.md`, `LICENSE` | project background and licensing |

`skills/herdr.skill.md` is retained from the published tooling lineage and can
be refreshed from the installed Herdr binary with `mymate skills fetch`.

## State files

Runtime state is written outside Git:

- Windows: `%LOCALAPPDATA%\mymate\`
- macOS/Linux: `<repo>/.mymate-state/`

| file | contents |
| --- | --- |
| `herdr-state.json` | live snapshot of every agent and its state |
| `herdr-blockers.json` | agents currently blocked on a decision |
| `herdr-event-alerts.jsonl` | append-only native event stream |
| `herdr-conductor-inbox.jsonl` | items the conductor must read and relay |
| `herdr-auto-approvals.jsonl` | permission prompts the conductor granted |

## Setup and safety

Read [`INSTALL.md`](INSTALL.md) for the complete Windows/macOS/Linux path.
`mymate install` never edits your `PATH` or overwrites an existing conductor
skill or policy without explicit `--force` where applicable.

Mutating commands (`dispatch`, `talk`, `key`) require `HERDR_ENV=1`; read-only
`status`, `probe`, and `read` do not. IDs come from Herdr JSON responses, never
from tab order.

Every crew pane must end in a labelled, visible Herdr tab. The safe startup
sequence is:

```sh
herdr pane split --current --direction right --cwd "$PWD" --no-focus
herdr agent start <name> --kind <kind> --pane <pane-id>
herdr pane move <pane-id> --new-tab --label "<label>" --tab-label "<label>" --no-focus
```

Never use a CLI window, a background shell, or a hidden `herdr --session` for a
crew member. See [`conductor-policy.md`](conductor-policy.md) for the full
placement and permission boundary.

## Windows signal bridge

The native plugin is Windows-only. It receives `pane.agent_status_changed`
events and writes the event stream and conductor inbox without requiring a
client attachment. `watch-herdr.ps1` is the reconciliation fallback: it polls
`mymate status --json`, maintains state/blocker snapshots, and detects visible
permission prompts that native lifecycle state misses. It is observe-only and
never approves prompts or sends agent input.

On macOS and Linux the CLI remains usable, but this Windows JSONL event bridge
is not installed; use the CLI boards or a compatible polling fallback.

## Published material

The landing page remains at [`index.html`](index.html). The surrounding
material is intentionally preserved from the published lineage:

- [`briefs/`](briefs/) — task and project briefs
- [`lessons/`](lessons/) — recorded lessons
- [`learning-records/`](learning-records/) — learning-record entries
- [`reference/`](reference/) — reference notes
- [`MISSION.md`](MISSION.md), [`NOTES.md`](NOTES.md), [`RESOURCES.md`](RESOURCES.md)

## License

MIT — see [`LICENSE`](LICENSE).
