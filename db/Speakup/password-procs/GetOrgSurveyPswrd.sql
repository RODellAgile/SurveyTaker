-- Source: Speakup2026_2027.dbo.GetOrgSurveyPswrd (scripted 2026-10-08)
-- =============================================
-- Author:		Bob O'Dell
-- Create date: 08/12/2009
-- Description:	For Email purposes we return the Organization Survey Password
-- =============================================
CREATE PROCEDURE [dbo].[GetOrgSurveyPswrd] 
	@orgid int
AS
BEGIN
	SELECT SurveyPassword FROM Organizations WHERE Organization_ID =@orgid
END
GO

