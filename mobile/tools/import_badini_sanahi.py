#!/usr/bin/env python3
"""Import the exact 6,236-ayah Badini Sanahi source, preserving source attribution.

Separate from QuranEnc's pinned 13-edition manifest so neither source/version
can be silently conflated. Rights authorization is user-provided, not audited.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import urllib.request

from import_quranenc_translations import verse_counts, require

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets/quran/badini"
COMMIT = "d0752aaa22f197261a58cad75724bac9cffd868d"
SOURCE = "https://raw.githubusercontent.com/0xdolan/kurdish_quran/" + COMMIT + "/txt/translation_sanahi.txt"
SOURCE_PAGE = "https://github.com/0xdolan/kurdish_quran/blob/" + COMMIT + "/txt/translation_sanahi.txt"
EDITION = "badini_sanahi"
BIDI = set("\u202a\u202b\u202c\u202d\u202e")


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def encode(item: object) -> bytes:
    return (json.dumps(item, ensure_ascii=False, separators=(",", ":")) + "\n").encode("utf-8")


def verify(output: Path = OUTPUT) -> dict:
    manifest = json.loads((output / "manifest.json").read_bytes())
    require(manifest["schemaVersion"] == 1, "Unknown Badini manifest version")
    require(manifest["editionKey"] == EDITION and manifest["sourceCommit"] == COMMIT,
            "Badini source revision mismatch")
    source = manifest["source"]
    require(source["languageCode"] == "kmr" and source["editionKey"] == EDITION
            and source["version"] == COMMIT[:12] and source["sourceUrl"] == SOURCE_PAGE,
            "Badini source attribution changed")
    counts, canonical = verse_counts()
    require(manifest["canonicalIndexSha256"] == canonical,
            "Canonical Quran index changed")
    require(manifest["verseCount"] == 6236, "Quran coverage mismatch")
    require(len(manifest["surahSha256"]) == 114, "Missing chapter fingerprints")
    actual = {p.name for p in output.iterdir() if p.is_file()}
    expected = {"manifest.json", *{str(i) + ".json" for i in range(1, 115)}}
    require(actual == expected, "Missing or unexpected files in Badini edition")
    for chapter, n in counts.items():
        raw = (output / (str(chapter) + ".json")).read_bytes()
        require(sha256(raw) == manifest["surahSha256"][str(chapter)],
                "Badini chapter hash mismatch")
        doc = json.loads(raw)
        require(doc["schemaVersion"] == 1 and doc["languageCode"] == "kmr"
                and doc["editionKey"] == EDITION
                and doc["version"] == source["version"]
                and doc["surah"] == chapter
                and list(doc["verses"]) == [str(i) for i in range(1, n + 1)],
                "Badini ayah identity invalid")
        for row in doc["verses"].values():
            require(isinstance(row["translation"], str) and row["translation"].strip()
                    and row["footnotes"] == "", "Invalid Badini verse content")
    return manifest


def import_source() -> None:
    counts, canonical = verse_counts()
    request = urllib.request.Request(
        SOURCE, headers={"User-Agent": "Salahaldin-Source-Verifier/1.0"})
    with urllib.request.urlopen(request, timeout=45) as resp:
        require(resp.status == 200, "Source HTTP failure")
        blob = resp.read(5_000_001)
    require(len(blob) <= 5_000_000, "Badini source unexpectedly large")
    require(blob.startswith(b"\xef\xbb\xbf") is False, "Unexpected BOM in edition")
    lines = blob.decode("utf-8").splitlines()
    require(len(lines) == 6236, "Badini source does not have 6236 original verse lines")
    for i, value in enumerate(lines):
        require(bool(value.strip()) and len(value) <= 6000 and
                not any(ch in BIDI or ch == "\x00" for ch in value),
                "Badini verse is empty or unsafe at canonical row " + str(i + 1))
    source = {
        "languageCode": "kmr",
        "editionKey": EDITION,
        "title": "Badînî / Behdînî — Translation Sanahi",
        "publisher": "Sanahi (source: 0xdolan/kurdish_quran)",
        "version": COMMIT[:12],
        "sourceUrl": SOURCE_PAGE,
        "isTafsir": False,
        "provider": "0xdolan/kurdish_quran",
        "description": "User-authorized original Badini verse lines, split into surahs without rewriting.",
    }
    output = OUTPUT
    output.mkdir(parents=True, exist_ok=True)
    require(set(output.iterdir()) == set() or
            set(p.name for p in output.iterdir()) ==
            {"manifest.json", *{str(i) + ".json" for i in range(1, 115)}},
            "Refusing to overwrite unexpected existing Badini files")
    cursor, hashes = 0, {}
    for surah, n in counts.items():
        verse_lines = lines[cursor:cursor + n]
        cursor += n
        doc = {
            "schemaVersion": 1, "languageCode": "kmr",
            "editionKey": EDITION, "version": source["version"],
            "surah": surah,
            "verses": {
                str(i + 1): {"translation": value, "footnotes": ""}
                for i, value in enumerate(verse_lines)
            }
        }
        encoded = encode(doc)
        require(json.loads(encoded)["verses"] == doc["verses"],
                "Source text altered by serialization")
        (output / (str(surah) + ".json")).write_bytes(encoded)
        hashes[str(surah)] = sha256(encoded)
    require(cursor == 6236, "Badini edition split did not cover every verse")
    manifest = {
        "schemaVersion": 1,
        "editionKey": EDITION,
        "source": source,
        "sourceCommit": COMMIT,
        "sourceTextSha256": sha256(blob),
        "canonicalIndexSha256": canonical,
        "verseCount": cursor,
        "surahSha256": hashes,
        "licenseAssertion": "Project owner states they hold full permission to use this content; preserve original upstream attribution.",
        "contentReview": "Structural checks only. Publisher identity and scholarly accuracy require independent verification.",
    }
    (output / "manifest.json").write_bytes(encode(manifest))
    verify(output)
    print(json.dumps({"language": "kmr", "dialect": "Badini",
                      "verses": cursor, "chapters": len(hashes),
                      "sourceSha256": sha256(blob), "commit": COMMIT}))


if __name__ == "__main__":
    arg = argparse.ArgumentParser(description=__doc__)
    arg.add_argument("--verify-only", action="store_true")
    parsed = arg.parse_args()
    if parsed.verify_only:
        manifest = verify()
        print("Verified 6,236 original Badini Sanahi lines across 114 surahs, " +
              manifest["sourceTextSha256"])
    else:
        import_source()
