#requires -version 5.1
# mymate.ps1 - Windows PowerShell shim so `mymate` works from PowerShell panes.
$bashCandidates = @(
  "$env:ProgramFiles\Git\bin\bash.exe",
  "${env:ProgramFiles(x86)}\Git\bin\bash.exe",
  "$env:LOCALAPPDATA\Programs\Git\bin\bash.exe",
  "$env:LOCALAPPDATA\Programs\Git\usr\bin\bash.exe"
)
$bash = $bashCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if (-not $bash) {
  Write-Error "mymate: Git for Windows bash.exe not found"
  exit 1
}
& $bash (Join-Path $PSScriptRoot 'mymate') @args
exit $LASTEXITCODE
