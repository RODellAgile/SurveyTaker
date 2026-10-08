-- Source: Speakup2026_2027.dbo.GetContactListA (scripted 2026-10-08)
-- =============================================
-- Author:		GetContactList
-- Create date: 08/16/2010
-- Modified:	05/08/2015
--				09/09/2017 - Accommodated case where status is null and then we want to return status
--				09/29/2018 - even if status is null we don't return closed/deleted schools
--				10/08/2018 - correct PRIVDISTRICT to PRIVDIST
-- Description:	Provide a list of districts/organizations that fit a criteria
--				to eventually show the contacts and passwords
-- =============================================
CREATE PROCEDURE [dbo].[GetContactListA]
	@regtype varchar(20), -- DISTRICT (org table), PUBSCHOOL, PRIVATE, INTERNATIONAL, OTHER
	@status char(1) = NULL, -- whether activated or not, NULL indicates we want all statuses
	@state varchar(2), 
	@country varchar(50) = null, -- this may not be present
	@instit varchar(20)
AS
BEGIN
	IF @regtype = 'DISTRICT' OR @regtype = 'CANDISTRICT' OR @regtype = 'CHARTER' OR @regtype = 'PRIVDIST' -- if district we need to look up in organization table
	BEGIN
		IF @status iS NULL
		BEGIN
			IF @country IS NULL
			BEGIN
				SELECT Organization_id AS id, OrgName AS name, Status FROM Organizations
				WHERE MailState = @state AND OrgName LIKE @instit AND OrgType = @regtype AND status NOT IN ('C','D');
			END
			ELSE
			BEGIN
				SELECT Organization_id AS id, OrgName AS name, Status FROM Organizations
				WHERE MailState = @state AND OrgName LIKE @instit AND OrgType = @regtype AND status NOT IN ('C','D')
				AND Country = @country;
			END
		END
		ELSE
		BEGIN
			IF @country IS NULL
			BEGIN
				SELECT Organization_id AS id, OrgName AS name FROM Organizations
				WHERE status = @status AND MailState = @state AND OrgName LIKE @instit AND OrgType = @regtype AND status NOT IN ('C','D');
			END
			ELSE
			BEGIN
				SELECT Organization_id AS id, OrgName AS name FROM Organizations
				WHERE status = @status AND MailState = @state AND OrgName LIKE @instit AND OrgType = @regtype AND status NOT IN ('C','D')
				AND Country = @country;
			END
		END
	END
	ELSE
	BEGIN
		IF @status IS NULL -- want all status codes
		BEGIN
			IF @country IS NULL
			BEGIN
				SELECT Registration_Id AS id, RegistrantName AS name, Status FROM registrations
				WHERE MailState = @state AND RegistrantName LIKE @instit
				AND registranttype = @regtype;
			END
			ELSE
			BEGIN
				SELECT Registration_Id AS id, RegistrantName AS name, Status FROM registrations
				WHERE MailState = @state AND RegistrantName LIKE @instit
				AND registranttype = @regtype AND Country = @country;
			END
		END
		IF @status = 'A' -- if lookup status is 'A' we need to also include 'B'
		BEGIN
			IF @country IS NULL
			BEGIN
				SELECT Registration_Id AS id, RegistrantName AS name FROM registrations
				WHERE status IN ('A','B') AND MailState = @state AND RegistrantName LIKE @instit
				AND registranttype = @regtype;
			END
			ELSE
			BEGIN
				SELECT Registration_Id AS id, RegistrantName AS name FROM registrations
				WHERE status IN ('A','B') AND MailState = @state AND RegistrantName LIKE @instit
				AND registranttype = @regtype AND Country = @country;
			END
		END
		ELSE -- status is not 'A' so we don't need special code
		BEGIN
			IF @country IS NULL
				BEGIN
					SELECT Registration_Id AS id, RegistrantName AS name FROM registrations
					WHERE status = @status AND MailState = @state AND RegistrantName LIKE @instit
					AND registranttype = @regtype;
				END
				ELSE
				BEGIN
					SELECT Registration_Id AS id, RegistrantName AS name FROM registrations
					WHERE status = @status AND MailState = @state AND RegistrantName LIKE @instit
					AND registranttype = @regtype AND Country = @country;
				END
		END
	END
END
GO

