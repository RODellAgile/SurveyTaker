-- Source: Speakup2026_2027.dbo.ChkStatePassword (scripted 2026-10-08)
-- =============================================
-- Author:		Bob O'Dell
-- Create date: 10/08/2012
-- Modified:
-- Description:	Authenticate a state password for access to reports
-- =============================================
create PROCEDURE [dbo].[ChkStatePassword] 
	@state varchar(20),
	@adminpassword varchar(20)
AS
BEGIN
	SELECT * FROM StatePasswords
	WHERE state = @state
	AND CONVERT(varbinary(20),AdminPassword) = CONVERT(varbinary(20),@adminpassword)
	AND AdminPassword = @adminpassword
END
GO

