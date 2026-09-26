# Draft upstream issue — DO NOT FILE until reviewed

Target repo: https://github.com/herdrdev/herdr (verify before filing — this draft assumes it's the official tracker)
Suggested labels: bug, windows, session/restore

---

**Title:** Restored tabs silently deleted ~4 min after restore: pane dies with 0xC000013A + "PaneDied for unknown pane", no tab.close issued

**Body:**

### Environment
- Herdr **0.9.1** (update channel `preview`)
- Windows 11 Pro (user paths contain a space, e.g. `C:\Users\<name with a space>\...`)
- Config: `[session] resume_agents_on_restore` and `[experimental] pane_history` were **absent** at the time (defaults) — added afterwards, unrelated to this repro

### Summary
After a server restart, the session restored successfully (`persist.restore outcome="ok"`), but **two restored tabs were destroyed ~4 minutes later** without any user action closing them. Their panes exited with `0xC000013A` (STATUS_CONTROL_C_EXIT, logged as `signal=Hangup`) immediately after a `tab.focus`, and Herdr reported `PaneDied for unknown pane` — i.e. the death event referenced a pane the app state no longer (or never) tracked. The tabs were dropped from `session.json` on the next save.

The same failure pattern (`PaneDied for unknown pane` + exit `0xC000013A`, **without** a preceding `tab.close`/`pane.close` API call) also occurred **mid-run** on the previous server run for several panes, so this is not restore-specific — but restore makes it worse because the persisted snapshot is silently reduced afterwards.

### Timeline (from herdr-server.log)

Previous run (server started `2026-09-23T01:06:51Z`):
```
2026-09-23T02:15:24  pane.split creates pane 8 (tab w1:t12)
2026-09-23T02:19:15  agent changed pane=8 -> OpenCode
2026-09-23T02:27:09  WARN pane session still alive after forced shutdown pane=8 pid=23924 pids=[23924, 24548]
2026-09-23T02:27:14  pane session terminated pane=8 signal=Hangup
                     pane.exit status="ExitStatus { code: 3221225786, signal: None }"
                     WARN herdr::app::actions: PaneDied for unknown pane pane=8
                     # no tab.close / pane.close API request precedes this
2026-09-23T02:33:30  same pattern, pane=5 (tab w1:tY)  — 1s after tab.focus w1:tY
2026-09-23T02:33:34  same pattern, pane=6 (tab w1:tZ)  — 1s after tab.focus w1:tZ
2026-09-23T03:07:13  same pattern, pane=9 (split pane)
```

Server killed without final save (last `persist.save` `2026-09-23T12:04:55Z`, last log line `12:29:48Z`, next line is the new server start `2026-09-24T00:42:13Z`) — separate observation: no save appears to happen on ungraceful shutdown.

Restore run:
```
2026-09-24T00:42:14.065  persist.restore outcome="ok" workspaces=1   # restored 6 tabs incl. w1:t14, w1:t15
2026-09-24T00:43:22      tab.focus w1:t14            → ok
2026-09-24T00:46:06      tab.focus w1:t14            → ok
2026-09-24T00:46:10.473  tab.focus w1:t15            → ok
2026-09-24T00:46:10.490  pane session terminated pane=6 pid=15248 signal=Hangup
                         pane.exit status="ExitStatus { code: 3221225786, signal: None }"
                         WARN herdr::app::actions: PaneDied for unknown pane pane=6
2026-09-24T00:46:11.707  tab.focus w1:t14            → ok
2026-09-24T00:46:11.726  pane session terminated pane=5 pid=3892 signal=Hangup
                         pane.exit status="ExitStatus { code: 3221225786, signal: None }"
                         WARN herdr::app::actions: PaneDied for unknown pane pane=5
2026-09-24T00:46:31      persist.save ok             # session.json now has 4 tabs; t14/t15 gone
```

Only `notification.show` API requests appear between `00:42` and `00:46:31` — **no `tab.close`, no `pane.close`**.

### Expected behavior
- A restored tab should not die from a console-control signal (`0xC000013A`) shortly after restore/focus.
- If a pane does die, `PaneDied` should not report it as "unknown pane" — suggests the PID→pane mapping is stale or the pane was already evicted from app state (stale/recycled PID bookkeeping across restore?).
- A tab dropped due to pane death should ideally not be silently removed from the persisted snapshot, or should at least be logged with its tab_id/label.

### Notes for reproduction
- Both death sites are immediately preceded by `tab.focus` on the affected tab.
- exit code `3221225786` = `0xC000013A` = STATUS_CONTROL_C_EXIT; Herdr logs it as `signal=Hangup`.
- `PaneDied for unknown pane` also fired for *intentionally* closed tabs (post-`tab.close`), which may be normal cleanup — the bug is the same warning appearing for panes no one closed.
- Windows-only as far as observed; `0xC000013A` is a Windows console teardown code.

### Impact
Session restore silently loses tabs; with no `session.json` rotation the earlier snapshot is overwritten and the tabs are unrecoverable (labels/cwds survive only in the server log).

---

## Second reproduction — 2026-09-25 (cleaner than the first)

Config **with** `[session] resume_agents_on_restore = true` and `[experimental] pane_history = true` both present, integrations current (opencode v12, pi v9, kilo v4), binary `herdr 0.9.1` built `2026-09-16`.

```
01:55:39.177  api server listening (fresh server start)
01:55:39.188  pane.spawn pane=2 pid=1828; pane=3 pid=24116; pane=4 pid=25980   # restored tabs
01:55:39.346  persist.restore outcome="ok" workspaces=1   # 4 tabs: w1:t2, w1:tV, w1:t11, w1:t13
01:55:57-01:56:00  tab.focus tV, t11, t13, t2 → all ok, all panes healthy (~18 s of normal use)
01:56:05.588  persist.save ok                             # session.json has 4 tabs
01:56:34.309  tab.focus w1:t11 → ok
01:56:34.326  pane session terminated pane=3 signal=Hangup       # 17 ms after its own tab.focus
01:56:34.351  pane.exit status="ExitStatus { code: 3221225786 }" # 0xC000013A
01:56:34.352  WARN herdr::app::actions: PaneDied for unknown pane pane=3
01:56:36.241  tab.focus w1:t13 → ok → pane=4 dies identically   # 18 ms later
01:56:37.922  tab.focus w1:tV  → ok → pane=2 dies identically   # 18 ms later
01:56:42.944  persist.save ok                             # session.json now has ONLY w1:t2
```

Observations strengthening the diagnosis:

- **Death is consistently 17–18 ms after `tab.focus` of the dying tab's own tab** (this run) or 1–4 s (2026-09-24 run) — focus-correlated, Windows console teardown (`0xC000013A`) — as if focusing attaches/detaches a hidden console whose handle is stale for restored panes.
- Restored panes had spawned fine 55 s earlier and survived multiple focus cycles of *other* tabs; the first focus *of their own tab* after ~1 min killed them. On 2026-09-24 the two deaths likewise followed `tab.focus` within 1–4 s.
- **No `tab.close`/`pane.close` API request occurs between restore and death** — only `tab.focus` and `notification.show`.
- The surviving tab was the one whose pane the attached TUI client had (re)spawned itself, not the ones spawned by the restore path — perhaps the restore-path spawned panes hold a console/control handle the focus path then signals.
- Each death removes the tab from app state, and the next `persist.save` **overwrites session.json without any tombstone or rotation**, so the layout is unrecoverable from Herdr's own files (we rebuilt it from a manually kept `session.json.bak`).

---

## Post-update verification — 2026-09-25 (update applied, bug did NOT reproduce)

Updated both client and server to **0.9.1-preview.2026-09-21-0ff0f27e2226** (head = PR #4400 "preserve session layouts across shutdown and restore failures", merged 2026-09-20). Restart performed via `herdr server stop` + fresh `herdr` launch.

```
02:17:54Z  herdr server stop (deliberate restart; the two PaneDied ERROR lines at 02:17:56Z for panes 7/8
           are shutdown noise — "failed to send PaneDied event ... channel closed" — not this bug)
02:18:52Z  new server starts on 0ff0f27e2226; client matches (restart_needed=no, server_binary_stale=no)
02:18:53Z  persist.restore outcome="ok" — 5 tabs (w1:t2, w1:t16, w1:t17, w1:t18, w1:t19), 5 panes spawned
02:18:54Z  resume_agents relaunches opencode in t2 and kilo in t16
02:22:14–02:23:51Z  tab.focus cycle t16 → t17 → t18 → t19 → t2 — every restored tab focused in turn,
           5 s dwell each — all ok (this is the exact trigger that killed panes 17–18 ms after their
           own tab.focus 22 minutes earlier)
02:25–02:28Z  further tab.focus activity by the user — all ok
02:31Z+    all 5 tabs still present; zero PaneDied / 0xC000013A entries in herdr-server.log after the
           restart; session.json still contains all 5 tabs on the next persist.save
```

**Outcome: no reproduction on the updated binary.** PR #4400 appears to fix the failure (layout snapshots keep panes; the focus/console path no longer eats restored tabs).

Disposition: per the test-first agreement, filing is **on hold pending decision** — current evidence favors *not filing*. If a future restore again loses tabs on focus, reopen this draft and add a third, post-#4400 reproduction.
