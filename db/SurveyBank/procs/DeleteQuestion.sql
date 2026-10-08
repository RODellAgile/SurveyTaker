-- Source: SurveyBank.dbo.DeleteQuestion (scripted from local restore 2026-10-08)
-- =============================================
-- Author:		Bob O'Dell
-- Create date: 07/12/2009
-- Modified:	07/12/2009
-- Description:	To eliminate dups from backing up, we delete question first
--				This should be called whenever a question is being saved
-- =============================================
CREATE PROCEDURE [dbo].[DeleteQuestion] 
	@TakenSurveyID int,
	@QuestionID int
AS
	BEGIN
		DELETE FROM answersDaily
		WHERE taken_survey_id = @TakenSurveyID AND question_id = @QuestionID
	END
GO

