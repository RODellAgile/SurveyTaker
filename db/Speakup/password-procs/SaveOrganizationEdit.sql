-- Source: Speakup2026_2027.dbo.SaveOrganizationEdit (scripted 2026-10-08)
-- =============================================
-- Author:		Bob O'Dell
-- Create date: 5/24/2009
-- Modified:	08/11/2011
--				09/15/2016 - submit date is updated now if it has been over 9 months
--				09/09/2018 - added position type and religious affiliation
--				12/24/2018 - added staff notes to the update
--				09/04/2019 - added linkcode for new districts
--				11/07/2019 - added contact phone
-- Description:	Save the Edits to the Organization Record.  This could mean inserting
--				a new record if it doesn't yet exist
-- =============================================
CREATE PROCEDURE [dbo].[SaveOrganizationEdit] 
	@orgid int,
	@linkcode varchar(4) = null, -- skipped unless it is new
	@orgtype varchar(20),
	@leaid varchar(20) = 0,
	@otherid varchar(20) = null,
	@orgname varchar(100),
	@orgcity varchar(50),
	@orgstate varchar(2),
	@orgzip varchar(20),
	@religiontype varchar(50) = NULL, -- most of the time this is empty
	@partperc int,
	@contfirst varchar(50),
	@contlast varchar(50),
	@conttitle varchar(50),
	@contposition varchar(50) = NULL, -- added late so this will prevent errors on pages that aren't providing it
	@contemail varchar(75),
	@contphone varchar(50) = NULL,  -- added in 2019, the NULL will prevent errors on pages that aren't providing it
	@emailoptinout varchar(10),
	@adminpswrd varchar(20),
	@surveypswrd varchar(20),
	@status char(1),
	@staffnotes varchar(2000) = null
AS
BEGIN
	-- if orgid = 0 then we need to insert the record not update and return what the new id is
	IF @orgid = 0
	BEGIN
		-- submitdate is set since it is new and we know we need to activate
		INSERT INTO Organizations (LinkCode, OrgType, LeaID, OtherID, OrgName, MailCity, MailState, MailZIP, ReligiousAffiliation,
		ParticipationPerc, ContactFirstName, ContactLastName, ContactTitle, ContactPositionType, ContactEmail, 
		EmailOptInOut, AdminPassword, SurveyPassword, Status, SubmitDate, UpdateDate, InsertDate, Staff_Notes)
		VALUES(@linkcode, @orgtype, @leaid, @otherid, @orgname, @orgcity, @orgstate, @orgzip, @religiontype,
		@partperc, @contfirst, @contlast, @conttitle, @contposition, @contemail, 
		@emailoptinout, @adminpswrd, @surveypswrd, @status, getdate(), getdate(), getdate(), @staffnotes);
		SELECT @@IDENTITY
	END
	ELSE
	BEGIN
		-- First check if this is just and update or whether it is an update and activate
		-- if status is not A then it is also an activation
		UPDATE Organizations SET SubmitDate=getdate() 
		WHERE Organization_ID = @orgid AND (Status <> 'A' OR SubmitDate < DATEADD(m,-9,GetDate()) OR SUBMITDATE IS NULL); -- updates submit date if not active or if over 9 months ago

		UPDATE Organizations SET
			OrgType=@orgtype, 
			LeaID=@leaid, 
			OtherID=@otherid, 
			OrgName=@orgname, 
			MailCity=@orgcity, 
			MailState=@orgstate, 
			MailZIP=@orgzip,
			ReligiousAffiliation=@religiontype,
			ParticipationPerc=@partperc,
			ContactFirstName=@contfirst, 
			ContactLastName=@contlast, 
			ContactTitle=@conttitle, 
			ContactPositionType=@contposition,
			ContactEmail=@contemail, 
			EmailOptInOut=@emailoptinout,
			AdminPassword=@adminpswrd, 
			SurveyPassword=@surveypswrd, 
			Status=@status, 
			UpdateDate=getdate(),
			Staff_Notes = @staffnotes
			WHERE Organization_ID = @orgid;
			SELECT @orgid
	END
END
GO

