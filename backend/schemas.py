from pydantic import BaseModel, field_validator


class LoginRequest(BaseModel):
    username: str  # email pro učitele, login_code pro studenta
    password: str
    is_teacher: bool = True  # True pro učitele, False pro studenta


class CreateStudentRequest(BaseModel):
    login_code: str
    password: str
    group_id: int = 1
    
    @field_validator('password')
    @classmethod
    def validate_password_length(cls, v):
        if len(v.encode('utf-8')) > 72:
            raise ValueError("Heslo může mít maximálně 72 bytů")
        return v


class CreateTeacherRequest(BaseModel):
    name: str
    email: str
    password: str
    
    @field_validator('password')
    @classmethod
    def validate_password_length(cls, v):
        if len(v.encode('utf-8')) > 72:
            raise ValueError("Heslo může mít maximálně 72 bytů")
        return v


class Token(BaseModel):
    access_token: str
    token_type: str
    user_type: str
    user_id: int


class CreateGroupRequest(BaseModel):
    name: str
    description: str = None
