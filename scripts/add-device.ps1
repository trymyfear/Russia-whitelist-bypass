param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidatePattern('^[A-Za-z0-9._-]{1,48}$')]
    [string]$Name,

    [string]$RelayHost,
    [string]$RelayUser,
    [int]$RelayPort = 0,
    [string]$RelayPublicKey,
    [string]$RelayShortId,
    [string]$RelaySni,
    [string]$KeyPath,
    [string]$KnownHostsPath
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot

# Helper to load .env / config files if present
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

# Resolve configuration
if (-not $RelayHost) { $RelayHost = $env:RUSSIAN_IP }
if (-not $RelayUser) { $RelayUser = if ($env:RUSSIAN_LOGIN) { $env:RUSSIAN_LOGIN } else { 'whitelist' } }
if ($RelayPort -eq 0) { $RelayPort = if ($env:RUSSIAN_PORT) { [int]$env:RUSSIAN_PORT } else { 443 } }
if (-not $RelayPublicKey) { $RelayPublicKey = $env:RELAY_REALITY_PUBLIC_KEY }
if (-not $RelayShortId) { $RelayShortId = $env:RELAY_SHORT_ID }
if (-not $RelaySni) { $RelaySni = if ($env:RELAY_SNI) { $env:RELAY_SNI } else { 'ya.ru' } }

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
if (-not $RelayPublicKey) {
    throw 'RelayPublicKey (RELAY_REALITY_PUBLIC_KEY) is not specified. Set it in config.env or pass -RelayPublicKey <KEY>'
}
if (-not $RelayShortId) {
    throw 'RelayShortId (RELAY_SHORT_ID) is not specified. Set it in config.env or pass -RelayShortId <ID>'
}

$privateArtifacts = Join-Path $projectRoot 'artifacts\private'
$uuid = [guid]::NewGuid().Guid

$sshArgs = @()
if ($KeyPath) { $sshArgs += "-i", $KeyPath }
if ($KnownHostsPath) { $sshArgs += "-o", "UserKnownHostsFile=$KnownHostsPath" }
$sshArgs += "-o", "BatchMode=yes"
$sshArgs += "-o", "StrictHostKeyChecking=accept-new"
$sshArgs += "$RelayUser@$RelayHost"
$sshArgs += "sudo -n /usr/local/sbin/wlb-device add '$Name' '$uuid'"

& ssh @sshArgs
if ($LASTEXITCODE -ne 0) {
    throw "The relay server ($RelayHost) rejected the new device registration."
}

$link = "vless://$uuid@$RelayHost`:$RelayPort`?encryption=none&flow=xtls-rprx-vision&security=reality&sni=$RelaySni&fp=chrome&pbk=$RelayPublicKey&sid=$RelayShortId&spx=%2F&type=tcp#Whitelist-Bypass-$Name"

New-Item -ItemType Directory -Force -Path $privateArtifacts | Out-Null
$linkPath = Join-Path $privateArtifacts "$Name.txt"
$qrPath = Join-Path $privateArtifacts "$Name-qr.png"
Set-Content -LiteralPath $linkPath -Value $link -Encoding utf8

& python (Join-Path $PSScriptRoot 'make-qr.py') $link $qrPath 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Warning "Device added and saved to $linkPath, but QR generation script exited with non-zero code."
}

Write-Host "--------------------------------------------------------" -ForegroundColor Green
Write-Host "Device '$Name' added successfully!" -ForegroundColor Green
Write-Host "--------------------------------------------------------" -ForegroundColor Green
Write-Host "VLESS Link: $link"
Write-Host "Saved Link: $linkPath"
if (Test-Path -LiteralPath $qrPath) {
    Write-Host "QR Code:    $qrPath"
}
Write-Host "--------------------------------------------------------"
