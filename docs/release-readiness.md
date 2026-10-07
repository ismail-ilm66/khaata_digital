# Release readiness (M7)

Status on 7 October 2026, version 1.0.0+1.

## Release gate

Run before every store upload. There's no CI by the owner's choice; this script is the gate and stops at the first failure.

```
tool/release_check.sh
```

It checks, in order: formatting, `flutter analyze`, the full test suite (including every golden backup restoring to the paisa), the golden backups again on their own, line coverage of core and domain code ≥ 80 % (`tool/coverage_gate.dart`), and a signed release bundle.

On-device checks (iOS simulator or any device):

```
flutter test integration_test/key_flows_test.dart -d <device>      # first run → add/edit/delete → Urdu → lock → 10k import
flutter test integration_test/backup_restore_test.dart -d <device> # receipt: attach → encrypted backup → restore → view
flutter test integration_test/reminder_test.dart -d <device>       # bill reminder delivered by the OS
```

Last results: all three pass on the iPhone 17 simulator (iOS 26); 10,000 rows import in 1.4 s on the device.

## Phase 1.5 — every complaint, row by row

| # | Complaint | Status | Evidence |
|---|-----------|--------|----------|
| 1 | Backup fails, data lost | **Done.** (a) SQLite in WAL mode with an integrity check at every start, a restore prompt on failure; (b) one-tap backup to a file or the user's own Google Drive, visible "Kharcha Backups" folder, optional AES-256 passphrase, weekly automatic backups; (c) golden backups from every schema version must restore to the paisa — enforced by `tool/release_check.sh` (the owner removed CI; the script is the gate). | `test/golden/`, `test/features/backup/`, `integration_test/backup_restore_test.dart` |
| 2 | App abandoned | **In-app part done:** "What's new" in More → About. Monthly releases and answering every ≤4★ review within 72 h are **owner commitments** (no code). | `lib/features/settings/domain/changelog.dart` |
| 3 | Receipt attach broken | **Done.** Compressed JPEGs in app storage, `attachments` rows with SHA-256, included in backups; instrumentation test proves attach → backup → restore → view, byte for byte. | `integration_test/backup_restore_test.dart` |
| 4 | Reports capped | **Done.** Day / Week / Month / Year / Custom / All time; no history cap; totals reconcile to the paisa. | `test/features/reports/` |
| 5 | No custom month start | **Done**, beyond spec: day 1–28 **or the last working day**; Home, Budgets and Reports all follow it. | `test/core/dates/budget_cycle_test.dart` |
| 6 | Forced login | **Done.** No account anywhere; Google sign-in only to connect Drive. | — |
| 7 | Crashes & calculation bugs | **Done.** Integer paisa only (a standing-rule test bans `double` in money code); one row per transfer; editing keeps the original date; recurring engine tested on month-ends. | `test/standing_rules_test.dart`, `test/features/transactions/transaction_form_bloc_test.dart`, `test/core/dates/recurrence_test.dart` |
| 8 | Deleted names can't be reused | **Done.** Soft delete; unique names only among active rows. | `test/core/db/schema_test.dart` |
| 9 | No multi-currency | **MVP done:** per-account currency, manual rate on transfers, Hysab Kytab travel-currency fields imported. **Deferred (v2):** automatic exchange rates. | `test/features/import_export/` |
| 10 | Missing quality-of-life | **Done:** dark mode, hide balances, full-text search, reorder accounts and categories, Excel/CSV export. **Deferred (v2):** PDF reports, subcategories, home-screen widget. | — |
| 11 | Ads backlash | **Done.** No ads; stated in the listing and in More → About. | `store/listing_en.md` |
| 12 | Support unreachable | **Done**, needs one owner step: Contact us opens an email with diagnostics once `SUPPORT_EMAIL` is set in `.env`; until then it copies the diagnostics. | `lib/features/settings/data/diagnostics.dart` |

## Store assets (`store/`)

- `listing_en.md`, `listing_ur.md` — title, short and full description, keywords, release notes.
- `screenshots/1_home.png` … `8_dark.png` — 1080×1920, captioned as in spec 2.2.
- `feature_graphic.png` — 1024×500.
- `icon_512.png` — Play icon.
- Regenerate all of them with `flutter test tool/store/render_store_test.dart`.

## Owner checklist before the first upload

- [ ] Publish `docs/privacy-policy.md` at a public URL (GitHub Pages from `/docs` is simplest) and enter it in Play Console.
- [ ] Set `SUPPORT_EMAIL` in `.env`, and the same address on the store listing.
- [ ] Back up `android/app/kharcha-upload.jks` and its password somewhere safe.
- [ ] Create the app in Play Console with id `com.expensetracker.kharcha`; enroll in Play App Signing; upload `build/app/outputs/bundle/release/app-release.aab`.
- [ ] Google Cloud → Google Auth Platform → Audience: **Publish app** (Testing → In production). While in Testing, only listed test users can connect Drive ("Access blocked … verification process"). `drive.file` is non-sensitive, so no scope review; Google may ask for brand verification (hosted privacy policy + verified home-page domain).
- [ ] After the first upload, add the **Play app-signing SHA-1** (Play Console → App integrity) as another Android OAuth client in Google Cloud, or Drive sign-in fails for Play installs.
- [ ] Content rating questionnaire; target audience 13+; ads: **No**.
- [ ] Data safety form — see below.
- [ ] Closed testing: 20+ testers for 14 days (Play's rule for new personal accounts), then open beta, then production (spec 2.3).

## Play Console data safety — suggested answers

These match what the code does; review before submitting.

- **Does the app collect or share user data?** No. All financial data stays on the device; Kharcha's makers never receive it.
- **Is data encrypted in transit?** Yes — Google Drive backups use HTTPS (Google's APIs); there is no other network traffic.
- **Can users request deletion?** Yes — uninstalling or clearing app data deletes everything; Drive backups are in the user's own Drive.
- **Notes:** backups and exports are user-initiated and go to destinations the user chooses (their own files or their own Google Drive). The optional "Contact us" email is sent by the user from their own mail app.

## Deferred, by decision

- In-app review prompt (spec 2.3) — to add with the first update, once real success moments (first restore, a month under budget) can be measured on devices.
- Automatic exchange rates, PDF reports, subcategories, home-screen widget, sync — v2 (spec roadmap).
