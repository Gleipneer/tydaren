#!/usr/bin/env bash
# Skapar/uppdaterar MySQL-användaren tyda_workbench@localhost (Funnel TCP → ser ut som localhost)
# och skriver anslutningsuppgifter till database/COMPANION_WORKBENCH.txt (gitignorerad).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$ROOT/database/COMPANION_WORKBENCH.txt"
PASS="$(openssl rand -hex 20)"

if ! sudo mysql -N -e "SELECT 1" >/dev/null 2>&1; then
  echo "FEL: sudo mysql fungerar inte. Kör som användare med sudo och MySQL root via auth_socket."
  exit 1
fi

FUNNEL_HOST=""
if command -v tailscale >/dev/null 2>&1; then
  FUNNEL_HOST="$(tailscale status --json 2>/dev/null | jq -r '.Self.DNSName | rtrimstr(".")' 2>/dev/null || true)"
fi
[[ -z "$FUNNEL_HOST" || "$FUNNEL_HOST" == "null" ]] && FUNNEL_HOST="(sätt Funnel-värdnamn från tailscale status)"

sudo mysql <<SQL
-- mysql_native_password: fungerar över Funnel-TCP utan att Workbench måste använda MySQL-SSL
-- (caching_sha2_password kräver säker anslutning och strular mot ren TCP).
CREATE USER IF NOT EXISTS 'tyda_workbench'@'localhost'
  IDENTIFIED WITH mysql_native_password BY '${PASS}';
ALTER USER 'tyda_workbench'@'localhost'
  IDENTIFIED WITH mysql_native_password BY '${PASS}';
REVOKE ALL PRIVILEGES ON *.* FROM 'tyda_workbench'@'localhost';
GRANT SELECT, INSERT, UPDATE, DELETE, SHOW VIEW, EXECUTE, CREATE TEMPORARY TABLES
  ON reflektionsarkiv.* TO 'tyda_workbench'@'localhost';
FLUSH PRIVILEGES;
SQL

umask 077
cat >"$OUT" <<EOF
Anslutning till Reflektionsarkiv (MySQL Workbench via Tailscale Funnel)
========================================================================
Skicka dessa uppgifter till kompanjonen. Filen ska inte checkas in i git.

MySQL Workbench → ny anslutning:
  Connection method:  Standard (TCP/IP)
  Hostname:           ${FUNNEL_HOST}
  Port:               8443   (om timeout: prova 10000 — samma host, samma user/lösen)
  Username:           tyda_workbench
  Password:           ${PASS}
  Default Schema:     reflektionsarkiv

SSL (fliken SSL i Workbench):
  Sätt "Use SSL" till "No" — inte "If available".
  Det betyder: slå av MySQL-protokollets eget SSL-lager. Anslutningen skyddas ändå av Tailscale Funnel på vägen över internet.
  "If available" kan strula (Workbench försöker då slå på MySQL-SSL i onödan).

Webbappen (samma värdnamn, port 443): https://${FUNNEL_HOST}/

--- Om du får "Lost connection … error 10060" (timeout) ---
Det betyder att din dator inte når servern på vald port (brandvägg/WiFi/IPv6).

1) Testa i PowerShell:
     Test-NetConnection ${FUNNEL_HOST} -Port 8443
     Test-NetConnection ${FUNNEL_HOST} -Port 10000
   TcpTestSucceeded ska vara True för minst en av dem.

2) Om båda False: prova mobilt nät (surfzon) eller annat WiFi — skolor blockar ofta port 8443.

3) Om 8443 fail men 10000 True: använd Port 10000 i Workbench.

4) Om båda True men Workbench timeout: prova Hostname = IPv4-adressen från
     ping -4 ${FUNNEL_HOST}
   (samma port). Tvingar IPv4 om IPv6 strular.

Om inget funkar: be Joakim köra ./scripts/start-tydaren.sh och skicka ny status från
  tailscale funnel status
(ska visa TCP 8443 och 10000 → 127.0.0.1:3306).

Lösenord roteras om du kör: ./scripts/setup-companion-workbench.sh igen.
EOF
chmod 600 "$OUT"
echo "Klart. Uppgifter i: $OUT"
