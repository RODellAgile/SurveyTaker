-- Source: Speakup2026_2027.dbo.GetWeeklyReminders (scripted 2026-10-08)
-- =============================================
-- Author:		Bob O'Dell
-- Create date: 08/05/2009
-- Modified:	05/08/2015
--				10/26/2015 -- Added status 'B' to building weekly reminders
--              07/05/2018 - updated location of survey bank
--				03/25/2019 - Modified the queries to only send emails for active within the last week.  In addition we pull counts only for those districts and schools in the 7 day list
--				03/26/2019 - added a constraint that some questions must be completed
--				01/18/2020 - Made the queries look the individual summaries for querying - this added group_with in a couple of cases, Use_survey=1 and added a test on groups to ensure value isn't null
--				01/27/2020 - Set the returns to ignore optin optout
--				05/01/2021 - Because of how we are doing registrations this year I had to add code to allow status U in orgs and regs where they have taken surveys
--				05/02/2021 - changed so any active marked org or building gets email or anyone who has completed a query
--				11/02/2024 - change surveypage > 0 to SurveyPage IS NOT NULL
--				03/28/2025 - changed Surveypage IS NOT NULL to QuesCompleted > 0
-- Description:	Get each active district and all schools and provides a summary of the surveys taken to date
--				to be included there must be an email address and it must be marked for opt-in
--				also gets each school that is active and which has a contact email address that is marked in
--				opt-in, provides a summary of the surveys taken to date
-- =============================================
CREATE PROCEDURE [dbo].[GetWeeklyReminders]
AS
BEGIN
	-- ORGANIZATION WEEKLY REMINDERS
	-- get a list of organizations and contact names and email addresses that are active and have opt-in email addresses
	SELECT organization_ID, orgname, ContactFirstName, ContactLastName, ContactEmail, SurveyPassword, AdminPassword, mailstate 
	INTO #tempOrg
	FROM organizations 
	WHERE (status = 'A' OR (status = 'U' AND organization_id IN (SELECT organization_ID FROM users_surveys))) AND Len(ContactEmail) > 0 --AND EmailOptInOut = 'OPTIN'
	--AND Organization_ID IN (SELECT Organization_ID FROM Users_Surveys 
	--WHERE LastUpdate > DATEADD(day,-8,GETDATE()) AND SurveyPage IS NOT NULL)  removed per Pilar 5/2/2021
	ORDER BY mailstate, orgname

	SELECT * FROM #tempOrg -- this keeps the order of the tables the same

	-- get the corresponding counts for active buildings in the organization. This could return an empty set for
	-- organizations because no buildings are active
	SELECT o.Organization_ID, r.RegistrantName, r.MailState, r.Enrollment, r.Participation,
	(SELECT COUNT(*) FROM users_surveys u JOIN SurveyBank.dbo.surveys s ON u.survey_id = s.survey_id 
		WHERE s.survey_type IN ('STUDENT','STUSPAN') AND u.registration_id = r.registration_id AND u.QuesCompleted > 0 AND s.GroupSurvey = 0 AND u.UseSurvey = 1) AS students,
	(SELECT SUM(k2grpcnt) FROM users_surveys u JOIN SurveyBank.dbo.surveys s ON u.survey_id = s.survey_id 
		WHERE s.survey_type IN ('STUDENT','STUSPAN') AND u.registration_id = r.registration_id AND u.QuesCompleted > 0 AND s.GroupSurvey = 1 AND u.UseSurvey = 1 AND u.k2GrpCnt IS NOT NULL ) AS k2grp,
	(SELECT COUNT(*) FROM users_surveys u JOIN SurveyBank.dbo.surveys s ON u.survey_id = s.survey_id 
		WHERE (Group_With = 'TEACHER' OR Group_With = 'LIBRARIAN') AND u.registration_id = r.registration_id AND u.QuesCompleted > 0 AND s.GroupSurvey = 0 AND u.UseSurvey = 1) AS teachers,
--	(SELECT COUNT(*) FROM users_surveys u JOIN SurveyBank.dbo.surveys s ON u.survey_id = s.survey_id -- made like district summary 01/18/2020
--		WHERE s.survey_type = 'TEACHER' AND u.registration_id = r.registration_id AND u.SurveyPage IS NOT NULL AND s.GroupSurvey = 0 AND u.UseSurvey = 1) AS teachers,
	(SELECT COUNT(*) FROM users_surveys u JOIN SurveyBank.dbo.surveys s ON u.survey_id = s.survey_id 
		WHERE Group_With IN ('DISTRICTADMIN','SCHOOLADMIN','TECHLEADER') AND u.registration_id = r.registration_id AND u.QuesCompleted > 0 AND s.GroupSurvey = 0 AND u.UseSurvey = 1) AS administrators,
--	(SELECT COUNT(*) FROM users_surveys u JOIN SurveyBank.dbo.surveys s ON u.survey_id = s.survey_id  -- made like district summary 01/18/2020
--		WHERE s.survey_type = 'ADMIN' AND u.registration_id = r.registration_id AND u.SurveyPage IS NOT NULL AND s.GroupSurvey = 0 AND u.UseSurvey = 1) AS administrators,
	(SELECT COUNT(*) FROM users_surveys u JOIN SurveyBank.dbo.surveys s ON u.survey_id = s.survey_id 
		WHERE (s.survey_type = 'FAMILY' OR s.survey_type = 'FAMSPAN') AND u.registration_id = r.registration_id AND u.QuesCompleted > 0 AND s.GroupSurvey = 0 AND u.UseSurvey = 1) AS parents,
	(SELECT SUM(k2grpcnt) FROM users_surveys u JOIN SurveyBank.dbo.surveys s ON u.survey_id = s.survey_id 
		WHERE (s.survey_type = 'FAMILY' OR s.survey_type = 'FAMSPAN') AND u.registration_id = r.registration_id AND u.QuesCompleted > 0 AND s.GroupSurvey = 1 AND u.UseSurvey = 1 AND u.k2GrpCnt IS NOT NULL ) AS pargrp,
	(SELECT COUNT(*) FROM users_surveys u JOIN SurveyBank.dbo.surveys s ON u.survey_id = s.survey_id 
		WHERE s.survey_type = 'COMMUNITY' AND u.registration_id = r.registration_id AND u.QuesCompleted > 0 AND s.GroupSurvey = 0 AND u.UseSurvey = 1) AS community,
	(SELECT SUM(k2grpcnt) FROM users_surveys u JOIN SurveyBank.dbo.surveys s ON u.survey_id = s.survey_id 
		WHERE s.survey_type = 'COMMUNITY' AND u.registration_id = r.registration_id AND u.QuesCompleted > 0 AND s.GroupSurvey = 1 AND u.UseSurvey = 1 AND u.k2GrpCnt IS NOT NULL) AS commgrp
	FROM Organizations o
	JOIN Registrations r ON r.organization_id = o.organization_id
	WHERE (o.status = 'A' OR (o.status = 'U' AND o.organization_id IN (SELECT organization_ID FROM users_surveys))) 
	AND (r.status IN ('A','B') OR (r.status='U' AND r.registration_id IN (SELECT registration_id FROM users_surveys))) 
	AND LEN(o.ContactEmail) > 0 AND o.EmailOptInOut = 'OPTIN'
	AND o.Organization_ID IN (SELECT Organization_ID FROM #tempOrg)
	ORDER BY o.Organization_ID, r.RegistrantName

	-- BUILDING WEEKLY REMINDERS
	-- get the counts for active buildings with opt-in emails
	SELECT r.Registration_ID, r.registrantname, r.ContactFirstName, r.ContactLastName, r.ContactEmail, r.MailState,
	r.LocalAdminPassword, r.LocalSurveyPassword, r.Enrollment, r.Participation,
	(SELECT COUNT(*) FROM users_surveys u JOIN SurveyBank.dbo.surveys s ON u.survey_id = s.survey_id 
		WHERE s.survey_type IN ('STUDENT','STUSPAN') AND u.registration_id = r.registration_id AND u.QuesCompleted > 0 AND s.GroupSurvey = 0 AND u.UseSurvey = 1) AS students,
	(SELECT SUM(k2grpcnt) FROM users_surveys u JOIN SurveyBank.dbo.surveys s ON u.survey_id = s.survey_id 
		WHERE s.survey_type IN ('STUDENT','STUSPAN') AND u.registration_id = r.registration_id AND u.QuesCompleted > 0 AND s.GroupSurvey = 1 AND u.UseSurvey = 1 AND u.k2GrpCnt IS NOT NULL) AS k2grp,
	(SELECT COUNT(*) FROM users_surveys u JOIN SurveyBank.dbo.surveys s ON u.survey_id = s.survey_id 
		WHERE (Group_With = 'TEACHER' OR Group_With = 'LIBRARIAN') AND u.registration_id = r.registration_id AND u.QuesCompleted > 0 AND s.GroupSurvey = 0 AND u.UseSurvey = 1) AS teachers,
	(SELECT COUNT(*) FROM users_surveys u JOIN SurveyBank.dbo.surveys s ON u.survey_id = s.survey_id 
		WHERE Group_With IN ('DISTRICTADMIN','SCHOOLADMIN','TECHLEADER') AND u.registration_id = r.registration_id AND u.QuesCompleted > 0 AND s.GroupSurvey = 0 AND u.UseSurvey = 1) AS administrators,
--	(SELECT COUNT(*) FROM users_surveys u JOIN SurveyBank.dbo.surveys s ON u.survey_id = s.survey_id  -- made like school summary 01/18/2020
--		WHERE s.survey_type = 'TEACHER' AND u.registration_id = r.registration_id AND u.SurveyPage IS NOT NULL AND s.GroupSurvey = 0) AS teachers,
--	(SELECT COUNT(*) FROM users_surveys u JOIN SurveyBank.dbo.surveys s ON u.survey_id = s.survey_id   -- made like school summary 01/18/2020
--		WHERE s.survey_type = 'ADMIN' AND u.registration_id = r.registration_id AND u.SurveyPage IS NOT NULL AND s.GroupSurvey = 0) AS administrators,
	(SELECT COUNT(*) FROM users_surveys u JOIN SurveyBank.dbo.surveys s ON u.survey_id = s.survey_id 
		WHERE (s.survey_type = 'FAMILY' OR s.survey_type = 'FAMSPAN') AND u.registration_id = r.registration_id AND u.QuesCompleted > 0 AND s.GroupSurvey = 0 AND u.UseSurvey = 1) AS parents,
	(SELECT SUM(k2grpcnt) FROM users_surveys u JOIN SurveyBank.dbo.surveys s ON u.survey_id = s.survey_id 
		WHERE (s.survey_type = 'FAMILY' OR s.survey_type = 'FAMSPAN') AND u.registration_id = r.registration_id AND u.QuesCompleted > 0 AND s.GroupSurvey = 1 AND u.UseSurvey = 1 AND u.k2GrpCnt IS NOT NULL) AS pargrp,
	(SELECT COUNT(*) FROM users_surveys u JOIN SurveyBank.dbo.surveys s ON u.survey_id = s.survey_id 
		WHERE s.survey_type = 'COMMUNITY' AND u.registration_id = r.registration_id AND u.QuesCompleted > 0 AND s.GroupSurvey = 0 AND u.UseSurvey = 1) AS community,
	(SELECT SUM(k2grpcnt) FROM users_surveys u JOIN SurveyBank.dbo.surveys s ON u.survey_id = s.survey_id 
		WHERE s.survey_type = 'COMMUNITY' AND u.registration_id = r.registration_id AND u.QuesCompleted > 0 AND s.GroupSurvey = 1 AND u.UseSurvey = 1 AND u.k2GrpCnt IS NOT NULL) AS commgrp
	FROM Registrations r 
	WHERE (r.status IN ('A','B') OR (r.status='U' AND r.registration_id IN (SELECT registration_id FROM users_surveys))) AND LEN(r.ContactEmail) > 0 --AND r.EmailOptInOut = 'OPTIN'
	--AND Registration_ID IN (SELECT Registration_ID FROM Users_Surveys WHERE LastUpdate > DATEADD(day,-8,GETDATE()) AND SurveyPage IS NOT NULL) removed per Pilar 5/2/2021
	ORDER BY r.mailstate, r.registrantname

	
	-- Get the additional email addresses for weekly reminders
	SELECT * FROM AddlWeeklyEmails

END
GO

