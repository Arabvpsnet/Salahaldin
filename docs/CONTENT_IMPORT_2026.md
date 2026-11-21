# Salahaldin Quran translation, tafsir and recitation import

**Recorded:** 21 November 2026. The project owner stated that full content licences were obtained. This statement is recorded as owner-provided authorization; individual publisher obligations and source attribution remain in force. Copies of private permissions should be kept with release compliance records rather than published in this repository.

## Actually transferred
The QuranEnc publisher archives below were downloaded and copied verbatim to per-surah Flutter assets by GitHub Actions run 44849866546. All 114 surahs/6,236 ayahs per edition and archive, SQLite and output JSON SHA256 hashes were validated.

| Language | Publisher edition key | Version at import | New assets |
| --- | --- | --- | --- |
| Bosnian | `bosnian_rwwad` | 2.0.4 | 114 per-surah JSON |
| German | `german_rwwad` | 1.0.16 | 114 per-surah JSON |
| Kurdish | `kurdish_bamoki` | 1.1.1 | 114 per-surah JSON |

**Total:** 342 new translation JSON files; 13 installed editions including the previous 10, with Arabic `arabic_moyassar` tafsir preserved. The Kurdish Bamoki edition must not be advertised as a proven Badini translation without separate dialect/source review.

The original text, publisher names, footnotes, source URL, version number and canonical verse identities are retained. The 13-language library is reachable from the existing Quran list/reader and requires no internet for translated text.

## Tafsir status
- Arabic Al-Muyassar is already bundled, versioned and usable in the reader.
- Additional Arabic/translated tafsir editions listed as `remote-source` in the shared catalogue have **not** been copied into the app; do not label those as installed.
- Adding another tafsir requires distinct edition identifiers and edition-specific integrity checks, not replacing the Al-Muyassar text.

## Audio status
The mobile app already streams MP3Quran recitations from its provider API. This branch adds per-surah download buttons with secure HTTPS host validation, a 60 MiB per-file cap, MP3 header checks and offline playback from application support storage. **Recordings are downloaded to the user's device only when they choose to save a surah; the full audio catalogue is not bulk-committed to Git**, which would make repository and store bundles unreasonably large.

The audio provider and each reciter/riwayah remain attributed by the existing reciter metadata. File hashes are filenames for cache identity, not proof that audio recordings were matched against a publisher-supplied master recording. Android/iOS playback and storage tests are release requirements.

## Reproducibility
- Initial transfer workflow: `.github/workflows/import-licensed-quran.yml`.
- Extended source importer: `mobile/tools/import_approved_quranenc_editions.py`.
- Verify all pinned assets offline: `cd mobile && python3 tools/import_quranenc_translations.py --verify-only`.
- Test bundled language selection, Quran text display and audio download/playback on phones and tablets before publication.

Sources:
- https://quranenc.com/en/home/api/
- https://quranenc.com/en/home/about/terms
- https://www.mp3quran.net/ar/api
