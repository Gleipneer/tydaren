# Starta Tyda lokalt

**URL:** [http://localhost:5173](http://localhost:5173) · API: [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs)

## Första gången (en gång per maskin)

1. **Python 3.11+**, **Node.js 20+**, valfritt **Docker** (MySQL enligt `docker-compose.yml`).
2. `copy backend\.env.example backend\.env` — med Docker: sätt `DB_PASSWORD=tydaren_local_dev` (samma som i `docker-compose.yml`).
3. **Backend:** `cd backend` → `py -3 -m venv venv` (eller `python -m venv venv`) → `venv\Scripts\pip install -r requirements.txt` (Windows) / `venv/bin/pip install -r requirements.txt` (Mac/Linux).
4. **Frontend:** `cd frontend` → `npm ci` eller `npm install`.
5. **Databas:** `docker compose up -d` i projektroten *eller* importera `reflektionsarkiv.sql` till egen MySQL och stäm av `backend/.env`.

## Starta (varje gång)

| Plattform | Kommando |
|-----------|----------|
| Windows | Dubbelklicka **`start.bat`** eller `.\scripts\start.ps1` |
| Mac/Linux | `./scripts/start.sh` |

**Windows (`start.bat` / `start.ps1`):** frigör portar **8000** och **5173**, `docker compose up -d`, väntar på healthy MySQL-container, sätter tom `DB_PASSWORD` mot Docker-lösenord vid behov, startar **uvicorn** minimierat, väntar tills **/api/health** och **/api/db-health** svarar, kör sedan **`npm run dev`**.

**Portar:** 3306 MySQL · 8000 API · 5173 webb.

**Utan Docker:** ha MySQL igång och rätt värden i `backend/.env`; skriptet hoppar över compose om `docker` saknas.

**Stopp:** `Ctrl+C` i terminalen (stäng ev. minimierat backend-fönster på Windows).
