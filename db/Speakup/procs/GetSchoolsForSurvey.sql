-- =============================================
-- Author:      SurveyTaker (Claude Code with Bob O'Dell)
-- Create date: 10/08/2026
-- Description: Schools in a district for the survey taker's school picker (/D/ links). Same filter and order as
--              the second result set of GetInstInDistrict, but only the columns the picker shows: the legacy proc
--              also returns contact names and emails, which a public page has no need for.
--              New, additive object: GetInstInDistrict is unchanged and still used by the legacy site.
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[GetSchoolsForSurvey]
    @orgid int
AS
BEGIN
    SET NOCOUNT ON;
    SELECT Registration_ID, RegistrantName, RegistrantType
    FROM Registrations
    WHERE Organization_ID = @orgid AND Organization_ID IS NOT NULL AND Status NOT IN ('X', 'D', 'C')
    ORDER BY RegistrantType, RegistrantName;
END
GO
