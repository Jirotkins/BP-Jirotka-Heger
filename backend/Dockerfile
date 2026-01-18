# Použijeme lehkou verzi Pythonu
FROM python:3.11-slim

# Nastavíme pracovní adresář uvnitř kontejneru
WORKDIR /app

# Nejprve zkopírujeme requirements (kvůli cacheování Dockeru)
COPY requirements.txt .

# Nainstalujeme závislosti
RUN pip install --no-cache-dir -r requirements.txt

# Zkopírujeme zbytek aplikace
COPY . .