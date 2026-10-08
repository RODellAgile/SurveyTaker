-- Source: Speakup2026_2027.dbo.GetNewsletterRecipients (scripted 2026-10-08)
-- =============================================
-- Author:		Bob O'Dell
-- Create date: 01/18/2020
-- Modified:	11/21/2020 - shouldn't be sending newsletter texts to district records in registrations
-- Based on the GetWeeklyReminders library
-- Description:	Get each active district and all schools
--				to be included there must be an email address and it must be marked for opt-in
--				also gets each school that is active and which has a contact email address that is marked in
--				opt-in
-- =============================================
CREATE PROCEDURE [dbo].[GetNewsletterRecipients]
AS
BEGIN
	-- ORGANIZATION 
	-- get a list of organizations and contact names and email addresses that are active and have opt-in email addresses
	SELECT organization_ID, orgname, ContactFirstName, ContactLastName, ContactEmail, SurveyPassword, AdminPassword, mailstate 
	INTO #tempOrg
	FROM organizations 
	WHERE status='A' AND Len(ContactEmail) > 0 AND EmailOptInOut = 'OPTIN'
	ORDER BY mailstate, orgname

	SELECT * FROM #tempOrg -- this keeps the order of the tables the same

	-- BUILDING 
	SELECT r.Registration_ID, r.registrantname, r.ContactFirstName, r.ContactLastName, r.ContactEmail, r.MailState,
	r.LocalAdminPassword, r.LocalSurveyPassword, r.Enrollment, r.Participation
	FROM Registrations r 
	WHERE r.status IN ('A') AND LEN(r.ContactEmail) > 0 AND r.EmailOptInOut = 'OPTIN' AND r.RegistrantType <> 'DISTRICT'
	ORDER BY r.mailstate, r.registrantname
END
GO

