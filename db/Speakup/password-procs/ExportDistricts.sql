-- Source: Speakup2026_2027.dbo.ExportDistricts (scripted 2026-10-08)
-- =============================================
-- Author:		Bob O'Dell
-- Create date: 09/26/2009
-- Modified:	12/11/2010
--				11/13/2017 - now will only return districts with contacts
-- Description:	Retrieve the information for Districts needed for an Export
-- =============================================
CREATE PROCEDURE [dbo].[ExportDistricts] 
	@state varchar(20) = null
AS
BEGIN
	IF @state IS null -- if this is set to null we return all states
	BEGIN
		SELECT Organization_ID,
			OrgName,
			OrgType,
			AdminPassword,
			SurveyPassword,
			ContactFirstName,
			ContactLastName,
			ContactTitle,
			ContactEmail,
			EmailOptInOut,
			MailCity,
			MailState,
			MailZIP,
			Country
		FROM Organizations
		WHERE Status='A' AND OrgType IN ('DISTRICT', 'CANDISTRICT', 'CHARTER', 'PRIVDISTRICT')  AND LEN(ContactEmail) > 0 
	END
	ELSE
	BEGIN
		SELECT Organization_ID,
			OrgName,
			OrgType,
			AdminPassword,
			SurveyPassword,
			ContactFirstName,
			ContactLastName,
			ContactTitle,
			ContactEmail,
			EmailOptInOut,
			MailCity,
			MailState,
			MailZIP,
			Country
		FROM Organizations 
		WHERE Status='A' AND OrgType IN ('DISTRICT', 'CANDISTRICT', 'CHARTER', 'PRIVDISTRICT') AND mailstate = @state  AND LEN(ContactEmail) > 0 
	END

END
GO

