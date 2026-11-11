-- =============================================
-- Author:      SurveyTaker (Claude Code with Bob O'Dell)
-- Create date: 11/11/2026
-- Description: Marks a take of a Development survey as test data (UseSurvey = 0), so it never counts in reports
--              even after the survey is made Active. SurveyTaker calls it right after StartNewSurvey, only for
--              Development surveys taken by the test organization (Survey:TestOrganizationId). The organization
--              must match the take, so the proc can't be used to hide other organizations' answers.
--              New, additive object (Survey Building cutover). Run in each new season's database too.
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[MarkTestSurveyTake]
    @takensurveyid int,
    @organizationid int
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE users_surveys SET UseSurvey = 0
    WHERE TAKEN_SURVEY_ID = @takensurveyid AND Organization_Id = @organizationid;
    SELECT @@ROWCOUNT AS Marked;
END
GO
