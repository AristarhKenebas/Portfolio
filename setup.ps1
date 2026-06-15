$ErrorActionPreference = "Stop"

function Check-Command($cmd) {
  return [bool](Get-Command $cmd -ErrorAction SilentlyContinue)
}

function Generate-Secret {
  $chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
  -join (1..48 | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })
}

function Collect-Config {
  Write-Host ""
  Write-Host "Configuration"
  Write-Host "-------------"
  Write-Host "Press Enter to use the default value shown in brackets."
  Write-Host ""

  do {
    $GITHUB_USERNAME = Read-Host "GitHub username"
  } while (-not $GITHUB_USERNAME)

  $GITHUB_TOKEN = Read-Host "GitHub token (optional)"

  $ADMIN_USERNAME = Read-Host "Admin username [admin]"
  if (-not $ADMIN_USERNAME) { $ADMIN_USERNAME = "admin" }

  do {
    $ADMIN_PASSWORD = Read-Host "Admin password (min 8 chars)" -AsSecureString
    $plain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
      [Runtime.InteropServices.Marshal]::SecureStringToBSTR($ADMIN_PASSWORD)
    )
    if ($plain.Length -lt 8) {
      Write-Host "Password must be at least 8 characters"
      $plain = ""
    } else {
      $confirm = Read-Host "Confirm password" -AsSecureString
      $confirmPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($confirm)
      )
      if ($plain -ne $confirmPlain) {
        Write-Host "Passwords do not match"
        $plain = ""
      }
    }
  } while (-not $plain)
  $ADMIN_PASSWORD = $plain

  $POSTGRES_PASSWORD_INPUT = Read-Host "Database password [auto-generated]"
  $POSTGRES_PASSWORD = if ($POSTGRES_PASSWORD_INPUT) { $POSTGRES_PASSWORD_INPUT } else { Generate-Secret }

  $SESSION_SECRET = Generate-Secret

  $SITE_PORT = Read-Host "Site port [3000]"
  if (-not $SITE_PORT) { $SITE_PORT = "3000" }

  $API_PORT = Read-Host "API port [3001]"
  if (-not $API_PORT) { $API_PORT = "3001" }

  $ADMIN_PORT = Read-Host "Admin port [3002]"
  if (-not $ADMIN_PORT) { $ADMIN_PORT = "3002" }

  @"
POSTGRES_USER=portfolio
POSTGRES_PASSWORD=$POSTGRES_PASSWORD
POSTGRES_DB=portfolio

SESSION_SECRET=$SESSION_SECRET
ADMIN_USERNAME=$ADMIN_USERNAME
ADMIN_PASSWORD=$ADMIN_PASSWORD

GITHUB_USERNAME=$GITHUB_USERNAME
GITHUB_TOKEN=$GITHUB_TOKEN

SITE_PORT=$SITE_PORT
API_PORT=$API_PORT
ADMIN_PORT=$ADMIN_PORT
"@ | Out-File -FilePath ".env" -Encoding utf8

  Write-Host ""
  Write-Host ".env created"
}

if (-not (Check-Command "docker")) {
  Write-Host "Installing Docker Desktop..."
  $installer = "$env:TEMP\DockerDesktopInstaller.exe"
  Invoke-WebRequest "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe" -OutFile $installer
  Start-Process $installer -Wait -ArgumentList "install --quiet"
  Write-Host "Docker installed. Restart your computer, then run this script again"
  exit 0
}

if (-not (Check-Command "git")) {
  Write-Host "Installing Git..."
  $installer = "$env:TEMP\GitInstaller.exe"
  Invoke-WebRequest "https://github.com/git-for-windows/git/releases/download/v2.45.0.windows.1/Git-2.45.0-64-bit.exe" -OutFile $installer
  Start-Process $installer -Wait -ArgumentList "/SILENT"
}

if (-not (Test-Path ".env")) {
  Collect-Config
}

if (-not (Test-Path "api")) { git clone https://github.com/AristarhKenebas/portfolio-api.git api }
if (-not (Test-Path "site")) { git clone https://github.com/AristarhKenebas/portfolio-site.git site }
if (-not (Test-Path "admin")) { git clone https://github.com/AristarhKenebas/portfolio-admin.git admin }

docker compose up -d --build

Write-Host ""
Write-Host "Site:  http://localhost:$((Get-Content .env | Select-String 'SITE_PORT').ToString().Split('=')[1])"
Write-Host "Admin: http://localhost:$((Get-Content .env | Select-String 'ADMIN_PORT').ToString().Split('=')[1])"
Write-Host "API:   http://localhost:$((Get-Content .env | Select-String 'API_PORT').ToString().Split('=')[1])"
