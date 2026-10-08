-- Source: Speakup2026_2027.dbo.ChkAdminPassword (scripted 2026-10-08)
-- =============================================
-- Author:		Bob O'Dell
-- Create date: 5/24/2009
-- Description:	Authenticate an Organization Administrator based off organization id and admin password
-- =============================================
CREATE PROCEDURE [dbo].[ChkAdminPassword] 
	@orgid int,
	@password varchar(20)
AS
BEGIN
	SELECT Organization_ID, OrgName FROM Organizations
	WHERE Organization_ID = @orgid
	AND CONVERT(varbinary(20),AdminPassword) = CONVERT(varbinary(20),@password)
	AND AdminPassword = @password
END
GO

