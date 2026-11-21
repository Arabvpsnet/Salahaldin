#!/usr/bin/env python3
"""Import complete Al-Mukhtasar Arabic tafsir without touching Al-Muyassar.

Reads only QuranEnc official publisher ZIP/SQLite and their unmodified strings.
Saves a separate versioned 114-chapter source with per-file SHA256 evidence.
"""
import argparse
from datetime import datetime, timezone
import json
from pathlib import Path

from import_quranenc_translations import (
    HOME_URL, PublisherCards, download, encode, read_archive, require,
    sha256, verse_counts
)

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets/quran/tafsir/arabic_mokhtasar"
KEY = "arabic_mokhtasar"
ARCHIVE = "https://quranenc.com/downloads/sqlite/" + KEY + ".zip"
URL = "https://quranenc.com/en/browse/" + KEY


def verify() -> dict:
    counts, index_hash = verse_counts()
    manifest = json.loads((OUTPUT / "manifest.json").read_bytes())
    source = manifest.get("source", {})
    require(manifest["schemaVersion"] == 1 and manifest["editionKey"] == KEY,
            "Incorrect tafsir manifest")
    require(manifest["canonicalIndexSha256"] == index_hash and
            manifest["verseCount"] == 6236, "Tafsir index mismatch")
    require(source["languageCode"] == "ar" and
            source["editionKey"] == KEY and
            source["sourceUrl"] == URL and
            source["isTafsir"] is True and
            isinstance(source["version"], str) and source["version"],
            "Incorrect tafsir publisher/source metadata")
    require(len(manifest["surahSha256"]) == 114, "Tafsir hashes incomplete")
    require({p.name for p in OUTPUT.iterdir() if p.is_file()} ==
            {"manifest.json", *{str(s) + ".json" for s in range(1, 115)}},
            "Unexpected files in tafsir data")
    for surah, n in counts.items():
        raw = (OUTPUT / (str(surah) + ".json")).read_bytes()
        require(sha256(raw) == manifest["surahSha256"][str(surah)],
                "Tafsir asset hash changed")
        data = json.loads(raw)
        require(data["schemaVersion"] == 1 and
                data["languageCode"] == "ar" and
                data["editionKey"] == KEY and
                data["version"] == source["version"] and
                data["surah"] == surah and
                list(data["verses"]) == [str(i) for i in range(1, n + 1)],
                "Tafsir verse identity mismatch")
        require(all(isinstance(row.get("translation"), str) and
                    row["translation"].strip() and
                    isinstance(row.get("footnotes"), str)
                    for row in data["verses"].values()),
                "Malformed tafsir text or notes")
    return manifest


def install() -> None:
    counts, canonical_hash = verse_counts()
    cards = PublisherCards()
    cards.feed(download(HOME_URL).decode("utf-8"))
    meta = cards.metadata(KEY)
    require(meta.get("version") and meta.get("title") and meta.get("description"),
            "Official publisher tafsir metadata missing")
    archive = download(ARCHIVE)
    editions, sqlite, members = read_archive(archive, KEY, counts)
    if OUTPUT.exists() and any(OUTPUT.iterdir()):
        old = verify()
        require(old["source"]["version"] == meta["version"] and
                old["archiveSha256"] == sha256(archive),
                "Tafsir was revised; requires explicit source re-review")
        print("Pinned Al-Mukhtasar tafsir already installed: " + old["source"]["version"])
        return
    OUTPUT.mkdir(parents=True, exist_ok=True)
    source = {
        "languageCode": "ar",
        "editionKey": KEY,
        "title": meta["title"],
        "publisher": "مركز تفسير للدراسات القرآنية — Tafsir Center",
        "version": meta["version"],
        "sourceUrl": URL,
        "isTafsir": True,
        "provider": "QuranEnc.com",
        "description": meta["description"],
    }
    hashes = {}
    for surah, verses in editions.items():
        encoded = encode({
            "schemaVersion": 1,
            "languageCode": "ar",
            "editionKey": KEY,
            "version": source["version"],
            "surah": surah,
            "verses": verses,
        })
        require(json.loads(encoded)["verses"] == verses,
                "Serialization modified publisher tafsir content")
        (OUTPUT / (str(surah) + ".json")).write_bytes(encoded)
        hashes[str(surah)] = sha256(encoded)
    (OUTPUT / "manifest.json").write_bytes(encode({
        "schemaVersion": 1,
        "editionKey": KEY,
        "source": source,
        "canonicalIndexSha256": canonical_hash,
        "archiveSha256": sha256(archive),
        "sqliteSha256": sha256(sqlite),
        "sourceArchiveUrl": ARCHIVE,
        "sourceArchiveMembers": members,
        "verseCount": 6236,
        "surahSha256": hashes,
        "checkedAt": datetime.now(timezone.utc).isoformat(),
    }))
    verify()
    print(json.dumps({"tafsir": KEY, "surahs": len(hashes),
                      "verses": 6236, "version": source["version"],
                      "publisherArchiveSha256": sha256(archive)}, ensure_ascii=False))


if __name__ == "__main__":
    args = argparse.ArgumentParser(description=__doc__)
    args.add_argument("--verify-only", action="store_true")
    selected = args.parse_args()
    if selected.verify_only:
        result = verify()
        print("Verified 114 Al-Mukhtasar tafsir surahs: " + result["source"]["version"])
    else:
        install()
