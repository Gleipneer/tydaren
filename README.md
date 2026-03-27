Reflektionsarkiv
Joakim Emilsson – YH25  
Martin Fält – YH25  

Reflektionsarkiv är vårt slutprojekt i kursen Databaser.  
Projektets huvuddel är en relationsdatabas i MySQL som används för att lagra och organisera personliga texter.

Vi har byggt databasen för att en användare ska kunna skapa poster, välja kategori, koppla begrepp till poster och se aktivitet som hör till posterna. Ovanpå databasen finns ett webbsystem som visar hur databasen fungerar i praktiken, men databasen är projektets kärna.

-- Systemets idé

Systemet är gjort för att en användare ska kunna:

- registrera sig och logga in
- skapa egna poster
- välja kategori på posten
- spara poster
- koppla begrepp till poster
- se aktivitet som hör till poster

Exempel på kategorier i systemet är dröm, vision, tanke, reflektion och dikt.

-- Databasens tabeller

-- Anvandare
I tabellen `Anvandare` sparar vi information om användarna i systemet.

Exempel på kolumner:

- `AnvandarID`
- `Anvandarnamn`
- `Epost`
- `LosenordHash`
- `ArAdmin`
- `SkapadDatum`

Varje användare får ett unikt ID. E-postadressen är också unik. Lösenord lagras som saltad hash och inte i klartext. Saltningen sker genom python backend/app/security.

-- Kategorier
I tabellen `Kategorier` sparar vi vilka typer av poster som finns.

Exempel på kolumner:

- `KategoriID`
- `Namn`
- `Beskrivning`

Den här tabellen gör att vi kan hålla isär olika typer av innehåll.

-- Poster
`Poster` är den centrala tabellen i databasen. Här lagras själva texterna som användaren skriver.

Exempel på kolumner:

- `PostID`
- `AnvandarID`
- `KategoriID`
- `Titel`
- `Innehall`
- `Synlighet`
- `SkapadDatum`

Varje post hör till en användare och en kategori. Varje post har också en synlighet, alltså om den är privat eller publik.

-- Begrepp
I tabellen `Begrepp` sparar vi ord och symboler som kan kopplas till poster.

Exempel på kolumner:

- `BegreppID`
- `Ord`
- `Beskrivning`
- `SkapadDatum`

Detta fungerar som ett begreppsbibliotek där vi kan lagra ord som till exempel orm, vatten, tempel, eld och resa.

-- PostBegrepp
`PostBegrepp` är kopplingstabellen mellan `Poster` och `Begrepp`.

Exempel på kolumner:

- `PostBegreppID`
- `PostID`
- `BegreppID`

Den behövs eftersom en post kan ha flera begrepp, och samma begrepp kan finnas i flera poster. Det är alltså en många-till-många-relation.

-- AktivitetLogg
I tabellen `AktivitetLogg` sparar vi händelser som gäller poster.

Exempel på kolumner:

- `LoggID`
- `PostID`
- `AnvandarID`
- `Handelse`
- `Tidpunkt`

Här loggar vi till exempel när en ny post skapas eller när en post uppdateras.

-- Relationer i databasen

Vi har byggt databasen med tydliga relationer mellan tabellerna.

- en användare kan ha flera poster
- en kategori kan kopplas till flera poster
- en post kan ha flera begrepp
- ett begrepp kan förekomma i flera poster
- en post kan ha flera logghändelser

Många-till-många-relationen mellan poster och begrepp löses med tabellen `PostBegrepp`.

-- Databasens regler

För att hålla datan korrekt använder vi vanliga databasregler som:

- `PRIMARY KEY`
- `FOREIGN KEY`
- `NOT NULL`
- `UNIQUE`
- `DEFAULT`
- `CHECK`

Det innebär bland annat att:

- varje tabell har en primärnyckel
- relationerna säkras med främmande nycklar
- vissa fält inte får vara tomma
- vissa värden måste vara unika
- vissa kolumner får standardvärden
- vissa värden kontrolleras innan de sparas

Vi använder också `ON DELETE CASCADE` där det passar.

-- Trigger och lagrad procedur

För att uppfylla projektkraven har vi byggt in både triggers och en lagrad procedur i databasen.

-- Triggers
Vi använder triggers som loggar händelser i `AktivitetLogg`, till exempel när en post skapas eller uppdateras.

Det gör att databasen själv kan reagera på vissa händelser.

-- Lagrad procedur
Vi har gjort en lagrad procedur som heter `hamta_poster_per_kategori`.

Den används för att visa hur många poster som finns per kategori inom ett valt datumintervall.

-- Transaktioner

Vi har även visat transaktioner i projektet.

I vår SQL-fil finns exempel där vi:

- gör en ändring
- kontrollerar resultatet
- använder `ROLLBACK` för att ångra ändringen

Detta visar hur man kan arbeta säkrare med data och hur transaktioner hjälper till att skydda dataintegriteten.

-- Säkerhet

Vi har försökt hålla säkerheten på en rimlig nivå för ett skolprojekt.

Vi använder bland annat:

- primärnycklar och främmande nycklar för att hålla relationerna korrekta
- `NOT NULL`, `UNIQUE`, `DEFAULT` och `CHECK`
- hashade lösenord
- stöd för administratör i systemet genom kolumnen `ArAdmin`

Detta hjälper till att skydda både datan och strukturen i databasen.

-- Prestanda och index

Vi har lagt index på kolumner som används ofta vid relationer, sökningar, sortering och loggning.

Exempel på sådana index är:

- `Poster(AnvandarID)`
- `Poster(KategoriID)`
- `Poster(SkapadDatum)`
- unikt index på `PostBegrepp(PostID, BegreppID)`
- index på `PostBegrepp(BegreppID)`
- `AktivitetLogg(PostID, Tidpunkt)`

Det gör databasen mer effektiv när man hämtar och söker data.

-- Varför vi valde en relationsdatabas

Vi valde MySQL och en relationsdatabas eftersom vår data är tydligt strukturerad och innehåller flera relationer mellan olika delar.

Vi arbetar med:

- användare
- kategorier
- poster
- begrepp
- kopplingar mellan poster och begrepp
- aktivitetsloggar

Det passar bra i en relationsdatabas där vi kan använda primärnycklar, främmande nycklar, JOIN, GROUP BY, constraints, triggers och lagrade procedurer.

-- Reflektion

När vi byggde projektet blev det tydligt för oss att en databas inte bara handlar om att lagra data, utan om att lagra den på ett sätt som är tydligt, hållbart och lätt att arbeta med.

Det som varit viktigast i projektet är bland annat:

- att förstå varför tabeller behöver delas upp
- att förstå varför många-till-många-relationer behöver en egen kopplingstabell
- att hålla databasen så normaliserad som möjligt
- att tänka på dataintegritet
- att tänka på säkerhet och rättigheter

Vi har därför sett databasen som själva kärnan i projektet.

-- Slutsats

Reflektionsarkiv är vårt databassystem för att lagra och organisera personliga texter i olika kategorier.

Vi har byggt en relationsdatabas med tydliga tabeller, relationer, constraints, triggers, lagrad procedur, säkerhetstänk och indexering.

Projektet visar hur en databas kan byggas upp på ett strukturerat sätt och användas som grund i ett större system.