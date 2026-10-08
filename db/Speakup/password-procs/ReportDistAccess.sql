-- Source: Speakup2026_2027.dbo.ReportDistAccess (scripted 2026-10-08)
-- =============================================
-- Author:		Bob O'Dell
-- Create date: 02/01/2010
-- Modified:	02/13/2010
-- Description:	Check District Access for getting end of survey reports
-- =============================================
CREATE PROCEDURE [dbo].[ReportDistAccess] 
	@mailstate varchar(20),
	@distname varchar(50),
	@password varchar(20)
AS
BEGIN
	SELECT Organization_ID, OrgName, MailCity FROM Organizations
	WHERE Orgname LIKE @distname
	AND CONVERT(varbinary(20),AdminPassword) = CONVERT(varbinary(20),@password)
	AND AdminPassword = @password AND status = 'A'
END
GO

