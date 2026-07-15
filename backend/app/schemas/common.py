from typing import Optional, Any, List, Generic, TypeVar
from pydantic import BaseModel

T = TypeVar("T")


class BaseResponse(BaseModel):
    success: bool = True
    message: str = "Berhasil"
    data: Optional[Any] = None


class PaginatedResponse(BaseModel, Generic[T]):
    success: bool = True
    message: str = "Berhasil"
    data: List[T] = []
    total: int = 0
    page: int = 1
    per_page: int = 20
    total_pages: int = 0


class ErrorResponse(BaseModel):
    success: bool = False
    message: str
    detail: Optional[Any] = None
