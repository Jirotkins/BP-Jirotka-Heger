from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
import os

# Načtení URL databáze z proměnné prostředí nebo default (pro Docker)
# Formát: postgresql://uzivatel:heslo@host:port/nazev_db
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://uzivatel:tajneheslo@localhost:5432/mojedb")

# Vytvoření "motoru" pro komunikaci s DB
engine = create_engine(DATABASE_URL, echo=False)  # echo=True vypisuje SQL dotazy do konzole (dobré pro debug)

# Továrna na session (relace), přes kterou budeš posílat dotazy
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Základní třída, ze které budou dědit všechny modely
Base = declarative_base()

# Pomocná funkce pro získání DB session (např. pro FastAPI dependency)
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()