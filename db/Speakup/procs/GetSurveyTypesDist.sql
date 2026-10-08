-- Source: Speakup2026_2027.dbo.GetSurveyTypesDist (scripted from local restore 2026-10-08)
-- =============================================
-- Author:		Bob O'Dell
-- Create date: 09/16/2019 
-- Modified:	11/21/2019 - modified where first result sorted
-- Description:	Get the survey types for a district
-- =============================================
CREATE PROCEDURE [dbo].[GetSurveyTypesDist]
	@orgid int,
	@deck varchar(20)  -- we get survey types from the default deck if they do not have custom surveys
AS
BEGIN
	SELECT DISTINCT s.survey_type, t.SurveyTypeName, t.SortOrder 
	INTO #temp
	FROM MarkedSurveys m
	JOIN SurveyBank.dbo.surveys s ON s.survey_id = m.survey_id
    JOIN SurveyBank.dbo.SurveyType t ON s.survey_type = t.SurveyTypeCode
	WHERE Organization_ID = @orgid
	AND s.archive = 0

	IF @@ROWCOUNT > 0 
	BEGIN
		SELECT * FROM #temp	ORDER BY SortOrder;
;
	END
	ELSE
	BEGIN
		DECLARE @state varchar(2);
		SELECT @state = MailState FROM Organizations where Organization_ID=@orgid;
		SELECT DISTINCT s.survey_type, t.SurveyTypeName, t.SortOrder
		FROM SurveyBank.dbo.SurveyDeckSurveyList sdl
		JOIN SurveyBank.dbo.surveys s ON s.survey_id = sdl.survey_id
		JOIN SurveyBank.dbo.SurveyType t ON s.survey_type = t.SurveyTypeCode
		WHERE sdl.DeckCode = @deck
		AND ((s.include = 'ALL' AND (s.Exclude NOT LIKE '%' + @state + '%' OR s.Exclude IS NULL))  OR (s.include <> 'ALL' AND s.include like '%' + @state + '%' ))
		AND s.archive = 0
		ORDER BY t.SortOrder;
	END

END
GO

