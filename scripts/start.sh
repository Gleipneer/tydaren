#!/usr/bin/env bash
# Tyda — Docker-MySQL, backend :8000, frontend :5173 (Unix). Se START.md.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
BACKEND_PORT=8000
FRONTEND_PORT=5173
DOCKER_PW="tydaren_local_dev"

kill_port() {
  local p="$1"
  if command -v fuser >/dev/null 2>&1; then
    fuser -k "${p}/tcp" >/dev/null 2>&1 || true
  elif command -v lsof >/dev/null 2>&1; then
    pids="$(lsof -ti ":$p" 2>/dev/null || true)"
    if [ -n "$pids" ]; then echo "$pids" | xargs kill -9 2>/dev/null || true; fi
  fi
}

echo ""
echo "Tyda — startar..."
st=""
if command -v docker >/dev/null 2>&1 && [ -f "$ROOT/docker-compose.yml" ]; then
  docker compose -f "$ROOT/docker-compose.yml" up -d
  for _ in $(seq 1 60); do
    st="$(docker inspect tydaren-mysql --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' 2>/dev/null || true)"
    [ "$st" = "healthy" ] && break
    sleep 2
  done
  ENV_FILE="$ROOT/backend/.env"
  if [ -f "$ENV_FILE" ] && [ "$st" = "healthy" ] && grep -qE '^[[:space:]]*DB_PASSWORD[[:space:]]*=$' "$ENV_FILE" 2>/dev/null; then
    sed -i.bak "s/^[[:space:]]*DB_PASSWORD[[:space:]]*=$/DB_PASSWORD=${DOCKER_PW}/" "$ENV_FILE" && rm -f "${ENV_FILE}.bak"
    echo "Backend: satte DB_PASSWORD for Docker-MySQL."
  fi
else
  echo "Docker saknas — antar att MySQL redan kör (se START.md)."
fi

PY="$ROOT/backend/venv/bin/python"
if [ ! -x "$PY" ]; then
  echo "Saknas backend/venv. Se START.md."
  exit 1
fi

kill_port "$BACKEND_PORT"
kill_port "$FRONTEND_PORT"
sleep 1

(cd "$ROOT/backend" && exec "$PY" -m uvicorn app.main:app --host 127.0.0.1 --port "$BACKEND_PORT") &

ready=0
for _ in $(seq 1 120); do
  if curl -fsS --connect-timeout 2 "http://127.0.0.1:${BACKEND_PORT}/api/health" >/dev/null 2>&1 \
    && curl -fsS --connect-timeout 5 "http://127.0.0.1:${BACKEND_PORT}/api/db-health" >/dev/null 2>&1; then
    ready=1
    break
  fi
  sleep 0.5
done
if [ "$ready" -ne 1 ]; then
  echo "Backend svarar inte eller når inte databasen. Kontrollera Docker/MySQL och backend/.env"
  exit 1
fi

echo "Backend OK (http://127.0.0.1:${BACKEND_PORT})"
cd "$ROOT/frontend"
[ -d node_modules ] || npm install
echo ""
echo "Frontend: http://localhost:${FRONTEND_PORT}"
echo "Tryck Ctrl+C för att stoppa Vite (backend fortsätter i bakgrunden)."
echo ""
exec npm run dev
