# Tyda — startar MySQL (Docker), backend, frontend. Kor fran repo-roten via start.bat
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$BackendDir = Join-Path $Root "backend"
$FrontendDir = Join-Path $Root "frontend"
$ComposeFile = Join-Path $Root "docker-compose.yml"
$VenvPy = Join-Path $BackendDir "venv\Scripts\python.exe"
$BackendPort = 8000
$FrontendPort = 5173
$DockerDbPassword = "tydaren_local_dev"

Set-Location $Root

function Stop-ListenersOnPort([int] $Port) {
    $pids = @()
    netstat -ano 2>$null | Select-String "LISTENING" | Select-String ":$Port\s" | ForEach-Object {
        if ($_ -match "\s+(\d+)\s*$") { $pids += [int]$Matches[1] }
    }
    foreach ($procId in ($pids | Sort-Object -Unique)) {
        if ($procId -gt 0) {
            Stop-Process -Id $procId -Force -ErrorAction SilentlyContinue
        }
    }
}

$dockerBin = Join-Path $env:ProgramFiles "Docker\Docker\resources\bin"
if (Test-Path $dockerBin) { $env:Path = "$dockerBin;$env:Path" }

Write-Host ""
Write-Host "Tyda — startar..." -ForegroundColor Cyan

$mysqlHealth = ""
if (Get-Command docker -ErrorAction SilentlyContinue) {
    if (Test-Path $ComposeFile) {
        docker compose -f $ComposeFile up -d
        $deadline = (Get-Date).AddSeconds(120)
        while ((Get-Date) -lt $deadline) {
            $mysqlHealth = docker inspect tydaren-mysql --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' 2>$null
            if ($mysqlHealth -eq "healthy") { break }
            Start-Sleep -Seconds 2
        }
        # Tom DB_PASSWORD + Docker-MySQL: satt samma losenord som i docker-compose.yml
        $envFile = Join-Path $BackendDir ".env"
        if ((Test-Path $envFile) -and ($mysqlHealth -eq "healthy")) {
            $lines = Get-Content $envFile -Encoding UTF8
            $changed = $false
            for ($i = 0; $i -lt $lines.Count; $i++) {
                if ($lines[$i] -match '^\s*DB_PASSWORD\s*=\s*$') {
                    $lines[$i] = "DB_PASSWORD=$DockerDbPassword"
                    $changed = $true
                    break
                }
            }
            if ($changed) {
                $lines | Set-Content $envFile -Encoding UTF8
                Write-Host 'Backend: satte DB_PASSWORD for Docker-MySQL.' -ForegroundColor Yellow
            }
        }
    }
} else {
    Write-Host 'Docker saknas — antar att MySQL redan kor (se START.md).' -ForegroundColor Yellow
}

if (-not (Test-Path $VenvPy)) {
    Write-Host 'Saknas backend\venv. Se START.md: skapa venv och pip install -r requirements.txt' -ForegroundColor Red
    exit 1
}

Stop-ListenersOnPort $BackendPort
Stop-ListenersOnPort $FrontendPort
Start-Sleep -Seconds 1

Start-Process -FilePath $VenvPy -WorkingDirectory $BackendDir -WindowStyle Minimized `
    -ArgumentList "-m", "uvicorn", "app.main:app", "--host", "127.0.0.1", "--port", "$BackendPort"

$ready = $false
for ($i = 0; $i -lt 120; $i++) {
    try {
        $r = Invoke-RestMethod -Uri "http://127.0.0.1:$BackendPort/api/health" -TimeoutSec 2
        if ($r.status -eq "ok") {
            $db = Invoke-RestMethod -Uri "http://127.0.0.1:$BackendPort/api/db-health" -TimeoutSec 5
            if ($db.status -eq "ok") { $ready = $true; break }
        }
    } catch { }
    Start-Sleep -Milliseconds 500
}

if (-not $ready) {
    Write-Host 'Backend svarar inte eller nar inte databasen. Kontrollera Docker/MySQL och backend\.env' -ForegroundColor Red
    exit 1
}

Write-Host "Backend OK (http://127.0.0.1:$BackendPort)" -ForegroundColor Green
Set-Location $FrontendDir
if (-not (Test-Path "node_modules")) {
    Write-Host 'Installerar frontend-beroenden...' -ForegroundColor Yellow
    npm install
}

Write-Host ""
Write-Host "Frontend: http://localhost:$FrontendPort" -ForegroundColor Green
Write-Host 'Tryck Ctrl+C for att stoppa Vite (backend fortsatter i bakgrunden).' -ForegroundColor Gray
Write-Host ""

npm run dev
