from app.services.prompts import system_prompt_for


def test_known_subjects():
    assert "English tutor" in system_prompt_for("english")
    assert "Russian tutor" in system_prompt_for("russian")
    assert "German tutor" in system_prompt_for("german")
    assert "Turkish tutor" in system_prompt_for("turkish")
    assert "math tutor" in system_prompt_for("math").lower()


def test_uzbek_alias_for_math():
    assert system_prompt_for("matematika") == system_prompt_for("math")


def test_unknown_subject_falls_back_to_english():
    assert system_prompt_for("klingon") == system_prompt_for("english")


def test_empty_subject_falls_back_to_english():
    assert system_prompt_for("") == system_prompt_for("english")
    assert system_prompt_for(None) == system_prompt_for("english")  # type: ignore[arg-type]
