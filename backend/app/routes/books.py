"""
Book CRUD routes — GET, POST, PATCH, DELETE.
"""

import uuid
from typing import List

from fastapi import APIRouter, HTTPException, status

from app.models import BookCreate, BookUpdate, BookResponse
from app.store import books_db

router = APIRouter()


@router.get(
    "",
    response_model=List[BookResponse],
    summary="List all books",
    status_code=status.HTTP_200_OK,
)
async def get_books():
    """Return every book in the store."""
    return list(books_db.values())


@router.get(
    "/{book_id}",
    response_model=BookResponse,
    summary="Get a single book by ID",
    status_code=status.HTTP_200_OK,
)
async def get_book(book_id: str):
    """Return a single book or 404."""
    book = books_db.get(book_id)
    if not book:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Book with id '{book_id}' not found",
        )
    return book


@router.post(
    "",
    response_model=BookResponse,
    summary="Create a new book",
    status_code=status.HTTP_201_CREATED,
)
async def create_book(payload: BookCreate):
    """Create a book with an auto-generated UUID."""
    book_id = str(uuid.uuid4())
    book = {"id": book_id, **payload.model_dump()}
    books_db[book_id] = book
    return book


@router.patch(
    "/{book_id}",
    response_model=BookResponse,
    summary="Partially update a book",
    status_code=status.HTTP_200_OK,
)
async def update_book(book_id: str, payload: BookUpdate):
    """Update only the fields provided in the request body."""
    book = books_db.get(book_id)
    if not book:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Book with id '{book_id}' not found",
        )

    update_data = payload.model_dump(exclude_unset=True)
    if not update_data:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No fields provided for update",
        )

    book.update(update_data)
    books_db[book_id] = book
    return book


@router.delete(
    "/{book_id}",
    summary="Delete a book",
    status_code=status.HTTP_204_NO_CONTENT,
)
async def delete_book(book_id: str):
    """Remove a book from the store or return 404."""
    if book_id not in books_db:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Book with id '{book_id}' not found",
        )
    del books_db[book_id]
    return None
