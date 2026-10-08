-- Source: Speakup2026_2027.dbo.RetrieveBldgPswrd (scripted 2026-10-08)
-- =============================================
-- Author:		Bob O'Dell
-- Create date: 11/09/2012
-- Modified:
-- Description:	Retrieve the contact, contact email and passwords for a specific building
-- =============================================
create PROCEDURE [dbo].[RetrieveBldgPswrd] 
	@regid int
AS
BEGIN
	SELECT ContactFirstName, ContactLastName, ContactEmail, LocalAdminPassword, LocalSurveyPassword
	FROM Registrations
	WHERE registration_id = @regid
END
GO

