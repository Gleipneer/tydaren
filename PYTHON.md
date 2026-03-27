Tyda – backend (mellanlager)

Backenden är delen mellan frontend och databasen. Den tar emot anrop från webbappen, pratar med MySQL och skickar tillbaka svar.

Vi valde FastAPI eftersom det är ett modernt och tydligt Python-ramverk som passar bra när man vill bygga ett API snabbt men ändå strukturerat. Det är lätt att dela upp koden i olika delar, lätt att testa och fungerar bra tillsammans med JSON och HTTP, vilket passade vårt projekt.

I vårt system används backenden till att:

- hantera inloggning och användare
- hämta och spara poster
- hämta kategorier, begrepp och aktivitet
- skicka data mellan frontend och databasen

Vi ser alltså backenden som ett mellanlager som gör att frontend inte behöver prata direkt med databasen.