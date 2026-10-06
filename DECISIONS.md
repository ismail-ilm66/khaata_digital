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
| 9 | Theme/locale persistence | `ThemeCubit` / `LocaleCubit` are in-memory in M0; default theme = system, default locale = English. | The `settings` table arrives in M1; persistence is wired then. |
| 10 | Theme/language toggles in M0 | More tab already has Theme (System/Light/Dark) and Language (English/اردو) selectors. | Needed to verify the M0 acceptance criterion ("both themes and both locales") on a device. |
| 11 | Generated code | `lib/core/l10n/gen/` and `*.config.dart` are generated (`flutter gen-l10n`, `build_runner`) and excluded from analysis. CI regenerates them. | Standard Flutter practice. |
| 12 | Extra platform folders | `linux/`, `macos/`, `web/`, `windows/` left untouched. | Spec targets Android and iOS only; removing generated folders is the owner's call. |
| 13 | Urdu font | M0 uses the platform's default Urdu font (Naskh on most Androids). | A Nastaliq font such as Noto Nastaliq Urdu is a polish item for the M6 RTL audit. |

## Open items carried forward

- **M5 importer input format:** the provided sample `specs/Hysab Kytab_ExportAll 2026-10-06 18-12-26.xls` is a real legacy **BIFF8 `.xls`** (CDFV2) file, not `.xlsx`. The `excel` package only reads `.xlsx`, so M5 needs a `.xls` (BIFF8) reader. It will be a pure-Dart, on-device reader, with no network.
