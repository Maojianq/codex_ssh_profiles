param(
    [string]$SshDir = "$env:USERPROFILE\.ssh",
    [string]$ConfigPath,
    [string]$ProfilePath,

    [string]$DlName = "DL-mjq",
    [string]$DlHost = "211.69.141.156",
    [int]$DlPort = 22345,
    [string]$DlUser = "mjq",

    [string]$HpcName = "HPC-jqmao",
    [string]$HpcHost = "211.69.141.130",
    [int]$HpcPort = 22333,
    [string]$HpcUser = "jqmao",
    [string]$HpcDefaultRemoteDir = "/public/home/jqmao/codex/codex_hpc_jqmao_bundle",

    [switch]$Force
)

$ErrorActionPreference = "Stop"

if (-not $ConfigPath) {
    $ConfigPath = Join-Path $SshDir "config"
}
if (-not $ProfilePath) {
    $ProfilePath = Join-Path $SshDir "codex_ssh_profiles.json"
}

function Show-Plan {
    Write-Host "This script will configure Codex SSH profiles for Windows." -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Files to write:"
    Write-Host "  SSH config:       $ConfigPath"
    Write-Host "  Codex profile:    $ProfilePath"
    Write-Host ""
    Write-Host "SSH hosts to add/update:"
    Write-Host "  $DlName"
    Write-Host "    HostName:       $DlHost"
    Write-Host "    Port:           $DlPort"
    Write-Host "    User:           $DlUser"
    Write-Host "    Auth note:      password is NOT stored"
    Write-Host ""
    Write-Host "  $HpcName"
    Write-Host "    HostName:       $HpcHost"
    Write-Host "    Port:           $HpcPort"
    Write-Host "    User:           $HpcUser"
    Write-Host "    Auth note:      password and Google Authenticator code are NOT stored"
    Write-Host "    Keep alive:     ServerAliveInterval=60, ServerAliveCountMax=10"
    Write-Host "    Remote dir:     $HpcDefaultRemoteDir"
    Write-Host ""
    Write-Host "Confirm these parameters before writing. Use -Force to skip this prompt."
}

function Confirm-Write {
    if ($Force) {
        return
    }
    $answer = Read-Host "Type YES to write these files"
    if ($answer -ne "YES") {
        Write-Host "Cancelled. No files were changed." -ForegroundColor Yellow
        exit 1
    }
}

function Backup-IfExists {
    param([string]$Path)
    if (Test-Path -LiteralPath $Path) {
        $backup = "$Path.bak.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        Copy-Item -LiteralPath $Path -Destination $backup
        Write-Host "Backed up: $backup"
    }
}

function Upsert-CodexBlock {
    param(
        [string]$Path,
        [string]$Block
    )

    $content = ""
    if (Test-Path -LiteralPath $Path) {
        $content = Get-Content -LiteralPath $Path -Raw
        if ($null -eq $content) {
            $content = ""
        }
    }

    $pattern = "(?ms)^# Codex saved SSH profiles\r?\n.*?(?=\r?\nHost\s|\z)"
    if ($content -match $pattern) {
        return [regex]::Replace($content, $pattern, $Block.TrimStart(), 1)
    }
    return $content.TrimEnd() + "`r`n" + $Block.TrimStart()
}

Show-Plan
Confirm-Write

New-Item -ItemType Directory -Force -Path $SshDir | Out-Null
if (-not (Test-Path -LiteralPath $ConfigPath)) {
    New-Item -ItemType File -Path $ConfigPath | Out-Null
}

Backup-IfExists -Path $ConfigPath
Backup-IfExists -Path $ProfilePath

$sshBlock = @"
# Codex saved SSH profiles
# $DlName: password-auth server. Password is intentionally not stored here.
Host $DlName
    HostName $DlHost
    Port $DlPort
    User $DlUser

# $HpcName: Google Authenticator required at login. Codex should keep the session alive after login until asked to disconnect.
Host $HpcName
    HostName $HpcHost
    Port $HpcPort
    User $HpcUser
    ServerAliveInterval 60
    ServerAliveCountMax 10
"@

$newConfig = Upsert-CodexBlock -Path $ConfigPath -Block $sshBlock
Set-Content -LiteralPath $ConfigPath -Value $newConfig -Encoding ascii

$profiles = [ordered]@{
    $DlName = [ordered]@{
        host = $DlHost
        port = $DlPort
        user = $DlUser
        ssh_config_host = $DlName
        auth = "password"
        password_stored = $false
        requires_google_authenticator = $false
        keep_connection_until_disconnect = $true
    }
    $HpcName = [ordered]@{
        host = $HpcHost
        port = $HpcPort
        user = $HpcUser
        ssh_config_host = $HpcName
        auth = "password + Google Authenticator TOTP"
        password_stored = $false
        otp_stored = $false
        requires_google_authenticator = $true
        keep_connection_until_disconnect = $true
        default_remote_dir = $HpcDefaultRemoteDir
    }
}

$profiles | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $ProfilePath -Encoding ascii

Write-Host ""
Write-Host "Done." -ForegroundColor Green
Write-Host "Wrote:"
Write-Host "  $ConfigPath"
Write-Host "  $ProfilePath"
Write-Host ""
Write-Host "Test commands:"
Write-Host "  ssh $DlName"
Write-Host "  ssh $HpcName"
Write-Host ""
Write-Host "No passwords or Google Authenticator codes were stored."
