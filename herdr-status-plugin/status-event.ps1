$ErrorActionPreference = "Stop"

$directory = Join-Path $env:LOCALAPPDATA "mymate"
New-Item -ItemType Directory -Force -Path $directory | Out-Null
$inbox = Join-Path $directory "herdr-conductor-inbox.jsonl"
$eventLog = Join-Path $directory "herdr-event-alerts.jsonl"

$raw = $env:HERDR_PLUGIN_EVENT_JSON
if ([string]::IsNullOrWhiteSpace($raw)) {
    throw "HERDR_PLUGIN_EVENT_JSON was not provided."
}

$event = $raw | ConvertFrom-Json
$payload = if ($event.data) { $event.data } elseif ($event.payload) { $event.payload } else { $event }
$paneId = [string]$payload.pane_id
$state = [string]$payload.agent_status
if ([string]::IsNullOrWhiteSpace($paneId) -or [string]::IsNullOrWhiteSpace($state)) {
    throw "Status event did not include pane_id and agent_status. Raw event: $raw"
}

$target = $paneId
$statusLines = & mymate status --json 2>$null
foreach ($line in $statusLines) {
    try {
        $payload = $line | ConvertFrom-Json
    } catch {
        continue
    }
    if ($payload.result.type -ne "agent_list") {
        continue
    }
    $agent = @($payload.result.agents | Where-Object { $_.pane_id -eq $paneId }) | Select-Object -First 1
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
    action = if ($state -eq "blocked") { "read-and-relay" } else { "observe" }
    requires_conductor_action = ($state -eq "blocked")
}
$line = $alert | ConvertTo-Json -Compress
$line | Add-Content -LiteralPath $eventLog
if ($state -eq "blocked") {
    $line | Add-Content -LiteralPath $inbox
}

$sound = if ($state -eq "blocked") { "request" } elseif ($state -in @("idle", "done")) { "done" } else { "none" }
$body = "Herdr event: $target changed to $state. Pane: $paneId."
if ($state -eq "blocked") {
    $body += " Read it with: mymate read $target"
}
& herdr notification show "Herdr agent $state`: $target" --body $body --sound $sound 2>$null | Out-Null
