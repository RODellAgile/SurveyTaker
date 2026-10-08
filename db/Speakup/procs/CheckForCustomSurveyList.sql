-- Source: Speakup2026_2027.dbo.CheckForCustomSurveyList (scripted from local restore 2026-10-08)
-- =============================================
-- Author:		Bob O'Dell
-- Create date: 08/01/2019
-- Modified:
-- Description:	Check to see if there is a custom survey list stored for the entity
-- =============================================
CREATE PROCEDURE CheckForCustomSurveyList
	@orgid int = null,
	@regid int = null
AS
BEGIN
	DECLARE @count int, @found bit;

	IF @orgid IS NOT NULL
	BEGIN
		SELECT @count = COUNT(*) FROM MarkedSurveys WHERE Organization_ID = @orgid;
	END
	ELSE -- must be a school
	BEGIN
		SELECT @count = COUNT(*) FROM MarkedSurveys WHERE Registration_ID = @regid;
	END

	IF @count > 0
	BEGIN
		SET @found = 1;
	END
	ELSE
	BEGIN
		SET @found = 0;
	END

	SELECT @found AS found;
END
GO

