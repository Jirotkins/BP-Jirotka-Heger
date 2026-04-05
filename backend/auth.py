from datetime import datetime, timedelta
from typing import Optional
from jose import JWTError, jwt
from passlib.context import CryptContext
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session

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

# HTTP Bearer scheme pro JWT extrakci
security = HTTPBearer()

def verify_access_token(token: str) -> dict:
    """Dekóduje a ověří JWT token"""
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Nelze ověřit přihlašovací údaje",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id: str = payload.get("sub")
        user_type: str = payload.get("type")
        if user_id is None or user_type is None:
            raise credentials_exception
        return {"user_id": int(user_id), "user_type": user_type}
    except JWTError:
        raise credentials_exception

def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    """Získá aktuálního přihlášeného uživatele z tokenu"""
    return verify_access_token(credentials.credentials)

def require_teacher(current_user: dict = Depends(get_current_user)):
    """Vyžaduje, aby uživatel byl učitel"""
    if current_user["user_type"] != "teacher":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Přístup povolen pouze pro učitele"
        )
    return current_user

def require_student(current_user: dict = Depends(get_current_user)):
    """Vyžaduje, aby uživatel byl student"""
    if current_user["user_type"] != "student":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Přístup povolen pouze pro studenty"
        )
    return current_user

