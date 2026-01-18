from fastapi import FastAPI
import os

app = FastAPI()

@app.get("/")
def read_root():
    return {
        "message": "Ahoj z Dockeru!",
        "db_url": os.getenv("DATABASE_URL") # Jen pro kontrolu, v produkci nevypisovat!
    }