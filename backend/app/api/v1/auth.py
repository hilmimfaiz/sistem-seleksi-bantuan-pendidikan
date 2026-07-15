from fastapi import APIRouter, Depends, Request
from sqlmodel import Session
from app.database import get_session
from app.schemas.auth import LoginRequest, RefreshTokenRequest, TokenResponse
from app.schemas.common import BaseResponse
from app.services.auth_service import AuthService
from app.core.dependencies import get_current_user, get_client_ip
from app.models.user import User
from app.core.security import hash_password, verify_password
from app.core.exceptions import BadRequestException
from app.config import settings
from app.services.notification_service import NotificationService
from app.models.notification import NotificationType
from fastapi import UploadFile, File
import os
import uuid
from datetime import datetime
from pydantic import BaseModel

router = APIRouter(prefix="/auth", tags=["Authentication"])

class ChangePasswordRequest(BaseModel):
    old_password: str
    new_password: str

class ChangeNameRequest(BaseModel):
    nama: str



@router.post("/login", response_model=BaseResponse)
def login(
    request: Request,
    body: LoginRequest,
    db: Session = Depends(get_session),
):
    """Login dengan email dan password."""
    service = AuthService(db)
    access_token, refresh_token, user = service.login(body.email, body.password)
    return BaseResponse(
        success=True,
        message="Login berhasil",
        data=TokenResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            token_type="bearer",
            user_id=user.id,
            email=user.email,
            role=user.role,
        ).model_dump(),
    )


@router.post("/logout", response_model=BaseResponse)
def logout(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_session),
):
    """Logout dan invalidasi token."""
    service = AuthService(db)
    service.logout(current_user)
    return BaseResponse(success=True, message="Logout berhasil")


@router.post("/refresh", response_model=BaseResponse)
def refresh_token(
    body: RefreshTokenRequest,
    db: Session = Depends(get_session),
):
    """Generate access token baru menggunakan refresh token."""
    service = AuthService(db)
    access_token, new_refresh_token = service.refresh_token(body.refresh_token)
    return BaseResponse(
        success=True,
        message="Token diperbarui",
        data={
            "access_token": access_token,
            "refresh_token": new_refresh_token,
            "token_type": "bearer",
        },
    )


@router.get("/me", response_model=BaseResponse)
def get_me(current_user: User = Depends(get_current_user)):
    """Ambil data user yang sedang login."""
    return BaseResponse(
        success=True,
        message="Berhasil",
        data={
            "id": current_user.id,
            "email": current_user.email,
            "role": current_user.role,
            "is_active": current_user.is_active,
            "foto_profil": current_user.foto_profil,
            "nama": current_user.nama,
            "created_at": current_user.created_at.isoformat(),
        },
    )

@router.post("/profile/photo", response_model=BaseResponse)
async def upload_profile_photo(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_session),
):
    """Upload foto profil."""
    ext = file.filename.rsplit(".", 1)[-1].lower() if "." in file.filename else ""
    if ext not in settings.allowed_extensions_list:
        raise BadRequestException(f"Tipe file '{ext}' tidak diizinkan.")

    upload_folder = os.path.join(settings.UPLOAD_DIR, "profiles", current_user.id)
    os.makedirs(upload_folder, exist_ok=True)

    unique_name = f"{uuid.uuid4()}_{file.filename}"
    file_path = os.path.join(upload_folder, unique_name)

    contents = await file.read()
    with open(file_path, "wb") as f:
        f.write(contents)

    # Use forward slashes for URLs
    file_path_url = file_path.replace("\\", "/")

    current_user.foto_profil = file_path_url
    current_user.updated_at = datetime.utcnow()
    db.add(current_user)
    db.commit()

    # Send Notification
    notif_service = NotificationService(db)
    notif_service.create_notification(
        user_id=current_user.id,
        title="Profil Diperbarui",
        body="Foto profil Anda berhasil diubah.",
        notif_type=NotificationType.GENERAL,
        reference_id=current_user.id,
    )

    return BaseResponse(success=True, message="Foto profil berhasil diperbarui", data={"foto_profil": file_path_url})

@router.post("/profile/password", response_model=BaseResponse)
def change_password(
    body: ChangePasswordRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_session),
):
    """Ubah password user."""
    if not verify_password(body.old_password, current_user.password_hash):
        raise BadRequestException("Password lama tidak sesuai")

    current_user.password_hash = hash_password(body.new_password)
    current_user.updated_at = datetime.utcnow()
    db.add(current_user)
    db.commit()

    return BaseResponse(success=True, message="Password berhasil diubah")

@router.post("/profile/name", response_model=BaseResponse)
def change_name(
    body: ChangeNameRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_session),
):
    """Ubah nama profil user."""
    current_user.nama = body.nama
    current_user.updated_at = datetime.utcnow()
    db.add(current_user)
    db.commit()

    # Send Notification
    notif_service = NotificationService(db)
    notif_service.create_notification(
        user_id=current_user.id,
        title="Profil Diperbarui",
        body=f"Nama Anda berhasil diubah menjadi {body.nama}",
        notif_type=NotificationType.GENERAL,
        reference_id=current_user.id,
    )

    return BaseResponse(success=True, message="Nama profil berhasil diubah", data={"nama": body.nama})
