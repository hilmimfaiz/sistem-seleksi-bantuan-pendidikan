from datetime import datetime
from typing import Optional, Tuple
from sqlmodel import Session, select
from app.models.user import User
from app.models.activity_log import ActivityLog
from app.core.security import (
    hash_password,
    verify_password,
    create_access_token,
    create_refresh_token,
    verify_refresh_token,
)
from app.core.exceptions import (
    UnauthorizedException,
    NotFoundException,
    BadRequestException,
)


class AuthService:
    def __init__(self, db: Session):
        self.db = db

    def login(self, email: str, password: str) -> Tuple[str, str, User]:
        """Login user dan return access + refresh token."""
        user = self.db.exec(select(User).where(User.email == email)).first()

        if not user:
            raise UnauthorizedException("Email atau password salah.")

        if not verify_password(password, user.password_hash):
            raise UnauthorizedException("Email atau password salah.")

        if not user.is_active:
            raise UnauthorizedException("Akun Anda tidak aktif. Hubungi administrator.")

        if user.deleted_at is not None:
            raise UnauthorizedException("Akun Anda telah dihapus.")

        token_data = {"sub": user.id, "email": user.email, "role": user.role}
        access_token = create_access_token(token_data)
        refresh_token = create_refresh_token(token_data)

        # Simpan refresh token ke database
        user.refresh_token = refresh_token
        user.updated_at = datetime.utcnow()
        self.db.add(user)
        self.db.commit()
        self.db.refresh(user)

        # Log aktivitas
        self._log_activity(user.id, "LOGIN", "users", user.id)

        return access_token, refresh_token, user

    def logout(self, user: User) -> None:
        """Logout user dengan menghapus refresh token."""
        user.refresh_token = None
        user.updated_at = datetime.utcnow()
        self.db.add(user)
        self.db.commit()
        self._log_activity(user.id, "LOGOUT", "users", user.id)

    def refresh_token(self, token: str) -> Tuple[str, str]:
        """Generate access token baru menggunakan refresh token."""
        payload = verify_refresh_token(token)
        if not payload:
            raise UnauthorizedException("Refresh token tidak valid atau sudah expired.")

        user_id = payload.get("sub")
        user = self.db.get(User, user_id)

        if not user:
            raise UnauthorizedException("Pengguna tidak ditemukan.")

        if user.refresh_token != token:
            raise UnauthorizedException("Refresh token tidak valid.")

        if not user.is_active or user.deleted_at is not None:
            raise UnauthorizedException("Akun tidak aktif.")

        token_data = {"sub": user.id, "email": user.email, "role": user.role}
        new_access_token = create_access_token(token_data)
        new_refresh_token = create_refresh_token(token_data)

        user.refresh_token = new_refresh_token
        user.updated_at = datetime.utcnow()
        self.db.add(user)
        self.db.commit()

        return new_access_token, new_refresh_token

    def _log_activity(
        self,
        user_id: str,
        action: str,
        entity_type: Optional[str] = None,
        entity_id: Optional[str] = None,
        detail: Optional[dict] = None,
        ip_address: Optional[str] = None,
    ):
        """Simpan activity log."""
        log = ActivityLog(
            user_id=user_id,
            action=action,
            entity_type=entity_type,
            entity_id=entity_id,
            detail=detail,
            ip_address=ip_address,
        )
        self.db.add(log)
        self.db.commit()
