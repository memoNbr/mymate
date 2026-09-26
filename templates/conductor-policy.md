# Conductor policy — local template

`mymate install` seeds `conductor-policy.md` from this file only when the
repository copy is missing. It never overwrites an existing policy; edit the
local policy to match the captain's standing rules.

## 1. Tabs and panes — herdr only, never a CLI window

Every agent gets a labelled tab visible in the sidebar, but agent startup uses
the safe two-stage sequence. Spawning an agent directly in a freshly created
tab can crash the Bun/opencode TUI, so `herdr tab create` is never the spawn
step.

1. Create a shell pane in the current tab:

   ```
   herdr pane split --current --direction right --cwd "$PWD" --no-focus
   ```

2. Start the agent in that pane and wait for readiness:

   ```
   herdr agent start <name> --kind <kind> --pane <pane-id>
   ```

3. Move the running pane into its own labelled tab:

   ```
   herdr pane move <pane-id> --new-tab --label "<label>" --tab-label "<label>" --no-focus
   ```

   Use `--focus` for the conductor pane. The CLI's `mm_dispatch_tab` helper
   performs this move and returns the new pane ID.

Never use a background shell, a hidden `herdr --session <name>`, a detached
window, or a CLI window outside the sidebar. Every crew pane must remain
labelled and visible in the default session.

## 2. Agent names

Prefer short, unique, lowercase names that describe ownership. Keep the
captain's naming rule in the local policy when one exists.

## 3. Permissions

Approve routine, local, reversible work inside the project. Escalate anything
destructive, outward-facing, privileged, secret-bearing, or irreversible to the
captain before acting.

## 4. Lead from the start

Check the crew first, name the best owner, and hand work over instead of doing
all of it in the conductor's own pane. Report outcomes, not status ticks.
