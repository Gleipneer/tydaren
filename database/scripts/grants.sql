-- Applikationsanvändare
-- Den här användaren är tänkt för själva systemet när det körs i vardagen.
-- Vi vill att appen bara ska ha de rättigheter den faktiskt behöver, inte full kontroll över databasen.

-- Skapar en användare för appen om den inte redan finns
CREATE USER IF NOT EXISTS 'reflektionsarkiv_app'@'localhost' IDENTIFIED BY 'app_password_placeholder';

-- Tar bort gamla rättigheter om användaren redan finns
-- Vi gör detta för att börja från ett rent läge innan vi delar ut rätt rättigheter igen
REVOKE ALL PRIVILEGES ON reflektionsarkiv.* FROM 'reflektionsarkiv_app'@'localhost';

-- Ger appen rätt att läsa, lägga till, ändra och ta bort data i databasen
-- Det räcker för vanlig användning i systemet
GRANT SELECT, INSERT, UPDATE, DELETE ON reflektionsarkiv.* TO 'reflektionsarkiv_app'@'localhost';

-- Ger appen rätt att köra lagrade procedurer i databasen
-- Det behövs till exempel om systemet ska anropa hamta_poster_per_kategori
GRANT EXECUTE ON reflektionsarkiv.* TO 'reflektionsarkiv_app'@'localhost';

-- Vi ger alltså inte appen full kontroll över databasen
-- Appen ska inte kunna skapa om tabeller, ändra struktur eller ta bort hela databasen

-- --------------------------------------------------

-- Administrativ användare
-- Den här användaren är till för mer avancerat arbete med databasen
-- Till exempel när vi sätter upp databasen från början, kör om SQL-filen eller gör större ändringar

-- Skapar en administrativ användare om den inte redan finns
CREATE USER IF NOT EXISTS 'reflektionsarkiv_admin'@'localhost' IDENTIFIED BY 'admin_password_placeholder';

-- Tar bort gamla rättigheter om användaren redan finns
-- På så sätt vet vi exakt vilka rättigheter användaren får efteråt
REVOKE ALL PRIVILEGES ON reflektionsarkiv.* FROM 'reflektionsarkiv_admin'@'localhost';

-- Ger den administrativa användaren full kontroll över databasen
-- Den här användaren kan användas vid setup, ändringar och underhåll
GRANT ALL PRIVILEGES ON reflektionsarkiv.* TO 'reflektionsarkiv_admin'@'localhost';

-- Läser in rättigheterna så att ändringarna börjar gälla direkt
FLUSH PRIVILEGES;