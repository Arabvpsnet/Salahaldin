# Salahaldin — صلاتي / صلاح الدين

Source integration of mobile prayer/Quran app, mosque TV display, and a self-hosted API.

## Components
- `mobile/`: [SalaTime Flutter](https://github.com/HydraaLabs/salatime_app), pinned at `b418b217287d81915d59fe75d1ac05c8a2fa4aac`.
- `tv/`: [Sakina TV](https://github.com/filinodz/sakina), pinned at `b5fcb673910902e0a73f280048c09a6686af2d11`, Danish and Turkish display-label additions.
- `server/`: [SalaTime Laravel](https://github.com/HydraaLabs/salatime), pinned at `b3596745537f9d58291df8b94f37d0c5b54eea10`.
- `shared/`: data contract and multilingual Quran-source status.

The sources are imported with `.github/workflows/import-sources.yml`, which runs on this integration branch. Root `main` remains unchanged until reviewed.

## Language requirements
TV: Arabic, Danish, English, Turkish. A French upstream fallback is retained. The Danish/Turkish core labels are implemented; longer settings screens still use English fallback.
Quran mobile reader: Arabic, Turkish, Bosnian, Danish, German, English, Latin-script transliteration and/or Latin, Kurdish Sorani (ckb), Kurdish Bahdini (kmr). Do not claim tafsir editions exist where only translation editions exist. Added-language content must be properly sourced and checked for redistribution rights.

## Unified schedules
Configure `tv/.env.example.salahaldin` and install a vetted JSON schedule under `server/storage/app/prayer/schedules/<mosque-id>.json`. TV reads `/api/salahaldin/v1/schedules/<mosque-id>` and caches last applied data in local settings. The future administrator import screen must validate Excel columns before publishing JSON, and the phone still needs an opt-in linked mosque selector.

## Status
Code import and initial TV synchronization are integration work, not a tested finished release. Do not deploy before Android/iOS/TV builds, Ramadan/high-latitude/DST tests, source attribution checks and authentication review.

## Copyright, licenses, notices
SalaTime code is MIT, Sakina is MIT; retain all three upstream LICENSE files and third-party notices. Quran translations/tafsir, audio recordings, visual assets and fonts have independent conditions. QuranEnc permits attributed, intact republication under its published rules; see the bundled source metadata. No Quran translations should be generated or altered with AI.
