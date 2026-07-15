from datetime import datetime
from typing import Optional
from fastapi import APIRouter, Depends, Query
from sqlmodel import Session, select, and_
from app.database import get_session
from app.schemas.data_finansial import DataFinansialCreate, DataFinansialUpdate, DataFinansialResponse
from app.schemas.common import BaseResponse
from app.core.dependencies import get_current_user, require_admin, require_mahasiswa
from app.core.exceptions import NotFoundException, ConflictException
from app.models.user import User
from app.models.mahasiswa import Mahasiswa
from app.models.data_finansial import DataFinansial

router = APIRouter(prefix="/finansial", tags=["Data Finansial"])


def _get_mahasiswa_by_user(user_id: str, db: Session) -> Mahasiswa:
    """Helper: ambil mahasiswa dari user_id."""
    mahasiswa = db.exec(
        select(Mahasiswa).where(
            and_(Mahasiswa.user_id == user_id, Mahasiswa.deleted_at.is_(None))
        )
    ).first()
    if not mahasiswa:
        raise NotFoundException(
            "Profil mahasiswa belum lengkap. Lengkapi data mahasiswa terlebih dahulu."
        )
    return mahasiswa


@router.get("/me", response_model=BaseResponse)
def get_my_finansial(
    current_user: User = Depends(require_mahasiswa),
    db: Session = Depends(get_session),
):
    """Ambil data finansial mahasiswa yang sedang login."""
    mahasiswa = _get_mahasiswa_by_user(current_user.id, db)
    finansial = db.exec(
        select(DataFinansial).where(
            and_(
                DataFinansial.mahasiswa_id == mahasiswa.id,
                DataFinansial.deleted_at.is_(None),
            )
        )
    ).first()
    if not finansial:
        return BaseResponse(success=True, message="Data finansial belum ada", data=None)
    return BaseResponse(
        success=True,
        message="Berhasil",
        data=DataFinansialResponse.model_validate(finansial).model_dump(),
    )


@router.post("", response_model=BaseResponse)
def create_finansial(
    body: DataFinansialCreate,
    current_user: User = Depends(require_mahasiswa),
    db: Session = Depends(get_session),
):
    """Buat data finansial mahasiswa."""
    mahasiswa = _get_mahasiswa_by_user(current_user.id, db)

    existing = db.exec(
        select(DataFinansial).where(
            and_(
                DataFinansial.mahasiswa_id == mahasiswa.id,
                DataFinansial.deleted_at.is_(None),
            )
        )
    ).first()
    if existing:
        raise ConflictException("Data finansial sudah ada. Gunakan PUT untuk memperbarui.")

    finansial = DataFinansial(mahasiswa_id=mahasiswa.id, **body.model_dump())
    db.add(finansial)
    db.commit()
    db.refresh(finansial)
    return BaseResponse(
        success=True,
        message="Data finansial berhasil disimpan",
        data=DataFinansialResponse.model_validate(finansial).model_dump(),
    )


@router.put("/me", response_model=BaseResponse)
def update_finansial(
    body: DataFinansialUpdate,
    current_user: User = Depends(require_mahasiswa),
    db: Session = Depends(get_session),
):
    """Update data finansial mahasiswa."""
    mahasiswa = _get_mahasiswa_by_user(current_user.id, db)
    finansial = db.exec(
        select(DataFinansial).where(
            and_(
                DataFinansial.mahasiswa_id == mahasiswa.id,
                DataFinansial.deleted_at.is_(None),
            )
        )
    ).first()
    if not finansial:
        raise NotFoundException("Data finansial tidak ditemukan.")

    update_data = body.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(finansial, key, value)
    finansial.updated_at = datetime.utcnow()

    db.add(finansial)
    db.commit()
    db.refresh(finansial)
    return BaseResponse(
        success=True,
        message="Data finansial berhasil diperbarui",
        data=DataFinansialResponse.model_validate(finansial).model_dump(),
    )


# === ADMIN ===

@router.get("", response_model=BaseResponse)
def list_finansial(
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    search: Optional[str] = Query(None),
    program_studi: Optional[str] = Query(None),
    angkatan: Optional[int] = Query(None),
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_session),
):
    """[Admin] Daftar semua data finansial."""
    query = select(DataFinansial).join(Mahasiswa, DataFinansial.mahasiswa_id == Mahasiswa.id).where(DataFinansial.deleted_at.is_(None))
    
    if search:
        query = query.where(
            Mahasiswa.nama.contains(search) | Mahasiswa.nim.contains(search)
        )
    if program_studi:
        query = query.where(Mahasiswa.program_studi == program_studi)
    if angkatan:
        query = query.where(Mahasiswa.angkatan == angkatan)

    query = query.order_by(DataFinansial.created_at.desc())

    all_results = db.exec(query).all()
    total = len(all_results)
    offset = (page - 1) * per_page
    finansial_list = db.exec(query.offset(offset).limit(per_page)).all()

    result_data = []
    for f in finansial_list:
        mahasiswa = db.get(Mahasiswa, f.mahasiswa_id)
        item = DataFinansialResponse.model_validate(f).model_dump()
        item["mahasiswa_nama"] = mahasiswa.nama if mahasiswa else None
        item["mahasiswa_nim"] = mahasiswa.nim if mahasiswa else None
        result_data.append(item)

    return BaseResponse(
        success=True,
        message="Berhasil",
        data={
            "items": result_data,
            "total": total,
            "page": page,
            "per_page": per_page,
            "total_pages": (total + per_page - 1) // per_page,
        },
    )
