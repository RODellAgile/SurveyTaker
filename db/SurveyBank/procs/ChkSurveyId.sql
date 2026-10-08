-- Source: SurveyBank.dbo.ChkSurveyId (scripted from local restore 2026-10-08)
-- =============================================
-- Author:		Bob O'Dell
-- Create date: 10/30/2014
-- Modified:	10/15/2025 - added obtaining value for survey_type
-- Description:	For the generic district entry, this checks that the survey id is active
--				Returns the survey name if found
-- =============================================
CREATE PROCEDURE [dbo].[ChkSurveyId] 
	@surveyid int
AS
BEGIN
	SELECT name, survey_type FROM surveys WHERE survey_id = @surveyid AND archive = 0;
END
GO

