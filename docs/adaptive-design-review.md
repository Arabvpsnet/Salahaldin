# Adaptive design — Salahaldin

Phase 1: preserve existing brand, data, Quran fonts and features. Correct inconsistent width classification and reflow home action labels, including enlarged Arabic text. Existing offline NotoSansArabic is used as a fallback; Cairo/Tajawal are proposals, not newly bundled fonts.

## Verification targets

- Phone: 320–649 logical px; use vertical reflow.
- Tablet / split screen: 650–1299; adapt to available width, not hardware. Modern home uses two panels only when enough width remains at the chosen text scale.
- Desktop: 1300+; verify keyboard and focus.
- TV: verify 720p, 1080p, 4K, 960×540 WebView, remote direction keys, Arabic/Danish/Turkish/English and reduced motion. Separate TV readability PR remains to be reconciled.
- Test widths 320, 390, 430, 650, 768, 840, 1024, 1300, 1920; portrait/landscape, light/dark, RTL/LTR, text scaling 1.0/1.3/2.0, offline, loading/error states and route preservation.
- Prefer 48 logical px touch targets; don't claim accessibility compliance until verified. Do not change Quran text or recitation data.

References: https://docs.flutter.dev/ui/adaptive-responsive/best-practices and https://www.w3.org/TR/WCAG22/.

## Validation status

New breakpoint tests added; CI and real native-device coverage pending. No release or signing changes. Remaining: audit Quran, prayer, account, settings and server administration screens; reconcile open feature PRs before merging.
