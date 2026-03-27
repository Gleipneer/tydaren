#!/usr/bin/env bash
# Startar Reflektionsarkiv (Tyda): MySQL (om möjligt), FastAPI på :8000, Vite på :5173,
# och Tailscale Funnel (HTTPS → http://127.0.0.1:5173).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Kräver venv + node_modules (kör ./scripts/start.sh en gång på ny klon om något saknas).
BACKEND_DIR="$ROOT/backend"
FRONTEND_DIR="$ROOT/frontend"
BACKEND_LOG="${TYDAREN_BACKEND_LOG:-/tmp/tydaren-backend.log}"
FRONTEND_LOG="${TYDAREN_FRONTEND_LOG:-/tmp/tydaren-frontend.log}"

log() { printf '%s %s\n' "$(date -Iseconds)" "$*"; }

stop_listeners() {
  local p
  for p in 5173 8000; do
    if command -v fuser >/dev/null 2>&1; then
      fuser -k -TERM "${p}/tcp" >/dev/null 2>&1 || true
    fi
  done
  sleep 1
  for p in 5173 8000; do
    if command -v fuser >/dev/null 2>&1; then
      fuser -k -KILL "${p}/tcp" >/dev/null 2>&1 || true
    fi
  done
  sleep 0.5
}

ensure_mysql() {
  if ! command -v systemctl >/dev/null 2>&1; then
    log "systemctl saknas — hoppar över att starta MySQL (antar att den redan kör)."
    return 0
  fi
  for svc in mariadb mysql; do
    if systemctl cat "${svc}.service" >/dev/null 2>&1; then
      if systemctl is-active --quiet "${svc}.service" 2>/dev/null; then
        log "MySQL/MariaDB (${svc}) är redan aktiv."
        return 0
      fi
      log "Försöker starta ${svc}.service …"
      if systemctl start "${svc}.service" 2>/dev/null; then
        log "${svc}.service startad."
        return 0
      fi
    fi
  done
  log "Kunde inte starta MySQL via systemctl (behövs ev. sudo). Kontrollera att MariaDB/MySQL kör på :3306."
}

wait_http() {
  local url="$1" name="$2" max="${3:-90}"
  local i
  for ((i = 1; i <= max; i++)); do
    if curl -sf --connect-timeout 2 "$url" >/dev/null; then
      log "${name} svarar: ${url}"
      return 0
    fi
    sleep 1
  done
  log "FEL: ${name} svarade inte inom ${max}s: ${url}"
  return 1
}

configure_funnel() {
  if ! command -v tailscale >/dev/null 2>&1; then
    log "tailscale saknas — hoppar över Funnel."
    return 0
  fi
  if ! tailscale status >/dev/null 2>&1; then
    log "Tailscale verkar inte vara uppe — hoppar över Funnel."
    return 0
  fi
  log "Konfigurerar Tailscale Funnel → http://127.0.0.1:5173 (HTTPS 443, path /) …"
  if tailscale funnel --bg --yes --https=443 --set-path=/ http://127.0.0.1:5173; then
    :
  elif tailscale funnel --bg --yes http://127.0.0.1:5173; then
    log "Funnel satt med förenklad syntax."
  else
    log "VARNING: tailscale funnel misslyckades (ACL/cap funnel eller behörighet?). Kör manuellt: tailscale funnel status"
    return 0
  fi
  log "Konfigurerar Funnel TCP 8443 + 10000 → MySQL 127.0.0.1:3306 …"
  if tailscale funnel --bg --yes --tcp=8443 tcp://127.0.0.1:3306; then
    :
  else
    log "VARNING: TCP-funnel 8443 misslyckades (tillåtna portar: 443, 8443, 10000)."
  fi
  if tailscale funnel --bg --yes --tcp=10000 tcp://127.0.0.1:3306; then
    :
  else
    log "VARNING: TCP-funnel 10000 misslyckades."
  fi
  tailscale funnel status 2>/dev/null | head -40 || true
}

cd "$ROOT"

log "Stoppar befintliga lyssnare på 5173 och 8000 …"
stop_listeners

ensure_mysql

if [[ ! -x "$BACKEND_DIR/venv/bin/uvicorn" ]]; then
  log "FEL: $BACKEND_DIR/venv/bin/uvicorn saknas. Skapa venv och pip install -r requirements.txt i backend/."
  exit 1
fi

if [[ ! -f "$FRONTEND_DIR/package.json" ]]; then
  log "FEL: frontend/package.json saknas."
  exit 1
fi

log "Startar backend (uvicorn) …"
: >"$BACKEND_LOG"
(
  cd "$BACKEND_DIR"
  exec ./venv/bin/uvicorn app.main:app --host 127.0.0.1 --port 8000 >>"$BACKEND_LOG" 2>&1
) &
BACKEND_PID=$!

log "Startar frontend (npm run dev:funnel) …"
: >"$FRONTEND_LOG"
(
  cd "$FRONTEND_DIR"
  exec npm run dev:funnel >>"$FRONTEND_LOG" 2>&1
) &
FRONTEND_PID=$!

cleanup_on_fail() {
  log "Avslutar pga fel …"
  kill "$BACKEND_PID" 2>/dev/null || true
  kill "$FRONTEND_PID" 2>/dev/null || true
}
trap cleanup_on_fail ERR

wait_http "http://127.0.0.1:8000/api/health" "Backend"
wait_http "http://127.0.0.1:8000/api/db-health" "Backend→MySQL"
wait_http "http://127.0.0.1:5173/" "Frontend"
wait_http "http://127.0.0.1:5173/api/concepts" "Frontend→API-proxy"

trap - ERR
configure_funnel

FUNNEL_URL=""
if command -v tailscale >/dev/null 2>&1 && FUNNEL_URL=$(tailscale status --json 2>/dev/null | jq -r '.Self.DNSName | rtrimstr(".")' 2>/dev/null); then
  if [[ -n "$FUNNEL_URL" && "$FUNNEL_URL" != "null" ]]; then
    log "Klart. Öppna i webbläsare: https://${FUNNEL_URL}"
  fi
fi

log "Processer: backend pid=${BACKEND_PID}, frontend pid=${FRONTEND_PID}"
log "Loggar: $BACKEND_LOG | $FRONTEND_LOG"
log "Stoppa lyssnare: fuser -k 5173/tcp 8000/tcp  (eller kör skriptet igen — det stoppar portar först)"
