[CmdletBinding()]
param(
    [int]$IntervalSeconds = 1,
    [string]$AlertLog = (Join-Path $env:LOCALAPPDATA "mymate\herdr-alerts.jsonl"),
    [string]$DataDirectory = (Join-Path $env:LOCALAPPDATA "mymate"),
    [bool]$AutoApproveSafe = $false,
    [switch]$Once
)

# This watcher is deliberately observe-only. Permission and selection prompts
# are reported to the conductor; it never sends keys or approves anything.
$ErrorActionPreference = "Stop"

if ($env:HERDR_ENV -ne "1") {
    throw "watch-herdr must run inside a Herdr-managed pane (HERDR_ENV=1)."
}
if ($IntervalSeconds -lt 1) {
    throw "IntervalSeconds must be at least 1."
}
if ($AutoApproveSafe) {
    throw "Automatic approvals are disabled; run this bridge in observe-only mode."
}
if ([string]::IsNullOrWhiteSpace($DataDirectory)) {
    $DataDirectory = Join-Path $env:LOCALAPPDATA "mymate"
}

New-Item -ItemType Directory -Force -Path $DataDirectory | Out-Null
$logDirectory = Split-Path -Parent $AlertLog
if ([string]::IsNullOrWhiteSpace($logDirectory)) {
    $logDirectory = $DataDirectory
}
New-Item -ItemType Directory -Force -Path $logDirectory | Out-Null

$stateFile = Join-Path $DataDirectory "herdr-state.json"
$blockerFile = Join-Path $DataDirectory "herdr-blockers.json"
$inboxFile = Join-Path $DataDirectory "herdr-conductor-inbox.jsonl"
$eventLog = Join-Path $DataDirectory "herdr-event-alerts.jsonl"
$effectiveColorFile = Join-Path $DataDirectory "effective-colors.state"
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

function Write-AtomicText {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Content
    )
    $temporary = "$Path.$PID.tmp"
    [System.IO.File]::WriteAllText($temporary, $Content, $utf8NoBom)
    Move-Item -LiteralPath $temporary -Destination $Path -Force
}

$previous = @{}
$hasBaseline = $false

while ($true) {
    $current = @{}
    $records = New-Object System.Collections.Generic.List[object]
    $statusLines = @()
    $sawAgentList = $false

    try {
        $statusLines = @(& mymate status --json 2>$null)
    } catch {
        $statusLines = @()
    }

    foreach ($line in $statusLines) {
        try {
            $payload = $line | ConvertFrom-Json
        } catch {
            continue
        }
        if ($null -eq $payload.result -or $payload.result.type -ne "agent_list") {
            continue
        }
        $sawAgentList = $true

        foreach ($agent in @($payload.result.agents)) {
            $paneId = [string]$agent.pane_id
            $target = if ($agent.name) {
                [string]$agent.name
            } else {
                # Herdr's read/keys APIs accept an exact pane ID; the older
                # agent:pane fallback is not a valid target for unnamed panes.
                $paneId
            }
            if ([string]::IsNullOrWhiteSpace($paneId)) {
                $paneId = $target
            }

            $rawState = [string]$agent.agent_status
            try {
                $visible = (& herdr agent read $target --source visible --lines 40 2>$null | Out-String)
            } catch {
                $visible = ""
            }
            $hasVisiblePrompt = $visible -match
                "(?im)Permission required|Allow once|Allow always|Reject|Action Required"
            $state = if ($rawState -eq "working" -and $hasVisiblePrompt) {
                "blocked"
            } else {
                $rawState
            }

            $current[$paneId] = $state
            $records.Add([pscustomobject][ordered]@{
                target = $target
                pane_id = $paneId
                state = $state
                raw_state = $rawState
                detection = if ($hasVisiblePrompt) { "visible-prompt" } else { "integration" }
            })

            $previousState = if ($hasBaseline -and $previous.ContainsKey($paneId)) {
                [string]$previous[$paneId]
            } else {
                ""
            }
            $changed = ($state -eq "blocked" -and -not $hasBaseline) -or
                ($hasBaseline -and $previousState -ne $state)
            if (-not $changed) {
                continue
            }

            # Native Herdr events own ordinary integration transitions. This
            # loop only raises a fallback event when a visible prompt is found
            # while the integration still reports working.
            if ($rawState -eq "blocked") {
                continue
            }

            $severity = if ($state -eq "blocked") { "request" } else { "none" }
            $title = "Herdr agent $state`: $target"
            $body = "State changed from $previousState to $state. Pane: $paneId."
            if ($state -eq "blocked") {
                $body += " Read it with: mymate read $target"
            }
            try {
                & herdr notification show $title --body $body --sound $severity 2>$null | Out-Null
            } catch {
                # A notification failure must not prevent the state snapshot.
            }

            $alert = [ordered]@{
                timestamp = [DateTimeOffset]::UtcNow.ToString("o")
                target = $target
                pane_id = $paneId
                previous_state = $previousState
                state = $state
                raw_state = $rawState
                source = "watch-herdr-visible"
                detection = if ($hasVisiblePrompt) { "visible-prompt" } else { "integration" }
                action = if ($state -eq "blocked") { "read-and-relay" } else { "observe" }
                requires_conductor_action = ($state -eq "blocked")
            }
            Append-JsonLine -Path $AlertLog -Record $alert
            if ($hasVisiblePrompt) {
                Append-JsonLine -Path $eventLog -Record $alert
            }
            if ($state -eq "blocked") {
                Append-JsonLine -Path $inboxFile -Record $alert
            }
        }
    }

    if (-not $sawAgentList) {
        if ($Once) {
            throw "mymate status --json returned no agent_list payload; existing snapshots were left untouched."
        }
        Start-Sleep -Seconds $IntervalSeconds
        continue
    }

    $timestamp = [DateTimeOffset]::UtcNow.ToString("o")
    # Windows PowerShell 5.1 can hit a dynamic-enumeration bug when a generic
    # List[object] is used directly inside @(...). Materialize it once.
    $recordArray = $records.ToArray()
    $stateJson = [ordered]@{
        timestamp = $timestamp
        agents = @($recordArray)
    } | ConvertTo-Json -Depth 8
    $blockerJson = [ordered]@{
        timestamp = $timestamp
        blockers = @($recordArray | Where-Object { $_.state -eq "blocked" })
    } | ConvertTo-Json -Depth 8
    $effective = ($recordArray | ForEach-Object { "$($_.target)`t$($_.state)" }) -join [Environment]::NewLine

    Write-AtomicText -Path $stateFile -Content ($stateJson + [Environment]::NewLine)
    Write-AtomicText -Path $blockerFile -Content ($blockerJson + [Environment]::NewLine)
    Write-AtomicText -Path $effectiveColorFile -Content ($effective + [Environment]::NewLine)

    $previous = $current
    $hasBaseline = $true
    if ($Once) {
        break
    }
    Start-Sleep -Seconds $IntervalSeconds
}
