# MyMate repair record

- **Recorded/updated:** 2026-09-25T14:43:22+02:00
- **Approved scope:** restore the recoverable CLI and bridge source; no stale-data cleanup, no new pane/tab, no automatic approvals.
- **Follow-up approval:** run the restored watcher once to refresh the state/blocker snapshot; no persistent watcher process.
- **Source of truth:** Git commit `61c505077825c23dab635fc064a4ae90b8794a7c` (`mymate: native status-event plugin plus visible-prompt reconciliation`, 2026-09-21). A local archive of an earlier distribution was inspected read-only and was not used; it is a separate distro and explicitly not a CLI.

## Repository paths added or changed

All paths below were absent from the current working tree before the approved repair. Existing untracked Herdr diagnostic scripts were not modified.

- `bin/mymate` — restored conductor CLI; runtime cache paths now use `MM_DATA_DIR`.
- `bin/lib/herdr.sh` — restored JSON wrappers; scratch/error files now stay under the approved data root.
- `bin/mymate.cmd` — portable Git Bash shim using its own directory.
- `bin/mymate.ps1` — portable PowerShell shim using its own directory.
- `mymate.skill.md` — restored conductor contract.
- `skills/android.skill.md`
- `skills/concise.skill.md`
- `skills/env.skill.md`
- `skills/herdr.skill.md`
- `skills/jobbrain.skill.md`
- `skills/jobcore.skill.md`
- `skills/jobscout.skill.md`
- `skills/mind.skill.md`
- `skills/ssh.skill.md`
- `skills/starter.skill.md`
- `watch-herdr.ps1` — restored bridge with observe-only default, atomic snapshots, local-data-root state, exact pane-ID reads for unnamed agents, and no automatic key/approval actions. The one-shot run also required a Windows PowerShell 5.1 `List[object]` materialization fix.
- `herdr-status-plugin/herdr-plugin.toml` — restored manifest at the already-registered local link.
- `herdr-status-plugin/status-event.ps1` — restored event handler with UTF-8 JSONL append and graceful missing-agent handling.
- `mymate-repair-record.md` — this record.

No `package.json` was added; the implementation is shell/PowerShell, not an npm package.

## Local data paths affected under `%LOCALAPPDATA%\\mymate`

- `herdr-event-alerts.jsonl` — append-only native plugin output resumed after source restoration and continues to receive live events.
- `herdr-cli.err` — new empty CLI scratch file created by the restored wrapper layer.
- `probe.state` — new four-line cache created by `mymate probe`.
- `effective-colors.state` — new live four-agent snapshot written by the approved one-shot watcher run.
- `herdr-state.json` — refreshed by the approved one-shot watcher at 2026-09-25T12:42:38Z; now contains the four live agents, including `w1:pC`, `w1:p1S`, `w1:p1P`, and the current repair pane `w1:p1T`.
- `herdr-blockers.json` — refreshed at the same timestamp; the live snapshot has zero blockers. The old `w1:pV` blocker was replaced by reconciliation, not deleted by a cleanup operation.
- `herdr-conductor-inbox.jsonl` — 320 entries after a real native `blocked` event for live pane `w1:p1T`; no historical entry was pruned.
- `herdr-alerts.jsonl` and `herdr-auto-approvals.jsonl` — unchanged.

## Validation

- Bash syntax: `bin/mymate` and `bin/lib/herdr.sh` passed `bash -n`.
- PowerShell syntax: `watch-herdr.ps1` and `status-event.ps1` passed the PowerShell parser.
- `mymate status --json`: exit 0; two valid JSON lines (`workspace_list`, `agent_list`).
- `mymate probe`: exit 0; live board rendered.
- `mymate skills list`: exit 0; all 10 restored skills listed.
- `mymate watch --until idle --timeout 5000 --interval 1`: exit 0; reached `idle`.
- `mymate dispatch` and `mymate talk` were exercised only with missing arguments to verify their usage paths; no live agent was addressed.
- `mymate --version` works through PowerShell, `cmd`, and Git Bash.
- `herdr plugin list` now reports the local MyMate plugin with **no manifest warning**.
- `herdr plugin log list` shows successful new `pane.agent_status_changed` executions after restoration.
- `.\watch-herdr.ps1 -Once -AutoApproveSafe $false` completed successfully after the compatibility fixes; it refreshed state/blocker snapshots without sending keys or approving prompts.

## Safety boundaries

- No website file was changed; SHA-256 checks for `index.html`, `style.css`, and `script.js` remained unchanged.
- No Herdr session, pane, agent, or binary was mutated.
- No new pane/tab or hidden named session was created.
- The polling watcher was run once under the approved follow-up scope and exited; no persistent watcher process was started. The native server-side plugin is active; a real client-detach test remains a separate, explicitly approved test.
- Stale blocker/state/inbox cleanup remains pending. Any future cleanup must protect exact live pane IDs `w1:pC`, `w1:p1S`, and `w1:p1P`, plus any other live pane returned by Herdr.

## Reachability pass — 2026-09-26

Implemented the fresh-clone bootstrap and diagnostics:

- `bin/lib/install.sh` — `mymate install` and `mymate doctor`, with dry-run support, herdr version checking, idempotent plugin linking, skill drift detection, PATH guidance, state-dir setup, and policy seeding.
- `bin/mymate` / `bin/lib/herdr.sh` — version loading, bootstrap command routing, and the safe split → start → move-to-tab sequence (`mm_dispatch_tab`).
- `VERSION` — `0.2.0`.
- `herdr-status-plugin/herdr-plugin.toml` — plugin version `0.2.0`.
- `INSTALL.md` — manual six-step setup path and platform limitations.
- `templates/conductor-policy.md` — non-destructive policy seed template.
- `README.md`, `conductor-policy.md`, `docs/IMPLEMENTATION.md` — install link, versioned layout, and safe tab-placement wording.
- `.gitignore` — excludes the non-Windows runtime state directory and test residue.

Validation performed without writing outside this repository:

- `mymate --version` reports CLI and plugin `0.2.0`.
- `mymate doctor` reports the installed global skill as stale (expected; not overwritten).
- `mymate install --dry-run` reports the exact safe remediation.
- An isolated in-repo install using overridden skill/state/policy paths succeeded twice, proving idempotence; test residue was removed.
- Bash syntax checks pass for all three CLI files.

No environment variable, global skill file, or plugin link was changed by this pass. The only outside-repo runtime activity was the existing state directory's diagnostic write probe; no cleanup or persistent bridge change was made. The captain must run `mymate install --force` to replace the stale global skill. Do not push; create a release tag only after review with `git tag v0.2.0`.