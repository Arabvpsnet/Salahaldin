# Quran language coverage and provenance policy

Requested reader languages: ar, tr, bs, da, de, en, ckb (Sorani, Arabic script), kmr (Bahdini / Northern Kurdish, usually Arabic or Latin script), and Latin-script Arabic transliteration. Classical Latin translation is a distinct edition and must not be conflated with transliteration.

Arabic source text always remains Uthmani Arabic; a Latin-script option displays a vetted transliteration alongside it, never replaces the mushaf.

Proposed sources for licensed, complete editions:
- Existing upstream mobile QuranEnc manifest: Arabic Al-Muyassar tafsir and Turkish/English meaning translations; preserve official publisher titles, version, footnotes, SHA256 manifest and source attribution.
- QuranEnc catalogue: check Bosnian, Danish, German and Kurdish editions case by case against publisher rights.
- Quran Foundation resource catalogue: alternative discoverability; API use and republication rights are distinct.
- Sorani and Bahdini: investigate separately, including alphabet, dialect and verified text provenance; never label Kurmanji Latin script as Badini Arabic script without publisher confirmation.
- Tafsir != translation. Where a scholarly tafsir is not licensed in that language, provide a clearly marked translation of meanings and Arabic tafsir, not an invented local-language tafsir.

Status: content corpus integration and edition-by-edition license validation are pending. The application cannot represent unavailable tafsir as installed.

Sources:
https://quranenc.com/en/home/api/
https://api-docs.quran.foundation/
https://github.com/HydraaLabs/salatime_app
https://github.com/filinodz/sakina
