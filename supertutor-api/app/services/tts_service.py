import edge_tts


DEFAULT_VOICES = {
    "en": "en-US-AriaNeural",
    "uz": "uz-UZ-MadinaNeural",
    "ru": "ru-RU-SvetlanaNeural",
    "de": "de-DE-KatjaNeural",
    "tr": "tr-TR-EmelNeural",
}


async def synthesize(text: str, language: str = "en", voice: str | None = None) -> bytes:
    voice = voice or DEFAULT_VOICES.get(language, "en-US-AriaNeural")
    communicate = edge_tts.Communicate(text=text, voice=voice)
    audio = bytearray()
    async for chunk in communicate.stream():
        if chunk["type"] == "audio":
            audio.extend(chunk["data"])
    return bytes(audio)
