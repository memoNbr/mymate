param(
    [int]$IntervalSeconds = 1,
    [string]$AlertLog = (Join-Path $env:LOCALAPPDATA "mymate\herdr-alerts.jsonl"),
    [bool]$AutoApproveSafe = $true
)

if ($env:HERDR_ENV -ne "1") {
    throw "watch-herdr must run inside a Herdr-managed pane (HERDR_ENV=1)."
}

if ($IntervalSeconds -lt 1) {
    throw "IntervalSeconds must be at least 1."
}

$logDirectory = Split-Path -Parent $AlertLog
New-Item -ItemType Directory -Force -Path $logDirectory | Out-Null
$stateFile = Join-Path $logDirectory "herdr-state.json"
$blockerFile = Join-Path $logDirectory "herdr-blockers.json"
$inboxFile = Join-Path $logDirectory "herdr-conductor-inbox.jsonl"
$automationLog = Join-Path $logDirectory "herdr-auto-approvals.jsonl"
$effectiveColorFile = Join-Path (Join-Path $env:USERPROFILE ".mymate") "effective-colors.state"
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $effectiveColorFile) | Out-Null

$previous = @{}
$hasBaseline = $false

function Test-SafeProjectPrompt([string]$Target, [string]$Visible) {
    $trustedTarget = $Target -in @("cabin-mind", "cabin-avatar", "aae-core", "aae-scouts")
    $diffPrompt = $Visible -match "(?m)^\s*\d+\s+[+-]\s+\S"
    $readOrEdit = $Visible -match "(?im)\b(Read|Edit|Create|Write)\b" -or $diffPrompt
    $dangerous = $Visible -match "(?im)\b(Delete|Remove|Reset|Push|Publish)\b|\.env|secret|credential|token|password|ssh"
    return $trustedTarget -and $readOrEdit -and -not $dangerous
}

while ($true) {
    $current = @{}
    $records = [System.Collections.Generic.List[object]]::new()
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

        foreach ($agent in $payload.result.agents) {
            $target = if ($agent.name) {
                [string]$agent.name
            } else {
                "$($agent.agent):$($agent.pane_id)"
            }
            $rawState = [string]$agent.agent_status
            $visible = (& herdr agent read $target --source visible --lines 40 2>$null | Out-String)
            $hasVisiblePrompt = $visible -match
                "(?im)Permission required|Allow once|Allow always|Reject|Action Required"
            if ($AutoApproveSafe -and $hasVisiblePrompt -and (Test-SafeProjectPrompt $target $visible)) {
                & mymate key $target down enter 2>$null | Out-Null
                [ordered]@{
                    timestamp = [DateTimeOffset]::UtcNow.ToString("o")
                    target = $target
                    pane_id = [string]$agent.pane_id
                    action = "allow-always"
                    reason = "trusted non-destructive cabin/AAE project prompt"
                } | ConvertTo-Json -Compress | Add-Content -LiteralPath $automationLog
                Start-Sleep -Milliseconds 250
                $visible = (& herdr agent read $target --source visible --lines 40 2>$null | Out-String)
                $hasVisiblePrompt = $visible -match
                    "(?im)Permission required|Allow once|Allow always|Reject|Action Required"
            }
            $state = if ($rawState -eq "working" -and $hasVisiblePrompt) {
                "blocked"
            } else {
                $rawState
            }
            $current[$target] = $state
            $records.Add([pscustomobject][ordered]@{
                target = $target
                pane_id = [string]$agent.pane_id
                state = $state
                raw_state = $rawState
                detection = if ($hasVisiblePrompt) { "visible-prompt" } else { "integration" }
            })

            $changed = ($state -eq "blocked" -and -not $hasBaseline) -or
                ($hasBaseline -and (($previous[$target] -as [string]) -ne $state))
            if (-not $changed) {
                continue
            }
            # Native Herdr events own integration state transitions. This loop
            # only raises alerts for visible prompts that native state missed.
            if ($rawState -eq "blocked") {
                continue
            }

            $severity = if ($state -eq "blocked") { "request" } else { "none" }
            $title = "Herdr agent $state`: $target"
            $body = "State changed from $($previous[$target]) to $state. Pane: $($agent.pane_id)."
            if ($state -eq "blocked") {
                $body += " Read it with: mymate read $target"
            }

            & herdr notification show $title --body $body --sound $severity 2>$null | Out-Null

            $alert = [ordered]@{
                timestamp = [DateTimeOffset]::UtcNow.ToString("o")
                target = $target
                pane_id = [string]$agent.pane_id
                previous_state = [string]$previous[$target]
                state = $state
                action = if ($state -eq "blocked") { "read-and-relay" } else { "observe" }
                requires_conductor_action = ($state -eq "blocked")
            }
            $alert | ConvertTo-Json -Compress | Add-Content -LiteralPath $AlertLog
            if ($state -eq "blocked") {
                $alert | ConvertTo-Json -Compress | Add-Content -LiteralPath $inboxFile
            }
        }
    }

    $timestamp = [DateTimeOffset]::UtcNow.ToString("o")
    [ordered]@{
        timestamp = $timestamp
        agents = @($records)
    } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $stateFile

    [ordered]@{
        timestamp = $timestamp
        blockers = @($records | Where-Object { $_.state -eq "blocked" })
    } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $blockerFile
    @($records | ForEach-Object { "$($_.target)`t$($_.state)" }) |
        Set-Content -LiteralPath $effectiveColorFile

    $previous = $current
    $hasBaseline = $true
    Start-Sleep -Seconds $IntervalSeconds
}
