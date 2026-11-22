# Salahaldin Quran translation and tafsir import

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

## Reproducibility
- Initial transfer workflow: `.github/workflows/import-licensed-quran.yml`.
- Extended source importer: `mobile/tools/import_approved_quranenc_editions.py`.
- Verify all pinned assets offline: `cd mobile && python3 tools/import_quranenc_translations.py --verify-only`.
- Test bundled language selection, and Quran text display on phones and tablets before publication.

Sources:
- https://quranenc.com/en/home/api/
- https://quranenc.com/en/home/about/terms

## Badini Sanahi independent edition

The user-authorized Badini / Behdini original Sanahi verse text was imported **separately** from the QuranEnc Kurdish Bamoki edition, from upstream commit `d0752aaa22f197261a58cad75724bac9cffd868d` in `0xdolan/kurdish_quran`. GitHub Actions verified 6,236 source lines and 114 canonical surahs, hashed every resulting chapter, and retained the original upstream link in `mobile/assets/quran/badini/manifest.json`. The mobile reader verifies each chapter's SHA256 before display. This is a structural and chain-of-custody check, **not a scholarly verification of translation accuracy or identity of the copyright owner**; the user's claimed grant must match that particular edition and intended distribution.

**Total after this addition:** 14 offline editions: 13 QuranEnc originals plus one separately attributed Sanahi Badini translation.

## Al-Mukhtasar — additional complete Arabic tafsir

QuranEnc edition `arabic_mokhtasar` **version 1.0.0** was independently imported from the official publisher ZIP into `mobile/assets/quran/tafsir/arabic_mokhtasar/`, with all 114 surahs/6,236 ayahs, unchanged publisher translations and notes, original edition title/source, archive SHA256 and chapter SHA256. It does not replace the existing Al-Muyassar tafsir. The app's edition library now offers both choices; independent local hashes are checked before display. Source: https://quranenc.com/en/browse/arabic_mokhtasar .

**Final bundle count in this work branch: 15 editions**: 13 original QuranEnc translations/tafsir, 1 Badini Sanahi translation and 1 additional Al-Mukhtasar Arabic tafsir. Official source identity and textual completeness are checked; a structural check is not theological review.
