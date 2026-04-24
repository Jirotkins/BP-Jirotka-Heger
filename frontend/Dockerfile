# FÁZE 1: Stažení Flutteru a sestavení aplikace
FROM debian:latest AS build-env

# Instalace potřebných nástrojů pro stažení Flutteru
RUN apt-get update && apt-get install -y curl git unzip xz-utils

# Stažení Flutteru (verze stable)
RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Povolení pro git, aby si nestěžoval na práva v Dockeru
RUN git config --global --add safe.directory /usr/local/flutter

# Nastavení a aktualizace Flutteru
RUN flutter channel stable
RUN flutter upgrade
RUN flutter config --enable-web

# Vytvoření pracovní složky a zkopírování našeho kódu
RUN mkdir /app
WORKDIR /app
COPY . .

# Instalace balíčků a sestavení produkční webové verze
RUN flutter pub get
RUN flutter build web --release

# FÁZE 2: Nasazení na lehký webový server Nginx
FROM nginx:alpine

# Zkopíruje zkompilované soubory z fáze 1 přímo do Nginxu
COPY --from=build-env /app/build/web /usr/share/nginx/html

# Aplikace poběží na portu 80
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]