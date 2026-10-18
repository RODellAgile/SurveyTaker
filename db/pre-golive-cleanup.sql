/*
  Pre-go-live cleanup of the season database (Speakup2026_2027): removes taken-survey records (users_surveys) left by
  testing, keeping the organizations you name (the real out-of-season district). Bob, 2026-10: "I NEVER remove
  anything from answers" -- this script never touches answers/answersDaily; their rows simply become orphans.

  HOW TO USE (in SSMS, production, the day before go-live):
    1. Run PART 1 alone (select it, press Execute). Look at the list: which organizations are real?
    2. In PART 2, put the real organizations' ids in the INSERT INTO @keep line.
    3. Run PART 2. It deletes INSIDE a transaction and shows what it would leave, then ROLLS BACK (nothing changes).
    4. If the numbers are right, change the last line from ROLLBACK to COMMIT and run PART 2 again.
  Take a copy-only backup of Speakup2026_2027 first.
*/
USE Speakup2026_2027;
GO

-- ===== PART 1: who has taken-survey records ======================================================================
SELECT u.Organization_Id,
       ISNULL(o.OrgName, '(no organization record)') AS OrgName, o.MailState,
       COUNT(*) AS TakenSurveys,
       SUM(CASE WHEN u.QuesCompleted > 0 THEN 1 ELSE 0 END) AS WithAnswers,
       SUM(CASE WHEN u.UseSurvey = 0 THEN 1 ELSE 0 END) AS AlreadyMarkedTest,
       MIN(u.TimeEntered) AS FirstStarted, MAX(u.LastUpdate) AS LastActivity,
       STRING_AGG(CAST(u.Survey_Id AS varchar(10)), ',') WITHIN GROUP (ORDER BY u.Survey_Id) AS SurveyIds
FROM users_surveys u
LEFT JOIN Organizations o ON o.Organization_ID = u.Organization_Id
GROUP BY u.Organization_Id, o.OrgName, o.MailState
ORDER BY COUNT(*) DESC;
GO

-- ===== PART 2: delete everything except the kept organizations (rolls back until you change the last line) ======
DECLARE @keep TABLE (Organization_Id int PRIMARY KEY);
INSERT INTO @keep (Organization_Id) VALUES (0);   -- <<< replace 0 with the real organization ids, e.g. (34220), (34259)

BEGIN TRANSACTION;

DELETE u
FROM users_surveys u
WHERE ISNULL(u.Organization_Id, 0) NOT IN (SELECT Organization_Id FROM @keep);

SELECT @@ROWCOUNT AS DeletedTakenSurveys;

SELECT u.Organization_Id, COUNT(*) AS Remaining
FROM users_surveys u GROUP BY u.Organization_Id ORDER BY u.Organization_Id;

ROLLBACK;   -- <<< change to COMMIT only after checking the numbers above
GO
