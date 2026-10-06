# Decisions log

Choices made where the spec (`specs/Master Build Specification …md`) was silent
or could not be followed literally. Newest milestone at the bottom.

## M0 — Project foundation

| # | Topic | Decision | Why |
|---|-------|----------|-----|
| 1 | Project / package name | Kept the existing project `khaata_digital` (Dart package `khaata_digital`) instead of creating `kharcha`. User-facing name is **Kharcha** (Android label, iOS display name, `appTitle`). | The project was already created by the owner; renaming a Dart package touches every import for no user benefit. |
| 2 | Android applicationId | Left as `com.example.khaata_digital` for now. | Changing it later is free until first Play upload, and the final ID is an owner decision. **Must be changed before M7** (Play rejects `com.example.*`). |
| 3 | Android minSdk | `flutter.minSdkVersion` (= **24**), not 23 as in spec 4.1. | Flutter 3.38 rewrites any lower `minSdk` back to its own floor during build. Android 6 (API 23) is ~0.3% of devices. |
| 4 | `injectable` version | `injectable` 2.7 / `injectable_generator` 2.9 (not 3.x). | `injectable_generator` 3.x needs `analyzer` ≥10, which conflicts with `bloc_test` → `test` on Dart 3.10.8. 2.x is API-compatible for our use. |
| 5 | Router location | `lib/core/router/` (`app_router.dart`, `app_shell.dart`). | Spec 4.1 tree has no router folder; it is cross-feature infrastructure, so it lives under `core/`. |
| 6 | Home feature folder | Added `lib/features/home/`. | Spec 3.2 defines a Home screen but 4.1 lists no home feature. |
| 7 | More tab | Lives in `features/settings/presentation/more_screen.dart`. | Spec 3.2 #10 treats More and Settings as one screen. |
| 8 | Add tab | Not a router branch; tapping it opens a modal bottom sheet over the current tab, and the previously selected tab stays highlighted. | Spec 3.2 #3: "Add Transaction (modal sheet)". |
| 9 | Theme/locale persistence | Default theme = system, default locale = English. In-memory in M0; **persisted from M1** via the `settings` table. | — |
| 10 | Theme/language toggles in M0 | More tab already has Theme (System/Light/Dark) and Language (English/اردو) selectors. | Needed to verify the M0 acceptance criterion ("both themes and both locales") on a device. |
| 11 | Generated code | `lib/core/l10n/gen/` and `*.config.dart` are generated (`flutter gen-l10n`, `build_runner`) and excluded from analysis. CI regenerates them. | Standard Flutter practice. |
| 12 | Extra platform folders | `linux/`, `macos/`, `web/`, `windows/` left untouched. | Spec targets Android and iOS only; removing generated folders is the owner's call. |
| 12a | CI | GitHub Actions workflow **removed** at the owner's request (after M1). Checks run locally instead: `flutter analyze`, `flutter test`, `flutter build appbundle --release`. The spec's CI items (M0 "CI green", the M7 golden-backup CI gate) are deferred until CI is reinstated. | Owner decision: not needed for now. |
| 13 | Urdu font | M0 uses the platform's default Urdu font (Naskh on most Androids). | A Nastaliq font such as Noto Nastaliq Urdu is a polish item for the M6 RTL audit. |

## M1 — Core domain & database

| # | Topic | Decision | Why |
|---|-------|----------|-----|
| 14 | Design foundation | Tokens in `core/theme`: `AppColors` (ThemeExtension), `AppSpacing`, `AppRadii`, `AppTypography`; `context.l10n / .text / .colors` shortcuts. Flat surfaces, no shadows. Colour only carries meaning: income green, expenses neutral ink, red/amber reserved for budget thresholds. | Owner asked for reusable components and a minimal UI; every later screen draws from one place. |
| 14a | Modern refresh (after M1, at owner's request) | **Floating frosted-glass nav bar** (`GlassNavBar` on `GlassSurface`: real backdrop blur, translucent fill, light edge, soft shadow) with a raised gradient "+" in the centre. The Add action has an accessible label instead of visible text. A single faint **ambient brand glow** (`AmbientBackground`) sits behind all tabs so the glass has colour to blur. **Large titles** that scroll with content (`PageScaffold`). Settings use **inset grouped cards** (`SurfaceCard`, `SettingTile`) and a **sliding pill picker** (`SegmentedPicker`, to be reused for Expense/Income/Transfer/Udhaar in M2). | The owner found the flat Material look dated. Boldness goes into one element (the glass bar); everything else stays quiet. |
| 14b | Icons | **Phosphor** (`phosphor_flutter`, MIT) replaces Material icons. Regular weight at rest, filled for selected states and tinted badges. Every icon goes through `AppIcons` in `core/widgets/app_icons.dart`, and a standing-rule test fails on any `Icons.*` or Phosphor import elsewhere. Category icon keys in the database are unchanged; only their mapping moved, and a test keeps icons unique within each category kind. | Owner found the stock icons basic. Phosphor has consistent geometry and real outline/filled pairs. The fonts ship offline and are tree-shaken to ~5 KB in release. |
| 15 | Typeface | **Manrope** (OFL), bundled as a variable font in `assets/fonts/`. Weights set through the `wght` axis by `AppTypography.weighted`. | Clean tabular numerals for amounts. Bundled because runtime Google Fonts would be a network call. |
| 16 | Seed categories | The 42 categories from the real export's `CATEGORY` sheet, verbatim and in order, instead of the spec's illustrative list ("School Fee", "Zakat & Charity"…). | The spec says "mirror Hysab Kytab's export vocabulary"; the real export is the authority, and exact names make M5 imports match with no remapping. |
| 17 | "No Category" | Not seeded as a row. `category_id IS NULL` is shown and exported as "No Category". | Spec 3.3 maps "No Category" to null on import; one representation avoids two meanings. |
| 18 | Name uniqueness | Partial unique indexes compare names **case-insensitively** (`COLLATE NOCASE`). Categories are unique per `(kind, name)`; people and tags/events by name. | "Cash" and "cash" side by side is a bug report waiting to happen. "Savings" exists as both an account and an income category in the real export. |
| 19 | Adjustment sign | `amount_minor` is positive for every type **except `adjustment`**, where the sign is the direction (+ into the account). Enforced by a CHECK constraint. | Spec 3.3 requires positive amounts but also needs adjustments (unpaired transfers) that can go either way, and there is no direction column. |
| 20 | Transaction currency | `transactions.currency_code` is always the source account's currency; a transfer's `to_amount_minor` is in the destination currency. | Keeps every balance a single-currency sum. |
| 21 | Net worth & udhaar across currencies | Reported **per currency**, never summed across currencies. | v1 has no automatic rates (spec 1.5 #9). |
| 22 | Cycle identity | A budget cycle is identified by the month it **starts** in: with a start day of 25, `cycle 2026-09` = 25 Sep – 24 Oct. `budgets.cycle_year/month` use this. | The spec is silent. Start month is deterministic and needs no clamping (start day ≤ 28). |
| 23 | Extra columns | Added `created_at`/`updated_at` to mutable tables and `deleted_at` to `recurring_rules`. Table names unchanged. | Spec 3.4: "UUID keys, updated_at, soft deletes" for future sync. |
| 24 | `day_rule` | Text enum with one value, `clampToMonthEnd`. | The spec names the behaviour; the enum leaves room for alternatives. |
| 25 | Import idempotency storage | Deferred to M5, which will ship as **schema v2 with a migration**. | Spec 3.3 says hashes are stored but names no column or table. Shipping it as a real migration also exercises the migration framework and golden gate end to end. |
| 26 | DAO scope | DAOs exist for accounts, categories, people, transactions, labels (tags+events), budgets and settings. Recurring, attachments and backup-meta DAOs land with their features (M3/M5). | Their tables exist now; writing DAOs before their callers would be speculative code. |
| 27 | Account presets | 13 presets with brand-adjacent colours and monograms (e.g. "MB", "JC") instead of logos. Presets also carry aliases ("United Bank Limited" → UBL) and drive `guessType` for imports. | Bank and wallet logos are trademarks; real assets need sourcing or permission before M7. |
| 28 | Account type guess | Spec rule plus two additions: a known preset name wins first, and names containing "saving" map to `savings`. | The real export has an account literally called "Savings". |
| 29 | Codegen | `build_runner` runs with `--force-jit` (locally). Drift's manager API is disabled (`generate_manager: false`). | AOT build-script compilation fails on this toolchain because of a dependency's build hooks. The manager API is unused and produced name-clash warnings. |
| 30 | Golden fixture form | M1's golden is a raw v1 SQLite file (`test/fixtures/golden/v1/kharcha.db`) with hand-computed `expected.json`. M5 adds `.kharcha` archive fixtures. | The archive format doesn't exist until M5; the database file is the part that migrations can break. |
| 31 | Standing-rule enforcement | `test/standing_rules_test.dart` fails CI on `double` in money/date/data/domain code, on network/analytics/ads imports, and on hand-rolled month arithmetic outside `BudgetCycle`. | It makes the spec's standing rules mechanical rather than relying on review. |

## M2 — Transactions & accounts

| # | Topic | Decision | Why |
|---|-------|----------|-----|
| 32 | PKR symbol | PKR is displayed as **"Rs"**, not "₨". `₨` is still accepted when parsing. | Manrope has no ₨ glyph, so phones substitute a condensed glyph from another font that clashed visibly (checked on the iOS simulator). "Rs" is what Pakistanis write and stays in the app's typeface. |
| 33 | Udhaar segment | The Add sheet ships Expense / Income / Transfer in M2. The **Udhaar** segment arrives in M3 with People. | Udhaar entries need the People module (spec M3). `person_id` is already preserved on edit. |
| 34 | Cross-currency entry | The keypad types into whichever amount is focused (sent or received). The **rate is derived** (received ÷ sent) and shown, not typed. | One keypad, fewer fields; the stored `fx_rate_micros` stays consistent with the two amounts by construction. |
| 35 | Category on save | A category is optional; Save needs only an amount and an account, so the fastest path is + → digits → Save. Tapping a selected category clears it. | Matches Hysab Kytab's "No Category" usage (859 of 1,710 rows in the real export). |
| 36 | List grouping | The Transactions list is grouped by **budget cycle** (sticky glass header, e.g. "25 Sep – 24 Oct"), then by day with daily totals. | Spec 3.4: every date grouping respects the month-start setting. |
| 37 | Paging | Pages of 60 entries; a page never ends mid-day, so daily totals on screen are always complete. | Correct totals without a separate aggregate query. |
| 38 | Search | `LIKE` matching (wildcards escaped) over note, place, category, both account names and tag names, plus an exact amount match when the text parses as money. No FTS table. | Fast enough at personal scale (10k rows) with no schema change. |
| 39 | Receipts | Compressed to ≤1600 px JPEG q75 in `<app documents>/receipts/`; SHA-256 stored. New images are compressed *before* the DB transaction, and partial files are cleaned up on any failure. Removing a receipt in an edit deletes its file. iOS camera/photo usage descriptions added. | Spec 1.5 #3 / 3.4. The end-to-end attach → backup → restore → view test lands in M5 with the backup archive. |
| 40 | Last-used account | Stored in `settings` as `last_account_id`; new entries default to it. | Spec 3.2 #3 "account (defaults last-used)". No schema change. |
| 41 | Home in M2 | Home shows net worth (with the hide-balance eye), this cycle's income / spent / left, an accounts carousel and the 5 most recent entries. Budgets and Udhaar cards come in M3. | With real data in M2, a "Coming soon" Home would hide it. |
| 42 | Hide balance | Masks net worth and account balances (Home and Accounts). Individual transaction amounts stay visible. | Spec quote: "hide 'what you have in all accounts'". |
| 44 | Navigation structure (fix after owner review) | Tabs are shell branches. **Every other page (Accounts, account form, transaction detail, Search) is a top-level route on the root navigator**, pushed full-screen over the shell. All bottom sheets open on the root navigator (`showAppSheet`). Pages paint their own ambient background, so they're opaque. | Owner saw rough transitions and a sheet hidden behind the glass nav bar. Root cause: transparent pages overlapped during push, cross-tab pushes switched tabs mid-animation, and sheets opened inside the tab under the floating bar. UI tests now fail on any mis-targeted tap. |
| 45 | Add / edit is a full screen (owner feedback) | The bottom sheet is replaced by `EntryEditorScreen`, pushed full-screen from `/add` and `/edit/:id`. Top to bottom: type picker → amount, with account and date chips → a **quick row of the 4 most-used categories + "All"** (full grid in a sheet) → Note / Tags / Receipt pills (each in its own small sheet) → keypad → a Save button that names the action ("Save expense"). Transfers swap the category row for From/To account cards with a swap button. Compact key height on short screens. | The sheet showed everything at once. One job per area keeps the 4-tap path (+ → amount → category → Save) and nothing is hidden off-screen on small phones. |
| 43 | Account currency change | Allowed in the edit form; existing transactions keep their stored `currency_code`. | Rare; a guard or conversion flow can come later if needed. |

## Open items carried forward

- **M5 importer input format:** the provided sample `specs/Hysab Kytab_ExportAll 2026-10-06 18-12-26.xls` is a real legacy **BIFF8 `.xls`** (CDFV2) file, not `.xlsx`. The `excel` package only reads `.xlsx`, so M5 needs a `.xls` (BIFF8) reader. It will be a pure-Dart, on-device reader, with no network.
- **Hysab Kytab sample findings (affect M5):** the type column is named `Voucher Type` (not `Type`); amounts are text such as `"-2520.0"`; the travel-currency columns are empty in this sample; and **people are stored as accounts**. 33 of the 37 HK "accounts" are people such as "Mudassir Bhai" and "Sannan", whose "transfers" are udhaar. M5 needs a rule (or a user prompt in the import preview) to map person-accounts to `people` rather than creating 33 fake accounts.
- **Seed data on first run:** a Cash account (PKR) is created at database creation. Onboarding (M6) changes its currency if the user picks another default.
