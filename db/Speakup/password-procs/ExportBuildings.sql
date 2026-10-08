-- Source: Speakup2026_2027.dbo.ExportBuildings (scripted 2026-10-08)
-- =============================================
-- Author:		Bob O'Dell
-- Create date: 09/26/2009
-- Modified:	05/08/2015
--				11/13/2017 - now will only return buildings with contacts
-- Description:	Retrieve the information for Buildings needed for an Export
-- =============================================
CREATE PROCEDURE [dbo].[ExportBuildings] 
	@state varchar(20) = NULL
AS
BEGIN
	IF @state IS NULL -- if this is set to null we return all states
	BEGIN
		SELECT r.Registration_ID,
			r.RegistrantType,
			r.RegistrantName,
			o.Organization_ID,
			o.OrgName,
			o.AdminPassword,
			r.LocalAdminPassword,
			o.SurveyPassword,
			r.LocalSurveyPassword,
			r.ContactFirstName,
			r.ContactLastName,
			r.ContactTitle,
			r.ContactEmail,
			r.EmailOptInOut,
			r.MailCity,
			r.MailState,
			r.MailZIP,
			r.Country
		FROM Registrations r
		JOIN Organizations o ON o.Organization_Id = r.Organization_Id
		WHERE r.Status IN ('A','B') AND LEN(r.ContactEmail) > 0 
	END
	ELSE
	BEGIN
		SELECT r.Registration_ID,
			r.RegistrantType,
			r.RegistrantName,
			o.Organization_ID,
			o.OrgName,
			o.AdminPassword,
			r.LocalAdminPassword,
			o.SurveyPassword,
			r.LocalSurveyPassword,
			r.ContactFirstName,
			r.ContactLastName,
			r.ContactTitle,
			r.ContactEmail,
			r.EmailOptInOut,
			r.MailCity,
			r.MailState,
			r.MailZIP,
			r.Country
		FROM Registrations r
		JOIN Organizations o ON o.Organization_Id = r.Organization_Id
		WHERE r.Status IN ('A','B') AND r.mailstate = @state AND LEN(r.ContactEmail) > 0 
	END

END
GO

