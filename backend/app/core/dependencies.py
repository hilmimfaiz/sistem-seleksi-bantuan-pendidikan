from typing import Optional
from fastapi import Depends, Header, Request
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlmodel import Session, select
from app.database import get_session
from app.core.security import verify_access_token
from app.core.exceptions import UnauthorizedException, ForbiddenException
from app.models.user import User, UserRole

security = HTTPBearer(auto_error=False)


def get_current_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(security),
    db: Session = Depends(get_session),
) -> User:
    """Dependency untuk mendapatkan current user dari JWT token."""
    if not credentials:
        raise UnauthorizedException("Token tidak ditemukan. Silakan login terlebih dahulu.")

    token = credentials.credentials
    payload = verify_access_token(token)

    if not payload:
        raise UnauthorizedException("Token tidak valid atau sudah expired. Silakan login kembali.")

    user_id = payload.get("sub")
    if not user_id:
        raise UnauthorizedException("Token tidak valid.")

    user = db.get(User, user_id)
    if not user:
        raise UnauthorizedException("Pengguna tidak ditemukan.")

    if not user.is_active:
        raise UnauthorizedException("Akun Anda tidak aktif. Hubungi administrator.")

    if user.deleted_at is not None:
        raise UnauthorizedException("Akun Anda telah dihapus.")

    return user


def get_current_active_user(current_user: User = Depends(get_current_user)) -> User:
    """Dependency untuk user aktif."""
    return current_user


def require_admin(current_user: User = Depends(get_current_user)) -> User:
    """Dependency yang hanya mengizinkan ADMIN."""
    if current_user.role != UserRole.ADMIN:
        raise ForbiddenException("Fitur ini hanya tersedia untuk Admin.")
    return current_user


def require_mahasiswa(current_user: User = Depends(get_current_user)) -> User:
    """Dependency yang hanya mengizinkan MAHASISWA."""
    if current_user.role != UserRole.MAHASISWA:
        raise ForbiddenException("Fitur ini hanya tersedia untuk Mahasiswa.")
    return current_user


def get_client_ip(request: Request) -> str:
    """Mendapatkan IP address client."""
    forwarded = request.headers.get("X-Forwarded-For")
    if forwarded:
        return forwarded.split(",")[0].strip()
    return request.client.host if request.client else "unknown"
