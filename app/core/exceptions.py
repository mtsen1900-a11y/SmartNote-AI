from fastapi import HTTPException, status

class AppException(HTTPException):
    def __init__(self, status_code: int, detail: str):
        super().__init__(status_code=status_code, detail=detail)

class NotFoundException(AppException):
    def __init__(self, detail: str = "Tài nguyên không tồn tại"):
        super().__init__(status_code=status.HTTP_404_NOT_FOUND, detail=detail)

class ConflictException(AppException):
    def __init__(self, detail: str = "Xung đột phiên bản dữ liệu"):
        super().__init__(status_code=status.HTTP_409_CONFLICT, detail=detail)

class AIServiceException(AppException):
    def __init__(self, detail: str = "Dịch vụ AI cục bộ chưa sẵn sàng"):
        super().__init__(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail=detail)
