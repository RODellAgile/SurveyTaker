-- Source: Speakup2026_2027.dbo.GetContactListB (scripted 2026-10-08)
-- =============================================
-- Author:		GetContactList
-- Create date: 08/16/2010
-- Modified:	06/24/2015
--				09/09/2017 - Added Status to ALL returns
--			    08/21/2018 - Missing U status on school return
--				10/08/2018 - correct PRIVDISTRICT to PRIVDIST
--				10/14/2020 - added natlorselectdistrict to result when a district is returned
-- Description:	Provides contact and passwords of an organization and school
-- =============================================
CREATE PROCEDURE [dbo].[GetContactListB]
	@regtype varchar(20),
	@id int
AS
BEGIN
	IF @regtype = 'DISTRICT' OR @regtype = 'CANDISTRICT' OR @regtype = 'CHARTER' OR @regtype = 'PRIVDIST'
	BEGIN
		SELECT organization_id, OrgName, ContactFirstName, ContactLastName, 
		ContactEmail, AdminPassword, SurveyPassword, MailCity, MailState, MailZip, NatlOrSelectDistrict, Status
		FROM Organizations 
		WHERE organization_id = @id;

		SELECT registration_id, RegistrantName, ContactFirstName, ContactLastName,
		ContactEmail, LocalAdminPassword, LocalSurveyPassword, MailCity, MailState, MailZip, Status
		FROM Registrations 
		WHERE organization_id = @id AND status IN ('A','B','U');
	END
	ELSE
	BEGIN
		DECLARE @orgid int;
		SELECT @orgid = organization_id FROM registrations
		WHERE registration_id = @id

		SELECT organization_id, OrgName, ContactFirstName, ContactLastName, 
		ContactEmail, AdminPassword, SurveyPassword, MailCity, MailState, MailZip, NatlOrSelectDistrict, Status
		FROM Organizations 
		WHERE organization_id = @orgid;

		SELECT registration_id, RegistrantName, ContactFirstName, ContactLastName,
		ContactEmail, LocalAdminPassword, LocalSurveyPassword, MailCity, MailState, MailZip, Status
		FROM Registrations 
		WHERE registration_id = @id AND status IN ('A', 'B', 'U');

	END
END
GO

