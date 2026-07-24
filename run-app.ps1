Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$projectRoot = $PSScriptRoot
$port = 8000
$url = "http://localhost:$port/yamaha-inventory-system.html"
$htmlFile = Join-Path $projectRoot "yamaha-inventory-system.html"

function Get-PythonCommand {
  foreach ($name in @("py","python","python3")) {
    $cmd = Get-Command $name -ErrorAction SilentlyContinue
    if (-not $cmd) { continue }
    try {
      $version = & $cmd.Source --version 2>&1
      if ($LASTEXITCODE -eq 0 -and "$version" -match "^Python\s+\d") {
        return @($cmd.Source, @("-m", "http.server", "$port"))
      }
    } catch {}
  }
  return $null
}

Set-Location $projectRoot

$listening = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
if (-not $listening) {
  $pythonCmd = Get-PythonCommand
  if (-not $pythonCmd) {
    Start-Process $htmlFile
    Write-Host "Python is not available. Opened the app directly in browser instead."
    exit 0
  }

  $serverCommand = "Set-Location '$projectRoot'; & '$($pythonCmd[0])' $($pythonCmd[1] -join ' ')"
  Start-Process -FilePath "powershell" -ArgumentList @("-NoProfile", "-NoExit", "-Command", $serverCommand) -WorkingDirectory $projectRoot | Out-Null
  Start-Sleep -Seconds 2
  $listening = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
  if (-not $listening) {
    Start-Process $htmlFile
    Write-Host "Local server did not start. Opened the app directly in browser instead."
    exit 0
  }
}

Start-Process $url
Write-Host "App opened at $url"
