-- Source: Speakup2026_2027.dbo.ChkBuildingPassword (scripted 2026-10-08)
-- =============================================
-- Author:		Bob O'Dell
-- Create date: 11/09/2012
-- Modified:
-- Description:	Authenticate a building password for access to reports
-- =============================================
create PROCEDURE [dbo].[ChkBuildingPassword] 
	@regid varchar(20),
	@adminpassword varchar(20)
AS
BEGIN
	SELECT * FROM Registrations
	WHERE registration_id = @regid
	AND CONVERT(varbinary(20),LocalAdminPassword) = CONVERT(varbinary(20),@adminpassword)
	AND LocalAdminPassword = @adminpassword
END
GO

