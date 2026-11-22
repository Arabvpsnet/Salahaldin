# Review of user-selected community prayer and Quran projects
Date: 21 November 2026.

This review identifies useful functions and actual Salahaldin changes. No Quran translation, tafsir, voice recording, font or photograph was copied. A software MIT license does not grant rights to separately owned religious content.

## Source review
- Khiro95/Awqat-Salaat (MIT, Windows C#/WinUI): cached monthly prayer times, next-prayer countdown, strict CSV import and reminder presentation. Adapted official CSV and Aladhan validation in the TypeScript TV app, not a Windows binary.
- mohamed-sallam/Al-Miqata (GPL-3.0, ATmega328P C firmware): clear prayer wall clock, Hijri/Gregorian date, RTC and 12/24h formatting. Presentation reference only. No GPL source copied into MIT components.
- yassindaboussi/Salaty (MIT, Electron): offline fallback, consistent calculation method, Friday labelling, notifications, Quran reading and reading position. Salahaldin already offered much of this; extended calendar input robustness and explicit estimated-time warning.
- bahaback-hub/quran-app (MIT code, separately licensed Quran and recitation assets): hifz plans, resume after app restart, range repetition, normalized search and Mushaf layouts. Adapted a new native Flutter Hifz model and page; no translation, tafsir, font, audio or text copied.
- github.com/topics/quran-translation: directory containing differently licensed repositories; individual translation publishers must authorize reuse.

## Changes on this branch
- TV: reject incomplete and forged Aladhan calendar payloads, safely cache a complete month, restrict request size/time, validate month length and civil dates; preserve CSV column positions and reject malformed rows/duplicates.
- TV: present a visible warning in Arabic, English, Danish, Turkish and French when approved/imported mosque times are unavailable and the application falls back to astronomical estimates.
- Mobile: local-only Quran Hifz planner and progress tracker with verse/repetition bounds, review dates over daylight-saving transitions, resumable progress, and four translated user interfaces.
- Quality: new provider, CSV, Hifz and data-validator regression tests.
- Quran data: offline structural identity checker for a user-supplied 6236-verse translation JSON without downloading or publishing the text. Structural checks do not establish religious accuracy.

## Candidate translations: reference only
- QuranEnc https://quranenc.com : verify the edition title, translator, publisher and contract before any use.
- Kurdish Badini (Sanahi) versus Sorani (Asan, Puxta, Raman): https://github.com/0xdolan/kurdish_quran. No redistribution license found.
- King Fahd Complex Sorani translation: https://qurancomplex.gov.sa/quran-translations/ and independent reference list https://github.com/quran-ws/kfgqpc-resources . The PDF is publisher-owned.
- OCR/AI-extracted Sorani JSON: https://github.com/alurini/quran-translations in data/ku/quran_ku.json. Software MIT does not relicense text. README expressly warns about possible OCR errors, so do not copy without publisher authorization and verification.
- bahaback Quran app media and content rights report: https://github.com/bahaback-hub/quran-app/blob/main/NOTICE.md .

## Exclusions and release limitations
- No GPL firmware, Electron desktop shell, Windows-only deskband or incompatible binaries.
- No unlicensed full Quran translations, audio, or altered QCF calligraphy.
- No claim that all Quran reader locales are already installed; existing bundled languages remain distinct from reference-only edition metadata.
- Full release still requires security audit (legacy Laravel dependency), Android and iOS device testing, prayer timetable verification by mosque management, and rights clearance.
