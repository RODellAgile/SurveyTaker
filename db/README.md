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

## Legacy call contract (from reading speakup2026 pages, 2026-10-08)

What the new app must reproduce so its rows match the old app's:

- **Connections:** everything on Speakup except `ChkSurveyId`, `GetSurveyDesc`, `GetSurveyToTake` and the intro/type reads of `surveys` (SurveyBank). `DeleteQuestion`/`SaveAnswer` use **Speakup**.
- **StartNewSurvey:** surveyname = `surveys.name`; surveytitle = `"Speak Up " + TextYear`; surveytype = raw `surveys.survey_type`; ip = the direct client address (REMOTE_ADDR, no X-Forwarded-For); quesperpage = 5 (the new app uses 1).
- **School link (/S/code/survey):** `SELECT Organization_Id, Registration_Id, RegistrantName, MailState FROM Registrations WHERE LinkCode = @linkcode` (no status filter, first row), then `GetOrganizationInfo @orgid`. LogEntryPoint `@reglinkcode`, `@survid` only if present, `@entrypoint='SCHOOLSTART'`.
- **District link (/D/code/survey):** `GetOrganizationInfo @linkcode`; LogEntryPoint `@orglinkcode`, `@entrypoint='DISTRICTSTART'`, no survid. School chosen from `GetInstInDistrict` (2nd result set).
- **Open checks, in order:** maintenance window (`MaintenanceStart < now < MaintenanceEnd` → maintenance page); season (`OpenDate > now || DistrictCloseDate < now` → closed); district (`GetDistrictOpenClose`: no row or both OpenDate and SurveyStatus empty → open; SurveyStatus set → it decides; else open between OpenDate 00:00:01 and CloseDate 23:59:59, closed message = `ClosedMessage` or a default date-range text).
- **Paging:** `SurveyRules.AssignPages` — ranges of Question_Sort, not question counts (ported exactly).
- **Saving a page:** for every question on the page `DeleteQuestion`, then `SaveAnswer` per row. Empty OptionId/OptionValue are sent as NULL.
  - checkbox/radio/likert/likertgrid/grid: one row per selected option, value NULL.
  - checkboxother: Other saved when ticked **or** text typed (value = trimmed text, NULL if empty); other selections value NULL.
  - radioother: typed Other text wins over the selected radio (only the Other row is saved); else the selected radio.
  - Other option = `SurveyRules.FindOtherOptionId` (starts with OTHER/OTR, last match wins — the interim fix of 2026-09-27).
  - integer: one row **per option, even blank** (value NULL when blank); legacy saved the untrimmed text unvalidated.
  - text: one row with OptionId NULL and the (untrimmed) text — **even when blank** (both NULL).
  - dropdownlist: always one row with the selected value (NULLs when nothing chosen). No active questions use it.
- **Progress:** legacy `UpdateSurveyProgress` sends quesoffset = 0 and quescompleted = 0 always, page = the page being moved to. Not called on the final Next.
- **Completion:** `MarkSurveyCompleted @quescompleted = total question rows from GetSurveyToTake` (grid sub-rows each count).
- **Restart:** `GetRestartInfo`; `completed = 'YES'` → don't reopen. Legacy forgot to read QuesPerPage on restart (every row became its own page); the new app honors the stored value.
- **Cookie:** `ProjectTomorrowSurvey` = TSI, 3 hours (set at start).
- **Logging:** legacy writes page events to proc `LogEntryEnhanced` (Page_File, Method, EntryType, IP, Referer, UserAgent, ValueName, Value, EntryText). Bob's log analysis uses this table.
- **Legacy kludges not ported unless Bob says so:** district link `5BF7` bypasses the season check; org 25690 relabels EDUCATOR as "Teacher"; VA uses deck `VA2022` for school survey types; survey 162 → LookupBuildingQS (page doesn't exist); group surveys hidden from the school survey list.
