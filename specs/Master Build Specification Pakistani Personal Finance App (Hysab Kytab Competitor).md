# Master Build Specification: Pakistani Personal Finance App (Hysab Kytab Competitor)

## Executive summary

Build **Kharcha** (final name selection in Phase 2): an offline-first, Flutter-based personal finance app for Pakistan that keeps everything users love about Hysab Kytab — clean UI, PKR-native accounts (banks, Easypaisa, JazzCash, cash), budgets, lend/borrow tracking, free with no ads — and fixes the five failures that destroyed its rating: **unreliable backup/data loss, app abandonment, broken receipt attachment, rigid reporting (11-month cap, no custom date ranges, no custom month start), and forced/fragile login**.

The wedge is trust in data: Hysab Kytab's single most-upvoted review (55 thumbs) is a user who "lost most of my record of expenses after reinstalling." The spec below is the single source of truth for Claude Code — review analysis, ASO plan, product spec, data model (import-compatible with the Hysab Kytab Excel export), and an ordered milestone build plan with acceptance criteria. Build from this document without further clarification. Default assumptions where the brief was silent: currency defaults to PKR with multi-currency support, Android-first (Play Store) with iOS from the same Flutter codebase, and monetization is free at launch (optional Pro tier deferred to v2).

## Phase 1.1 — Complaint analysis (all \~1,100 attached reviews, 2017–2026)

Every attached review was read and tagged. Ranked below by a blend of frequency, severity (data loss > annoyance), and recency (2024–2026 reviews weighted highest because they describe the product users would compare us against today). Thumbs-up counts come from the `thumbsUpCount` column.

| #   | Theme                                                                                                                                                                                                                                       | Freq.                                          | Severity                                                                             | Representative quotes (verbatim)                                                                                                                                                                                                                                                                                                              |
| --- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------- | ------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | **Backup fails / data lost on device change**                                                                                                                                                                                               | \~120+ reviews, dominant in every year         | Critical — causes 1-star reviews and churn                                           | "I've lost most of my record of expenses after reinstalling" (55 👍, Apr 2025); "Every time I try to restore, it says 'invalid DB file'" (Oct 2025); "backups keep failing and I need web access" (13 👍); "lost my 4 years data with no help" (Jun 2022); "Reported a backup sync issue… 15 June… now 25 July, still no response" (Jul 2026) |
| 2   | **App abandoned — no updates, bugs never fixed**                                                                                                                                                                                            | \~30 reviews, all 2024–2026                    | Critical — kills trust & rating                                                      | "there is no update from the company since 2023" (2 👍); "like the empty ship in the middle of the sea, nobody there to handle the wheel" (2 👍, Dec 2025); "This app is not maintained anymore, I don't recommend using it" (3 👍); "Team please yar is ko update kr do 2023 k bd koi update ni aya" (3 👍)                                  |
| 3   | **Attach-receipt feature broken**                                                                                                                                                                                                           | \~20 reviews, 2021–2026                        | High — advertised feature that silently fails                                        | "when I click on 'Add Receipt' nothing happened"; "'Attach receipt' option is not working. Looks like a fake option"; "app get crash when I try to attach or take pic of receipt"                                                                                                                                                             |
| 4   | **Rigid reporting: only \~11 months history, no custom date range, no daily/weekly view**                                                                                                                                                   | \~45 reviews                                   | High — blocks tax filing & real analysis                                             | "I can't see my whole tax year insights properly" (10 👍); "it only shows last 11 months data" (5 👍); "add a filter to check income and expenses for specific periods such as 01 July to 15 July"; "PLEASE ADD A DATE FILTER"                                                                                                                |
| 5   | **No custom month start date (salary on 24th–26th)**                                                                                                                                                                                        | \~15 reviews, repeatedly promised since 2018   | High — core Pakistani salary use case                                                | "my month begins on 25th… budget and other things are not aligned at all"; "the app shows my transactions from a single salary in 2 different month's graphs"                                                                                                                                                                                 |
| 6   | **Forced login, OTP/sign-in failures, social-only auth**                                                                                                                                                                                    | \~35 reviews                                   | High — blocks first use entirely                                                     | "locked behind a mandatory login… app is absolutely unusable" (3 👍); "Can't signup without Google or Facebook or Apple!"; "didn't receive OTP for trying even 10 times"                                                                                                                                                                      |
| 7   | **Crashes & calculation bugs** (recurring tx crash, edit resets date, amounts change by themselves, transfer direction reversed, 4-digit/decimal input broken)                                                                              | \~40 reviews                                   | High                                                                                 | "whenever I try to add a recurring expense, the app crashes"; "When I update my old transaction, it is updating with current date"; "transfer from wallet 1 to wallet 2 it considered it as transferring from wallet 2 to wallet 1" (1 👍); "can't add transactions over four digits and no decimals anymore"                                 |
| 8   | **Deleted account name can't be reused** ("account already exists")                                                                                                                                                                         | \~12 reviews                                   | Medium — small bug, large irritation, acknowledged by devs in 2023 but never shipped | "I deleted an account… now the app indicates an account with this name already exists"                                                                                                                                                                                                                                                        |
| 9   | **No multi-currency accounts**                                                                                                                                                                                                              | \~25 reviews (freelancers earning USD/AED/RMB) | Medium-high — recurring since 2018                                                   | "I earn in Dollars, RMB, AED and PKR"; "a dollar account and other rupee accounts. How is that possible?" (8 👍)                                                                                                                                                                                                                              |
| 10  | **Missing quality-of-life features**: dark mode, hide-balance toggle, PDF export, subcategories, account reordering, widgets, search/tag filters, web version, shared/family accounts, credit-card handling, loan payable-receivable totals | \~130 reviews combined                         | Medium — each small, together they define the v2 backlog                             | "DARK MODE!!!!!!!!!!!" (5 👍); "hide 'what you have in all accounts' until I click" (1 👍); "exported file is also super raw" (10 👍); "option to arrange my accounts as I desire"                                                                                                                                                            |
| 11  | **Ads / "Deals & Flyers" backlash**                                                                                                                                                                                                         | \~25 reviews (2019 UI rewrite)                 | Historic but instructive — the 2019 monetization pivot caused a mass 5★→1★ wave      | "Is this an Ecommerce app or a money tracking app?"; "how is one supposed to save money if you keep showing them ads?" (5 👍)                                                                                                                                                                                                                 |
| 12  | **Unresponsive support**                                                                                                                                                                                                                    | \~25 reviews                                   | Medium — amplifies every other complaint                                             | "emailed you guys but no response yet" (2 👍); "No resolution or even response from Support team" after 4 escalations (1 👍)                                                                                                                                                                                                                  |

**Reading of the data:** the rating problem is not UI quality (users praise it) — it is _reliability and abandonment_. Fixing #1, #2, #6 and #7 alone would flip most 1-star reviews; #4, #5, #9 and #10 are the differentiating feature set.

## Phase 1.2 — What users consistently praise (must preserve or improve)

These show up in hundreds of 4–5★ reviews and are the retention core. Every one is a hard requirement for MVP.

1. **Simple, clean, ad-free UI.** "Clean and simple to use UI… Hands down best personal finance management apps I have used"; "No ads at all" — and the 2019 ads experiment proves the inverse. **Decision: no ads, ever, in the core app.**
2. **Pakistani-native accounts.** "money from various bank accounts, easypaisa and jazz cash account can be managed at one place"; repeated requests to add SadaPay, NayaPay, Meezan. **Decision: ship with a curated Pakistani bank/wallet picker (logos included) + custom account.**
3. **Budgets per category with progress bars.** "Budget allocation and tracking is awesome." Preserve, and add the repeatedly requested overall monthly budget and custom-cycle budgets.
4. **People / lend–borrow (udhaar) tracking.** "You can add receivables Payables Income and expenses. You can see your Equity" (3 👍). Pakistani users treat udhaar as first-class. Preserve, fix the direction/double-count bugs, and add the requested consolidated "who owes me / whom I owe" totals.
5. **Multiple accounts + transfers + net worth view.** Keep, add the requested "exclude account from total" and hide-balance toggle.
6. **Charts/insights by category.** Keep, extend with custom ranges and daily totals (top request).
7. **Excel export.** Keep, make it clean (totals, running balance, date-range pick) and add PDF.
8. **Free.** "the best thing is it's totally free of cost." Launch free; any Pro tier (v2) must never paywall data export or backup.

## Phase 1.3 — Hysab Kytab Today: Status, Ownership, and Why the Door Is Open

**Ownership & origin.** Hysab Kytab is a product of **Jaffer Business Systems (JBS)**, the Pakistani technology group led by CEO Veqar-ul-Islam. It launched in September 2017 as a free consumer budgeting app and grew to a claimed **640,000+ users across 160+ countries with 12M+ logged transactions** ([JBS solutions page](https://jbs.live/our-solutions/hysab-kytab)).

**The strategic pivot — the single most important competitive fact.** Around 2021–2022 the company repositioned Hysab Kytab as a **B2B white-label PFM engine sold to banks**, not a consumer product:

- **Feb 2022** — white-labelled PFM listed on **Temenos Exchange**, integrated with Temenos Infinity, giving it distribution to 3,000+ bank clients in 150 countries ([IBS Intelligence](https://ibsintelligence.com/ibsi-news/pakistans-hysab-kytab-goes-live-with-pfm-solution-on-temenos-exchange)).
- **Feb 2022** — partnership agreement with **Askari Bank** to embed PFM into its digital banking ([Finextra company news](https://www.finextra.com/company-news/8753/hysab-kytab)).
- **HBL** launched "Pakistan's first comprehensive PFM tool, powered by Hysab Kytab" inside its banking app, and **Bank of Punjab** integrated it via NdcTech ([TechJuice coverage](https://www.techjuice.pk/tag/hysab-kitab/)).
- JBS's own marketing now leads with the bank-facing PFM platform; the consumer app is described in legacy terms with no public roadmap.

**Consequence for the consumer app.** The Play Store app has been effectively frozen at v4.0.x since \~2023. The review corpus confirms the symptoms of abandonment: backup/restore failures unfixed for years, the receipt-attach feature broken since at least 2022, support unreachable (reviews as recent as Jul 2026 report no reply), and reviewers explicitly calling it dead ("empty ship in the middle of the sea"). Engineering attention moved to the bank-embedded product, where the revenue is.

**Pricing.** The consumer app is free with no in-app purchases. A 2019 experiment with ads ("Deals & Flyers") caused a ratings backlash and was rolled back. The B2B product is licensed to banks; pricing is not public.

**What this means for us:**

1. **The incumbent will not fight back.** JBS has no commercial incentive to resurrect the free consumer app — it would undercut its own bank customers' embedded PFM deployments.
2. **A warm, orphaned user base exists.** Hundreds of thousands of installs, years of logging habit, and no working migration path. Our one-tap **Hysab Kytab Excel import** (Section 10) is the highest-leverage acquisition feature we can ship.
3. **The bar is reliability, not features.** Users are not asking for AI insights; they are asking for backups that restore. We win by being dependable and visibly alive: frequent updates, answered reviews.

## Phase 1.4 — Competitor Landscape

Ratings are approximate Google Play figures as of late 2025/2026; verify at build time.

| App                                         | Rating / scale                                                                                                                                                                   | Standout strengths                                                                                                       | Gaps we exploit in Pakistan                                                                                                |
| ------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------- |
| **Hysab Kytab** (JBS, PK)                   | \~4.0★, 500K+ installs                                                                                                                                                           | Pakistani category/account vocabulary, People (udhaar) module, free, Excel export                                        | Abandoned; broken backup; forced login; no custom date ranges; no multi-currency                                           |
| **Money Manager** (Realbyte, KR)            | \~4.6–4.7★, 10M+ installs ([t-online test](https://www.t-online.de/finanzen/ratgeber/verbraucher/id_100488254/money-manager-ueberschaubar-und-fair-allerdings-nur-bedingt.html)) | Double-entry bookkeeping, subcategories, PC-over-WiFi view, strong stats                                                 | Korean-centric UX, no PKR/Urdu localization, no udhaar concept, dense UI intimidates casual users                          |
| **Wallet** (BudgetBakers, CZ)               | \~4.5★, 5M+ installs                                                                                                                                                             | Bank sync in 50+ countries, web app, shared wallets ([overview](https://getfinny.app/blog/best-money-manager-apps-2026)) | Subscription paywall on core features; bank sync excludes Pakistani banks, so its headline feature is dead weight here     |
| **Monefy** (Reflective Tech)                | \~4.4★, 10M+ installs                                                                                                                                                            | Fastest entry UX (one-tap pie), beloved simplicity                                                                       | Paid sync, no budgets-per-category depth, no lend/borrow tracking, no PK localization                                      |
| **Spendee** (CZ)                            | \~4.3★, 1M+ installs                                                                                                                                                             | Beautiful visual reports, shared wallets                                                                                 | Subscription-gated; bank sync not PK; weak offline story                                                                   |
| **CreditBook / Udhaar Book** (PK, adjacent) | 4.5★+, 5M+ installs                                                                                                                                                              | Roman-Urdu-first khata ledgers for shopkeepers; prove huge local demand for "hisaab" apps                                | B2B ledger intent (customer credit), not personal budgeting — different job; validates our keyword space without competing |

**Synthesis.** Global apps win on polish but all share three Pakistan-shaped blind spots: (1) **monetization models that paywall sync/backup** — unacceptable to a market anchored by free Hysab Kytab; (2) **bank-sync-centric value propositions that don't work with Pakistani banks**, leaving manual entry as the real UX battleground; (3) **no cultural fit** — no udhaar/People tracking, no Easypaisa/JazzCash presets, no Roman Urdu, no salary-date month cycles. Hysab Kytab had the cultural fit and squandered the reliability. **Our position: Hysab Kytab's cultural fit + Money Manager's reporting depth + Monefy's entry speed, free, offline-first, and actively maintained.**

## Phase 1.5 — Master Table: Every Major Complaint → Our Solution

This table is the contract between research and build. Every row's "Our solution" column is binding on Phases 3–4.

| #   | Complaint / gap (evidence)                                                                     | Our solution (binding design decision)                                                                                                                                                                                                                                                                                                                             |
| --- | ---------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 1   | Backup fails, data lost on reinstall/device change ("lost my 4 years data", "invalid DB file") | Three-layer safety net: (a) local SQLite with WAL + integrity check on open; (b) one-tap encrypted backup file to user's Google Drive **app-data-free, user-visible folder** with automatic weekly schedule; (c) restore flow tested in CI on every release with golden backup files from every prior schema version. Backup file format documented in Section 10. |
| 2   | App abandoned, zero updates since 2023                                                         | Operational commitment, not code: monthly release train, changelog in-app, every Play review ≤4★ answered within 72h (Section 7).                                                                                                                                                                                                                                  |
| 3   | Receipt attach broken ("Looks like a fake option")                                             | Receipts stored as compressed JPEG in app documents dir, row in `attachments` table, included in backup archive. Feature ships only with instrumentation test proving attach→backup→restore→view.                                                                                                                                                                  |
| 4   | Reports capped (\~11 months, no custom range, no daily view)                                   | Reports support Day / Week / Month / Year / **Custom range** / All-time. No history cap ever — SQLite handles decades of personal transactions trivially.                                                                                                                                                                                                          |
| 5   | No custom month start (salary on 24th–26th)                                                    | Settings → "Month starts on day N" (1–28). Every budget, report, and home summary respects it. Requested since 2018; we ship it in MVP.                                                                                                                                                                                                                            |
| 6   | Forced login, OTP failures, social-only auth                                                   | **No account required, ever.** App opens straight into use. Optional Google sign-in exists solely to enable Drive backup.                                                                                                                                                                                                                                          |
| 7   | Crashes & calculation bugs (recurring tx crash, edit resets date, reversed transfers)          | Money as integer paisa (no doubles), transfer stored as single double-entry record, edit screen snapshot-restores original values, recurring engine covered by unit tests incl. month-end edge cases (29–31st).                                                                                                                                                    |
| 8   | Deleted account name can't be reused                                                           | Soft-delete with `deleted_at`; unique constraint scoped to non-deleted rows. Name reuse works day one.                                                                                                                                                                                                                                                             |
| 9   | No multi-currency (freelancers: USD, AED, RMB)                                                 | MVP: account-level currency + manual rate on transfer, matching Hysab Kytab's own export columns (Travel Currency fields). v2: automatic rates.                                                                                                                                                                                                                    |
| 10  | Missing QoL: dark mode, hide balance, PDF export, subcategories, reordering, search            | MVP ships: dark mode, hide-balance toggle, full-text search, account/category reordering, CSV+Excel export. v2: PDF reports, subcategories, home widget (Section 8 roadmap).                                                                                                                                                                                       |
| 11  | 2019 ads backlash                                                                              | **No ads, ever** — stated in Play listing and in-app About. Monetization deferred; if ever added, cosmetic/optional only, never gating data features.                                                                                                                                                                                                              |
| 12  | Support unreachable                                                                            | In-app "Contact us" opens prefilled email with diagnostics (app version, DB integrity status, last backup date); public commitment to reply.                                                                                                                                                                                                                       |

## Phase 2.1 — ASO: Candidate Names

Search behavior in Pakistan mixes English ("budget app", "expense tracker") with Roman Urdu ("hisab", "kharcha", "paisa", "bachat"). The name must carry a high-intent Roman Urdu keyword in the title itself (title keywords carry the most ASO weight) while staying pronounceable and brandable.

| Candidate     | Meaning / keyword value                                                                                                     | Availability & conflict check                                                                                                                                                                                                                   | Verdict                                    |
| ------------- | --------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------ |
| **Kharcha**   | "Expense/spending" — the exact word Pakistanis use for daily spending; high search intent, zero ambiguity about app purpose | No major Play Store budgeting app owns this word; a few tiny utilities use it in long titles, none with brand equity. Trademark risk low (descriptive + distinctive combo with suffix).                                                         | ✅ **Recommended**                         |
| Mera Hisaab   | "My account/tally" — strong keyword "hisaab"                                                                                | "Hisaab/Hisab" space is crowded by shopkeeper khata ledger apps (CreditBook, Udhaar Book clones); search intent skews B2B credit ledger, not personal budgeting; also collides with Hysab Kytab's own brand spelling, inviting confusion/claims | ❌ Keyword captured in description instead |
| Bachat        | "Savings" — aspirational                                                                                                    | **Conflict:** Bachat is an existing funded Pakistani fintech (digital committees/ROSCA); direct brand collision                                                                                                                                 | ❌ Eliminated                              |
| Paisa Track   | "Paisa" = money; bilingual compound                                                                                         | "Paisa" heavily colonized by loan/earning/rewards apps (often low-trust); adjacency damages a finance app whose whole pitch is trust                                                                                                            | ❌                                         |
| Roz Ka Hisaab | "Daily tally" — long-tail phrase match                                                                                      | Too long for a brand, weak as an icon word; better used verbatim as a keyword phrase in the full description                                                                                                                                    | ❌ Keyword only                            |

**Decision: the app is named `Kharcha`.** Play Store title (≤30 chars): **"Kharcha: Budget & Hisab Kitab"** (29 chars) — brand + top English keyword + the Roman Urdu phrase users actually type, legitimately descriptive. All subsequent sections use this name. (Final legal/trademark search before publishing is a launch-checklist item, Section 16.)

## Phase 2.2 — Full Play Store Listing

**Title (29/30 chars):** `Kharcha: Budget & Hisab Kitab`

**Short description (79/80 chars):** `Expense tracker & budget app for Pakistan. Offline, free, backup that works.`

**Full description (keyword-optimized, \~2,900/4,000 chars):**

> **Kharcha — the budget & expense tracker made for Pakistan 🇵🇰**
>
> Track your daily kharcha, manage your monthly budget, and keep your hisab kitab in one simple, fast, offline app. No login required. No ads. Free.
>
> **Why Kharcha?** ✔️ Works 100% offline — add expenses anywhere, instantly ✔️ Backup that actually works — one tap to your own Google Drive, restore on any phone ✔️ No forced sign-up — open the app and start ✔️ Made for Pakistani money life — PKR default, Easypaisa, JazzCash, SadaPay, NayaPay & bank accounts built in
>
> **Expense tracker & money manager** Add an expense in under 3 seconds. Categories for grocery, petrol, bills, school fees, rent and more — or make your own. Attach receipts. Search any transaction.
>
> **Budget planner (monthly budget app)** Set a budget for each category or your whole month. Progress bars show what's left. Start your month on your salary date — 1st, 25th, any day you choose.
>
> **Udhaar & lena dena (People)** Lent money to a friend? Borrowed from family? Track udhaar both ways and always know who owes whom.
>
> **Reports & insights** Daily, weekly, monthly, yearly or any custom date range. Pie charts and trends for income vs expense. Your full history, never cut off.
>
> **Multiple accounts & transfers** Cash, bank accounts, mobile wallets, savings — see each balance and your total net worth. Hide balances with one tap.
>
> **Your data is yours** Export to Excel/CSV anytime. Import your old Hysab Kytab export in one tap and keep your years of records.
>
> Roz ka hisab, asaan. Download Kharcha free today — daily expense tracker, paisa manager, budget planner aur hisab kitab app for Pakistan.

**Keyword list** (woven into description; never keyword-stuff beyond this):

- English: expense tracker, budget app, money manager, budget planner, expense manager, daily expenses, spending tracker, personal finance, PKR
- Roman Urdu: kharcha, hisab, hisab kitab, hisaab, udhaar, lena dena, paisa, bachat, roz ka hisab, mahana budget

**Screenshot sequence (phone, 1080×1920, captioned top-band, Urdu-flavored English):**

1. Home dashboard — "Apka poora kharcha, aik nazar mein" (balance, month summary, recent transactions)
2. Add-expense sheet — "Add an expense in 3 seconds"
3. Budgets screen with progress bars — "Set budgets. Stay on track."
4. Reports with custom date range — "Any date range. Full history."
5. People/udhaar screen — "Udhaar ka hisab, both ways"
6. Backup screen — "One-tap backup to YOUR Google Drive"
7. Accounts with Easypaisa/JazzCash/bank logos — "All your accounts in one place"
8. Dark mode collage — "Dark mode included"

**Icon direction:** bold rounded square, deep green (#0E7C4A — money/Pakistan association) with a white stylized rupee ₨ forming a rising tick/chart line. No text in icon. Must read clearly at 48px.

**Feature graphic (1024×500):** green gradient, phone mockup of home screen right-aligned, left text: "Kharcha — Pakistan ka budget app. Offline · Free · No login."

## Phase 2.3 — Launch & Ranking Tactics

**Review generation (the ethical flywheel):**

- In-app review prompt (Google Play In-App Review API) triggered only at genuine success moments: after the user's **first successful backup restore**, after 30 days of active use, or after completing a month under budget. Never on launch, never after a crash session.
- "Enjoying Kharcha?" pre-prompt with two paths: happy → Play review; unhappy → in-app feedback email. (Standard, compliant routing — we never gate or incentivize reviews.)

**Update cadence (directly attacks complaint #2):**

- Monthly release train minimum for the first 12 months, even if a release is only fixes. "What's new" text written for humans and localized (English + Urdu).
- Publish a lightweight public roadmap/changelog page linked from the app; reviewers repeatedly cited silence as proof of abandonment.

**Review reply policy:**

- Every 1–3★ review answered within 72 hours with a concrete response (not boilerplate), including the fix version when shipped. Replying to reviews measurably converts updated ratings; Hysab Kytab's unanswered reviews are our recruiting ground.
- Maintain a saved-reply library for the top 12 complaint categories from Phase 1.1.

**Localization:**

- Store listing localized in **English (default)** and **Urdu**; app ships with English + Urdu (RTL) from MVP (Section 14 covers implementation).
- Roman Urdu is intentionally used inside the English listing copy (that is how people type searches), while the Urdu listing uses proper script.

**Launch sequence:**

1. Closed testing (20+ testers, 14 days — current Play policy for new personal accounts), recruiting from personal-finance Facebook groups and r/pakistan threads where Hysab Kytab refugees already complain.
2. Open beta with the Hysab Kytab import as the headline hook: "Apna purana Hysab Kytab data wapas lao."
3. Production launch + Product Hunt/Pakistani tech press pitch (TechJuice, ProPakistani) angled as "the app that rescues your abandoned budgeting data."
4. First 90 days: weekly triage of all reviews → fixes feed the monthly train; target ≥4.5★ before any paid acquisition is even considered.

## Phase 3.1 — Product Spec: MVP Feature Set & v2 Roadmap

Every MVP feature below is justified by Phase 1 evidence (complaint # or praise item). If a feature has no evidence tag, it does not ship in MVP.

**MVP (v1.0) — "Reliable Hysab Kytab":**

1. **Transactions**: expense / income / transfer with amount, account, category, date-time, note, tags, People link, receipt photo. 3-second entry path. _(Praise: entry speed; Complaints 3, 7)_
2. **Accounts**: unlimited; curated Pakistani picker (Cash, Easypaisa, JazzCash, SadaPay, NayaPay, Meezan, HBL, UBL, MCB, Allied, Bank Alfalah, Askari, Standard Chartered + custom); per-account currency; exclude-from-total flag; reorder; archive (soft-delete). _(Praise: PK accounts; Complaint 8)_
3. **Transfers**: single double-entry record; optional cross-currency with manual rate. _(Complaints 7, 9)_
4. **Categories**: seeded Pakistani set mirroring Hysab Kytab's export vocabulary (Food & Drink, Fuel & Maintenance, Bills & Utilities, School Fee, Rent, Zakat & Charity, Loan Given/Received, Savings…), custom add/edit/reorder/archive, icon + color. Subcategories deferred to v2.
5. **Budgets**: per-category and overall-month; progress bars; configurable month start day (1–28). _(Praise: budgets; Complaint 5)_
6. **People (udhaar)**: contacts with running two-way balance (maine diya / maine liya), settle-up action, consolidated "total receivable / total payable" header. _(Praise: People module + its bug reports)_
7. **Reports**: income vs expense, category pie, trend line; Day/Week/Month/Year/Custom/All-time; filter by account, category, tag, person; no history cap. _(Complaint 4)_
8. **Search**: full-text across note, amount, category, tag, person. _(QoL #10)_
9. **Backup & restore**: local encrypted archive export + Google Drive one-tap backup, weekly auto-backup, restore wizard with preview. _(Complaint 1 — flagship)_
10. **Import**: Hysab Kytab Excel/CSV import (Section 10 mapping); generic CSV import with column mapper.
11. **Export**: Excel (.xlsx) matching Hysab Kytab's column layout + plain CSV. _(Praise: export)_
12. **Security**: optional app lock (PIN + biometric). No account/login anywhere. _(Complaint 6)_
13. **Personalization**: dark/light/system theme; hide-balance toggle; English + Urdu (RTL). _(QoL #10)_
14. **Recurring transactions**: templates with daily/weekly/monthly/yearly rules, month-end-safe. _(Complaint 7)_
15. **Bill reminders**: local notifications tied to recurring templates.

**v2 roadmap (ordered by review demand):**

1. PDF report export
2. Subcategories
3. Home-screen widgets (balance + quick add)
4. Automatic multi-currency rates
5. Savings goals
6. Shared/family book (export-import based first; sync later)
7. SMS-parse assisted entry for bank/wallet SMS (on-device only, permission-gated)
8. Web/desktop read-only viewer

**Explicit non-goals (v1–v2):** bank account linking/open banking (infrastructure doesn't exist for PK consumers), server-side accounts and cloud sync service (reintroduces the trust problem we're attacking), ads, paywalls on data features, AI chat.

## Phase 3.2 — Screen-by-Screen Specification & Flows

Navigation: bottom bar with 5 tabs — **Home · Transactions · (+) Add · Reports · More**. Budgets, People, Accounts live on Home cards and under More.

**1. Onboarding (first run only, 3 screens, skippable):** value promise → choose currency (PKR preselected) + month start day → optional "Import from Hysab Kytab?" and "Enable app lock?". No login screen exists. Lands on Home with a seeded Cash account.

**2. Home:** header with net worth (eye icon toggles hide-balance), month selector respecting custom start day; cards: This Month (income/expense/left), Budgets preview (top 3 bars), Accounts carousel, Udhaar summary (receivable vs payable), Recent transactions (5). Pull-to-refresh recomputes. FAB mirrors the Add tab.

**3. Add Transaction (modal sheet, the 3-second path):** segmented Expense | Income | Transfer | Udhaar. Numeric keypad open immediately; amount → category grid (2 taps) → Save. Collapsed "More" section: date-time (defaults now), account (defaults last-used), note, tags, person, receipt camera/gallery, recurring toggle. Transfer mode: from-account, to-account, optional rate + foreign amount when currencies differ. Editing an existing transaction opens the same sheet **pre-filled with its stored values — the date never resets to today** (Complaint 7).

**4. Transactions list:** grouped by day with daily totals (requested in reviews); sticky month header; filter chips (account, category, tag, person, type); search icon → full-text search screen; swipe left delete (undo snackbar), swipe right edit; tap → detail with receipt viewer.

**5. Accounts:** list with balances + net worth footer; drag-to-reorder; add flow = curated Pakistani picker with logos + "Custom"; edit: name, type (cash/bank/wallet/card/savings), currency, opening balance, exclude-from-total, archive. Archived section collapsed at bottom; archived names reusable (Complaint 8).

**6. Budgets:** month navigator (custom cycle); overall budget card; per-category rows with progress bars (green <80%, amber 80–100%, red >100%); tap category → its transactions this cycle; "Copy last month" action.

**7. People (Udhaar):** two totals pinned on top: "Aap ko milne hain ₨X" / "Aap ne dene hain ₨Y"; person rows with net balance and direction color; person detail: ledger of give/take/settle entries with running balance; actions: I gave / I received / Settle up. Every entry is also a normal transaction against a chosen account, so account balances stay truthful (fixes double-count bug class).

**8. Reports:** range selector Day/Week/Month/Year/Custom/All; charts: category donut (tap slice → drill-down), income-vs-expense bars, balance trend line; filters as in list; export button (Excel/CSV of the filtered view).

**9. Backup & Restore (under More, also surfaced as Home banner if no backup in 14 days):** status card ("Last backup: date · location"); Backup now (local file via SAF or Google Drive); auto-backup toggle (weekly, Wi-Fi only option); Restore: pick file → preview (counts of accounts/transactions/date range) → confirm replaces or merges; result screen confirms integrity check.

**10. More/Settings:** import (Hysab Kytab / generic CSV), export, categories manager, recurring manager, reminders, app lock, theme, language (English/اردو), month start day, hide balance, About (version, changelog, contact-us prefilled email, "No ads, ever" statement).

**Key flows (acceptance-level):**

- _Fresh install → first expense logged:_ ≤ 4 taps after onboarding skip.
- _Hysab Kytab refugee:_ onboarding import → file picker → mapping preview (auto-detected) → import → Home shows historical data; total time < 2 min for 10k rows.
- _Device change:_ old phone Backup now → Drive; new phone install → Restore → identical net worth figure, byte-identical receipt images.
- _Salary-cycle user:_ sets month start = 25; Home, Budgets, Reports all show "25 Sep – 24 Oct" as the current month.

## Phase 3.3 — Data Model (Import-Compatible with Hysab Kytab)

All money amounts are **integer minor units (paisa)**, `amount_minor BIGINT`, sign always positive with direction carried by `type` — never floating point (Complaint 7's "amounts change themselves" class is float arithmetic). Timestamps are UTC epoch millis; display converts to local.

**Tables (SQLite via Drift; names final):**

| Table                       | Key columns                                                                                                                                                                                                                                                                      | Notes                                                                                     |
| --------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| `accounts`                  | id (uuid), name, type (cash/bank/wallet/card/savings), currency_code, opening_balance_minor, icon, color, sort_order, exclude_from_total (bool), deleted_at (nullable)                                                                                                           | Unique index on `(name) WHERE deleted_at IS NULL` — deleted names reusable                |
| `categories`                | id, name, kind (expense/income), icon, color, sort_order, parent_id (nullable, v2 subcategories), deleted_at                                                                                                                                                                     | Seed set mirrors Hysab Kytab vocabulary incl. literal `No Category`                       |
| `transactions`              | id, type (expense/income/transfer/adjustment), amount_minor, currency_code, account_id, to_account_id (transfers), to_amount_minor + fx_rate_micros (cross-currency), category_id (nullable), person_id (nullable), occurred_at, note, place, created_at, updated_at, deleted_at | One row per transfer (double-entry derived in queries) — kills reversed/double-count bugs |
| `tags` / `transaction_tags` | id, name / (transaction_id, tag_id)                                                                                                                                                                                                                                              | Hysab Kytab `Tags` column is comma-separated → split on import                            |
| `events`                    | id, name + `transaction_events` join                                                                                                                                                                                                                                             | Maps Hysab Kytab `Events` column                                                          |
| `people`                    | id, name, contact_hint, deleted_at                                                                                                                                                                                                                                               | Balance = SUM over linked transactions; never stored                                      |
| `attachments`               | id, transaction_id, file_name, mime, byte_size, sha256                                                                                                                                                                                                                           | Files under `appdocs/receipts/`; sha256 verified on restore                               |
| `budgets`                   | id, category_id (nullable = overall), amount_minor, cycle_year, cycle_month                                                                                                                                                                                                      | Cycle resolved against month-start setting                                                |
| `recurring_rules`           | id, template (json of transaction fields), freq, interval, day_rule (clamp-to-last-day), next_run_at, end_at                                                                                                                                                                     | Month-end-safe by design                                                                  |
| `settings`                  | key, value                                                                                                                                                                                                                                                                       | month_start_day, theme, locale, hide_balance, lock_enabled…                               |
| `backup_meta`               | id, created_at, destination, schema_version, row_counts (json)                                                                                                                                                                                                                   | Shown in Backup status card                                                               |

**Hysab Kytab Excel import mapping** (source columns verified from the user-provided export sample):

| Hysab Kytab column                               | → Our field             | Transform                                                                                                              |
| ------------------------------------------------ | ----------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| Type (`Expense`/`Income`/`Transfer`)             | transactions.type       | lowercase                                                                                                              |
| Voucher Date (`DD/MM/YYYY`)                      | occurred_at             | parse day-first; midday local time to dodge TZ drift                                                                   |
| Voucher Amount (expenses negative)               | amount_minor            | `abs(value) × 100`, rounded; sign discarded (type carries it)                                                          |
| Description                                      | note                    | trim                                                                                                                   |
| Category Name                                    | category_id             | match case-insensitive on seeded+existing; else create; blank/`No Category` → null                                     |
| Account Name                                     | account_id              | match else create (type guessed from name: contains "bank"→bank, Easypaisa/JazzCash/SadaPay/NayaPay→wallet, else cash) |
| Tags                                             | transaction_tags        | split `,`, trim, dedupe                                                                                                |
| Events                                           | transaction_events      | same                                                                                                                   |
| Place                                            | place                   | as-is                                                                                                                  |
| Travel Currency Rate/Symbol/Amount/Location/Date | fx fields + note suffix | symbol→ISO lookup; rate→fx_rate_micros; amount→to_amount_minor; location/date appended to note                         |
| Transfers (exported as paired rows)              | single transfer row     | pair matcher: same date+amount, opposite signs, within file order; unpaired → adjustment with warning in import report |

Import is **idempotent**: a content hash per source row is stored; re-importing the same file creates zero duplicates. Import ends with a report screen (rows imported / merged / skipped / warnings) and an automatic pre-import backup.

**Export** writes the same column layout back (Excel + CSV), so a Kharcha export is itself re-importable into Kharcha — and even into Hysab Kytab. Users are never locked in; that asymmetry of confidence is a marketing point.

## Phase 3.4 — Offline-First, Backup/Restore & Sync Strategy

**Offline-first is absolute.** Every feature works with airplane mode on. Network is used for exactly two optional things: Google Drive backup and (v2) currency rates. No analytics SDK that blocks, no remote config gating features, no login.

**Backup architecture (the flagship fix for Complaint 1):**

- Backup file = single `.kharcha` archive: ZIP containing `data.db` (vacuumed SQLite snapshot), `receipts/` (all attachments), `manifest.json` (schema_version, app_version, created_at, row counts, per-file sha256).
- Optional encryption: AES-256-GCM with a user passphrase; manifest stays cleartext so restore can preview without the key.
- Destinations: (a) **local file via Android Storage Access Framework** — user picks the folder, file is theirs, survives uninstall; (b) **Google Drive** into a visible `Kharcha Backups/` folder in the user's own Drive — _never_ the hidden appDataFolder, because invisible backups are exactly what burned Hysab Kytab users ("invalid DB file", unrestorable). Users can see, copy, and email the file.
- Auto-backup: weekly WorkManager job (charging + unmetered constraints configurable), retains last 8, nudge banner on Home after 14 backup-less days.
- **Restore correctness is a release gate:** CI keeps a corpus of golden backup files from every schema version ever shipped; every release must restore all of them and reproduce known account balances to the paisa. A migration that breaks a golden file cannot ship.
- Restore flow verifies manifest hashes, runs `PRAGMA integrity_check`, imports into a temp DB, and only then atomically swaps — a failed restore can never destroy existing data.

**Sync strategy (deliberate minimalism):** no real-time multi-device sync in v1/v2-early. Rationale: sync servers are the trust liability and cost center that pushed competitors to subscriptions and Hysab Kytab to logins. Multi-device story = backup/restore (manual or auto). The schema is sync-ready for the future (UUID keys, `updated_at`, soft deletes allow last-write-wins merge) so v3 sync is an addition, not a rewrite.

**Complaint-driven design decisions recap (binding):** integer paisa math; single-row transfers; edit sheet pre-filled from stored values; soft-delete with scoped unique names; no history caps anywhere; month-start setting respected by every date computation through one shared `BudgetCycle` utility (never ad-hoc date math); receipts inside the backup archive; no login; no ads.

## Phase 4.1 — Technical Specification (Flutter)

**Stack decisions (final):** Flutter stable (latest), Dart 3.x, Android-first (minSdk 23, target latest); iOS kept compiling but unreleased in v1. Clean Architecture, feature-first, with BLoC.

**Project structure:**

```
lib/
  core/
    db/              # Drift database, migrations, golden-backup test hooks
    money/           # Money value type (int paisa), formatting, PKR defaults
    dates/           # BudgetCycle (month-start logic) — the ONLY date-cycle code
    di/              # get_it + injectable setup
    l10n/            # ARB files en/ur, RTL helpers
    theme/           # light/dark themes, Pakistani-green palette
    widgets/         # shared UI (AmountText, CategoryIcon, EmptyState…)
    error/           # Failure types, Result<T>
  features/
    transactions/
      data/          # DAOs, repositories impl, DTOs
      domain/        # entities, repository interfaces, use cases
      presentation/  # blocs, screens, widgets
    accounts/ · categories/ · budgets/ · people/ · reports/
    backup/ · import_export/ · recurring/ · settings/ · onboarding/ · security/
  app.dart           # MaterialApp.router, theme, locale
  main.dart          # DI init, DB open + integrity check, run
```

**BLoC map (flutter_bloc; one Bloc per screen responsibility, Cubits for simple toggles):**

| Bloc                                                                       | Events (→) / emits                                                             | Notes                                       |
| -------------------------------------------------------------------------- | ------------------------------------------------------------------------------ | ------------------------------------------- |
| `TransactionFormBloc`                                                      | Started(existing?), FieldChanged, Submitted → Initial/Valid/Saving/Saved/Error | Pre-fills from entity on edit (Complaint 7) |
| `TransactionListBloc`                                                      | Load, FilterChanged, SearchChanged, Delete, Undo → paginated grouped state     | Streams from Drift `watch`                  |
| `AccountsBloc`, `CategoriesBloc`                                           | CRUD + Reorder + Archive                                                       | Soft-delete rules here                      |
| `BudgetsBloc`                                                              | CycleChanged, SetBudget, CopyLast → per-category progress                      | Uses `BudgetCycle` only                     |
| `PeopleBloc` / `PersonLedgerBloc`                                          | Give/Receive/Settle → balances derived                                         | Writes via transactions use case            |
| `ReportsBloc`                                                              | RangeChanged, FiltersChanged → chart datasets                                  | All SQL aggregation in DAO                  |
| `BackupBloc`                                                               | BackupNow(dest), RestoreRequested(file), AutoToggled → progress/result         | Long ops in isolate                         |
| `ImportBloc`                                                               | FilePicked, MappingConfirmed, Run → report state                               | Parsing in isolate                          |
| `RecurringBloc`, `SettingsCubit`, `LockCubit`, `ThemeCubit`, `LocaleCubit` | —                                                                              |                                             |

**Database — decision: Drift (over Isar and Hive).** Justification: (1) reports, budgets, and People balances are relational aggregations — Drift gives typed SQL, joins, and `watch()` streams for free; Hive has no queries and Isar's maintenance/fork situation is a risk for a decade-horizon finance app; (2) Drift sits on SQLite — the most battle-tested storage on Android, with `integrity_check`, `VACUUM INTO` for snapshot backup, and trivially portable files (our whole backup story leans on this); (3) first-class migration framework with step-by-step tests — the exact capability whose absence killed Hysab Kytab backups.

**Key packages (pinned at project init):** `flutter_bloc`, `drift` + `sqlite3_flutter_libs`, `get_it` + `injectable`, `go_router`, `fl_chart` (charts; pure-Dart, themeable), `intl` + `flutter_localizations` (en + ur, RTL), `flutter_local_notifications` + `workmanager` (reminders, auto-backup), `local_auth` (biometric), `file_picker` + SAF, `googleapis` + `google_sign_in` (Drive scope only), `excel` (xlsx read/write), `csv`, `image_picker` + `flutter_image_compress` (receipts), `archive` + `cryptography` (backup zip + AES-GCM), `equatable`, `uuid`, `freezed`.

**Testing strategy (quality bars are release gates):**

- Unit: Money arithmetic, BudgetCycle (incl. month-start 25 + Feb + leap years), recurring date rules, import parsers (fixture files incl. the real Hysab Kytab sample), transfer pairing.
- DAO tests on in-memory SQLite: balance aggregation, soft-delete uniqueness, report queries.
- Bloc tests (`bloc_test`) per feature.
- Golden-backup CI suite: restore every historical schema's backup fixture → assert balances.
- Integration (`patrol`/`integration_test`): add-edit-delete flow, backup→wipe→restore, import 10k-row file under 2 min, lock screen, Urdu RTL smoke.
- Coverage gate 80% on `core/` and `domain/`; CI = GitHub Actions (analyze, test, build AAB).

## Phase 4.2 — Milestone Build Plan for Claude Code

Execute strictly in order; do not start a milestone until the previous one's acceptance criteria pass. Each milestone ends with `flutter analyze` clean and all tests green.

**M0 — Project foundation (scaffolding).** Create Flutter project `kharcha`; folder structure per 4.1; DI with get_it/injectable; go_router shell with bottom nav; light/dark theme; en+ur l10n wiring; CI workflow (analyze, test, build AAB). ✅ _Accept:_ app boots to empty tabbed shell in both themes and both locales; CI green.

**M1 — Core domain & database.** `Money` type (int paisa) with parser/formatter (₨, Urdu digits optional); `BudgetCycle` with month-start-day; full Drift schema from 3.3 + DAOs; seed data (PK accounts picker data, Hysab-compatible categories); migration framework + first golden backup fixture. ✅ _Accept:_ unit+DAO tests pass incl. month-start=25 Feb/leap cases; balances aggregate correctly on 10k generated rows.

**M2 — Transactions & accounts.** Add/edit/delete expense, income, transfer (single-row, cross-currency manual rate); accounts CRUD with picker, reorder, archive, exclude-from-total; transactions list with grouping, daily totals, filters, search; receipt attach (compress, store, view). ✅ _Accept:_ 3-second entry path ≤4 taps; edit re-opens with stored date; archived account name reusable; transfer shows once, balances move correctly both sides.

**M3 — Budgets, People, recurring, reminders.** Budgets per category + overall with progress and copy-last; People ledger with give/receive/settle writing real transactions; recurring engine + WorkManager materialization; bill reminder notifications. ✅ _Accept:_ budget bars respect custom month start; People totals match sum of ledger; recurring on the 31st clamps correctly; reminder fires in integration test.

**M4 — Reports & export.** fl_chart donut/bars/trend; Day/Week/Month/Year/Custom/All ranges with filters; Excel+CSV export of filtered view and full book in Hysab Kytab column layout. ✅ _Accept:_ report numbers reconcile with DAO sums to the paisa; exported file re-imports with zero diff (round-trip test).

**M5 — Backup, restore, import (flagship).** `.kharcha` archive build (VACUUM INTO + receipts + manifest, optional AES-GCM); SAF local + Google Drive visible-folder destinations; weekly auto-backup; restore wizard with preview, hash+integrity verification, atomic swap; Hysab Kytab importer (full 3.3 mapping, transfer pairing, idempotent hashing, report screen) + generic CSV mapper. ✅ _Accept:_ backup→uninstall→reinstall→restore reproduces exact balances and byte-identical receipts; the provided real Hysab Kytab sample imports with correct types, dates, tags, travel-currency fields; re-import creates 0 duplicates; 10k rows < 2 min.

**M6 — Security, settings, onboarding, polish.** PIN+biometric lock; hide-balance; settings (theme, locale, month start, data tools); 3-screen onboarding with import hook; empty states, undo snackbars, error surfaces; Urdu RTL audit of every screen. ✅ _Accept:_ lock gates cold start and resume; every 3.2 screen matches spec; RTL smoke test passes.

**M7 — Release readiness.** Golden-backup CI suite wired as gate; coverage ≥80% core/domain; crash-free instrumentation run of key flows; Play assets from 2.2 (listing text final, screenshots captured, icon, feature graphic); privacy policy page (no data leaves device except user-initiated Drive backup); closed-testing AAB. ✅ _Accept:_ `flutter build appbundle --release` signed; all 2.2 launch-sequence prerequisites checked; this document's Phase 1.5 table reviewed row-by-row — every "Our solution" is demonstrably implemented or explicitly deferred with a tracked issue.

**Standing rules for Claude Code:** never introduce `double` for money; all cycle math through `BudgetCycle`; every schema change ships with a migration + new golden backup fixture; no feature lands without its tests; no network calls outside backup/Drive; no login, no ads, no analytics SDKs in v1.
