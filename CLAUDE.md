# SurveyTaker – Speak Up survey taker (.NET 10)

Phase 1 of migrating Speak Up off ASP.NET Web Forms. Replaces the respondent-facing survey pages; served at `Speakup.Tomorrow.Org`. Full background: [docs/handoff-2026-10-08.md](docs/handoff-2026-10-08.md). Corrections to the handoff from reading the actual DB: [db/README.md](db/README.md) — those win where they disagree.

Legacy Web Forms app (live fallback, do not modify unless Bob asks): `C:\Users\rodel\source\repos\RODellAgile\speakup2026`. SurveyBank admin app: `..\SpeakupSurveyBank2024`.

## Layout

- `src/SurveyTaker.Web` – Blazor Web App, **static server rendering only** (`--interactivity None`). Matches the Agile-Ed team's Blazor choice; no SignalR circuit, so it stays stateless.
- `src/SurveyTaker.Data` – one thin Dapper wrapper per stored procedure (`Microsoft.Data.SqlClient`).
- `tests/SurveyTaker.Tests` – xUnit.
- `db/` – reference copies of the procs (not deployed). `docs/` – handoff and notes.
- `nuget.config` clears machine-wide feeds (Bob's machine has a dead Telerik v2 feed that breaks restore).

Don't rewrite source files with Windows PowerShell 5.1 `Get-Content`/`Set-Content`: it reads UTF-8 without BOM as ANSI and garbles accented text (broke the Spanish strings once). Use the Edit tool.

Build/test: `dotnet build SurveyTaker.slnx`, `dotnet test SurveyTaker.slnx`. Run: `dotnet run --project src/SurveyTaker.Web`.

## Scope (Bob, 2026-10-08)

**speakup.tomorrow.org = SurveyTaker = everything about taking a survey**: the /S/, /D/ and /Q/ short links, start pages, intro, questions, completion. **speakup2026.tomorrow.org becomes the report/admin portal**, and survey taking moves out of it. That's temporary: the admin portal moves on to **speakupadmin.tomorrow.org** once SurveyTaker is fully up. So SurveyTaker must NOT hand survey traffic back to speakup2026. The current hand-offs (/S/ without a survey id, all /D/ links) are temporary and must be replaced before go-live by: survey-type/survey pickers (/S/ without a survey id), the school picker (/D/), and /Q/ quick start (survey 195 in 2025-26). Open: whether SIDstart, LookupBuilding and Register come over too.

## Rules

- **Stateless**: no session; every request rebuilds from the DB via taken-survey ID (TSI). One form POST per page. Azure-ready: config/env settings, no local disk writes, no Windows-only APIs.
- **Same stored procedures, same parameters**; no schema changes, no EF Core. Rows written must be indistinguishable from the legacy app's.
- **No secrets in git.** Local dev uses Windows auth (no password). Production connection strings come from environment/user-secrets, never appsettings.json.
- **Never point at production** SQL (`DBEINFOPT\SQL2019` / 10.0.8.23). Local DBs: `Speakup2026_2027`, `Speakup2025_2026` (last season, full data — good for comparisons), `SurveyBank`, `Institution` (pending restore).
- Season values live in config (`Season:SurveyYear`, `Season:TextYear`).
- One top-level question per page (a grid counts as one); honor stored `quesperpage` on restart for surveys started by the old app.
- Fix "Other" detection (starts-with, not exact match). Group surveys: `surveys.GroupSurvey = 1` → ask respondent count first (`UpdateK2GrpCnt`), each integer answer ≤ `k2grpcnt` server-side; the old 6/55/110/471 exact-sum check is deprecated (see db/README.md). English + Spanish via resource files. WCAG 2.2 AA, mobile-first, branding tokens per handoff §3.
- UI – **[DECIDED 2026-10-08]**: Agile-Ed team uses Blazor Server + Telerik UI for Blazor + Bootstrap. SurveyTaker uses **Bootstrap + plain HTML form controls**, Project Tomorrow tokens layered on Bootstrap variables, **no Telerik** (survey inputs don't need it; most Telerik Blazor components require interactivity). Stays **static SSR**, not Server mode (phones on flaky networks; stateless rule). Server mode + Telerik are fine for the later admin site.

## 2026-10-15

- Pinned `System.Security.Cryptography.Pkcs` 10.0.13: Microsoft.Data.SqlClient 7.1.1 pulled 9.0.18, which has a high-severity advisory. That code reads signed CMS data, which SurveyTaker never does, so low real risk. **Package `publish/update-2026-10-15`** (no web.config/appsettings.Development.json) is built and NOT deployed; it's the deployed 10-14 build plus this fix. Deploy when convenient (stop the Speakup pool, copy, start).

## 2026-10-14

- Sponsor logos added to the full footer (intro, start, completion pages; not question pages, per the team's spec): AgileED, ClassDojo, Edmentum, edWeb.net, PowerSchool. Files in `wwwroot/img/sponsors` (PowerSchool SVG cropped to its drawing, checked for scripts); list and order in `Survey:Sponsors` settings. Each logo sits on a white tile for dark mode.
- **Update package `publish/update-2026-10-14`** (no web.config, no appsettings.Development.json) replaces update-2026-10-09: it contains the 10-09 changes (logo, completion page, theme) plus the sponsors. **Deployed by Bob 2026-10-15** (team had approved the 10-09 release; the logos were their main issue). Sam checking.
- Local preview: launch.json "surveytaker" now uses the publish folder as content root (the source folder as content root served empty static files).

## 2026-10-09

- Team feedback: pleased overall. Built and committed: the logo on every page (header at half size), a completion page matching their mockup, and a Light/Dark/Auto theme (dark palette is ours, WCAG-checked; swap in spec section 12 values when Bob sends them). Update package `publish/update-2026-10-09` (no web.config) is **built but NOT deployed**: waiting on the team's review.
- More text from the team expected next week. After that: SpeakupAdmin.

## Deployed (2026-10-08, night)

- **Live on speakup.tomorrow.org** (IIS site/pool "Speakup", No Managed Code, F:\inetpub\Speakup). Bob ran the smoke tests; Michelle and Sam test on 2026-10-09.
- Production DB: GetOrganizationForSurvey + GetSchoolsForSurvey created; login speakup_surveytaker created. Settings live in the server's web.config environment variables (not in git; built from `publish/`, which is gitignored).
- Follow-ups: change the speakup_surveytaker password if not done (it appeared in the session log); set stdoutLogEnabled="false"; clean up test rows (UseSurvey=0 or purge); SurveyBank titles still say "Speakup 2025"; Lawrence County (org 34245) admin password exposed in a session log, so reset it.
- To redeploy: `dotnet publish src/SurveyTaker.Web -c Release -o publish/SurveyTaker`, then copy everything EXCEPT web.config (the server's has the secrets) and appsettings.Development.json. **Stop the "Speakup" app pool first** (only that pool), copy, then start it: app_offline.htm alone left a file locked (Bob, 2026-10-15).

## Status (2026-10-08, evening)

- Working: /S/{school}/{survey} and /S/{school} (type and survey pickers), /D/{district}[/{survey}] (school picker, then pickers, then confirm) → intro → group count → one question per page (7 active types, Other fix, Back/resume, real progress) → completion. 32 tests pass. Click-throughs passed: survey 578 (/S/), group survey 174 (583), and /D/ under the restricted login (586).
- Spanish: no active STUSPAN/FAMSPAN surveys in 2026-27 (all archived). Ask Michelle whether one is planned.
- Data: SurveyBank survey titles still say "Speakup 2025" (shown as the page heading). Staff to update.
- /Q/{survey} quick start built (placeholder org 73021 / school 252487, one question per page, maintenance check only, as in legacy). **Change from legacy:** a Start button creates the survey instead of the page load (2025-26 had 17,490 quick starts but 590 completions, which looks like link previews and bots creating rows). Bob to confirm. Also logs EntryPoint 'QUICKSTART'.
- Next: decide on SIDstart / LookupBuilding / Register; accessibility and mobile pass; old-vs-new row comparison; production DB setup (2 new procs + create-surveytaker-login.sql); IIS deploy to speakup.tomorrow.org.
- Security work on the legacy site lives in the speakup2026 repo, not here.

## Working with Bob

CTO, returning to hands-on .NET after a few years; explain new .NET Core concepts when they come up. Prefers plain-text questions over multiple-choice, light backgrounds, click-by-click UI steps where practical, minimal wasted effort (hard October date). Don't ask him for passwords in chat.
