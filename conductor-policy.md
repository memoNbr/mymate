# Conductor policy — standing rules from the captain

Issued by the captain on 2026-09-25. These override the stock `mymate` skill
contract where they conflict. The stock contract relays *every* permission
prompt to the captain; the captain has ruled that most of them are the
conductor's to grant.

## 1. Tabs and panes — herdr only, never a CLI window

Every agent gets a labelled tab that is visible in the sidebar, but agent
startup uses a safe two-stage sequence. Spawning an agent directly in a freshly
created tab can crash the Bun/opencode TUI, so `herdr tab create` is never the
spawn step.

1. Create a shell pane in the current tab and keep the caller's focus:

   ```
   herdr pane split --current --direction right --cwd "$PWD" --no-focus
   ```

2. Start the agent in that pane and wait until Herdr reports it ready:

   ```
   herdr agent start <name> --kind <kind> --pane <pane-id>
   ```

3. Move the now-running pane into its own labelled tab:

   ```
   herdr pane move <pane-id> --new-tab --label "<label>" --tab-label "<label>" --no-focus
   ```

   Use `--focus` instead of `--no-focus` for the conductor pane. The CLI's
   `mm_dispatch_tab` helper performs this move and returns the new pane ID.

Never a background shell, never `herdr --session <name>` hidden sessions, never
a detached window, and never a CLI window outside the sidebar. If a task needs
isolation, use the labelled tab/pane sequence above in the default session.

## 2. Agent names — max 6 letters, alphabetic

Purpose: instant differentiation in the sidebar.

- 1–6 characters, letters only (`[a-z]` first, then `[a-z0-9-]` if unavoidable)
- herdr's hard limit is `[a-z][a-z0-9_-]{0,31}`; the captain's rule is stricter
- good: `repair`, `optmz`, `webfx`, `bench`
- not allowed: `mymate-repair`, `simulation-optimizer`, `page-fixer-long`

## 3. Permissions — the conductor grants, unless dangerous

The conductor approves routine permission prompts autonomously and keeps a
record of what it approved. Only the dangerous list goes to the captain.

### Auto-grant (routine, local, reversible)

- reading anything inside the captain's own project repos
- reading config, status, logs and state files (including
  `%LOCALAPPDATA%\mymate`, `%APPDATA%\herdr`, `~/.local/share/*`)
- writing or editing files inside the working repo
- running tests, builds, linters, formatters, dev servers on loopback
- `git status`, `git diff`, `git log`, `git show`, branch listing
- project-local installs (`npm i`, `pip install -e`, venv work)
- reading archived/reference folders the diagnosis depends on
- deleting the conductor's own test residue (temp dirs, scratch sessions,
  rejected prototypes) — the captain has ruled: judge and clean if worthless
- reading the agent's own session/conversation state

### Escalate to the captain (dangerous)

- anything destructive outside temp: deleting source, `git reset --hard`,
  dropping tables, history rewrites, `rm -rf` of anything not created by us
- anything outward-facing: `git push`, force-push, publishing, webhooks, email,
  posting anywhere
- credentials, keys, tokens, secrets, or anything under a vault
- privilege elevation: sudo, admin, services, registry, Program Files, global
  package installs
- network calls off localhost that send data anywhere
- opening firewall/ports, changing system config
- killing processes or stopping servers the captain did not ask about
  (e.g. `herdr server stop`)
- anything that cannot be undone by deleting a file

Rule of thumb: *if the worst case is "a file is gone and it can be restored from
git", it is routine. If the worst case is irreversible, public, or touches
someone else's system, it goes to the captain.*

## 4. Lead from the start — delegate early, don't hoard the work

The captain's standing lesson: a conductor should be invoked at the *beginning*
of a session, not once things are already half-done. From the first turn of any
working session:

1. run a crew status check (`mymate status --json`, or `herdr agent list` while
   the CLI is down)
2. name which crew member best owns the incoming work
3. hand it over instead of doing it in the conductor's own pane

The conductor coordinates, plans, reports, and grants permissions. Application
code, config changes and repairs belong to the agent that owns them.

## Change log

- 2026-09-25 — policy issued by the captain after the mymate health check
