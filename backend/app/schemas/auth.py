from pydantic import BaseModel, EmailStr, field_validator
import re


class LoginRequest(BaseModel):
    email: EmailStr
    password: str

    @field_validator("password")
    @classmethod
    def password_not_empty(cls, v):
        if not v or len(v.strip()) == 0:
            raise ValueError("Password tidak boleh kosong")
        return v


class RefreshTokenRequest(BaseModel):
    refresh_token: str


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user_id: str
    email: str
    role: str


class UserResponse(BaseModel):
    id: str
    email: str
    role: str
    is_active: bool
    created_at: str

    class Config:
        from_attributes = True
