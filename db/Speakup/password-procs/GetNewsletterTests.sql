-- Source: Speakup2026_2027.dbo.GetNewsletterTests (scripted 2026-10-08)
-- =============================================
-- Author:		Bob O'Dell
-- Create date: 12/28/2019
-- Modified:	01/15/2020 - Corrected error in retrieving district results
-- Description:	Get a PT district and PT schools and provides a summary of the surveys taken to date
--				This is the same as GetWeeklyReminders - except it only pulls one district and one school to review the email
-- =============================================
Create PROCEDURE [dbo].[GetNewsletterTests]
AS
BEGIN
	-- ORGANIZATION WEEKLY REMINDERS
	-- get a list of organizations and contact names and email addresses that are active and have opt-in email addresses
	SELECT organization_ID, orgname, ContactFirstName, ContactLastName, ContactEmail, SurveyPassword, AdminPassword, mailstate 
	INTO #tempOrg
	FROM organizations 
	WHERE Organization_ID = 25669

	SELECT * FROM #tempOrg -- this keeps the order of the tables the same


	-- BUILDING WEEKLY REMINDERS
	-- get the counts for active buildings with opt-in emails
	SELECT r.Registration_ID, r.registrantname, r.ContactFirstName, r.ContactLastName, r.ContactEmail, r.MailState,
	r.LocalAdminPassword, r.LocalSurveyPassword, r.Enrollment, r.Participation
	FROM Registrations r 
	WHERE Registration_ID = 211675

END
GO

