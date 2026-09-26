# backup-herdr-session.ps1 — Keep your own timestamped copies of Herdr's
# session state.
#
# WHY: Herdr overwrites session.json on every change. When restored panes die
# from the PaneDied bug (see herdr-issue-PaneDied-after-restore.md), the
# shrunken state overwrites the good one minutes later, and only a single
# session.json.bak generation survives. Your layout (tab labels, cwds,
# agent_session ids) is unrecoverable unless YOU kept a copy.
#
# Run it:
#   - after any important layout is set up,
#   - before restarting/updating the Herdr server,
#   - after a restore, to snapshot what came back.
#
# Copies session.json, session.json.bak and session-history.json into
# %APPDATA%\herdr\session-backups\<timestamp>\ and keeps the newest 30.

param(
    [string]$Dir = "$env:APPDATA\herdr",
    [int]$Keep = 30
)

$ErrorActionPreference = "Stop"
$out = Join-Path $Dir "session-backups"
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$dest = Join-Path $out $stamp
New-Item -ItemType Directory -Force -Path $dest | Out-Null

$copied = 0
foreach ($f in "session.json", "session.json.bak", "session-history.json") {
    $src = Join-Path $Dir $f
    if (Test-Path $src) {
        Copy-Item $src (Join-Path $dest $f) -Force
        $copied++
    }
}

# prune: keep the newest $Keep timestamped folders
Get-ChildItem $out -Directory |
    Sort-Object Name -Descending |
    Select-Object -Skip $Keep |
    Remove-Item -Recurse -Force

Write-Host "Backed up $copied file(s) -> $dest"
Write-Host ("Backups kept: " + (Get-ChildItem $out -Directory).Count)
