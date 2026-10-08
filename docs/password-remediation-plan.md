# Plain-text password remediation – plan (draft 2026-10-08)

Scope: the legacy Speak Up site (`speakup2026` repo), which is live and stays live until the new admin site replaces it. SpeakupSurveyBank2024 never touches these columns. SurveyTaker never reads them.

Sources: DB inventory (41 procs, scripted to `db/Speakup/password-procs/`) and a full code search of speakup2026 (2026-10-08).

## What exists today

| Column | Rows with a value (2026-27 DB) | What it is |
|---|---|---|
| `Organizations.AdminPassword` | 215 | District admin login |
| `Registrations.LocalAdminPassword` | 69 | School admin login |
| `Organizations.SurveyPassword`, `Registrations.LocalSurveyPassword` | 562 / 988 | Shared "secret word" respondents once typed. **No survey page checks it any more** (all entry is by link code). Still displayed, emailed, exported. |
| `LogIn_Additional.password`, `Regions.Login_Password`, `StatePasswords.*` | 0 locally (check production) | Extra district/school logins, regional reports, state reports |

- All login checks compare the plain text **inside SQL** (`WHERE AdminPassword = @password`).
- `LoginSchAdmin` uses the password to pick **which** record an email belongs to: 6 emails are shared by several districts/schools (up to 11 records each).
- `AdminPassword_Changed` is a date. NULL means "temporary password, must change at next login", and the login page already enforces that (61 districts, 62 schools are in that state).

## Urgent: holes that are exploitable now (independent of hashing)

1. **Forgot-password takeover.** `AdminLogin.aspx` puts the 6-digit reset code in a hidden label, so it's in ViewState in the page sent to the browser. It also writes the code to SpeakupLog. Anyone who knows a district contact's email can read the code and set a new password. **Fix:** keep the code server-side (hashed, 15-minute expiry, 5 attempts) and stop logging it.
2. **Password-mailing pages with no login.** `RetrieveDistPassword.aspx` (linked from EditPubDistrict) and `RetrieveBldgPassword.aspx` email the current admin and survey passwords to the contact on anyone's request. **Fix:** remove both and point the links at the AdminLogin forgot-password flow.
3. **`AdminMenuSch.aspx` shows the school's admin password** and only checks `Session["RegisterID"]`. **Fix:** remove the password label.
4. **Staff admin login is one hard-coded password in C#** (`Admin/Default.aspx.cs`), committed to GitHub. The SQL login password in `web.config` is also committed. **Fix:** move both out of the repo and **rotate both** (they're in git history). Longer term, staff sign in with Entra ID.
5. `SingleComplete.aspx.cs:59` logs the survey password, and RegionalReports(KY) logs reset codes. **Fix:** remove those log values.

## Hashing design

- **Algorithm:** PBKDF2-HMAC-SHA256, 16-byte random salt, 210,000 iterations, stored as `PBKDF2$sha256$210000$<salt b64>$<hash b64>`. It is available in .NET Framework 4.8 (`Rfc2898DeriveBytes` with `HashAlgorithmName.SHA256`) and in .NET 10, so the new admin site can verify the same hashes. It lives in one class, `App_Code/PasswordHasher.cs`.
- **Verify in C#, not SQL.** Login procs return the candidate rows with their hashes, and the page verifies them. For shared emails the page checks each candidate, which keeps today's "same email, different password" behavior.
- **Schema:** add `AdminPasswordHash varchar(150)` to `Organizations` and `Registrations`, plus a hash column for `LogIn_Additional`, `Regions` and `StatePasswords`. Keep `AdminPassword_Changed`.
- **New procs** (old ones are left in place until the code no longer calls them):
  - `GetAdminLoginCandidates @email`: id, type (ORG/REG/ORGADDL/REGADDL), hash, status, flags.
  - `GetAdminHash @orgid | @regid`.
  - `RecordAdminLogin @orgid | @regid`: the activation and access-count updates moved out of `LoginSchAdmin`.
  - `SetAdminPasswordHash @orgid | @regid, @hash, @isTemporary`: writes the hash, NULLs the plain text, and sets or clears `AdminPassword_Changed`.
- **Password generation** moves from `AuthGenPassword` (SQL `RAND()`, predictable) to `RandomNumberGenerator` in C#, using the same character rules.
- **No forced mass reset.** A one-time tool hashes every existing plain-text password into the new column. Once logins run on hashes, the plain-text columns are blanked. Users keep their current passwords.

## Page changes (about 25 pages)

| Today | After |
|---|---|
| Edit screens pre-fill the password in a visible text box (EditPubDistrict, EditPrivDistrict, EditOrg, EditBuilding, EnterNewProfile, EnterProfileSchInDist, AdminEditPubDistrict, AdminEditBuilding) | "New password" box, blank means unchanged. A typed value is hashed. |
| Welcome/registration emails include `#AdminPassword#` / `#TempAdminPassword#` (templates NEWREGISTRATION, REGISTRATION, UPDATEREGISTRATION, plus hard-coded emails in RegisterBuilding, SingleComplete, EditPubDistrict) | No passwords in email. Depends on decision 2 below. |
| Staff screens list passwords (DistCredentials, SchCredentials, LookupContacts, RegDistByDate, RegSchByDate) | Password columns removed. Credentials screens get a "Generate temporary password" button (decision 2). |
| Export Contacts (.xls) and the Access download include password columns | Columns removed (RDLC reports, ExportDataSet.xsd, SetupAnswerDownload). |
| `EnterProfileDist` emails the district's **current** password | Removed. |
| Pages read the plain text only to see whether one is set (EditPubDistrict, EditOrg, EditPrivDistrict, BldgPasswordExists) | Check whether the hash is set. |
| MergeOrganizations/MergeBuildings `SELECT *` into `*_Deleted` tables (which don't exist in the 2026-27 DB) | Leave alone. They are already broken. Note for phase 2. |

## Order (the live site never breaks)

1. **Urgent fixes 1–5.** Small, independent page changes. Test locally, deploy, then rotate the two committed secrets.
2. **Add hash columns and new procs.** Additive only, so old code keeps working.
3. **Deploy pages that write hashes** (set, change, generate) **and read hash-or-plain-text** for login during the switch.
4. **Run the one-time hashing tool.** Verify every row has a hash.
5. **Deploy pages with no plain-text reads** (displays, emails, exports removed).
6. **Blank the plain-text columns.** Later, drop them along with the old procs.

Each step is reversible until step 6. Take a database backup before 4 and 6.

## Decisions needed from Bob

1. **Survey "secret word":** retire it (stop showing, emailing and exporting it, then blank it), or keep it as a non-secret code? Nothing checks it.
2. **How users get a password from staff:** (a) staff click "Generate temporary password", see it **once**, and email it themselves as they do today; it's stored hashed and must be changed at first login. Or (b) the system emails a one-time "set your password" link, which needs working outbound email (Graph). (a) works now; (b) can come with the new admin site.
3. **Timing:** urgent fixes now. Hashing (steps 2–6) before or after the survey-taker go-live in late October?
4. **Production check:** do `LogIn_Additional`, `Regions` and `StatePasswords` have rows in production?
