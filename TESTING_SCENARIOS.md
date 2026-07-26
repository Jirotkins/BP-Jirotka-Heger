# Scénáře pro testování aplikace

Tento dokument podrobně popisuje end-to-end (E2E) testovací scénáře pro ověření kompletního toku aplikace. Všechny uvedené kroky jsou v současné době **plně testovatelné** jak přes připravovaný frontend, tak přímo přes Swagger UI (`http://localhost:8000/docs`).

## Úvodní příprava ve Swaggeru
1. Otevřete `http://localhost:8000/docs`
2. Pokud nemáte učitelský účet, vytvořte si jej přes **POST `/test/create-teacher`**.
3. Přihlaste se přes **POST `/login`** (případně kliknutím na zelené tlačítko `Authorize` nahoře) pomocí údajů vytvořeného učitele. Získáte JWT token, který vás opravňuje volat chráněné učitelské endpointy. Zadejte jej do formuláře Authorize.

---

## Scénář 1: Základní nastavení (Třída, Banka, Otázky)

**Cíl:** Ověřit, že učitel může vytvořit své základní organizační jednotky.

1. **Založení třídy:**
   - **Endpoint:** `POST /groups`
   - **Payload:** `{"name": "Fyzika 8.A", "description": "Základní kurz"}`
   - **Očekávané chování:** Vrátí vytvořenou skupinu s jejím `group_id`.
   
2. **Založení banky otázek:**
   - **Endpoint:** `POST /banks`
   - **Payload:** `{"name": "Fyzika - Kinematika", "description": "Otázky na rychlost a dráhu"}`
   - **Očekávané chování:** Vrátí novou banku s `bank_id`.

3. **Přidání otázek do banky:**
   - **Endpoint:** `POST /banks/{bank_id}/questions`
   - **Payload (Single Choice):**
     ```json
     {
       "text": "Jaká je základní jednotka rychlosti?",
       "type": "SINGLE_CHOICE",
       "default_points": 1,
       "answers": [
         {"text": "m/s", "is_correct": true},
         {"text": "km/h", "is_correct": false}
       ]
     }
     ```
   - **Očekávané chování:** Vrátí vytvořenou otázku. Vytvořte takto alespoň 2 různé otázky. Zkuste si zavolat `GET /banks` a ověřte, že nová vlastnost `questionCount` (nebo `question_count`) správně ukazuje počet otázek.

---

## Scénář 2: Správa studentů

**Cíl:** Ověřit hromadný import a následné odebírání studentů.

1. **Hromadné přidání studentů:**
   - **Endpoint:** `POST /groups/{group_id}/students/bulk`
   - **Payload:** `{"prefix": "student8a", "count": 5}`
   - **Očekávané chování:** API vytvoří 5 žáků a vrátí CSV soubor ke stažení (v prohlížeči) s jejich vygenerovanými e-maily, login kódy a hesly. **Tento soubor si uložte**, budete potřebovat údaje pro přihlášení studenta!

2. **Smazání studenta ze třídy:**
   - Nejprve zavolejte `GET /groups/{group_id}/students` a poznamenejte si `student_id` jednoho žáka.
   - **Endpoint:** `DELETE /groups/{group_id}/students/{student_id}`
   - **Očekávané chování:** Vrátí úspěch. Znovu zavolejte GET na studenty a ověřte, že byl odebrán. (Jeho účet ale nadále existuje v DB).

---

## Scénář 3: Tvorba a úprava testu

**Cíl:** Složit otázky do šablony testu a otestovat kaskádové efekty a modifikace.

1. **Vytvoření šablony testu:**
   - **Endpoint:** `POST /test-templates`
   - **Payload:** `{"name": "Pololetní test", "difficulty": "MEDIUM"}`
   - **Očekávané chování:** Vrátí `template_id`.

2. **Vložení otázek do testu:**
   - **Endpoint:** `POST /test-templates/{template_id}/questions`
   - **Payload:** Pole ID otázek z vaší banky, např. `[1, 2]`
   - **Očekávané chování:** Otázky se přidají do testu a zafixují si své pozice (1, 2...).

3. **Úprava otázky:**
   - **Endpoint:** `PUT /banks/{bank_id}/questions/{question_id}`
   - **Popis:** Změňte u jedné otázky znění textu nebo odpovědi.
   - **Očekávané chování:** Změna se projeví v DB. Jelikož test je zatím jen šablona, studenti, kteří jej dostanou v budoucnu, už uvidí novou verzi otázky.

*Poznámka k testování: Můžete zde zkusit smazat otázku (`DELETE /banks/{bank_id}/questions/{question_id}`) bez parametru `force=true`. API by vás mělo zastavit (409 Conflict), protože je otázka již v testu.*

---

## Scénář 4: Naplánování testu (Exam Assignment)

**Cíl:** Přiřadit test konkrétní třídě.

1. **Přiřazení testu:**
   - **Endpoint:** `POST /groups/{group_id}/exam-assignments`
   - **Payload:** 
     ```json
     {
       "template_id": 1,
       "time_limit_minutes": 45,
       "is_active": true
     }
     ```
   - **Očekávané chování:** Vrátí `assignment_id`. Díky `is_active: true` je test rovnou přístupný (pokud jste nenastavili `activate_from` do budoucnosti).

---

## Scénář 5: Vypracování testu studentem & Pozorování (SSE)

**Cíl:** Simulovat studenta, který řeší test, a učitele, který ho sleduje živě.

### Krok A: Napojení učitele na SSE (Sledování)
Tento krok se špatně testuje přímo ve Swaggeru (Swagger UI nepodporuje udržování SSE streams nativně), doporučujeme využít prohlížeč nebo např. Postman/cURL:
1. Učitel se musí připojit pomocí příkazu nebo nástroje podporujícího EventSource.
2. Příklad přes cURL: 
   `curl -N -H "Authorization: Bearer <TEACHER_TOKEN>" http://localhost:8000/api/sse/teacher/assignments/{assignment_id}/progress`
3. Spojení zůstává otevřené a "visí".

### Krok B: Pohled studenta
1. **Přihlášení studenta:** 
   Otevřete nové anonymní okno prohlížeče nebo získejte nový token. Použijte údaje (email, heslo/login kód) získané z CSV z kroku 2 na endpointu `POST /login` (nebo `POST /login/student`) a získejte studentův JWT Token. Vyměňte jej ve Swaggeru.
2. **Přehled testů:**
   - **Endpoint:** `GET /api/student/assignments`
   - **Očekávané chování:** Student by zde měl vidět přiřazený test ("Pololetní test"). Získá si jeho `assignment_id`.
3. **Spuštění testu:**
   - **Endpoint:** `POST /api/student/assignments/{assignment_id}/start`
   - **Očekávané chování:** Vrátí `attempt_id` a kopii (snapshot) všech otázek, které má zodpovědět. **Pozor:** Od tohoto okamžiku začíná běžet čas a stav je "STARTED".
4. **Odpovídání (Průběžné ukládání):**
   - **Endpoint:** `PUT /api/student/attempts/{attempt_id}/answers`
   - **Payload:** `{"answers": {"1": "123", "2": "true"}}` (Klíč je ID otázky z pohledu testu, hodnota je odpověď žáka).
   - **Co sledovat:** Po úspěšném uložení odpovědi backend "vystřelí" událost přes **SSE**. Podívejte se do okna s otevřeným cURL učitele (krok A). Okamžitě by se tam měla vypsat JSON zpráva informující o postupu daného studenta!
5. **Odevzdání testu:**
   - **Endpoint:** `POST /api/student/attempts/{attempt_id}/submit`
   - **Očekávané chování:** Test se ukončí, spočítají se body (pro automaticky vyhodnotitelné otázky) a stav se změní na `SUBMITTED`. Učitel opět obdrží přes SSE událost o tom, že student test odevzdal.

---
**Závěr:** Při těchto scénářích projdete celý životní cyklus v aplikaci. Pokud u kroku B4 vidíte události vyskakující v konzoli učitele, testování napojení SSE proběhlo úspěšně. Pro frontendáře doporučujeme u SSE používat standardní `EventSource` objekt v prohlížeči a posílat token v hlavičkách (nebo v query parametru, pokud hlavičky nejsou podporovány, což ale EventSource nativně neumožňuje bez polyfillu).
