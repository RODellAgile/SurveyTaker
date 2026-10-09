/* =====================================================================================================
   Least-privilege SQL login for SurveyTaker (the public survey-taking app).

   The legacy app's "speakup" login has db_datareader + db_datawriter + db_executor on Speakup and
   SurveyBank, i.e. it can read every table (including plain-text district/school passwords and all
   respondents' answers). SurveyTaker is public and anonymous, so it gets only what it calls:
     - EXECUTE on the stored procedures listed below (they do all reads/writes via ownership chaining)
     - SELECT on 5 columns of Registrations (the school link-code lookup; no password columns)
   District lookups use GetOrganizationForSurvey (create it first: db/Speakup/procs/GetOrganizationForSurvey.sql),
   NOT the legacy GetOrganizationInfo, which returns o.* including plain-text passwords. No Institution access.

   HOW TO RUN (SSMS, as sa or another sysadmin):
     1. Set the season database name below if it isn't Speakup2026_2027.
     2. Replace CHANGE_ME with a long random password (store it only in the server's app settings).
     3. Execute. Re-running is safe: it skips what already exists and re-applies the grants.
   ===================================================================================================== */

DECLARE @season sysname = N'Speakup2026_2027';   -- season database
DECLARE @password nvarchar(128) = N'CHANGE_ME';  -- long random password; never commit the real one

IF @password = N'CHANGE_ME' THROW 50000, 'Set @password before running.', 1;

-- ---------- login (server level) ----------
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'speakup_surveytaker')
BEGIN
    DECLARE @sql nvarchar(max) = N'CREATE LOGIN speakup_surveytaker WITH PASSWORD = ' + QUOTENAME(@password, '''')
        + N', CHECK_POLICY = ON, CHECK_EXPIRATION = OFF, DEFAULT_DATABASE = ' + QUOTENAME(@season) + N';';
    EXEC (@sql);
END

-- ---------- season database ----------
DECLARE @seasonSql nvarchar(max) = N'
USE ' + QUOTENAME(@season) + N';
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N''speakup_surveytaker'')
    CREATE USER speakup_surveytaker FOR LOGIN speakup_surveytaker;

GRANT EXECUTE ON dbo.GetMaintenanceDate       TO speakup_surveytaker;
GRANT EXECUTE ON dbo.GetSurveyDates           TO speakup_surveytaker;
GRANT EXECUTE ON dbo.GetDistrictOpenClose     TO speakup_surveytaker;
GRANT EXECUTE ON dbo.GetOrganizationForSurvey TO speakup_surveytaker;
GRANT EXECUTE ON dbo.GetInstInDistrict        TO speakup_surveytaker;  -- district school picker (/D/ links)
GRANT EXECUTE ON dbo.GetDescriptorText        TO speakup_surveytaker;
GRANT EXECUTE ON dbo.LogEntryPoint            TO speakup_surveytaker;
GRANT EXECUTE ON dbo.LogEntryEnhanced         TO speakup_surveytaker;
GRANT EXECUTE ON dbo.StartNewSurvey           TO speakup_surveytaker;
GRANT EXECUTE ON dbo.GetRestartInfo           TO speakup_surveytaker;
GRANT EXECUTE ON dbo.UpdateK2GrpCnt           TO speakup_surveytaker;
GRANT EXECUTE ON dbo.RetrievePartialSurvey    TO speakup_surveytaker;
GRANT EXECUTE ON dbo.DeleteQuestion           TO speakup_surveytaker;
GRANT EXECUTE ON dbo.SaveAnswer               TO speakup_surveytaker;
GRANT EXECUTE ON dbo.UpdateSurveyProgress     TO speakup_surveytaker;
GRANT EXECUTE ON dbo.MarkSurveyCompleted      TO speakup_surveytaker;

-- School link lookup (SpeakupDb.GetRegistrationByLinkCodeAsync). Column-level: no password columns.
GRANT SELECT ON dbo.Registrations (LinkCode, Organization_Id, Registration_Id, RegistrantName, MailState) TO speakup_surveytaker;
';
EXEC (@seasonSql);

-- ---------- SurveyBank ----------
USE SurveyBank;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'speakup_surveytaker')
    CREATE USER speakup_surveytaker FOR LOGIN speakup_surveytaker;
GRANT EXECUTE ON dbo.ChkSurveyId     TO speakup_surveytaker;
GRANT EXECUTE ON dbo.GetSurveyDesc   TO speakup_surveytaker;
GRANT EXECUTE ON dbo.GetSurveyToTake TO speakup_surveytaker;

USE master;
PRINT 'speakup_surveytaker ready.';
