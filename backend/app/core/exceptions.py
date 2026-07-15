from fastapi import HTTPException, status


class AppException(HTTPException):
    """Base exception untuk aplikasi."""
    pass


class UnauthorizedException(AppException):
    def __init__(self, detail: str = "Tidak memiliki akses"):
        super().__init__(status_code=status.HTTP_401_UNAUTHORIZED, detail=detail)


class ForbiddenException(AppException):
    def __init__(self, detail: str = "Akses ditolak"):
        super().__init__(status_code=status.HTTP_403_FORBIDDEN, detail=detail)


class NotFoundException(AppException):
    def __init__(self, detail: str = "Data tidak ditemukan"):
        super().__init__(status_code=status.HTTP_404_NOT_FOUND, detail=detail)


class ConflictException(AppException):
    def __init__(self, detail: str = "Data sudah ada"):
        super().__init__(status_code=status.HTTP_409_CONFLICT, detail=detail)


class BadRequestException(AppException):
    def __init__(self, detail: str = "Permintaan tidak valid"):
        super().__init__(status_code=status.HTTP_400_BAD_REQUEST, detail=detail)


class ValidationException(AppException):
    def __init__(self, detail: str = "Data tidak valid"):
        super().__init__(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=detail)


class ServerErrorException(AppException):
    def __init__(self, detail: str = "Terjadi kesalahan pada server"):
        super().__init__(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=detail)
