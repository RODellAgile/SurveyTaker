-- Source: Speakup2026_2027.dbo.RetrieveDistPswrd (scripted 2026-10-08)
-- =============================================
-- Author:		Bob O'Dell
-- Create date: 10/13/2012
-- Modified:
-- Description:	Retrieve the contact, contact email and passwords for a specific organization
-- =============================================
CREATE PROCEDURE [dbo].[RetrieveDistPswrd] 
	@orgid int
AS
BEGIN
	SELECT ContactFirstName, ContactLastName, ContactEmail, AdminPassword, SurveyPassword
	FROM organizations
	WHERE organization_id = @orgid
END
GO

