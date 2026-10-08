-- Source: Speakup2026_2027.dbo.UpdateSurveyProgress (scripted from local restore 2026-10-08)
-- =============================================
-- Author:		Bob O'Dell
-- Create date: 08/17/2012
-- Modified:	
-- Description:	Update Start Question Offset, Questions Completed and Current Page in users_surveys
-- =============================================
CREATE PROCEDURE [dbo].[UpdateSurveyProgress] 
	@takensurveyid int,
	@quesoffset int,
	@page int,
	@quescompleted int
AS
BEGIN
	UPDATE Users_Surveys 
	--SET StartQuesOffset = @quesoffset, QuesCompleted = @quescompleted, -- changed in 2011
	SET StartQuesOffset = @quesoffset, 
	QuesCompleted = CASE WHEN QuesCompleted < @quescompleted THEN @quescompleted ELSE QuesCompleted END,
	SurveyPage = @page,
	LastUpdate = GETDATE()
	WHERE taken_survey_id = @takensurveyid
END
GO

