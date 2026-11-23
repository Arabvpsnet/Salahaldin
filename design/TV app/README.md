# TV app — Salahaldin design specification

**Destination in Figma:** create a dedicated page named `TV app` within the Salahaldin design file (once the target Figma file/team is selected).

## Editable frames
| Frame | Dimensions | State |
|---|---:|---|
| TV / Landscape / Dashboard | 1920 × 1080 | prayer and iqamah table, countdown |
| TV / Landscape / Adhan | 1920 × 1080 | full-screen prayer call |
| TV / Landscape / Iqamah | 1920 × 1080 | 3:45 countdown |
| TV / Landscape / Prayer | 1920 × 1080 | silence and alignment |
| TV / Landscape / Adhkar | 1920 × 1080 | rotating dhikr |
| TV / Portrait / Dashboard | 1080 × 1920 | 6 stacked timetable cards |
| TV / Portrait / Iqamah | 1080 × 1920 | large countdown |
| TV / Languages / Arabic | 1920 × 1080 | RTL |
| TV / Languages / Dansk | 1920 × 1080 | LTR |
| TV / Languages / English | 1920 × 1080 | LTR |
| TV / Languages / Türkçe | 1920 × 1080 | LTR |
| TV / Settings | 1920 × 1080 | large touch/remote targets |

## Visual tokens
- Primary background `#071A17` deep emerald; panels `#12332E`; active prayer `#1C5849`
- Main type `#F6F0DB` ivory, secondary `#B8C9BD`, accent `#D9B77A` gold, separator `#33554D`
- TV Arabic face: Amiri or Noto Naskh Arabic; general UI: Noto Sans Arabic or system sans; Latin: Manrope
- Scale responsive by actual viewport, never rely on a single fixed pixel scene. Maintain high contrast.
- Minimum 44px equivalent remote focus targets on 1080p; 24px+ TV body labels; 80px+ countdown.

## Component architecture
- `BrandHeader`, `LocationDate`, `PrayerRow` (active/inactive/sunrise variants), `NextPrayerCountdown`, `IqamahCountdown`, `InfoTicker`, `DhikrCard`, `RemoteFocusButton`, `ScreenMode`, `LanguageSwitcher`.
- Bind data to the canonical mosque schedule; **do not** calculate different times from mobile.
- Each language is independently selectable per device, but all devices use the same mosque ID and prayer/iqamah schedule.
- Date/time display must use the mosque IANA timezone, not browser-local timezone.
- Screen transitions: dashboard → adhan → iqamah → prayer → adhkar → dashboard; network outages use cached calendar with an explicit last-synced timestamp and stale-data warning.

## Content safeguards
The mockup uses sample times strictly for design review, not live prayer times. Treat ayat/adhkar and translation content as separate source-attributed assets and preserve the licensing notices in the codebase. There are no live server credentials in the prototype.

## Proposed branch setup

The TV currently reads the public schedule for the mosque selected at build time. Its mosque identity and logo are configured locally. The next release can give each mosque a profile in one admin dashboard and share its published schedule between phones and TVs.

| Screen | Workflow |
|---|---|
| Admin | Set the mosque's name, logo, address, city and time zone. Preview and publish the official calendar, daily iqamah times and Friday sessions. Restrict editing to authorized accounts and retain a history of published revisions. |
| TV | Pair the display with a mosque using a short-lived code. Show the mosque identity, upcoming prayer and iqamah with large type and a visible remote-control focus indicator. Cache the published schedule and flag dates the cache does not cover. |
| Phone | Let the visitor choose a city and mosque or open the mosque's share link. Use the same published calendar revision as TV for the selected mosque. |
| Quran reader | Show the Arabic mushaf, Latin-script transliteration, translation of meanings and sourced tafsir as selectable views. Use the same Arabic recitation for a given surah and ayah in each view. Offer per-language spoken translations as separate tracks when recordings and rights are available. |

Pilot with two mosques in different cities. Verify that publishing a revision changes only the selected mosque, that phone and TV agree through daylight-saving changes and that the display remains usable offline.
