param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidatePattern('^[A-Za-z0-9._-]{1,48}$')]
    [string]$Name,

    [string]$RelayHost,
    [string]$RelayUser,
    [string]$KeyPath,
    [string]$KnownHostsPath
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot

function Import-EnvFile($path) {
    if (Test-Path -LiteralPath $path) {
        Get-Content -LiteralPath $path | ForEach-Object {
            $line = $_.Trim()
            if ($line -and -not $line.StartsWith('#') -and $line.Contains('=')) {
                $idx = $line.IndexOf('=')
                $key = $line.Substring(0, $idx).Trim()
                $val = $line.Substring($idx + 1).Trim().Trim('"').Trim("'")
                if (-not [System.Environment]::GetEnvironmentVariable($key)) {
                    [System.Environment]::SetEnvironmentVariable($key, $val, 'Process')
                }
            }
        }
    }
}

Import-EnvFile (Join-Path $projectRoot 'config.env')
Import-EnvFile (Join-Path $projectRoot '.env')
Import-EnvFile (Join-Path $projectRoot 'artifacts\private\deployment.env')

if (-not $RelayHost) { $RelayHost = $env:RUSSIAN_IP }
if (-not $RelayUser) { $RelayUser = if ($env:RUSSIAN_LOGIN) { $env:RUSSIAN_LOGIN } else { 'whitelist' } }

if (-not $KeyPath) {
    $defaultKey = Join-Path $projectRoot '.secrets\project_ed25519'
    $KeyPath = if (Test-Path -LiteralPath $defaultKey) { $defaultKey } else { '' }
}
if (-not $KnownHostsPath) {
    $defaultKnownHosts = Join-Path $projectRoot '.secrets\known_hosts'
    $KnownHostsPath = if (Test-Path -LiteralPath $defaultKnownHosts) { $defaultKnownHosts } else { '' }
}

if (-not $RelayHost) {
    throw 'RelayHost (RUSSIAN_IP) is not specified. Set it in config.env or pass -RelayHost <IP>'
}

$sshArgs = @()
if ($KeyPath) { $sshArgs += "-i", $KeyPath }
if ($KnownHostsPath) { $sshArgs += "-o", "UserKnownHostsFile=$KnownHostsPath" }
$sshArgs += "-o", "BatchMode=yes"
$sshArgs += "-o", "StrictHostKeyChecking=accept-new"
$sshArgs += "$RelayUser@$RelayHost"
$sshArgs += "sudo -n /usr/local/sbin/wlb-device remove '$Name'"

& ssh @sshArgs
if ($LASTEXITCODE -ne 0) {
    throw "The relay server ($RelayHost) rejected the removal request for device '$Name'."
}

Write-Host "Device '$Name' removed successfully." -ForegroundColor Yellow
