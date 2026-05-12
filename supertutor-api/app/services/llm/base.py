from abc import ABC, abstractmethod


class LLMProvider(ABC):
    name: str = "base"

    @abstractmethod
    def is_configured(self) -> bool: ...

    @abstractmethod
    def chat(self, messages: list[dict]) -> str: ...


class STTProvider(ABC):
    name: str = "base"

    @abstractmethod
    def is_configured(self) -> bool: ...

    @abstractmethod
    def transcribe(
        self, audio: bytes, filename: str = "audio.webm", language: str | None = None
    ) -> str: ...
