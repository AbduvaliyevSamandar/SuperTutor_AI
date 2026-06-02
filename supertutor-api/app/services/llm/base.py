from abc import ABC, abstractmethod
from typing import Iterator


class LLMProvider(ABC):
    name: str = "base"

    @abstractmethod
    def is_configured(self) -> bool: ...

    @abstractmethod
    def chat(self, messages: list[dict]) -> str: ...

    def chat_stream(self, messages: list[dict]) -> Iterator[str]:
        """Yield text chunks. Default: fall back to non-streaming."""
        yield self.chat(messages)


class STTProvider(ABC):
    name: str = "base"

    @abstractmethod
    def is_configured(self) -> bool: ...

    @abstractmethod
    def transcribe(
        self, audio: bytes, filename: str = "audio.webm", language: str | None = None
    ) -> str: ...


class VisionProvider(ABC):
    name: str = "base"

    @abstractmethod
    def is_configured(self) -> bool: ...

    @abstractmethod
    def analyze(
        self,
        prompt: str,
        image: bytes,
        mime: str = "image/jpeg",
        system: str | None = None,
    ) -> str: ...
