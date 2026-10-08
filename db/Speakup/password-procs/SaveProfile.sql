-- Source: Speakup2026_2027.dbo.SaveProfile (scripted 2026-10-08)
-- =============================================
-- Author:		Bob O'Dell
-- Create date: 08/18/2013
-- Modified:	06/24/2015
--				12/08/2015 - Activated buildings in a district when district is updated
--				09/23/2016 - added school name, city and zip as fields to be editted and saved
--				11/18/2016 - made @surveypassword optional
--				05/21/2018 - added two fields approval and accomplish
--				05/23/2018 - update registerdate if changing to status A (Active)
--				07/09/2018 - error in registerdate if change to status A - set all registration date not just the org/reg
--				07/25/2018 - error in registering buildings in a district being registered was missing organization id to link
--				09/09/2018 - added position type and religious affiliation
--				09/14/2018 - set school religious affilitations if update is for a district - normally will be NULL
--				09/02/2019 - added a default to optinout parameter
-- Description:	Save the profile for a administrator, either at the building level or for an entire district

-- THIS SHOULD BE OBSELETE AS OF 7/15/2019 - REPLACED BY FOUR PARTIAL PROFILE SAVES


-- =============================================
CREATE PROCEDURE [dbo].[SaveProfile]
	@id int,
	@type varchar(10),
	@firstname varchar(50),
	@lastname varchar(50),
	@title varchar(50),
	@position varchar(50) = NULL, -- added late so this will prevent errors on pages that aren't providing it
	@email varchar(100),
	@optinout varchar(10) = 'OPTIN',
	@adminpassword varchar(20),
	@surveypassword varchar(20) = NULL,
	@instname varchar(100),
	@instcity varchar(50),
	@instzip varchar(20),
	@religiontype varchar(50) = NULL, -- most of the time this is empty
	@approval bit = NULL,
	@accomplish varchar(MAX) = ''
AS
BEGIN
	DECLARE @currentstatus CHAR(1); -- determine if current status is other than active for setting registerdate
	IF @type = 'REG' -- single building
	BEGIN
		-- Determine current status before updating
		SELECT @currentstatus = Status FROM Registrations WHERE Registration_ID=@id;

		UPDATE Registrations SET
			ContactFirstName = @firstname,
			ContactLastName = @lastname,
			ContactTitle = @title,
			ContactPositionType=@position,
			ContactEmail = @email,
			EmailOptInOut = @optinout,
			LocalAdminPassword = @adminpassword,
			LocalSurveyPassword = @surveypassword,
			RegistrantName = @instname,
			MailCity = @instcity,
			MailZip = @instzip,
			ReligiousAffiliation = @religiontype,
			ApprovalRequired = @approval,
			HopeToAccomplish = @accomplish,
			Status = 'A', -- if they save a profile assume they are active
			UpdateDate = GETDATE()
		WHERE registration_id = @id;

		-- Update registerdate if status changed to A
		IF @currentstatus <> 'A'
		BEGIN
			UPDATE Registrations SET RegisterDate = GETDATE() WHERE registration_id = @id;
		END
	END
	ELSE -- district with all of the buildings
	BEGIN
		-- Determine current status before updating
		SELECT @currentstatus = Status FROM Organizations WHERE organization_id=@id;

		-- Update the Organization records
		UPDATE Organizations SET
			ContactFirstName = @firstname,
			ContactLastName = @lastname,
			ContactTitle = @title,
			ContactPositionType=@position,
			ContactEmail = @email,
			EmailOptInOut = @optinout,
			AdminPassword = @adminpassword,
			SurveyPassword = @surveypassword,
			OrgName = @instname,
			MailCity = @instcity,
			MailZip = @instzip,
			ReligiousAffiliation = @religiontype,
			ApprovalRequired = @approval,
			HopeToAccomplish = @accomplish,
			Status = 'A', -- if they save a profile assume they are active
			UpdateDate = GETDATE()
		WHERE organization_id = @id;

		-- Update registerdate if status changed to A
		IF @currentstatus <> 'A'
		BEGIN
			UPDATE Organizations SET RegisterDate = GETDATE() WHERE organization_id = @id;
		END


		-- Activate the associated building records that are not activated
		-- We activate with a B instead of an A, since it is activated from the district level
		UPDATE REGISTRATIONS SET
			ReligiousAffiliation = @religiontype, Status = 'B', RegisterDate = GETDATE()
		WHERE Status = 'U' AND Organization_ID = @id;
	END
END
GO

