-- MySQL-användare för polare som ansluter via Tailscale Funnel TCP (port 8443).
-- Trafiken terminerar som TCP till 127.0.0.1:3306, så MySQL ser klienten som @'localhost'
-- (inte @'%'). Därför måste användaren skapas för 'localhost'.
--
-- INNAN DU KÖR: byt lösenordet nedan. Applicera som root (eller annan admin):
--   mysql -u root -p < workbench_funnel_user.example.sql
-- (eller kopiera till en .sql-fil utan "example" i namnet om du vill undvika att checka in lösenord.)
--
-- SÄKERHET: Port 8443 blir nåbar på internet för alla som känner till DNS-namnet.
-- Använd ett långt slumpmässigt lösenord och minimala rättigheter. Stäng av med:
--   tailscale funnel --tcp=8443 off

CREATE USER IF NOT EXISTS 'tyda_workbench'@'localhost'
  IDENTIFIED WITH mysql_native_password BY 'BYT_TILL_ETT_LÅNGT_SLUMPMÄSSIGT_LÖSENORD';

REVOKE ALL PRIVILEGES ON *.* FROM 'tyda_workbench'@'localhost';

-- Läs + visa vyer + kör procedurer (justera vid behov)
GRANT SELECT, SHOW VIEW, EXECUTE ON reflektionsarkiv.* TO 'tyda_workbench'@'localhost';

-- Om polaren ska kunna ändra schema/data som i full Workbench-session, byt ovan till t.ex.:
-- GRANT ALL PRIVILEGES ON reflektionsarkiv.* TO 'tyda_workbench'@'localhost';

FLUSH PRIVILEGES;
