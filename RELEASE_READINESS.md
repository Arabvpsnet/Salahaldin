# Salahaldin — release readiness and security gates

Updated 2026-11-21. This is an **integration release candidate**, not authorization to publish.

## Verified automated checks

- GitHub Actions workflow run 44915110212: TV npm, backend npm, Composer, and repository secret audits all passed on the preceding integration commit.
- Workflow run 44915108313: Flutter analysis/tests, TV typecheck/tests/build, and API syntax/contract checks passed.
- Workflow run 44915108413: Flutter Android debug QA APK passed; **not** a signed production build.
- Security Advisory Scout queried OSV versions for Laravel 13.43.0, Symfony HTTP Foundation 8.1.11, firebase/php-jwt 7.2.2, Guzzle 7.16.5, Stripe PHP 20.3.2, Vite 8.3.8, Axios 1.21.1, Capacitor core 8.6.2 and others; none returned known advisories. This does **not** certify absence of vulnerabilities.
- Recitation cache hardening on this branch requires an MP3 header for cached files, bounds cached sizes, and rejects non-standard HTTPS ports; new tests cover port rejection.

## Required before production launch

1. **Branch consolidation:** review stacked PRs #10, #12, #13 and this release-hardening PR, reconcile with #5, #7 and #8, and complete all CI checks on the actual final candidate. `main` is currently only a bootstrap README.
2. **Signing and identity:** confirm final Android TV and mobile package IDs, Google Play listing ownership, production signing keystore, and release versionCode/versionName. TV still uses the original upstream Android applicationId `dz.filinodz.sakina`; mobile still uses `net.salatime.app`. Do **not** change package IDs blindly because installed-app upgrades and Play ownership depend on them.
3. **Native builds:** verify signed Android app bundles, Android TV APK, and iOS build/entitlements on actual devices. Debug APK success does not prove release signing or store acceptance.
4. **Native behavior:** test notifications/exact alarms, audio in background, TV boot recovery, network failure and offline Quran playback, time-zone and DST rollover, high-latitude Ramadan timetables, accessibility and RTL.
5. **Server deployment:** verify production PHP 8.4/required extensions, Laravel 13 migration, HTTPS-only origins/cookies, APP_DEBUG=false, secret environment variables, database backup/rollback, queue and scheduler supervision.
6. **Quran/media rights:** independently verify licensing, attribution and redistribution permissions for all text, translations, tafsir, fonts, images and audio; avoid shipping materials without affirmative rights.
7. **Data quality:** configure the official mosque prayer/iqama timetable and verify the time source and manual overrides. Design preview times are samples, not real mosque times.
8. **Privacy/security:** production login and OIDC redirect setup, secure storage, backup recovery, data deletion and incident reporting are required before accepting accounts.

Only mark release-ready when each item is verified and signed off.