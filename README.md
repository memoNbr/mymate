# mymate

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="assets/mymate-logo-dark.png">
  <img src="assets/mymate-logo.png" width="358" height="120" alt="mymate">
</picture>

**Conductor for a crew of coding agents.** mymate observes the agents running in
[herdr](https://herdr.dev) panes, keeps the captain informed, and hands work to
the agent that best owns it — instead of one agent doing everything.

Full architecture, ordering rules and the mission list:
**[`docs/IMPLEMENTATION.md`](docs/IMPLEMENTATION.md)**.

Fresh-clone setup and the manual Windows/macOS/Linux path:
**[`INSTALL.md`](INSTALL.md)**.

```
mymate install         # idempotent bootstrap; add --force only to replace stale files
mymate doctor          # check herdr, PATH, plugin, skill, and state directory
mymate status          # crew board: workspaces + agents and their states
mymate probe           # fast colour board: yellow=busy, red=blocked, green=ready
mymate watch           # live watcher, notifies on any colour change
mymate read <target>   # read one agent's recent output
mymate dispatch <name> <kind> "<brief>"
mymate talk <target> "<text>"
```

<p align="left">
  <img src="assets/mymate-mark.svg" width="20" height="20" alt="">
  <code>mymate</code>
</p>

The wordmark is set the way you would type it — monospace, one ink colour, with a
block cursor (`assets/mymate-logo.svg`). The small pixel mark
(`assets/mymate-mark.svg`) is the same idea on a 16px grid for favicons and
avatars. No fonts embedded, no dependencies, crisp at any size.

## What is in this repository

| path | what it is |
| --- | --- |
| `bin/` | the `mymate` CLI (`mymate`, `mymate.cmd`, `mymate.ps1`, `lib/`) |
| `INSTALL.md` | manual fresh-clone setup; Windows-only bridge limitation is stated first |
| `VERSION` | the CLI/plugin release version consumed by `mymate --version` |
| `templates/` | non-destructive seed template for a missing `conductor-policy.md` |
| `herdr-status-plugin/` | herdr plugin: receives native `pane.agent_status_changed` events and writes the bridge state files |
| `conductor-policy.md` | **standing rules from the captain** — tab/tab naming, permission boundaries, delegation |
| `mymate.skill.md` | the conductor contract the primary agent loads |
| `skills/` | worker skills handed to crew agents at dispatch |
| `watch-herdr.ps1` | reconciliation / visible-prompt fallback watcher |
| `herdr-server-failsafe.ps1` | restarts the herdr server if it dies |
| `backup-herdr-session.ps1` | snapshots `session.json` before risky operations |
| `herdr-issue-PaneDied-after-restore.md` | upstream bug report: `PaneDied for unknown pane` after restore |
| `mymate-repair-record.md` | record of the CLI + signal-bridge repair |
| `docs/` | architecture, the four orderings, mission list, known limits |

`skills/herdr.skill.md` is **not** committed — it belongs to Herdr and
`mymate skills fetch` regenerates it from `herdr --skill` during install.

## State files (written at runtime, not in git)

`%LOCALAPPDATA%\mymate\`

| file | contents |
| --- | --- |
| `herdr-state.json` | live snapshot of every agent and its state |
| `herdr-blockers.json` | agents currently blocked on a decision |
| `herdr-event-alerts.jsonl` | append-only native event stream from the plugin |
| `herdr-conductor-inbox.jsonl` | items needing the conductor to read and relay |
| `herdr-auto-approvals.jsonl` | permission prompts the conductor granted |

## Crew conventions

- **Every crew pane is visible in a labelled herdr tab**: split a shell pane,
  start the agent, then move the booted pane with `herdr pane move --new-tab`.
  Never use a CLI window or a hidden `--session`.
- **Agent names are short and unique**: 1–6 letters, describing the job
  (`cabin`, `webfix`, `repair`, `mymate`).
- **The conductor grants routine permissions** and escalates only the dangerous
  ones — see `conductor-policy.md` for the exact boundary.
- **Lead from the start**: check the crew, name the best owner, hand it over.

---

## Logo

The lockup is set in **Cascadia Mono SemiBold** — Microsoft's terminal typeface —
with tightened tracking and a block cursor in the brand pink. Light and dark
variants ship with the repo and swap automatically via `prefers-color-scheme`,
so the logo reads correctly on any background:

| file | use |
| --- | --- |
| `assets/mymate-logo.png` | 717×239, ink on transparent (light backgrounds) |
| `assets/mymate-logo-dark.png` | 717×239, cream on transparent (dark backgrounds) |
| `assets/mymate-mark.svg` | the 16px icon — a cursor and its crew |
| `assets/mymate-logo.txt` | the half-block terminal banner the CLI prints |

The terminal banner is the same identity in text art, the idiom OpenCode and
Kilo use for their marks — `█ ▀ ▄` on a monospace grid:

```
█▄█ █ █ █▄█ ▄█▄   █  ▄█▄
█ █ ███ █ █ ██▄ ▀█▀  ███
█ █  █▀ █ █ ▄██  █  ▄██
█ █  █  █ █ ▀▀█ ▄█▄ ▀▀▀
```
