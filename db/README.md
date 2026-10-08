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
- **Group surveys – [DECIDED by Bob 2026-10-08].** A survey is a group survey when `SurveyBank.surveys.GroupSurvey = 1` (current non-archived: 116, 135, 151, 158, 174, 181). Before the questions, ask the number of respondents (2–999) and save it with `UpdateK2GrpCnt` → `users_surveys.k2grpcnt` (keep the old column name). Rule: each integer answer ≤ k2grpcnt, enforced on the server. The old hard-coded exact-sum check (survey 6/55, question 110/471) is **deprecated — do not port it**; those IDs now belong to unrelated surveys. Last season ~60% of group-survey starts recorded a count (e.g. 151: 150 of 218; 174: 256 of 401), values 2–800.
- `StartNewSurvey` returns `@@IDENTITY` (not `SCOPE_IDENTITY()`); fine unless a trigger is added to `users_surveys`.
