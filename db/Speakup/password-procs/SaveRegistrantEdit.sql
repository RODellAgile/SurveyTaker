-- Source: Speakup2026_2027.dbo.SaveRegistrantEdit (scripted 2026-10-08)
-- =============================================
-- Author:		Bob O'Dell
-- Create date: 5/26/2009
-- Modified:	05/08/2015
--				09/15/2016 submitdate now modified if its been over 9 months
--				09/09/2018 - added position type and religious affiliation
--				09/29/2018 - add default null to religiontype
--				12/24/2018 - added staff notes to the update
--				09/04/2019 - added linkcode if it is a new building
--				11/07/2019 - added contact phone
-- Description:	Save the Edits to the Registration Record.  This could mean inserting
--				a new record if it doesn't yet exist, 
--				participation is calculated using district participation percent
-- =============================================
CREATE PROCEDURE [dbo].[SaveRegistrantEdit] 
	@regid int,
	@regtype varchar(20),
	@orgid int,
	@linkcode varchar(4) = null,
	@NCESSCH varchar(20) = null,
	@NCES_PrivateID varchar(20) = null,
	@otherid varchar(20) = null,
	@regname varchar(100),
	@regcity varchar(50),
	@regstate varchar(2),
	@regzip varchar(20),
	@regcountry varchar(100),
	@religiontype varchar(50) = null, -- most of the time this is empty
	@enroll int,
	@contfirst varchar(50) = null,
	@contlast varchar(50) = null,
	@conttitle varchar(50)= null,
	@contposition varchar(50) = NULL, -- added late so this will prevent errors on pages that aren't providing it
	@contemail varchar(75) = null,
	@contphone varchar(50) = null,
	@emailoptinout varchar(10) = null,
	@adminpassword varchar(20) = null,
	@surveypassword varchar(20) = null,
	@status char(1),
	@staffnotes varchar(2000) = null
AS
BEGIN
	-- we need to update participation, so we need to obtain the percent of participation for the district
	DECLARE @partperc int;
	SELECT @partperc = ParticipationPerc FROM Organizations WHERE Organization_ID = @orgid

	-- if regid = 0 then we need to insert the record not update and return what the new id is
	IF @regid = 0
	BEGIN
		-- if a new registration, we know it is being activated so we set the submitdate
		INSERT INTO Registrations (LinkCode, Organization_ID, RegistrantType, NCESSCH, NCES_PrivateID, OtherID, 
		RegistrantName, MailCity, MailState, MailZIP, Country, ReligiousAffiliation, Enrollment, Participation,
		ContactFirstName, ContactLastName, ContactTitle, ContactPositionType, ContactEmail, EmailOptInOut, ContactPhone,
		LocalAdminPassword, LocalSurveyPassword, Status, SubmitDate, UpdateDate, InsertDate, Staff_Notes)
		VALUES(@linkcode, @orgid, @regtype, @NCESSCH, @NCES_PrivateID, @otherid, @regname, 
		@regcity, @regstate, @regzip, @regcountry, @religiontype, @enroll, CAST(@enroll * @partperc/100 AS int),
		@contfirst, @contlast, @conttitle, @contposition, @contemail, @emailoptinout, @contphone,
		@adminpassword, @surveypassword, @status, getdate(), getdate(), getdate(), @staffnotes);
		SELECT @@IDENTITY -- return the new registration id
	END
	ELSE
	BEGIN
		-- First check if this is just and update or whether it is an update and activate
		-- if status is not A then it is also an activation
		UPDATE Registrations SET SubmitDate=getdate() WHERE Registration_ID = @regid AND (Status not IN ('A','B') OR SubmitDate < DATEADD(m,-9,GetDate()) OR SubmitDate IS NULL); -- updates submit date if not active or if over 9 months ago

		UPDATE Registrations SET
			RegistrantType=@regtype, 
			NCESSCH=@NCESSCH, 
			NCES_PrivateID=@NCES_PrivateID,
			OtherID=@otherid, 
			RegistrantName=@regname, 
			MailCity=@regcity, 
			MailState=@regstate, 
			MailZIP=@regzip,
			Country=@regcountry,
			ReligiousAffiliation=@religiontype,
			Enrollment=@enroll,
			Participation=CAST(@enroll*@partperc/100 AS int),
			ContactFirstName=@contfirst, 
			ContactLastName=@contlast, 
			ContactTitle=@conttitle, 
			ContactPositionType=@contposition,
			ContactEmail=@contemail, 
			EmailOptInOut=@emailoptinout,
			ContactPhone = @contphone,
			LocalAdminPassword=@adminpassword,
			LocalSurveyPassword=@surveypassword,
			Status=@status, 
			UpdateDate=getdate(),
			Staff_Notes = @staffnotes
			WHERE Registration_ID = @regid;

			SELECT @regid  -- return the registration id
	END
END
GO

