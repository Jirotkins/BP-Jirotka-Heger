# Dokumentace a integrační příručka Backend API pro Frontend vývojáře

Tento dokument slouží jako kompletní referenční příručka pro frontend vývojáře. Popisuje fungování aktualizovaného backendového API, životní cyklus testů, formáty dat pro jednotlivé typy otázek, autentizaci a klíčová úskalí, na která si dát při vývoji frontendu pozor.

---

## 1. Autentizace a role

Backend využívá **JWT Bearer Token** v HTTP hlavičce:
```http
Authorization: Bearer <access_token>
```

### Role a oddělení přístupů:
- **`teacher` (Učitel):** Správa bank otázek, šablon, přiřazení testů skupinám a manuální známkování.
- **`student` (Student):** Prohlížení přiřazených testů, spouštění pokusů, odevzdávání a prohlížení svých vlastních výsledků.

> [!WARNING]
> Pokud student zkusí přistoupit na endpoint vyžadující učitele (nebo naopak), backend vrátí **`403 Forbidden`**.

---

## 2. Životní cyklus testu a práce studenta

### 2.1. Získání seznamu přiřazených testů
```http
GET /api/student/assignments
```
- **Autentizace:** `require_student`
- **Návratová hodnota:** Seznam přiřazených testů. Každá položka obsahuje `assignment_id`, informace o testu, aktuální `status` a nově také **`attempt_id`** (pokud již student test zahájil, jinak `null`).

```json
[
  {
    "assignment_id": 5,
    "attempt_id": 12,
    "template_name": "Pololetní test z biologie",
    "description": "Základy buněčné biologie",
    "activate_from": "2026-05-10T08:00:00Z",
    "activate_to": "2026-05-10T12:00:00Z",
    "time_limit_minutes": 45,
    "requires_password": false,
    "status": "STARTED",
    "group_id": 2,
    "group_name": "3.A",
    "question_count": 10
  }
]
```

> [!TIP]
> **Stavy testu (`status`):**
> - `null` – Test ještě nebyl studentem spuštěn (tlačítko *Spustit test*).
> - `"STARTED"` – Test probíhá (tlačítko *Pokračovat v testu*).
> - `"SUBMITTED"` – Test byl odevzdán a čeká na manuální opravu otevřených otázek učitelem.
> - `"GRADED"` – Test je kompletně ohodnocen (tlačítko *Zobrazit výsledky*).

---

### 2.2. Zahájení / otevření pokusu
```http
POST /api/student/assignments/{assignment_id}/start
```
- **Autentizace:** `require_student`
- **Body (pokud je test chráněn heslem):**
```json
{
  "access_password": "heslo"
}
```
- **Odpověď:** Obsahuje `attempt_id`, `started_at`, `time_limit_minutes` a neměnný `questions_snapshot` (otázky a možnosti pro studenta).

---

### 2.3. Průběžné ukládání odpovědí (Auto-save)
```http
PUT /api/student/attempts/{attempt_id}/answers
```
- **Autentizace:** `require_student`
- **Body:**
```json
{
  "answers": {
    "10": 1,
    "11": [2, 3],
    "12": "Text odpovědi...",
    "13": { "Praha": "Česko", "Bratislava": "Slovensko" },
    "14": "fotosyntéza"
  }
}
```
- **Chování:** Ukládá rozpracované odpovědi do DB. Pokud má test zapnuté `show_immediate_feedback`, vrací průběžné vyhodnocení. Na pozadí bezpečně notifikuje učitele přes SSE.

---

### 2.4. Odevzdání testu
```http
POST /api/student/attempts/{attempt_id}/submit
```
- **Autentizace:** `require_student`
- **Body (volitelné – finální odpovědi):**
```json
{
  "answers": { ... }
}
```
- **Logika vyhodnocení stavu:**
  - **Bez otázek `OPEN_TEXT`:** Test se okamžitě automaticky ohodnotí a vrátí se stav **`"GRADED"`** s finálním `total_points` a `score_percent`.
  - **S otázkami `OPEN_TEXT`:** Uzavřou se automaticky hodnocené otázky a test přejde do stavu **`"SUBMITTED"`**, kde čeká na kontrolu učitelem.

```json
{
  "attempt_id": 12,
  "status": "GRADED",
  "total_points": 18.0,
  "max_points": 20.0,
  "score_percent": 90.0
}
```

---

### 2.5. Zobrazení detailu / výsledku studentovi
```http
GET /api/student/attempts/{attempt_id}
```
- **Autentizace:** `require_student`
- **Oprávnění:** Student může prohlížet **pouze své vlastní pokusy**. Přístup k cizímu pokusu vrátí **`403 Forbidden`**.
- **Odpověď:**
```json
{
  "attempt_id": 12,
  "assignment_id": 5,
  "student_id": 3,
  "started_at": "2026-05-10T08:05:00",
  "finished_at": "2026-05-10T08:35:00",
  "status": "GRADED",
  "total_points": 18.0,
  "max_points": 20.0,
  "score_percent": 90.0,
  "teacher_note": "Skvělá práce!",
  "questions_snapshot": [ ... ],
  "student_answers": { ... }
}
```

---

## 3. Typy otázek a formát dat

Backend podporuje 6 typů otázek (`QuestionType`).

| Typ otázky | Popis | Tvorba učitelem (`POST /banks/{id}/questions`) | Formát odpovědi studenta |
|---|---|---|---|
| `SINGLE_CHOICE` | Jedna správná možnost | Seznam odpovědí, právě jedna má `is_correct: true`. | `ID` odpovědi (int/string). Příklad: `15` |
| `MULTI_CHOICE` | Více správných možností | Seznam odpovědí, alespoň jedna má `is_correct: true`. | Pole `ID` odpovědí. Příklad: `[15, 17]` |
| `OPEN_TEXT` | Otevřená textová otázka (manuální oprava) | `answers` může být prázdné nebo obsahovat vzorové odpovědi/nápovědy. | Textový řetězec. Příklad: `"Popis procesu..."` |
| `ORDERING` | Řazení položek do správného pořadí | Každá odpověď má unikátní `order_index` (1, 2, 3...). | Pole seřazených ID nebo textů. Příklad: `[10, 12, 11]` |
| `MATCHING` | Spojování dvojic | Dvojice ve formátu `"Levá strana\|\|\|Pravá strana"` (s `is_correct: true`) **NEBO** objekt s `text` a `match_text`. | Objekt klíč-hodnota: `{"Levá": "Pravá"}` nebo pole dvojic `[{"left": "...", "right": "..."}]` |
| `SHORT_ANSWER` | Krátká textová odpověď (auto-evaluace) | V `answers` jsou vypsány všechny uznávané správné varianty (např. `"Země"`, `"Earth"`). | Textový řetězec. Porovnává se bez ohledu na velikost písmen a mezery. Příklad: `"  země "` |

### Příklad vytvoření MATCHING otázky:
```json
{
  "text": "Spojte hlavní města se státy",
  "type": "MATCHING",
  "default_points": 2,
  "answers": [
    { "text": "Praha|||Česko", "is_correct": true },
    { "text": "Bratislava|||Slovensko", "is_correct": true },
    { "text": "Vídeň|||Rakousko", "is_correct": true }
  ]
}
```

### Příklad vytvoření SHORT_ANSWER otázky:
```json
{
  "text": "Jaké je hlavní město Francie?",
  "type": "SHORT_ANSWER",
  "default_points": 1,
  "answers": [
    { "text": "Paříž", "is_correct": true },
    { "text": "Paris", "is_correct": true }
  ]
}
```

---

## 4. Rozhraní pro učitele (Hodnocení a výsledky)

### 4.1. Seznam odevzdaných pokusů v přiřazení
```http
GET /exam-assignments/{assignment_id}/attempts
```
- **Autentizace:** `require_teacher`
- **Návratová hodnota:** Seznam pokusů. Obsahuje nově pole **`student_name`** (přednostně e-mail studenta, případně login kód):
```json
{
  "assignment_id": 5,
  "attempt_count": 25,
  "attempts": [
    {
      "attempt_id": 12,
      "student_id": 3,
      "student_name": "jan.novak@skola.cz",
      "status": "SUBMITTED",
      "total_points": 14.0,
      "max_points": 20.0,
      "score_percent": 70.0,
      "started_at": "2026-05-10T08:05:00",
      "finished_at": "2026-05-10T08:35:00"
    }
  ]
}
```

---

### 4.2. Uložení manuálního hodnocení pokusu učitelem
```http
PUT /exam-assignments/{assignment_id}/attempts/{attempt_id}/grade
```
- **Autentizace:** `require_teacher`
- **Body:**
```json
{
  "total_points": 18.5,
  "teacher_note": "Dobře vypracováno, drobná nepřesnost u otázky č. 3.",
  "student_answers": {
    "10": {
      "answer": "Odpověď studenta...",
      "points": 4.5,
      "teacher_feedback": "Skvělá formulace"
    },
    "11": {
      "answer": 15,
      "points": 2.0
    }
  }
}
```
- **Důležité:**
  - `student_answers` je v DB uložen jako JSONB a backend spolehlivě propsal veškeré změny a body za jednotlivé otázky.
  - Stav pokusu se po uložení automaticky nastaví na **`"GRADED"`**.
  - `score_percent` se na backendu automaticky dopočítá z `total_points / max_points * 100`.

---

## 5. Na co si dát pozor na frontendu (Gotchas & Best Practices)

### ⚠️ 1. Klíče v `student_answers` jsou stringy
JSON serializuje klíče objektu vždy jako řetězce (`"10"`, nikoliv číslo `10`). Při vyhledávání odpovědi k otázce podle `question_id` (číslo) hledejte jako `student_answers[String(question.question_id)]` i `student_answers[question.question_id]`.

### ⚠️ 2. Bezpečnost a zobrazení správných odpovědí
- V `questions_snapshot` má student přístup k textům otázek a možnostem.
- U běžících testů (`STARTED`) frontend nesmí spoléhat na to, že `is_correct` je v snapshotu skryto – logiku správnosti vyhodnocuje výhradně backend při submitu / save.

### ⚠️ 3. Case & Whitespace Insensitivity u SHORT_ANSWER
Backend automaticky čistí odpovědi pomocí `.strip().lower()`. Není nutné na frontendu nutit uživatele psát malými písmeny, backend porovná `" Paříž  "` i `"paříž"` správně.

### ⚠️ 4. Oddělovač pro MATCHING (`|||`)
Při tvorbě nebo editaci otázek typu MATCHING skládejte páry pomocí `|||` (např. `left + "|||" + right`). Backend podporuje i explicitní pole `match_text`, ale `|||` v `text` je plně standardizovaný a zpětně kompatibilní formát.

### ⚠️ 5. Práce se stavem pokusu
- Pokud má pokus `status: "SUBMITTED"`, student by měl vidět informaci: *"Test byl odevzdán a čeká na hodnocení vyučujícím"*.
- Pokud má pokus `status: "GRADED"`, student může vidět výsledné body, procenta a slovní hodnocení učitele `teacher_note`.

### ⚠️ 6. SSE kanály pro živé sledování testu
Učitel může sledovat průběh testu v reálném čase přes Server-Sent Events na endpointu:
`GET /sse/teacher/assignments/{assignment_id}`.
Eventy, které backend posílá:
- `progress_update` – Student uložil další odpověď (obsahuje `attempt_id`, `student_id`, `answers_count`).
- `test_submitted` – Student dokončil a odevzdal test.
