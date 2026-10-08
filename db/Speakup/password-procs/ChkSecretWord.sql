-- Source: Speakup2026_2027.dbo.ChkSecretWord (scripted 2026-10-08)
-- =============================================
-- Author:		Bob O'Dell
-- Create date: 05/26/2009
-- Modified:	09/01/2012
-- Description:	Authenticate a user who is logging in to take a test
--				They can authenicate from a password at the building, district or state level
-- =============================================
CREATE PROCEDURE [dbo].[ChkSecretWord] 
	@registrationid int,
	@password varchar(20)
AS
BEGIN
	SELECT COUNT(*) From Registrations r
	JOIN Organizations o ON r.Organization_ID = o.Organization_Id
	LEFT OUTER JOIN StatePasswords p ON r.MailState = p.State
	WHERE Registration_ID = @registrationid AND
	-- First check the local building password 
	((CONVERT(varbinary(20), r.LocalSurveyPassword) = CONVERT(varbinary(20),@password)
	AND r.LocalSurveyPassword = @password)
	OR -- Then check the district password
	(CONVERT(varbinary(20), o.SurveyPassword) = CONVERT(varbinary(20),@password)
	AND o.SurveyPassword = @password)
	OR -- Then check the state password
	(CONVERT(varbinary(20), p.SurveyPassword) = CONVERT(varbinary(20),@password)
	AND p.SurveyPassword = @password))
END
GO

