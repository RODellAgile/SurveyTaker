-- Source: Speakup2026_2027.dbo.SaveAnswer (scripted from local restore 2026-10-08)
-- =============================================
-- Author:		Bob O'Dell
-- Create date: 07/09/2009
-- Modified:	07/12/2009
-- Description:	Save a question and response to a survey
--				It is called repeatedly for several types of questions that allow multiple answers
--				This saves into the answersDaily table which is loaded into
--				the main answers table daily
-- =============================================
CREATE PROCEDURE [dbo].[SaveAnswer] 
	@TakenSurveyID int,
	@QuestionID int,
	@OptionID int = null, -- for text questions there is no option associated with it
	@OptionValue varchar(4000) = null  -- other and text questions place their entries here, otherwise blank
AS
	BEGIN					
		INSERT INTO answersDaily
		(taken_survey_id,
		 question_id,
		 option_id,
		 option_value)

		VALUES
		(@TakenSurveyID,
		 @QuestionID,
		 @OptionID,
		 @OptionValue)
	END
GO

