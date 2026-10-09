-- =============================================
-- Author:      SurveyTaker (Claude Code with Bob O'Dell)
-- Create date: 10/08/2026
-- Description: District lookup for the survey taker. Same lookup as GetOrganizationInfo (by organization id
--              or district link code) but returns ONLY the columns the survey taker uses. GetOrganizationInfo
--              returns o.* (including the plain-text AdminPassword/SurveyPassword) and needs the Institution DB;
--              this does neither, so the survey taker's login never receives passwords.
--              New, additive object: GetOrganizationInfo is unchanged and still used by the legacy site.
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[GetOrganizationForSurvey]
    @orgid int = 0,
    @linkcode varchar(10) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @orgid = 0 AND @linkcode IS NOT NULL
        SELECT @orgid = Organization_ID FROM Organizations WHERE LinkCode = @linkcode;

    SELECT Organization_ID, LinkCode, OrgName, MailCity, MailState, SurveyDeckCode, Status
    FROM Organizations
    WHERE Organization_ID = @orgid;
END
GO
