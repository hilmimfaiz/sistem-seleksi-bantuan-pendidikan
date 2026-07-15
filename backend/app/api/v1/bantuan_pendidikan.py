from datetime import datetime
from typing import Optional
from fastapi import APIRouter, Depends, Query
from sqlmodel import Session, select, and_
from app.database import get_session
from app.schemas.bantuan_pendidikan import BantuanCreate, BantuanUpdate, BantuanResponse
from app.schemas.common import BaseResponse
from app.core.dependencies import get_current_user, require_admin
from app.core.exceptions import NotFoundException
from app.models.user import User
from app.models.bantuan_pendidikan import BantuanPendidikan, StatusBantuan

router = APIRouter(prefix="/bantuan", tags=["Bantuan Pendidikan"])


@router.get("", response_model=BaseResponse)
def list_bantuan(
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    status: Optional[str] = Query(None),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_session),
):
    """Daftar bantuan pendidikan yang tersedia."""
    query = select(BantuanPendidikan).where(BantuanPendidikan.deleted_at.is_(None))
    if status:
        query = query.where(BantuanPendidikan.status == status)
    query = query.order_by(BantuanPendidikan.created_at.desc())

    all_results = db.exec(query).all()
    total = len(all_results)
    offset = (page - 1) * per_page
    bantuan_list = db.exec(query.offset(offset).limit(per_page)).all()

    return BaseResponse(
        success=True,
        message="Berhasil",
        data={
            "items": [BantuanResponse.model_validate(b).model_dump() for b in bantuan_list],
            "total": total,
            "page": page,
            "per_page": per_page,
            "total_pages": (total + per_page - 1) // per_page,
        },
    )


@router.get("/{bantuan_id}", response_model=BaseResponse)
def get_bantuan(
    bantuan_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_session),
):
    """Detail bantuan pendidikan."""
    bantuan = db.exec(
        select(BantuanPendidikan).where(
            and_(BantuanPendidikan.id == bantuan_id, BantuanPendidikan.deleted_at.is_(None))
        )
    ).first()
    if not bantuan:
        raise NotFoundException("Bantuan tidak ditemukan")
    return BaseResponse(
        success=True,
        message="Berhasil",
        data=BantuanResponse.model_validate(bantuan).model_dump(),
    )


@router.post("", response_model=BaseResponse)
def create_bantuan(
    body: BantuanCreate,
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_session),
):
    """[Admin] Buat bantuan pendidikan baru."""
    bantuan = BantuanPendidikan(**body.model_dump())
    db.add(bantuan)
    db.commit()
    db.refresh(bantuan)
    return BaseResponse(
        success=True,
        message="Bantuan berhasil dibuat",
        data=BantuanResponse.model_validate(bantuan).model_dump(),
    )


@router.put("/{bantuan_id}", response_model=BaseResponse)
def update_bantuan(
    bantuan_id: str,
    body: BantuanUpdate,
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_session),
):
    """[Admin] Update bantuan pendidikan."""
    bantuan = db.exec(
        select(BantuanPendidikan).where(
            and_(BantuanPendidikan.id == bantuan_id, BantuanPendidikan.deleted_at.is_(None))
        )
    ).first()
    if not bantuan:
        raise NotFoundException("Bantuan tidak ditemukan")

    update_data = body.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(bantuan, key, value)
    bantuan.updated_at = datetime.utcnow()

    db.add(bantuan)
    db.commit()
    db.refresh(bantuan)
    return BaseResponse(
        success=True,
        message="Bantuan berhasil diperbarui",
        data=BantuanResponse.model_validate(bantuan).model_dump(),
    )


@router.delete("/{bantuan_id}", response_model=BaseResponse)
def delete_bantuan(
    bantuan_id: str,
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_session),
):
    """[Admin] Hapus bantuan pendidikan (soft delete)."""
    bantuan = db.exec(
        select(BantuanPendidikan).where(
            and_(BantuanPendidikan.id == bantuan_id, BantuanPendidikan.deleted_at.is_(None))
        )
    ).first()
    if not bantuan:
        raise NotFoundException("Bantuan tidak ditemukan")

    bantuan.deleted_at = datetime.utcnow()
    db.add(bantuan)
    db.commit()
    return BaseResponse(success=True, message="Bantuan berhasil dihapus")
