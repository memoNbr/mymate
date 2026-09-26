$ErrorActionPreference = "Stop"

$directory = Join-Path $env:LOCALAPPDATA "mymate"
New-Item -ItemType Directory -Force -Path $directory | Out-Null
$inbox = Join-Path $directory "herdr-conductor-inbox.jsonl"
$eventLog = Join-Path $directory "herdr-event-alerts.jsonl"
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Append-JsonLine {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][object]$Record
    )
    $json = $Record | ConvertTo-Json -Compress -Depth 8
    $bytes = $utf8NoBom.GetBytes($json + [Environment]::NewLine)
    $stream = [System.IO.File]::Open(
        $Path,
        [System.IO.FileMode]::Append,
        [System.IO.FileAccess]::Write,
        [System.IO.FileShare]::Read
    )
    try {
        $stream.Write($bytes, 0, $bytes.Length)
        $stream.Flush($true)
    } finally {
        $stream.Dispose()
    }
}

$raw = $env:HERDR_PLUGIN_EVENT_JSON
if ([string]::IsNullOrWhiteSpace($raw)) {
    throw "HERDR_PLUGIN_EVENT_JSON was not provided."
}

$event = $raw | ConvertFrom-Json
$payload = if ($event.data) { $event.data } elseif ($event.payload) { $event.payload } else { $event }
$paneId = [string]$payload.pane_id
$state = [string]$payload.agent_status
if ([string]::IsNullOrWhiteSpace($state)) {
    $state = [string]$payload.state
}
if ([string]::IsNullOrWhiteSpace($paneId) -or [string]::IsNullOrWhiteSpace($state)) {
    throw "Status event did not include pane_id and agent_status. Raw event: $raw"
}

# The event remains useful even if the agent disappears between the event and
# this lookup. A missing CLI/status response therefore does not discard it.
$target = $paneId
$statusLines = @()
try {
    $statusLines = @(& mymate status --json 2>$null)
} catch {
    $statusLines = @()
}
foreach ($line in $statusLines) {
    try {
        $statusPayload = $line | ConvertFrom-Json
    } catch {
        continue
    }
    if ($null -eq $statusPayload.result -or $statusPayload.result.type -ne "agent_list") {
        continue
    }
    $agent = @($statusPayload.result.agents | Where-Object { $_.pane_id -eq $paneId }) | Select-Object -First 1
    if ($null -ne $agent -and $agent.name) {
        $target = [string]$agent.name
    }
}

$alert = [ordered]@{
    timestamp = [DateTimeOffset]::UtcNow.ToString("o")
    target = $target
    pane_id = $paneId
    state = $state
    previous_state = $null
    source = "herdr-event"
    detection = "integration"
    action = if ($state -eq "blocked") { "read-and-relay" } else { "observe" }
    requires_conductor_action = ($state -eq "blocked")
}
Append-JsonLine -Path $eventLog -Record $alert
if ($state -eq "blocked") {
    Append-JsonLine -Path $inbox -Record $alert
}

$sound = if ($state -eq "blocked") { "request" } elseif ($state -in @("idle", "done")) { "done" } else { "none" }
$body = "Herdr event: $target changed to $state. Pane: $paneId."
if ($state -eq "blocked") {
    $body += " Read it with: mymate read $target"
}
& herdr notification show "Herdr agent $state`: $target" --body $body --sound $sound 2>$null | Out-Null
