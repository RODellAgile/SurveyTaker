-- Source: Speakup2026_2027.dbo.GetSurveyListByTypeDist (scripted from local restore 2026-10-08)
-- =============================================
-- Author:		Bob O'Dell
-- Create date: 09/16/2019 
-- Modified:	12/05/2019 - set explicit sort order for select from #temp
--				01/29/2021 - to handle custom district surveys added orgid to search INCLUDE and EXCLUDE
--				01/30/2021 - add deckcode to where 
--				12/04/2021 - added a check for district custom deckcodes
--				11/16/2022 - where rowcount 0 - fixed the code for OR by adding a set of parentheses - effectively lowering the or one level
--				12/05/2022 - Added parentheses around the AND and OR for Include/Exclude
-- Description:	Get the survey list for a district when survey type is specified
-- =============================================
CREATE PROCEDURE [dbo].[GetSurveyListByTypeDist]
	@orgid int,
	@survtype varchar(20),
	@deck varchar(20)  -- we get survey types from the default deck if they do not have custom surveys
AS
BEGIN
	-- First see if the district has a custom list of surveys (its own survey deck
	DECLARE @customdeck varchar(20) = NULL;
	SELECT @customdeck = SurveyDeckCode FROM Organizations WHERE Organization_ID = @orgid and SurveyDeckCode IS NOT NULL
	IF @@ROWCOUNT > 0
	BEGIN
		SET @deck = @customdeck;
	END

	SELECT DISTINCT s.survey_type, t.SurveyTypeName, m.survey_id, s.name, s.GroupSurvey, sd.SortOrder, sdl.Sort_Order
	INTO #temp
	FROM MarkedSurveys m
	JOIN SurveyBank.dbo.surveys s ON s.survey_id = m.survey_id
    JOIN SurveyBank.dbo.SurveyType t ON s.survey_type = t.SurveyTypeCode
	JOIN SurveyBank.dbo.SurveyDeckSurveyList sdl ON s.survey_id = sdl.survey_id
	JOIN SurveyBank.dbo.SurveyDeck sd ON sd.DeckCode = sdl.DeckCode
	WHERE Organization_ID = @orgid AND s.survey_type=@survtype AND sdl.DeckCode = @deck
	AND s.archive = 0
	ORDER BY sd.SortOrder, sdl.Sort_Order;

	IF @@ROWCOUNT > 0 
	BEGIN
		SELECT * FROM #temp ORDER BY SortOrder, Sort_Order;
	END
	ELSE
	BEGIN
		DECLARE @state varchar(2);
		SELECT @state = MailState FROM Organizations where Organization_ID=@orgid;
		SELECT DISTINCT s.survey_type, t.SurveyTypeName, sdl.survey_id, s.name, s.GroupSurvey, sd.SortOrder, sdl.Sort_Order
		FROM SurveyBank.dbo.SurveyDeckSurveyList sdl
		JOIN SurveyBank.dbo.surveys s ON s.survey_id = sdl.survey_id
		JOIN SurveyBank.dbo.SurveyType t ON s.survey_type = t.SurveyTypeCode
	JOIN SurveyBank.dbo.SurveyDeck sd ON sd.DeckCode = sdl.DeckCode
		WHERE sdl.DeckCode = @deck AND s.survey_type=@survtype
		AND (((s.include = 'ALL' AND ((s.Exclude NOT LIKE '%' + @state + '%' AND s.Exclude NOT LIKE '%' + CAST(@orgid AS VARCHAR(50)) + '%' ) OR s.Exclude IS NULL)))  
		OR (s.include <> 'ALL' AND (s.include like '%' + @state + '%' OR s.include like '%' + CAST(@orgid AS VARCHAR(50)) + '%' )))
		AND s.archive = 0
		ORDER BY sd.SortOrder, sdl.Sort_Order;
	END
END
GO

