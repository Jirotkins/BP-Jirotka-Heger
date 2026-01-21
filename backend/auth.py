from datetime import datetime, timedelta
from typing import Optional
from jose import JWTError, jwt
from passlib.context import CryptContext

# Nastavení pro hashování hesel
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# Nastavení pro JWT
SECRET_KEY = "tvuj-tajny-klic-zmen-ho-v-produkci"  # V produkci dej do .env!
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24  # 24 hodin

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Ověří, zda heslo odpovídá hashi"""
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password: str) -> str:
    """Vytvoří hash z hesla"""
    # Zkontroluje max 72 bytů (bcrypt limit)
    password_bytes = password.encode('utf-8')
    if len(password_bytes) > 72:
        raise ValueError(f"Heslo je příliš dlouhé ({len(password_bytes)} bytů). Maximum je 72 bytů.")
    return pwd_context.hash(password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    """Vytvoří JWT token"""
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt
