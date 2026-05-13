"""LLM-generated quizzes + result analysis."""
import json
import uuid

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from app.core.security import current_user_id
from app.core.supabase import get_supabase_admin
from app.services.llm.orchestrator import AllProvidersFailed, chat_with_fallback

router = APIRouter()


_LANG_NAMES = {
    "english": "English",
    "russian": "Russian",
    "german": "German",
    "turkish": "Turkish",
    "math": "Math",
}


class GenerateRequest(BaseModel):
    subject: str = "english"
    level: str = "A2"
    count: int = 5
    topic: str | None = None


class Question(BaseModel):
    id: str
    question: str
    options: list[str]
    correct_index: int
    explanation: str


class GenerateResponse(BaseModel):
    quiz_id: str
    subject: str
    level: str
    questions: list[Question]


class Answer(BaseModel):
    question_id: str
    chosen_index: int


class SubmitRequest(BaseModel):
    quiz_id: str
    subject: str
    level: str
    questions: list[Question]
    answers: list[Answer]


class QuestionResult(BaseModel):
    question: str
    correct_answer: str
    user_answer: str
    correct: bool
    explanation: str


class SubmitResponse(BaseModel):
    score: int
    total: int
    percentage: int
    weak_topics: list[str]
    results: list[QuestionResult]


def _build_prompt(req: GenerateRequest) -> str:
    subj = _LANG_NAMES.get(req.subject.lower(), "English")
    topic = f", topic: {req.topic}" if req.topic else ""
    return (
        f"Generate exactly {req.count} CEFR {req.level} level {subj} multiple-choice questions"
        f"{topic}. Return ONLY valid JSON: "
        '{"questions":[{"question":"...","options":["A","B","C","D"],'
        '"correct_index":0,"explanation":"why in Uzbek"}, ...]}. '
        "Each question must have exactly 4 options. correct_index is 0-3. "
        "Mix grammar, vocabulary, and reading comprehension. "
        "For language subjects ask in target language; for Math ask in plain text."
    )


@router.post("/quiz/generate", response_model=GenerateResponse)
def generate(req: GenerateRequest) -> GenerateResponse:
    if not 1 <= req.count <= 20:
        raise HTTPException(status_code=400, detail="count must be 1..20")

    messages = [
        {"role": "system", "content": "You are a strict JSON-only quiz generator."},
        {"role": "user", "content": _build_prompt(req)},
    ]
    try:
        reply, _ = chat_with_fallback(messages)
    except AllProvidersFailed as e:
        raise HTTPException(status_code=503, detail=str(e)) from e

    text = reply.strip()
    if text.startswith("```"):
        text = text.split("```", 2)[1]
        if text.startswith("json"):
            text = text[4:]
        text = text.rsplit("```", 1)[0]
    try:
        data = json.loads(text)
    except json.JSONDecodeError as e:
        raise HTTPException(status_code=502, detail=f"LLM JSON parse error: {e}") from e

    qs: list[Question] = []
    for q in data.get("questions", []):
        opts = q.get("options", [])
        if len(opts) != 4:
            continue
        try:
            ci = int(q.get("correct_index", 0))
        except (TypeError, ValueError):
            ci = 0
        qs.append(
            Question(
                id=str(uuid.uuid4()),
                question=q.get("question", ""),
                options=opts,
                correct_index=max(0, min(3, ci)),
                explanation=q.get("explanation", ""),
            )
        )
    if not qs:
        raise HTTPException(status_code=502, detail="Failed to generate questions")

    return GenerateResponse(
        quiz_id=str(uuid.uuid4()),
        subject=req.subject,
        level=req.level,
        questions=qs,
    )


@router.post("/quiz/submit", response_model=SubmitResponse)
def submit(
    req: SubmitRequest,
    user_id: str | None = Depends(current_user_id),
) -> SubmitResponse:
    answer_by_id = {a.question_id: a.chosen_index for a in req.answers}
    results: list[QuestionResult] = []
    score = 0
    weak: list[str] = []
    for q in req.questions:
        chosen = answer_by_id.get(q.id, -1)
        is_correct = chosen == q.correct_index
        if is_correct:
            score += 1
        else:
            weak.append(q.question[:60])
        results.append(
            QuestionResult(
                question=q.question,
                correct_answer=q.options[q.correct_index]
                if 0 <= q.correct_index < len(q.options)
                else "",
                user_answer=q.options[chosen]
                if 0 <= chosen < len(q.options)
                else "—",
                correct=is_correct,
                explanation=q.explanation,
            )
        )

    total = len(req.questions)
    percentage = int(round(score / total * 100)) if total else 0

    # Persist if user is authenticated
    if user_id:
        client = get_supabase_admin()
        if client is not None:
            try:
                client.table("quiz_results").insert(
                    {
                        "user_id": user_id,
                        "subject": req.subject,
                        "level": req.level,
                        "score": score,
                        "total": total,
                        "percentage": percentage,
                        "weak_topics": weak,
                    }
                ).execute()
            except Exception:
                pass

    return SubmitResponse(
        score=score,
        total=total,
        percentage=percentage,
        weak_topics=weak[:5],
        results=results,
    )


@router.get("/quiz/history")
def history(
    user_id: str | None = Depends(current_user_id),
) -> dict:
    if not user_id:
        raise HTTPException(status_code=401, detail="Login required")
    client = get_supabase_admin()
    if client is None:
        raise HTTPException(status_code=503, detail="DB not configured")
    r = (
        client.table("quiz_results")
        .select("subject, level, score, total, percentage, weak_topics, created_at")
        .eq("user_id", user_id)
        .order("created_at", desc=True)
        .limit(50)
        .execute()
    )
    return {"items": r.data or []}
