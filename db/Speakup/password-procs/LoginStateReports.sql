-- Source: Speakup2026_2027.dbo.LoginStateReports (scripted 2026-10-08)
-- =============================================
-- Author:		Bob O'Dell
-- Create date: 12/31/2019
-- Modified:
-- Description:	Login for state administrators to see report
-- =============================================
create PROCEDURE [dbo].[LoginStateReports] 
	@email varchar(20),
	@adminpassword varchar(20)
AS
BEGIN
	SELECT * FROM StatePasswords
	WHERE ContactEmail = @email 
	AND CONVERT(varbinary(20),AdminPassword) = CONVERT(varbinary(20),@adminpassword)
	AND AdminPassword = @adminpassword
END
GO

