-- Source: Speakup2026_2027.dbo.GetSurveyDates (scripted from local restore 2026-10-08)
-- =============================================
-- Author:		Bob O'Dell
-- Create date: 07/26/2009
-- Modified:	12/27/2009
-- Description:	Returns the Opening, Closing and Reports Available Dates for Surveys
-- =============================================
CREATE PROCEDURE [dbo].[GetSurveyDates]
	@site varchar(50)
AS
BEGIN
	SELECT * FROM SurveyDates
	WHERE site = @site
END
GO

