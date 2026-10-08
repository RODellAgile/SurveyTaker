-- Source: Speakup2026_2027.dbo.LoginRegion (scripted 2026-10-08)
-- =============================================
-- Author:		Bob O'Dell
-- Create date: 10/30/2024
-- Modified
-- Description:	Log-in for Regional Reports
-- =============================================
CREATE PROCEDURE [dbo].[LoginRegion] 
	@emailaddress varchar(100),
	@password varchar(20)
AS
BEGIN
	SELECT * FROM Regions
	WHERE Login_EmailAddress = @emailaddress
	--AND CONVERT(varbinary(20), AdminPassword) = CONVERT(varbinary(20),@password)
	AND Login_Password = @password COLLATE SQL_Latin1_General_CP1_CS_AS
	AND Status IN ('ACTIVE','INITIAL'); -- Initial means it has just been set up or the password manually changed and they will need to change it
END
GO

