-- Source: SurveyBank.dbo.GetSurveyToTake (scripted from local restore 2026-10-08)
-- =============================================
-- Author:		Bob O'Dell
-- Create date: 07/07/2009
-- Modified:	08/26/2015
--				11/15/2016 - Added grid_answer_type to return set
-- Description:	For a given survey number return the questions and a separate set of all options for that survey
-- =============================================
CREATE PROCEDURE [dbo].[GetSurveyToTake]
	@survey int 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- page number is added as 1.  It is used by the survey page to set which page each question appears on
    SELECT b.Question_Id, b.Reference, b.Version, b.question_text, b.question_type, 
		b.group_question, b.required, b.ques_grid, b.sort_grid, b.grid_answer_type, b.likertScale, b.question_grid_header,
		s.Question_Sort,
		1 AS PageNumber FROM SurveyQuestions s
	JOIN QuestionBank b ON b.Question_Id = s.Question_Id 
	WHERE s.survey_id = @survey AND b.status='A' ORDER BY s.Question_Sort, b.sort_grid;

	SELECT qo.option_id, ob.related_option_id, qo.Question_Id, ob.option_text, ob.filter_group, qo.Option_Sort 
	FROM QuestionOptions qo
	JOIN OptionBank ob ON ob.option_id = qo.Option_Id 
	WHERE qo.Question_Id IN (SELECT question_id FROM SurveyQuestions WHERE survey_id = @survey)
	AND ob.status = 'A'
	ORDER BY qo.Question_Id, qo.Option_Sort;
END
GO

