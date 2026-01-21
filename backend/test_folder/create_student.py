import sys
import os

# Přidání parent adresáře do PATH, aby fungovaly importy
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from database import SessionLocal
from models import Student
from auth import get_password_hash

def create_student(login_code: str, password: str, group_id: int = 1, active: bool = True):
    """
    Vytvoří nového studenta v databázi
    
    Args:
        login_code: Unikátní přihlašovací kód studenta
        password: Heslo v plain textu (automaticky se zahashuje)
        group_id: ID skupiny, do které student patří (default 1)
        active: Zda je student aktivní (default True)
    """
    db = SessionLocal()
    try:
        # Zahashování hesla pomocí stejné funkce jako při autentizaci
        password_hash = get_password_hash(password)
        
        # Vytvoření nového studenta
        new_student = Student(
            login_code=login_code,
            password_hash=password_hash,
            group_id=group_id,
            active_flag=active
        )
        
        db.add(new_student)
        db.commit()
        db.refresh(new_student)
        
        print(f"✅ Student úspěšně vytvořen!")
        print(f"   ID: {new_student.student_id}")
        print(f"   Login code: {new_student.login_code}")
        print(f"   Group ID: {new_student.group_id}")
        print(f"   Aktivní: {new_student.active_flag}")
        
        return new_student
        
    except Exception as e:
        db.rollback()
        print(f"❌ Chyba při vytváření studenta: {e}")
        return None
    finally:
        db.close()

if __name__ == "__main__":
    # TADY ZMĚŇ USERNAME A HESLO
    login_code = "3b_01_novak"
    password = "heslo123"
    group_id = 1  # Změň podle potřeby
    
    create_student(login_code, password, group_id)
