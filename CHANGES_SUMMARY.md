# Shrnutí změn a návod na testování (backend_requirements (3).md)

Tento dokument popisuje implementované backendové úpravy podle specifikace `backend_requirements (3).md` a návod, jak je ověřit.

---

## 1. Přehled implementovaných změn

### Bod 1: Ukládání `awardedPoints` pro jednotlivé otázky v `auto_grade`
- **Soubor:** `backend/db_layer.py` (funkce `auto_grade` a `submit_student_attempt`)
- **Popis změny:**
  - V `auto_grade` se nyní do snapshotu každé otázky (`q_snap["awardedPoints"]`) zapisuje konkrétní počet získaných bodů:
    - U otázek typu `SINGLE_CHOICE`, `MULTI_CHOICE`, `ORDERING`, `SHORT_ANSWER`, `MATCHING`: plný počet bodů při správné odpovědi, `0` při špatné nebo nevyplněné odpovědi.
    - U otázek typu `OPEN_TEXT`: `0` bodů (čeká na ruční ohodnocení učitelem).
  - V `submit_student_attempt` je přidáno volání `flag_modified(attempt, "questions_snapshot")`, které zaručuje uložení změn v JSONB sloupci do PostgreSQL.

### Bod 2: Přidání `student_name` do endpointů detailu pokusu
- **Soubory:** `backend/main.py` a `backend/schemas.py`
- **Popis změny:**
  - Ve schématu `StudentAttemptDetailedResponse` v `backend/schemas.py` je doplněno pole `student_name: str | None = None`.
  - V endpointu pro učitele `GET /exam-assignments/{assignment_id}/attempts/{attempt_id}` je doplněno `student_name` (prioritně `email`, sekundárně `login_code`).
  - V endpointu pro studenta `GET /api/student/attempts/{attempt_id}` je doplněno `student_name` (prioritně `email`, sekundárně `login_code`).

### Bod 3: SSE Broadcast při odevzdání testu (`attempt_submitted`)
- **Soubor:** `backend/db_layer.py` (funkce `submit_student_attempt`)
- **Popis změny:**
  - Při odevzdání testu studentem (`submit_student_attempt`) se publikuje SSE událost `attempt_submitted` na kanál učitele `teacher_assignment_{assignment_id}`.
  - Zpráva obsahuje: `attempt_id`, `student_id`, `status` a `score_percent`.
  - Frontendový `TestAttemptsNotifier` na tuto událost reaguje a okamžitě bez nutnosti refreshu aktualizuje tabulku pokusů v reálném čase.

---

## 2. Návod na spuštění a otestování

### A. Automatizované testy v Dockeru

Kontejnery běží v Dockeru. Testy lze spustit přímo uvnitř kontejneru `fastapi_backend`:

1. **Spuštění nového integračního testu pro požadavky (3):**
   ```powershell
   docker exec fastapi_backend python test_requirements_3.py
   ```
   *Tento test automaticky vytvoří testovací data, projde odevzdáním se všemi typy otázek, ověří hodnoty `awardedPoints` ve snapshotu, existenci `student_name` v obou endpointech a zachycení SSE události `attempt_submitted` přes HTTP stream.*

2. **Spuštění kompletní integrační sady:**
   ```powershell
   docker exec fastapi_backend python test_integration_all_requirements.py
   ```

---

### B. Manuální testování přes Swagger / API

Swagger UI je dostupné na adrese: `http://localhost:8000/docs`

1. **Kontrola jména studenta a `awardedPoints`:**
   - Přihlaste se jako učitel a otevřete `GET /exam-assignments/{assignment_id}/attempts/{attempt_id}`.
   - V odpovědi zkontrolujte:
     - Pole `"student_name"` obsahuje email/login kód studenta.
     - V poli `"questions_snapshot"` má každý objekt otázky klíč `"awardedPoints"` s odpovídajícím počtem bodů.
2. **Kontrola SSE události:**
   - Připojte se na SSE stream: `GET /api/sse/teacher/assignments/{assignment_id}/progress`.
   - Jako student odevzdejte test přes `POST /api/student/attempts/{attempt_id}/submit`.
   - V SSE streamu učitele se okamžitě zobrazí událost `{"event": "attempt_submitted", "attempt_id": ..., "student_id": ...}`.

---

### C. Uživatelské testování ve Flutter aplikaci

1. **Hodnocení testu učitelem (`TestEvaluationPage`):**
   - Otevřete hodnocení odevzdaného testu.
   - V hlavičce se již zobrazuje skutečný email/jméno studenta místo generického ID.
   - U automaticky hodnocených otázek se správně zobrazují získané body a zelené/červené označení.
2. **Živý přehled pokusů (`TestAttemptsPage`):**
   - Mějte otevřenou stránku se seznamem pokusů pro dané přiřazení testu.
   - Jakmile student v jiném okně test odevzdá, tabulka se sama v reálném čase zaktualizuje (změna stavu na `Odevzdáno` / `Ohodnoceno` a zobrazení bodů).
