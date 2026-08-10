# BP Jirotka Heger – Školní testovací systém

Tento repozitář obsahuje kompletní systém pro tvorbu, zadávání a hodnocení školních testů. Projekt se skládá z **FastAPI backendu** (Python), **PostgreSQL databáze** a **Flutter frontendu** aplikace pro web. 

---

## 🚀 Jak lokálně spustit projekt

### 1. Požadavky
Ujistěte se, že máte na svém počítači nainstalováno:
- **Git** (pro stažení projektu)
- **Docker** a **Docker Compose** (např. Docker Desktop)

### 2. Stažení projektu (Clone)
Otevřete terminál a stáhněte si repozitář z GitHubu:
```bash
git clone https://github.com/Jirotkins/BP-Jirotka-Heger.git
cd BP-Jirotka-Heger
```

### 3. Spuštění přes Docker
V kořenové složce projektu spusťte:
```bash
docker-compose up --build -d
```
*Poznámka: První spuštění může trvat pár minut, protože se stahují docker image a sestavuje se Flutter web.*

---

## 🌐 Přístup k běžícím službám

Jakmile proces doběhne a kontejnery běží, aplikace je dostupná na těchto lokálních adresách:

| Služba | URL adresa |
|--------|------------|
| **Klientská aplikace (Frontend)** | [http://localhost](http://localhost) |
| **Backend API (Swagger Docs)** | [http://localhost:8000/docs](http://localhost:8000/docs) |
| **Správce Databáze (DbGate)** | [http://localhost:3000](http://localhost:3000) |

---

## 🔑 Testovací účty (Mock data)

Při prvním spuštění databáze se automaticky vytvořila úvodní testovací data (učitel, studenti, třídy a ukázkové testy), abyste si mohli aplikaci ihned vyzkoušet bez nutnosti registrace.

**Přihlášení jako UČITEL:**
*   **Email:** `karel.novak@skola.cz`
*   **Heslo:** `karelnovak123`

**Přihlášení jako ŽÁK (Student):**
*   **Login kód:** `mat1_01`
*   **Heslo:** `okdJGp6e`

---

## 🛑 Zastavení projektu
Pokud chcete běžící aplikaci vypnout, stačí ve stejné složce spustit:
```bash
docker-compose down
```
*Pokud byste chtěli projekt spustit úplně čistý (smazat i uložená data v databázi), použijte `docker-compose down -v`.*
