# Reflektionsarkiv  
Joakim Emilsson – YH25  
Martin Fält – YH25  

Reflektionsarkiv är vårt databasprojekt där vi har byggt ett system för att lagra och organisera personliga texter.

Vi har valt att låta användare skapa poster, välja kategori, koppla begrepp och se aktivitet som hör till posterna. Ovanpå databasen har vi också byggt ett webbsystem för att visa hur databasen fungerar i praktiken. Det finns även en valfri AI-funktion som kan ge en möjlig tolkning av en drömtext, men AI-delen är bara ett extra lager. Själva kärnan i projektet är databasen.

Vi har byggt projektet ovanpå databasen `reflektionsarkiv` och delat upp informationen i flera tabeller för att undvika onödig dubbel lagring och få tydliga relationer mellan användare, kategorier, poster, begrepp och loggar.

--

Systemets huvudidé

Vi har gjort systemet för att en användare ska kunna:

- registrera sig och logga in
- skapa egna poster
- välja kategori på posten, till exempel dröm, vision, tanke, reflektion eller dikt
- spara posten som privat eller publik
- koppla begrepp till posten
- se aktivitet kopplad till poster
- i webbsystemet även kunna använda automatisk begreppsmatchning och valfri AI-tolkning

Vi ser alltså databasen som grunden, medan webbsystemet används för att visa hur databasen fungerar i ett riktigt system.

--

Databasens tabeller

-- Anvandare

I tabellen `Anvandare` sparar vi information om de användare som kan använda systemet.

Exempel på attribut:
`AnvandarID`, `Anvandarnamn`, `Epost`, `LosenordHash`, `ArAdmin`, `SkapadDatum`

Vi har gjort så att varje användare får ett unikt ID. E-postadressen måste också vara unik. Lösenord lagras inte i klartext utan som hash.

--

-- Kategorier

I tabellen `Kategorier` sparar vi vilka typer av poster som finns i systemet.

Exempel på attribut:
`KategoriID`, `Namn`, `Beskrivning`

Vi använder den här tabellen för att hålla isär olika typer av innehåll, till exempel dröm, vision, tanke, reflektion och dikt.

--

-- Poster

`Poster` är den centrala tabellen i databasen. Här sparar vi själva texterna som användaren skriver.

Exempel på attribut:
`PostID`, `AnvandarID`, `KategoriID`, `Titel`, `Innehall`, `Synlighet`, `SkapadDatum`

Varje post hör till en användare och en kategori. Vi har också valt att låta varje post ha en synlighet, alltså om den är privat eller publik.

--

-- Begrepp

I tabellen `Begrepp` sparar vi ord och symboler som kan kopplas till poster.

Exempel på attribut:
`BegreppID`, `Ord`, `Beskrivning`, `SkapadDatum`

Detta fungerar som ett litet begreppsbibliotek där vi kan lagra ord som till exempel orm, vatten, tempel, svart, eld och resa.

--

-- PostBegrepp

`PostBegrepp` är kopplingstabellen mellan `Poster` och `Begrepp`.

Exempel på attribut:
`PostBegreppID`, `PostID`, `BegreppID`

Vi behöver den här tabellen eftersom en post kan ha flera begrepp, och samma begrepp kan finnas i flera poster. Det är alltså en många-till-många-relation.

Vi har valt att lösa detta med en egen kopplingstabell i stället för att försöka lägga flera begrepp i samma kolumn. Det gör databasen tydligare och mer normaliserad.

--

-- AktivitetLogg

I tabellen `AktivitetLogg` sparar vi händelser som gäller poster.

Exempel på attribut:
`LoggID`, `PostID`, `AnvandarID`, `Handelse`, `Tidpunkt`

Här loggar vi till exempel när en ny post skapas eller när en post uppdateras.

--

Relationer i databasen

Vi har byggt databasen med tydliga relationer mellan tabellerna.

- en användare kan ha flera poster
- en kategori kan kopplas till flera poster
- en post kan ha flera begrepp
- ett begrepp kan förekomma i flera poster
- en post kan ha flera logghändelser

För att lösa många-till-många-relationen mellan poster och begrepp använder vi tabellen `PostBegrepp`.

Vi har gjort detta för att undvika dubbel lagring och för att få en tydlig och hållbar struktur.

--

Databasens regler och skydd

Vi har använt flera vanliga databasregler för att hålla datan korrekt.

Vi har använt:

- `PRIMARY KEY`
- `FOREIGN KEY`
- `NOT NULL`
- `UNIQUE`
- `DEFAULT`
- `CHECK`

Exempel på detta är att:

- varje tabell har en primärnyckel
- relationer mellan tabellerna säkras med främmande nycklar
- vissa fält inte får vara tomma
- e-post och begrepp är unika där det behövs
- vissa kolumner får standardvärden
- postens titel kontrolleras så att den inte blir tom

Vi har också använt `ON DELETE CASCADE` i kopplingar där det passar, så att kopplad data tas bort automatiskt när en post eller ett begrepp tas bort.

--

Triggers och lagrad procedur

För att uppfylla projektkraven har vi byggt in både triggers och en lagrad procedur i databasen.

-- Triggers

Vi har två triggers i projektet:

- en trigger som loggar när en ny post skapas
- en trigger som loggar när en post uppdateras

Båda skriver till tabellen `AktivitetLogg`.

Vi har valt att göra detta i databasen i stället för att lägga all logik i backend. På det sättet kan databasen själv reagera på vissa händelser.

--

-- Lagrad procedur

Vi har också gjort en lagrad procedur som heter `hamta_poster_per_kategori`.

Den används för att visa hur många poster som finns per kategori inom ett valt datumintervall.

Vi valde att ha detta i databasen för att visa att viss analyslogik kan ligga direkt där och inte bara i applikationen.

--

Transaktioner

Vi har även visat transaktioner i projektet.

I vår SQL-fil finns exempel där vi:

- gör en ändring
- kontrollerar resultatet
- använder `ROLLBACK` för att ångra ändringen

Vi har också visat ett exempel med borttagning av en post och sedan ångrat den med `ROLLBACK`.

Detta visar hur man kan arbeta säkrare med data och hur transaktioner hjälper till att skydda dataintegriteten.

--

Säkerhet

Vi har försökt hålla säkerheten på en rimlig nivå för ett skolprojekt.

-- I databasen

Vi har arbetat med säkerhet genom att använda:

- primärnycklar och främmande nycklar för att hålla relationerna korrekta
- `NOT NULL`, `UNIQUE`, `DEFAULT` och `CHECK` där det behövs
- separata databasanvändare med olika rättigheter

Vi har till exempel en applikationsanvändare som bara ska ha de rättigheter som behövs i vanlig drift, och en separat administrativ användare för mer full kontroll vid till exempel setup eller migrationer.

Vi har alltså tänkt på att appen inte ska behöva använda fulla root-rättigheter hela tiden.

--

-- I systemet ovanpå databasen

I webbsystemet har vi dessutom:

- hashade lösenord
- autentisering med JWT
- skyddade skrivoperationer
- vanliga användare som bara ska kunna arbeta med sina egna poster
- admin som har större rättigheter

Vi ser detta som ett extra skyddslager ovanpå databasen.

--

Prestanda och index

Vi har lagt index på de kolumner som används ofta vid relationer, sökningar, sortering och loggning.

Vi har till exempel index på:

- `Poster(AnvandarID)` för att snabbare kunna hämta en användares poster
- `Poster(KategoriID)` för att snabbare kunna filtrera poster per kategori
- `Poster(SkapadDatum)` för att snabbare kunna sortera poster efter datum
- `PostBegrepp(BegreppID)` för att snabbare kunna koppla och analysera begrepp
- `AktivitetLogg(PostID, Tidpunkt)` för att snabbare kunna läsa loggar för en viss post i tidsordning

Vi har alltså försökt tänka på prestanda redan i databasdesignen, även om detta är ett skolprojekt och inte en jättestor produktionsdatabas.

--

Varför vi valde relationsdatabas

Vi valde MySQL och en relationsdatabas eftersom vår data är tydligt strukturerad och innehåller flera relationer mellan olika delar.

Vi arbetar med:

- användare
- kategorier
- poster
- begrepp
- kopplingar mellan poster och begrepp
- aktivitetsloggar

Det passar bra i en relationsdatabas där vi kan använda:

- primärnycklar
- främmande nycklar
- JOIN
- GROUP BY
- constraints
- triggers
- lagrad procedur

Vi tycker att en NoSQL-lösning hade passat sämre här eftersom projektet bygger på tydliga relationer mellan tabellerna och på att datan ska vara lätt att kontrollera.

--

Vad som ligger i databasen och vad som ligger i systemet ovanpå

Vi har försökt vara tydliga med vad som hör hemma i databasen och vad som hör hemma i systemet ovanpå.

I databasen ligger:

- användare
- kategorier
- poster
- begrepp
- kopplingar mellan poster och begrepp
- aktivitetsloggar
- regler, relationer, triggers och procedur

I systemet ovanpå ligger:

- inloggningsflöde
- visning i frontend
- funktioner för att skapa och läsa poster
- automatisk begreppsmatchning i text
- valfri AI-tolkning av drömtext

Vi tycker att detta är viktigt eftersom databasen ska vara grunden, medan applikationen visar hur databasen kan användas i praktiken.

--

Reflektioner

När vi byggde projektet blev det tydligt för oss att en databas inte bara handlar om att lagra data, utan om att lagra den på ett sätt som är tydligt, hållbart och lätt att arbeta med.

Det som varit viktigast för oss i projektet är bland annat:

- att förstå varför tabeller behöver delas upp
- att förstå varför många-till-många-relationen mellan poster och begrepp behöver en egen kopplingstabell
- att hålla databasen så normaliserad som möjligt
- att tänka på dataintegritet
- att tänka på säkerhet och rättigheter
- att skilja mellan det som hör hemma i databasen och det som hör hemma i systemet ovanpå

Vi har därför sett databasen som själva kärnan i projektet. Frontend och AI-funktionerna har vi använt för att visa hur databasen kan användas i ett riktigt system, men de ersätter inte databasen och är inte huvudfokus i uppgiften.

--

Slutsats

Reflektionsarkiv är vårt databassystem för att lagra och organisera personliga texter i olika kategorier.

Vi har byggt en relationsdatabas med tydliga tabeller, relationer, constraints, triggers, lagrad procedur, säkerhetstänk och indexering.

Ovanpå databasen har vi byggt ett webbsystem för att göra det lättare att visa hur databasen fungerar i praktiken. Den valfria AI-funktionen är bara ett extra lager och inte det viktigaste i projektet.

På så sätt blir Reflektionsarkiv både ett databassystem och en konkret demonstration av hur en databas kan användas i ett riktigt användarsystem.

--

Hur systemet körs

Projektet innehåller:

- backend i Python / FastAPI
- frontend i React / Vite
- databas i MySQL

Vi har färdiga startskript för att köra systemet.

-- Windows

-- powershell
.\scripts\start.ps1

./scripts/start.sh