-- Source: Speakup2026_2027.dbo.MarkSurveyCompleted (scripted from local restore 2026-10-08)
-- =============================================
-- Author:		Bob O'Dell
-- Create date: 09/11/2010
-- Modified:	10/06/2010
-- Description:	When a survey is complete, mark the survey as completed and update questions taken
-- =============================================
CREATE PROCEDURE [dbo].[MarkSurveyCompleted] 
	@takensurveyid int,
	@quescompleted int
AS
BEGIN
	UPDATE Users_Surveys 
	SET Completed = 'YES',
	QuesCompleted = @quescompleted,
	LastUpdate = GETDATE()
	WHERE taken_survey_id = @takensurveyid
END
GO

