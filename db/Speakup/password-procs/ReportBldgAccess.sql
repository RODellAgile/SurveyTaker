-- Source: Speakup2026_2027.dbo.ReportBldgAccess (scripted 2026-10-08)
-- =============================================
-- Author:		Bob O'Dell
-- Create date: 02/01/2010
-- Modified:	05/08/2015
-- Description:	Check Building Access for getting end of survey reports
-- =============================================
CREATE PROCEDURE [dbo].[ReportBldgAccess] 
	@mailstate varchar(20),
	@bldgname varchar(50),
	@password varchar(20)
AS
BEGIN
	IF @mailstate = 'INTL' -- international we look for a country other than the united states
	BEGIN
		SELECT r.Registration_Id, r.RegistrantName, r.MailCity FROM Registrations r
		JOIN Organizations o ON o.Organization_Id = r.Organization_Id
		WHERE r.RegistrantName LIKE @bldgname 
		AND r.RegistrantType = 'INTERNATIONAL'
		AND r.Status IN ('A','B')
		AND 
		((CONVERT(varbinary(20),r.LocalAdminPassword) = CONVERT(varbinary(20),@password)
		AND r.LocalAdminPassword = @password)
		OR
		(CONVERT(varbinary(20),o.AdminPassword) = CONVERT(varbinary(20),@password)
		AND o.AdminPassword = @password))
	END
	ELSE -- US Schools
	BEGIN
		SELECT r.Registration_Id, r.RegistrantName, r.MailCity FROM Registrations r
		JOIN Organizations o ON o.Organization_Id = r.Organization_Id
		WHERE r.RegistrantName LIKE @bldgname AND r.MailState = @mailstate AND r.Status IN ('A','B')
		AND 
		((CONVERT(varbinary(20),r.LocalAdminPassword) = CONVERT(varbinary(20),@password)
		AND r.LocalAdminPassword = @password)
		OR
		(CONVERT(varbinary(20),o.AdminPassword) = CONVERT(varbinary(20),@password)
		AND o.AdminPassword = @password))
	END
END
GO

