-- Source: Speakup2026_2027.dbo.GetPasswordFromEmail (scripted 2026-10-08)
-- =============================================
-- Author:		Bob O'Dell
-- Create date: 10/13/2014
-- Modified:
-- Description:	Check in organization and regitration tables for a provided password
-- =============================================
CREATE PROCEDURE [dbo].[GetPasswordFromEmail]
	@emailaddress varchar(75)
AS
BEGIN
	DECLARE @password varchar(20);

	SELECT @password = AdminPassword FROM Organizations WHERE ContactEmail = @emailaddress;

	IF @@ROWCOUNT = 0
		SELECT @password = LocalAdminPassword FROM Registrations WHERE ContactEmail = @emailaddress;

	IF LEN(@password) > 0
		SELECT @password AS password; -- only return a password if one exists
END
GO

