# Installing mymate

> **Windows bridge limitation:** the native signal bridge is Windows-only.
> `herdr-status-plugin/herdr-plugin.toml` declares `platforms = ["windows"]`,
> and `watch-herdr.ps1` is PowerShell. On macOS and Linux the CLI still runs,
> but the JSONL state bridge is not installed; use the CLI's read-only boards or
> provide a compatible polling fallback.

The normal path is:

```sh
mymate install
mymate doctor
```

`install` is idempotent. It never edits your `PATH`, never overwrites an
existing conductor skill, and never overwrites an existing
`conductor-policy.md`. Use `--force` only when you intentionally want to replace
a stale skill or relink a plugin checkout.

## Manual path

Use these six steps when you do not want the bootstrap to do the work.

### 1. Install and start herdr

Install herdr, open a herdr-managed pane, and verify the client and server:

```sh
herdr --version
herdr status server
```

The Windows plugin link/enable step needs a running herdr server. On macOS and
Linux, skip the Windows-only plugin steps below.

### 2. Install Git for Windows (Windows)

The CLI core is Bash. Install Git for Windows and verify both tools from a
terminal:

```sh
git --version
bash --version
```

The PowerShell and `cmd` shims discover `bash.exe` automatically.

### 3. Put this checkout's `bin` on PATH

Do this manually; `mymate install` prints the command but never changes your
environment silently.

Git Bash:

```sh
export PATH="/absolute/path/to/mymate/bin:$PATH"
```

PowerShell, current session:

```powershell
$env:Path = 'C:\absolute\path\to\mymate\bin;' + $env:Path
```

Persist it for future PowerShell terminals:

```powershell
[Environment]::SetEnvironmentVariable(
  'Path',
  [Environment]::GetEnvironmentVariable('Path','User') + ';C:\absolute\path\to\mymate\bin',
  'User'
)
```

Use the actual checkout path. A fresh shell is required after changing the
persistent user `PATH`.

### 4. Link and enable the native bridge (Windows)

From the repository root, in Git Bash:

```sh
herdr plugin link "$(cygpath -w "$PWD/herdr-status-plugin")"
herdr plugin enable mymate.herdr-status
herdr plugin list
```

The last command should show `mymate.herdr-status` as enabled and linked to
this checkout. To start over, use the explicit unlink first:

```sh
herdr plugin unlink mymate.herdr-status
herdr plugin link "$(cygpath -w "$PWD/herdr-status-plugin")"
herdr plugin enable mymate.herdr-status
```

This is the only bootstrap step that changes state outside the repository and
the state directory. macOS and Linux users should skip it.

### 5. Install the conductor skill

The primary agent loads the skill from:

```text
~/.agents/skills/mymate/SKILL.md
```

Manual installation:

```sh
mkdir -p ~/.agents/skills/mymate
cp mymate.skill.md ~/.agents/skills/mymate/SKILL.md
```

If the target already exists, compare it rather than overwriting it. The
bootstrap reports `STALE` and tells you when this explicit command is needed:

```sh
mymate install --force
```

`--force` creates a timestamped backup beside the existing `SKILL.md` before
replacing it.

### 6. Create your own conductor policy

The repository ships a policy and a template. The bootstrap seeds the
repository-root policy only if it is absent; it never overwrites an existing
one. To start a local copy explicitly:

```sh
cp templates/conductor-policy.md conductor-policy.md
```

Edit `conductor-policy.md` to record the captain's naming, permission, and
pane-placement rules. The safe placement sequence is: split a pane, start the
agent, then move the booted pane into a labelled tab. Do not spawn an agent
directly with `herdr tab create`.

## Optional: jq

`jq` is optional. It makes `status`, `probe`, and `watch` boards easier to read;
the bootstrap and doctor report it as informational only. Install it with your
platform package manager if desired.

## Verify the install

```sh
mymate --version
mymate doctor
mymate status
```

`mymate doctor` reports each required item as `ok`, `warn`, or `FAIL`. A stale
or missing conductor skill and a missing/enabled-missing Windows plugin are
hard failures. A missing `PATH` entry is a warning with the exact command to
run, and a missing `jq` is informational.

The state directory is `%LOCALAPPDATA%\\mymate` on Windows and
`<repo>/.mymate-state` elsewhere. The bootstrap creates it; it is runtime state
and is not committed.
