# mymate — implementation

What mymate is, how the pieces fit, what it orders, and what it still has to do.

---

## 1. What it is

**mymate is the conductor.** The captain talks to one agent; that agent observes
the other agents running in [herdr](https://herdr.dev) panes, decides who should
own each request, hands the work over, and reports back in outcomes.

It is not a scheduler, a job queue, or a dashboard. It is a *router with a memory
of what everyone is doing*, and a permission boundary so routine work never
waits on a human.

```
        captain
           │  "get the cabin sim on screen"
           ▼
      ┌─────────────┐   route     ┌──────────────┐
      │   mymate    │────────────▶│    cabin     │  owns the simulation
      │ (conductor) │             │  (crew agent)│
      └─────────────┘             └──────────────┘
           │  observe                    │  works
           │  grant / escalate           ▼
           │                        cabin-agent-sim
           ▼
   herdr (panes, agents, state)
```

---

## 2. What it does

| capability | command | what actually happens |
| --- | --- | --- |
| Observe the crew | `mymate status` | lists workspaces, tabs, panes, agents and their state |
| Fast colour board | `mymate probe` | yellow=working, red=blocked, green=ready, with time-in-state |
| Diff against last look | `mymate check` | prints only what changed since the previous snapshot |
| Watch continuously | `mymate watch` | notifies on any state transition, optionally `--until` a state |
| Read one agent | `mymate read <target>` | that agent's recent output, unwrapped |
| Hand over new work | `mymate dispatch <name> <kind> "<brief>"` | creates a **visible herdr tab/pane**, starts a managed agent, delivers the brief |
| Steer existing work | `mymate talk <target> "<text>"` | types into the agent's own prompt surface |
| Answer a dialog | `mymate key <target> <key>…` | logical keys (`enter`, `esc`, `right`, `ctrl+c`) |
| Ship skills | `mymate skills …` | list / fetch / add worker skills |

---

## 3. How the pieces fit

```
  herdr server  ──(native pane.agent_status_changed events)──▶  herdr-status-plugin
                                                                        │
                                                          writes %LOCALAPPDATA%\mymate
                                                                        │
   bin/mymate (CLI)  ◀── reads state files + queries herdr API ─────────┘
        │
        ▼
   the conductor agent (loads mymate.skill.md, obeys conductor-policy.md)
```

**Components**

| path | role |
| --- | --- |
| `bin/mymate`, `bin/mymate.cmd`, `bin/mymate.ps1` | the CLI (PowerShell core, Unix shim) |
| `bin/lib/install.sh` | idempotent `install` bootstrap and `doctor` diagnostics |
| `VERSION`, `INSTALL.md` | release version and manual fresh-clone path |
| `templates/conductor-policy.md` | non-destructive policy seed template |
| `herdr-status-plugin/` | herdr plugin: native events → state files, server-owned so it survives client detach |
| `skills/` | worker skills handed to crew agents at dispatch |
| `mymate.skill.md` | the conductor contract (turn shape, signal reading, relay rules) |
| `conductor-policy.md` | the captain's standing rules — highest authority |
| `watch-herdr.ps1` | reconciliation + visible-prompt fallback when the plugin misses a transition |
| `herdr-server-failsafe.ps1` | restarts a dead herdr server |
| `backup-herdr-session.ps1` | snapshots `session.json` before risky operations |

**State files** (`%LOCALAPPDATA%\mymate\`, runtime only, never committed)

| file | role |
| --- | --- |
| `herdr-state.json` | live snapshot of every agent and state |
| `herdr-blockers.json` | who is blocked right now |
| `herdr-event-alerts.jsonl` | append-only native event stream |
| `herdr-conductor-inbox.jsonl` | items the conductor must read and relay |
| `herdr-auto-approvals.jsonl` | permissions the conductor granted on its own |

---

## 4. What is ordered

Two different orderings, and they are easy to confuse:

**a) The order of work** — the attention queue. `agent_panel_sort = "priority"`
makes the agent panel an attention queue: blocked first, then working, then
ready. The conductor's rule is that a red signal pre-empts everything else: a
blocked agent is waiting on a decision, and that decision is the only thing that
matters until it is carried back.

**b) The order of operations per turn** — the conductor's turn shape:

1. `mymate status` — read the whole crew first, every turn
2. route: `dispatch` for new work, `talk` to steer the agent that already owns it
3. any `blocked` → `read` that target → relay to the captain → carry the answer back
4. `watch` for the next transition worth reporting
5. report **outcomes**, never status ticks

**c) The permission order** — the conductor grants routine prompts itself and
escalates only the dangerous list in `conductor-policy.md` §3.

**d) Naming and placement order** — every crew pane ends in a labelled herdr
tab, but the safe startup sequence is `pane split` → `agent start` →
`pane move --new-tab` (never a direct `tab create` spawn, never a CLI window,
never a hidden `--session`); agent names are 1–6 letters and say what the agent
owns; the tab label repeats the role so the sidebar reads on its own.

---

## 5. Mission list

**Done**

- [x] restore the `mymate` CLI after it vanished from `bin/`
- [x] revive the signal bridge (native plugin active, survives client detach)
- [x] reconcile stale state so a conductor is not told about dead panes
- [x] write the captain's policy to disk so it survives a new session
- [x] short, meaningful agent names + self-explaining tab labels
- [x] herdr tabs for every pane, never CLI windows
- [x] fix `mymate talk` returning `null is null`
- [x] wordmark + mark + README + this document

**Next**

- [ ] commit `src/cabin.js` in cabin-agent-sim (boundary contracts) — waiting on the captain's word
- [ ] clean the 320-entry `herdr-conductor-inbox.jsonl`: archive-and-hash first, protect live pane IDs, no wildcard deletes
- [ ] real client-detach test for the bridge (needs explicit approval)
- [ ] make the conductor's own pane managed, so it resumes after a herdr restart like the crew does

**Later**

- [ ] attention-queue ordering by role, not only by state (needs upstream support in herdr)
- [ ] ship the pixel mark as the repo favicon and the wordmark into the site header — deliberately deferred, that page is the captain's portfolio
- [ ] record the crew's per-agent briefs in one place, so a new conductor can pick up context cold
- [x] a `mymate doctor` that checks plugin liveness, stale panes and integration versions in one command

---

## 6. Known limits

- **The agent panel has no identity ordering.** `agent_panel_sort` is the only
  key (`spaces` / `priority`). A permanent top row needs the conductor to be the
  leftmost pane of the first tab.
- **Unmanaged panes do not resume.** Panes started by typing an agent name come
  back as plain shells after a herdr restart; only panes started with
  `herdr agent start --kind …` carry a resumable session ref. Two legacy panes are
  still in that state.
- **The bridge is event-driven with a polling fallback.** If the plugin is
  disabled, a blocked agent can be noticed late.
- **Runtime state is append-only and grows.** The inbox and event log are never
  pruned automatically.
