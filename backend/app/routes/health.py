"""
Health check endpoint.
"""

from datetime import datetime, timezone
from fastapi import APIRouter, status

router = APIRouter()


@router.get(
    "/health",
    summary="Health check",
    status_code=status.HTTP_200_OK,
)
async def health_check():
    """Return service health status with uptime metadata."""
    return {
        "status": "healthy",
        "service": "AstroNova Book API",
        "version": "1.0.0",
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }
