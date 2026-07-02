"""
AstroNova API — FastAPI Application Entry Point
Manages a 'Book' entity with full CRUD operations in-memory.
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.routes.books import router as books_router
from app.routes.health import router as health_router

app = FastAPI(
    title="AstroNova Book API",
    description="REST API for managing books in-memory",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

# ─── CORS Middleware ──────────────────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ─── Register Routes ─────────────────────────────────────────
app.include_router(health_router, tags=["Health"])
app.include_router(books_router, prefix="/api/books", tags=["Books"])


@app.get("/", include_in_schema=False)
async def root():
    return {
        "service": "AstroNova Book API",
        "version": "1.0.0",
        "docs": "/docs",
    }
