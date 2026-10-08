-- Source: Speakup2026_2027.dbo.BldgPasswordExists (scripted 2026-10-08)
-- =============================================
-- Author:		Bob O'Dell
-- Create date: 08/12/2009
-- Description:	Check to see if a building's admin password exists or is blank
-- =============================================
CREATE PROCEDURE [dbo].[BldgPasswordExists] 
	@regid int
AS
BEGIN
	DECLARE @found bit;
	DECLARE @pswrd varchar(20);
	SELECT @pswrd = LocalAdminPassword FROM Registrations WHERE Registration_ID = @regid;
	IF LEN(@pswrd) > 0
		SET @found = 1;
	ELSE
		SET @found = 0;
	SELECT @found;
END
GO

