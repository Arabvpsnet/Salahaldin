#!/usr/bin/env python3
"""Import three additional unmodified QuranEnc editions for Salahaldin.

The existing ten editions and their pinned hashes are not changed. The repository
owner has stated that they possess distribution permission; public QuranEnc
terms, publisher attribution and version metadata remain binding.

No translations are generated, normalized, retranslated, or edited.
"""
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import json
from pathlib import Path
import shutil
import tempfile

from import_quranenc_translations import (
    CATALOG_URL, TERMS_URL, download, encode, read_archive, require,
    sha256, verse_counts, verify_assets
)

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets/quran/translations"
EXTRAS = {
    "de": ("german_rwwad", "Rowwad Translation Center"),
    "bs": ("bosnian_rwwad", "Rowwad Translation Center"),
    "ku": ("kurdish_bamoki", "Muhammad Salih Bamoki · Rowwad Translation Center"),
}


def assemble(language, key, publisher, entry, counts, folder):
    require(entry["key"] == key and entry["language_iso_code"] == language,
            "QuranEnc edition identity changed: " + key)
    require(isinstance(entry.get("version"), str) and entry["version"],
            "Missing publisher edition version: " + key)
    url = entry.get("database_url")
    require(url == "https://quranenc.com/downloads/sqlite/" + key + ".zip",
            "Source archive has changed: " + key)
    archive = download(url)
    verses, database_bytes, members = read_archive(archive, key, counts)
    folder.mkdir(parents=True, exist_ok=True)
    source = {
        "languageCode": language,
        "editionKey": key,
        "title": entry["title"],
        "publisher": publisher,
        "version": entry["version"],
        "sourceUrl": "https://quranenc.com/en/browse/" + key,
        "isTafsir": False,
        "provider": "QuranEnc.com",
        "description": entry.get("description", ""),
        "archiveUrl": url,
        "archiveSha256": sha256(archive),
        "sqliteSha256": sha256(database_bytes),
        "archiveBytes": len(archive),
        "sqliteBytes": len(database_bytes),
        "verseCount": 6236,
        "metadataProvenance": {
            "sourceUrl": CATALOG_URL,
            "apiMetadata": entry,
            "checkedAt": datetime.now(timezone.utc).isoformat(),
            "archiveMembers": members,
        },
        "surahSha256": {},
    }
    total = 0
    for surah, chapter in verses.items():
        doc = {
            "schemaVersion": 1,
            "languageCode": language,
            "editionKey": key,
            "version": source["version"],
            "surah": surah,
            "verses": chapter,
        }
        raw = encode(doc)
        require(json.loads(raw)["verses"] == chapter,
                "Chapter serialization altered the original publisher text")
        (folder / (str(surah) + ".json")).write_bytes(raw)
        source["surahSha256"][str(surah)] = sha256(raw)
        total += len(raw)
    source["assetBytes"] = total
    require(len(source["surahSha256"]) == 114, "Incomplete imported Quran edition")
    return source


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--verify-only", action="store_true",
                        help="Verify all 13 installed editions offline")
    args = parser.parse_args()
    counts, canonical_hash = verse_counts()

    if args.verify_only:
        verify_assets(OUTPUT, counts)
        print("Verified 13 complete QuranEnc editions, 114 surahs each.")
        return

    manifest_path = OUTPUT / "manifest.json"
    manifest = json.loads(manifest_path.read_bytes())
    require(manifest["schemaVersion"] == 1 and
            manifest["canonicalIndexSha256"] == canonical_hash,
            "Canonical Quran verse index has changed")
    existing = set(manifest["sources"])
    require(existing == {"ar", "bn", "en", "es", "fa", "fr", "id", "ms", "tr", "ur"} or
            existing == set(EXTRAS) | {"ar", "bn", "en", "es", "fa", "fr", "id", "ms", "tr", "ur"},
            "Existing Quran edition manifest is unexpectedly different")
    if set(EXTRAS).issubset(existing):
        verify_assets(OUTPUT, counts)
        print("All 13 editions already installed and verified.")
        return

    # Independently verify all existing, pinned files before changing anything.
    for language in existing:
        source = manifest["sources"][language]
        require(source["verseCount"] == 6236, "Incompatible pinned edition")
        for surah, count in counts.items():
            raw = (OUTPUT / language / (str(surah) + ".json")).read_bytes()
            require(sha256(raw) == source["surahSha256"][str(surah)],
                    "Existing Quran file hash mismatch")
            doc = json.loads(raw)
            require(doc["editionKey"] == source["editionKey"] and
                    doc["surah"] == surah and len(doc["verses"]) == count,
                    "Existing Quran file identity mismatch")

    catalog = json.loads(download(CATALOG_URL))
    available = {row["key"]: row for row in catalog["translations"]}
    new_sources = {}
    with tempfile.TemporaryDirectory(prefix="salahaldin-new-editions-") as tmp:
        stage = Path(tmp)
        for language, (key, publisher) in EXTRAS.items():
            require(key in available, "Requested edition is not published: " + key)
            new_sources[language] = assemble(
                language, key, publisher, available[key], counts, stage / language)
            print(json.dumps({
                "language": language, "key": key,
                "verses": 6236,
                "version": new_sources[language]["version"],
                "sha256": new_sources[language]["archiveSha256"],
            }), flush=True)

        for language, source in new_sources.items():
            dest = OUTPUT / language
            require(not dest.exists(), "Refusing to overwrite: " + str(dest))
            shutil.move(str(stage / language), str(dest))
            manifest["sources"][language] = source
        manifest["sourceTermsUrl"] = TERMS_URL
        manifest_path.write_bytes(encode(manifest))
    verify_assets(OUTPUT, counts, manifest)
    print("All 13 edition files imported with unmodified verse text and SHA256 checks.")


if __name__ == "__main__":
    main()
