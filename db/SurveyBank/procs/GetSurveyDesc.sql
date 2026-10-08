-- Source: SurveyBank.dbo.GetSurveyDesc (scripted from local restore 2026-10-08)
-- =============================================
-- Author:		Bob O'Dell
-- Create date: 08/22/2010
-- Modified:
-- Description:	Get description and other details of a survey including survey name
-- =============================================
CREATE PROCEDURE [dbo].[GetSurveyDesc] 
	@surveyid int
AS
BEGIN
	SELECT * FROM surveys where survey_id = @surveyid
END
GO

