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

## Rules

- **Stateless**: no session; every request rebuilds from the DB via taken-survey ID (TSI). One form POST per page. Azure-ready: config/env settings, no local disk writes, no Windows-only APIs.
- **Same stored procedures, same parameters**; no schema changes, no EF Core. Rows written must be indistinguishable from the legacy app's.
- **No secrets in git.** Local dev uses Windows auth (no password). Production connection strings come from environment/user-secrets, never appsettings.json.
- **Never point at production** SQL (`DBEINFOPT\SQL2019` / 10.0.8.23). Local DBs: `Speakup2026_2027`, `Speakup2025_2026` (last season, full data — good for comparisons), `SurveyBank`, `Institution` (pending restore).
- Season values live in config (`Season:SurveyYear`, `Season:TextYear`).
- One top-level question per page (a grid counts as one); honor stored `quesperpage` on restart for surveys started by the old app.
- Fix "Other" detection (starts-with, not exact match). Group surveys: `surveys.GroupSurvey = 1` → ask respondent count first (`UpdateK2GrpCnt`), each integer answer ≤ `k2grpcnt` server-side; the old 6/55/110/471 exact-sum check is deprecated (see db/README.md). English + Spanish via resource files. WCAG 2.2 AA, mobile-first, branding tokens per handoff §3.
- UI – **[DECIDED 2026-10-08]**: Agile-Ed team uses Blazor Server + Telerik UI for Blazor + Bootstrap. SurveyTaker uses **Bootstrap + plain HTML form controls**, Project Tomorrow tokens layered on Bootstrap variables, **no Telerik** (survey inputs don't need it; most Telerik Blazor components require interactivity). Stays **static SSR**, not Server mode (phones on flaky networks; stateless rule). Server mode + Telerik are fine for the later admin site.

## Working with Bob

CTO, returning to hands-on .NET after a few years; explain new .NET Core concepts when they come up. Prefers plain-text questions over multiple-choice, light backgrounds, click-by-click UI steps where practical, minimal wasted effort (hard October date). Don't ask him for passwords in chat.
