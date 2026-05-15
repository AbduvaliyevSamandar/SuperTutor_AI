"""User feedback / bug reports."""
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field

from app.core.security import current_user_id
from app.core.supabase import get_supabase_admin

router = APIRouter()


class FeedbackRequest(BaseModel):
    category: str = Field(default="general")  # "bug" | "feature" | "general"
    message: str = Field(min_length=5, max_length=2000)
    contact: str | None = None  # optional email / telegram


@router.post("/feedback")
def submit(
    req: FeedbackRequest,
    user_id: str | None = Depends(current_user_id),
) -> dict:
    client = get_supabase_admin()
    if client is None:
        raise HTTPException(status_code=503, detail="DB not configured")
    try:
        client.table("feedback").insert({
            "user_id": user_id,
            "category": req.category,
            "message": req.message,
            "contact": req.contact,
        }).execute()
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"DB error: {e}") from e
    return {"ok": True}
