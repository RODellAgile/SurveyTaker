# Database reference

`Speakup/procs/` and `SurveyBank/procs/` hold the stored procedures the survey taker calls, scripted from the local restore on 2026-10-08. They are **reference copies** — the databases are the source of truth and this app never deploys them.

## Findings from reading the procs and data (2026-10-08)

Corrections to `docs/handoff-2026-10-08.md`:

- **No separate temp database.** "Temp" is the `answersDaily` table in the Speakup DB. `SaveAnswer` inserts into it, `DeleteQuestion` deletes from it, `RetrievePartialSurvey` reads it. The nightly job moves rows to the main answers table (answersDaily was empty in the restore).
- **`ChkSurveyId`, `GetSurveyDesc`, `GetSurveyToTake` live in SurveyBank.** `DeleteQuestion` exists in both DBs with identical text; the Speakup copy is the one whose `answersDaily` matters.
- **`GetOrganizationInfo` reads `Institution.dbo.Institution`** — the Institution DB must be restored locally for `/D/` links.
- **Questions per page is purely an app concern.** `StartNewSurvey` just stores `@quesperpage`; `GetSurveyToTake` returns every question with a constant `PageNumber = 1`. One-per-page needs no proc change. Last season already had 17,490 surveys with quesperpage = 1 (survey 195, the Q quick-start path), so the old app already handles 1-per-page restarts.
- **`required` already exists.** `QuestionBank.required` is returned by `GetSurveyToTake`; all 3,422 active questions are 0. Honor it when non-zero — no proc change needed.
- **Only 7 question types are used by active questions:** likertgrid (1,971), checkboxother (351), radio (177), checkbox (94), text (83), integer (52), radioother (49). `dropdownlist`, `grid`, `likert`, `verticalgrid` have no active questions. No question uses the `QuestionBank.stored_proc` column.
- **The hard-coded group-survey rule is stale.** Old code checks survey 6/55 and question 110/471. Today survey 6 is "Classic Speak Up 2024-25 9-12" (not a group survey), 55 is "HT3 3-5 Individual Spanish"; question 110 is on survey 22 (AI admin), 471 on surveys 24/25 (Spanish). The current non-archived group surveys (`surveys.GroupSurvey = 1`) are 116, 135, 151, 158, 174, 181 — the exact-sum rule does **not** fire for any of them today. Needs Bob's decision on what rule, if any, current group surveys need.
- `StartNewSurvey` returns `@@IDENTITY` (not `SCOPE_IDENTITY()`); fine unless a trigger is added to `users_surveys`.
