"""Generate small WAV files for correct/wrong sound effects."""
import math
import struct
import wave
from pathlib import Path

OUT = Path(__file__).parent.parent / "assets" / "sounds"
OUT.mkdir(parents=True, exist_ok=True)

SAMPLE_RATE = 22050


def write_tone(path: Path, notes: list[tuple[float, float]], volume: float = 0.5) -> None:
    frames: list[int] = []
    for freq, dur in notes:
        n = int(SAMPLE_RATE * dur)
        for i in range(n):
            t = i / SAMPLE_RATE
            env = min(1.0, t * 30) * max(0.0, 1.0 - (i / n))
            sample = math.sin(2 * math.pi * freq * t) * env * volume
            frames.append(int(sample * 32767))
    raw = struct.pack(f"{len(frames)}h", *frames)
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SAMPLE_RATE)
        w.writeframes(raw)
    print("wrote", path)


def main() -> None:
    write_tone(OUT / "correct.wav", [(523.25, 0.10), (659.25, 0.10), (783.99, 0.18)])
    write_tone(OUT / "wrong.wav", [(311.13, 0.18), (233.08, 0.26)], volume=0.4)


if __name__ == "__main__":
    main()
