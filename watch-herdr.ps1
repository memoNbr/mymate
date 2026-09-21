param(
    [int]$IntervalSeconds = 1,
    [string]$AlertLog = (Join-Path $env:LOCALAPPDATA "mymate\herdr-alerts.jsonl")
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

$previous = @{}
$hasBaseline = $false

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
            $state = [string]$agent.agent_status
            $current[$target] = $state
            $records.Add([pscustomobject][ordered]@{
                target = $target
                pane_id = [string]$agent.pane_id
                state = $state
            })

            $changed = ($state -eq "blocked" -and -not $hasBaseline) -or
                ($hasBaseline -and (($previous[$target] -as [string]) -ne $state))
            if (-not $changed) {
                continue
            }

            $severity = if ($state -eq "blocked") { "request" } else { "none" }
            $title = "Herdr agent $state`: $target"
            $body = "State changed from $($previous[$target]) to $state. Pane: $($agent.pane_id)."
            if ($state -eq "blocked") {
                $body += " Read it with: mymate read $target"
            }

            & herdr notification show $title --body $body --sound $severity 2>$null | Out-Null

            [ordered]@{
                timestamp = [DateTimeOffset]::UtcNow.ToString("o")
                target = $target
                pane_id = [string]$agent.pane_id
                previous_state = [string]$previous[$target]
                state = $state
                action = if ($state -eq "blocked") { "read-and-relay" } else { "observe" }
            } | ConvertTo-Json -Compress | Add-Content -LiteralPath $AlertLog
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

    $previous = $current
    $hasBaseline = $true
    Start-Sleep -Seconds $IntervalSeconds
}
