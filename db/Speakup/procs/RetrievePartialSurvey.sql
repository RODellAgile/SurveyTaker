-- Source: Speakup2026_2027.dbo.RetrievePartialSurvey (scripted from local restore 2026-10-08)
-- =============================================
-- Author:		Bob O'Dell
-- Create date: 11/11/2009
-- Modified:	
-- Description:	Retrieves answers for a survey that is in progress.  This to allow rebuilding
--				of the answer array in memory if session variables fail
-- =============================================
CREATE PROCEDURE [dbo].[RetrievePartialSurvey] 
	@takensurveyid int
AS
BEGIN
	SELECT question_id, option_id, option_value
	FROM AnswersDaily
	WHERE taken_survey_id = @takensurveyid
END
GO

