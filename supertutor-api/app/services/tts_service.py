import edge_tts


DEFAULT_VOICES = {
    "en": "en-US-AriaNeural",
    "uz": "uz-UZ-MadinaNeural",
    "ru": "ru-RU-SvetlanaNeural",
    "de": "de-DE-KatjaNeural",
    "tr": "tr-TR-EmelNeural",
}

# Curated, fast-to-load voice catalog per language.
# Each entry: (voice_id, display_label, gender)
VOICE_CATALOG: dict[str, list[tuple[str, str, str]]] = {
    "en": [
        ("en-US-AriaNeural", "Aria — AQSH ayol", "F"),
        ("en-US-JennyNeural", "Jenny — AQSH ayol", "F"),
        ("en-US-GuyNeural", "Guy — AQSH erkak", "M"),
        ("en-US-DavisNeural", "Davis — AQSH erkak", "M"),
        ("en-GB-SoniaNeural", "Sonia — Britan ayol", "F"),
        ("en-GB-RyanNeural", "Ryan — Britan erkak", "M"),
    ],
    "uz": [
        ("uz-UZ-MadinaNeural", "Madina — O‘zbek ayol", "F"),
        ("uz-UZ-SardorNeural", "Sardor — O‘zbek erkak", "M"),
    ],
    "ru": [
        ("ru-RU-SvetlanaNeural", "Svetlana — Rus ayol", "F"),
        ("ru-RU-DmitryNeural", "Dmitry — Rus erkak", "M"),
    ],
    "de": [
        ("de-DE-KatjaNeural", "Katja — Nemis ayol", "F"),
        ("de-DE-ConradNeural", "Conrad — Nemis erkak", "M"),
    ],
    "tr": [
        ("tr-TR-EmelNeural", "Emel — Turk ayol", "F"),
        ("tr-TR-AhmetNeural", "Ahmet — Turk erkak", "M"),
    ],
}


def list_voices(language: str | None = None) -> dict:
    """Return curated voices, optionally filtered by language code."""
    if language and language in VOICE_CATALOG:
        items = VOICE_CATALOG[language]
        return {
            "items": [
                {"id": v[0], "label": v[1], "gender": v[2], "language": language}
                for v in items
            ]
        }
    out: list[dict] = []
    for lang, items in VOICE_CATALOG.items():
        for v in items:
            out.append(
                {"id": v[0], "label": v[1], "gender": v[2], "language": lang}
            )
    return {"items": out}


async def synthesize(text: str, language: str = "en", voice: str | None = None) -> bytes:
    voice = voice or DEFAULT_VOICES.get(language, "en-US-AriaNeural")
    communicate = edge_tts.Communicate(text=text, voice=voice)
    audio = bytearray()
    async for chunk in communicate.stream():
        if chunk["type"] == "audio":
            audio.extend(chunk["data"])
    return bytes(audio)
