#!/usr/bin/env python3
"""Check local Quran-translation JSON identity, not edition rights or text accuracy."""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
COUNTS_SOURCE = ROOT / "mobile/lib/service/reading/reading_progress_models.dart"
BIDI_OVERRIDES = set("\u202a\u202b\u202c\u202d\u202e")


def canonical_counts(path: Path = COUNTS_SOURCE) -> list[int]:
    source = path.read_text(encoding="utf-8")
    match = re.search(r"static const List<int> verseCounts\s*=\s*\[(.*?)\];", source, re.S)
    if match is None:
        raise ValueError("Canonical verse counts not found in Flutter source")
    counts = [int(value) for value in re.findall(r"\b\d+\b", match.group(1))]
    if len(counts) != 114 or sum(counts) != 6236:
        raise ValueError("Expected 114 surahs and 6236 Quran verses")
    return counts


def validate_translation(entries: object, counts: list[int]) -> dict[str, int]:
    expected = sum(counts)
    if not isinstance(entries, list) or len(entries) != expected:
        raise ValueError("Translation must have exactly " + str(expected) + " ayahs")
    offsets = [0]
    for count in counts:
        offsets.append(offsets[-1] + count)
    seen: set[int] = set()
    for index, entry in enumerate(entries):
        if not isinstance(entry, dict):
            raise ValueError("Verse entry must be an object at row " + str(index))
        verse_id, surah, ayah = (entry.get(key) for key in ("id", "surah", "ayah"))
        content = entry.get("text")
        if any(type(n) is not int for n in (verse_id, surah, ayah)):
            raise ValueError("Quran identifiers must be integers")
        if not (1 <= surah <= len(counts) and 1 <= ayah <= counts[surah - 1]):
            raise ValueError("Out-of-range Quran ayah")
        if verse_id != offsets[surah - 1] + ayah or verse_id in seen:
            raise ValueError("Duplicate or incorrect canonical verse identity")
        seen.add(verse_id)
        if not isinstance(content, str) or not content.strip() or len(content) > 10000:
            raise ValueError("Missing/invalid translation body")
        if any(char in BIDI_OVERRIDES or ord(char) == 0 for char in content):
            raise ValueError("Bidi override or NUL in translation text")
    if seen != set(range(1, expected + 1)):
        raise ValueError("Missing Quran verse identities")
    return {"surahs": len(counts), "verses": expected}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("dataset", type=Path, help="Local JSON data, never fetched automatically")
    args = parser.parse_args()
    if args.dataset.stat().st_size > 25_000_000:
        parser.error("Edition exceeds manual review limit")
    with args.dataset.open(encoding="utf-8") as stream:
        rows = json.load(stream)
    result = validate_translation(rows, canonical_counts())
    print(json.dumps({**result, "structure": "valid",
                      "accuracy": "not_verified",
                      "redistribution_rights": "not_granted_by_check"}))


if __name__ == "__main__":
    main()
