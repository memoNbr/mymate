# herdr-server-failsafe.ps1 - bring the Herdr server back up if it goes away
# during the update/restart, so the session restores (with the NEW binary)
# without anyone having to notice it is down.
#
# Spawned HIDDEN (own console) before a server restart so it outlives the
# pane/console teardown that kills everything else. Debounces transient
# socket blips so it never races a graceful handoff, and logs everything
# to session-backups\failsafe.log for post-mortem.
$ErrorActionPreference = "SilentlyContinue"
$sock = Join-Path $env:APPDATA "herdr\herdr.sock"
$exe  = "$env:LOCALAPPDATA\Programs\Herdr\bin\herdr.exe"
$log  = Join-Path $env:APPDATA "herdr\session-backups\failsafe.log"
function Note($m) { Add-Content -Path $log -Value ("{0} {1}" -f (Get-Date -Format s), $m) }

Note "failsafe started (pid $PID)"
$deadline = (Get-Date).AddMinutes(5)
$gone = 0
while ((Get-Date) -lt $deadline) {
    if (-not (Test-Path $sock)) { $gone++ } else { $gone = 0 }
    if ($gone -ge 3) { break }
    Start-Sleep -Seconds 1
}
if ($gone -lt 3) {
    Note "socket never disappeared - server stayed up; exiting"
    exit 0
}
Note "socket gone - waiting 3s before restart"
Start-Sleep -Seconds 3
if (Test-Path $sock) {
    Note "socket reappeared on its own; exiting"
    exit 0
}
Note "starting herdr server"
Start-Process -FilePath $exe -ArgumentList "server" -WindowStyle Hidden
Start-Sleep -Seconds 4
if (Test-Path $sock) { Note "server is back up" }
else { Note "WARNING: socket still missing after start attempt" }
Note "failsafe done"
