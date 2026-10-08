-- Source: Speakup2026_2027.dbo.GetWeeklyReminderTests (scripted 2026-10-08)
-- =============================================
-- Author:		Bob O'Dell
-- Create date: 12/28/2019
-- Modified:	01/15/2020 - Corrected error in retrieving district results
--				11/02/2024 - change surveypage > 0 to SurveyPage IS NOT NULL
--				
-- Description:	Get a PT district and PT schools and provides a summary of the surveys taken to date
--				This is the same as GetWeeklyReminders - except it only pulls one district and one school to review the email
-- =============================================
CREATE PROCEDURE [dbo].[GetWeeklyReminderTests]
AS
BEGIN
	-- ORGANIZATION WEEKLY REMINDERS
	-- get a list of organizations and contact names and email addresses that are active and have opt-in email addresses
	SELECT organization_ID, orgname, ContactFirstName, ContactLastName, ContactEmail, SurveyPassword, AdminPassword, mailstate 
	INTO #tempOrg
	FROM organizations 
	WHERE Organization_ID = 25669

	SELECT * FROM #tempOrg -- this keeps the order of the tables the same

	-- get the corresponding counts for active buildings in the organization. This could return an empty set for
	-- organizations because no buildings are active
	SELECT o.Organization_ID, r.RegistrantName, r.MailState, r.Enrollment, r.Participation,
	(SELECT COUNT(*) FROM users_surveys u JOIN SurveyBank.dbo.surveys s ON u.survey_id = s.survey_id 
		WHERE s.survey_type IN ('STUDENT','STUSPAN') AND u.registration_id = r.registration_id AND u.QuesCompleted > 0 AND s.GroupSurvey = 0) AS students,
	(SELECT SUM(k2grpcnt) FROM users_surveys u JOIN SurveyBank.dbo.surveys s ON u.survey_id = s.survey_id 
		WHERE s.survey_type IN ('STUDENT','STUSPAN') AND u.registration_id = r.registration_id AND u.QuesCompleted > 0 AND s.GroupSurvey = 1) AS k2grp,
	(SELECT COUNT(*) FROM users_surveys u JOIN SurveyBank.dbo.surveys s ON u.survey_id = s.survey_id 
		WHERE s.survey_type = 'TEACHER' AND u.registration_id = r.registration_id AND u.QuesCompleted > 0 AND s.GroupSurvey = 0) AS teachers,
	(SELECT COUNT(*) FROM users_surveys u JOIN SurveyBank.dbo.surveys s ON u.survey_id = s.survey_id 
		WHERE s.survey_type = 'ADMIN' AND u.registration_id = r.registration_id AND u.QuesCompleted > 0 AND s.GroupSurvey = 0) AS administrators,
	(SELECT COUNT(*) FROM users_surveys u JOIN SurveyBank.dbo.surveys s ON u.survey_id = s.survey_id 
		WHERE (s.survey_type = 'FAMILY' OR s.survey_type = 'FAMSPAN') AND u.registration_id = r.registration_id AND u.QuesCompleted > 0 AND s.GroupSurvey = 0) AS parents,
	(SELECT SUM(k2grpcnt) FROM users_surveys u JOIN SurveyBank.dbo.surveys s ON u.survey_id = s.survey_id 
		WHERE (s.survey_type = 'FAMILY' OR s.survey_type = 'FAMSPAN') AND u.registration_id = r.registration_id AND u.QuesCompleted > 0 AND s.GroupSurvey = 1) AS pargrp,
	(SELECT COUNT(*) FROM users_surveys u JOIN SurveyBank.dbo.surveys s ON u.survey_id = s.survey_id 
		WHERE s.survey_type = 'COMMUNITY' AND u.registration_id = r.registration_id AND u.QuesCompleted > 0 AND s.GroupSurvey = 0) AS community,
	(SELECT SUM(k2grpcnt) FROM users_surveys u JOIN SurveyBank.dbo.surveys s ON u.survey_id = s.survey_id 
		WHERE s.survey_type = 'COMMUNITY' AND u.registration_id = r.registration_id AND u.QuesCompleted > 0 AND s.GroupSurvey = 1) AS commgrp
	FROM Organizations o
	JOIN Registrations r ON r.organization_id = o.organization_id
	WHERE o.Organization_ID = 25669

	-- BUILDING WEEKLY REMINDERS
	-- get the counts for active buildings with opt-in emails
	SELECT r.Registration_ID, r.registrantname, r.ContactFirstName, r.ContactLastName, r.ContactEmail, r.MailState,
	r.LocalAdminPassword, r.LocalSurveyPassword, r.Enrollment, r.Participation,
	(SELECT COUNT(*) FROM users_surveys u JOIN SurveyBank.dbo.surveys s ON u.survey_id = s.survey_id 
		WHERE s.survey_type IN ('STUDENT','STUSPAN') AND u.registration_id = r.registration_id AND u.QuesCompleted > 0 AND s.GroupSurvey = 0) AS students,
	(SELECT SUM(k2grpcnt) FROM users_surveys u JOIN SurveyBank.dbo.surveys s ON u.survey_id = s.survey_id 
		WHERE s.survey_type IN ('STUDENT','STUSPAN') AND u.registration_id = r.registration_id AND u.QuesCompleted > 0 AND s.GroupSurvey = 1) AS k2grp,
	(SELECT COUNT(*) FROM users_surveys u JOIN SurveyBank.dbo.surveys s ON u.survey_id = s.survey_id 
		WHERE s.survey_type = 'TEACHER' AND u.registration_id = r.registration_id AND u.QuesCompleted > 0 AND s.GroupSurvey = 0) AS teachers,
	(SELECT COUNT(*) FROM users_surveys u JOIN SurveyBank.dbo.surveys s ON u.survey_id = s.survey_id 
		WHERE s.survey_type = 'ADMIN' AND u.registration_id = r.registration_id AND u.QuesCompleted > 0 AND s.GroupSurvey = 0) AS administrators,
	(SELECT COUNT(*) FROM users_surveys u JOIN SurveyBank.dbo.surveys s ON u.survey_id = s.survey_id 
		WHERE (s.survey_type = 'FAMILY' OR s.survey_type = 'FAMSPAN') AND u.registration_id = r.registration_id AND u.QuesCompleted > 0 AND s.GroupSurvey = 0) AS parents,
	(SELECT SUM(k2grpcnt) FROM users_surveys u JOIN SurveyBank.dbo.surveys s ON u.survey_id = s.survey_id 
		WHERE (s.survey_type = 'FAMILY' OR s.survey_type = 'FAMSPAN') AND u.registration_id = r.registration_id AND u.QuesCompleted > 0 AND s.GroupSurvey = 1) AS pargrp,
	(SELECT COUNT(*) FROM users_surveys u JOIN SurveyBank.dbo.surveys s ON u.survey_id = s.survey_id 
		WHERE s.survey_type = 'COMMUNITY' AND u.registration_id = r.registration_id AND u.QuesCompleted > 0 AND s.GroupSurvey = 0) AS community,
	(SELECT SUM(k2grpcnt) FROM users_surveys u JOIN SurveyBank.dbo.surveys s ON u.survey_id = s.survey_id 
		WHERE s.survey_type = 'COMMUNITY' AND u.registration_id = r.registration_id AND u.QuesCompleted > 0 AND s.GroupSurvey = 1) AS commgrp
	FROM Registrations r 
	WHERE Registration_ID = 211675

	
	-- Get the additional email addresses for weekly reminders
	-- done only for compatibility
	SELECT * FROM AddlWeeklyEmails

END
GO

