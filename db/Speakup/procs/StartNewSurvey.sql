-- Source: Speakup2026_2027.dbo.StartNewSurvey (scripted from local restore 2026-10-08)
-- =============================================
-- Author:		Bob O'Dell
-- Create date: 07/26/2009
-- Modified:	09/11/2010
--				01/15/2022 - Added a new parameter to save quesperpage
-- Description:	Insert a new survey taken record and return the taken_survey_id
-- =============================================
CREATE PROCEDURE [dbo].[StartNewSurvey] 
	@surveyid int,
	@organizationid int,
	@registrationid int,
	@surveyname varchar(100),
	@surveytitle varchar(100),
	@surveytype varchar(50),
	@quesperpage int = 5, -- default to 5 questions per page if not specified
	@ip varchar(50)
AS
BEGIN
	-- -1 signals this is a new survey not yet started
	INSERT INTO users_surveys 
	(survey_id, organization_id, registration_id, surveyname, surveytitle, surveytype, quesperpage, userip, startquesoffset)
	VALUES 
	(@surveyid, @organizationid, @registrationid, @surveyname, @surveytitle, @surveytype, @quesperpage, @ip, -1) 
	SELECT @@IDENTITY
END
GO

