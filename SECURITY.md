# Salahaldin security policy and audit log

## Scope and present limitations
This project is a three-application fork of independently maintained Flutter, TypeScript/Capacitor, and Laravel codebases. A successful CI build is not a penetration test or proof of no vulnerabilities. There must be no public deployment before dependency audits, authenticated admin flows, mobile API verification and deployment environment reviews succeed.

## Immediate baseline (20 November 2026)
- **Critical lifecycle issue:** Laravel 10 in `server/composer.json` ended security support on 4 February 2025. Migrate to a supported version (prefer Laravel 13 with compatible PHP and dependencies; Laravel 12 only if required by compatibility). The migration requires explicit dependency solver checks and feature/regression tests. Merely changing `^10.10` is not a safe upgrade.
- Backend front end uses Vite 4 and Vue tooling from older baselines. Security audits of **locked** versions are now required. Update dependency and lockfile as a tested pair, not package.json alone.
- Flutter's frozen `flutter_local_notifications` dependency has native alarm storage compatibility constraints; update only with notification migration tests on physical Android and iOS devices.
- GitHub Dependabot monitors npm (TV/server), composer, pub and GitHub Actions; it only starts scheduled PRs when the config is present on the default branch.
- All upstream licenses, translations, recordings and photo terms remain legally binding regardless of app branding.

## Hardening changes
- Removed sensitive exception/stack trace dumping from Excel import; added upload MIME, 5MB and row count limits, and transactional insert.
- Restricted default CORS to local dev origins and made production origins configurable.
- Added HTTP security headers (nosniff, referrer policy, frame restriction, permissions policy, conditional HSTS).
- Encrypted session payloads and default-secure session cookies in production; validate HTTPS/reverse-proxy trust configuration.
- Prevent remote TV configuration from loading over plaintext HTTP (except localhost), bound payload size and row counts, and validate IANA timezone/day formats.
- Replaced upstream TV brand in main visible entry points; retained mandatory license and attribution texts in source/about/third-party notices.

## Release gates
1. Run `npm ci && npm run typecheck && npm test && npm run build` in TV.
2. Run `flutter pub get && flutter analyze && flutter test` in mobile.
3. Run `composer install --no-interaction --prefer-dist && php artisan test` in server, then `composer audit --locked`.
4. Run `npm audit --package-lock-only --audit-level=high` in both TV and server.
5. Run authorization tests for all mutating routes; validate 401/403 behavior without CSRF bypass.
6. Require admin MFA, secrets stored outside VCS, encrypted backups, least privilege, database/firewall policies, TLS and server monitoring.
7. Test Copenhagen summer/winter clock changes, offline schedules, mosque identity, file imports, logging, and user notification permissions.
8. Turn off `APP_DEBUG` in every production environment. Configure `CORS_ALLOWED_ORIGINS` explicitly to owned domains.

## Incident response
Rotate any leaked secrets immediately; purge them from remote logs and builds where feasible and verify third-party revocations. Report suspected vulnerabilities via GitHub's private vulnerability reporting if enabled. Never post exploit payloads, tokens or personal prayer preferences in public issues.
