from pydantic import BaseModel, field_validator


class RegisterRequest(BaseModel):
    phone: str
    password: str
    name: str
    role: str = "elder"

    @field_validator("role")
    @classmethod
    def validate_role(cls, v: str) -> str:
        if v not in {"elder", "family"}:
            raise ValueError("role must be 'elder' or 'family'")
        return v

    @field_validator("phone")
    @classmethod
    def validate_phone(cls, v: str) -> str:
        v = v.strip()
        if not v:
            raise ValueError("phone cannot be empty")
        return v


class LoginRequest(BaseModel):
    phone: str
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user_id: str
    role: str
