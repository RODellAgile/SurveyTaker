-- Source: Speakup2026_2027.dbo.CheckBldgAccess (scripted 2026-10-08)
-- =============================================
-- Author:		Bob O'Dell
-- Create date: 6/24/2009
-- Modified:	08/01/2009
-- Description:	Check Building Access
--				Building access is achieved either through
--				the organization admin password or through
--				building admin password
-- =============================================
CREATE PROCEDURE [dbo].[CheckBldgAccess]
		@orgid int,
		@regid int = 0, -- if it is a new building being added, we would not have this id
		@password varchar(20),
		@orgaccess bit OUTPUT,
		@regaccess bit OUTPUT
AS
BEGIN
	DECLARE @cntorg int
	DECLARE @cntreg int

	SELECT @cntreg=COUNT(*) FROM Organizations 
	WHERE Organization_Id = @orgid
	AND CONVERT(varbinary(20),AdminPassword) = CONVERT(varbinary(20),@password)
	AND AdminPassword = @password

	IF @cntreg > 0
		SET @orgaccess = 1
	ELSE
		SET @orgaccess = 0

	SELECT @cntreg=COUNT(*) FROM Registrations 
	WHERE registration_id = @regid
	AND CONVERT(varbinary(20),LocalAdminPassword) = CONVERT(varbinary(20),@password)
	AND LocalAdminPassword = @password

	IF @cntreg > 0
		SET @regaccess = 1
	ELSE
		SET @regaccess = 0
END
GO

