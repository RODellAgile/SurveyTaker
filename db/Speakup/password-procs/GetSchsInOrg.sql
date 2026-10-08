-- Source: Speakup2026_2027.dbo.GetSchsInOrg (scripted 2026-10-08)
-- =============================================
-- Author:		Bob O'Dell	
-- Create date: 6/23/2009
-- Modified:	12/15/2009
-- Description:	Get the information about schools for a specific district from the registrations table
--				and those from NCES table that are not in the registrations table, merge the result
--				Since this will be used in grids, a unique id is needed, we concatenate a 'N' or 'R' 
--				to the relevant id (registration_id or NCESSCH) and use that as a unique id
-- =============================================
CREATE PROCEDURE [dbo].[GetSchsInOrg] 
	@orgid int -- need this id to start
AS
BEGIN
	DECLARE @leaid varchar(20) -- we can't use orgid as that is not in the NCES table
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Need to get the leaid.  There must be a record in organizations for this proc to be called
	-- successfully
	SET @leaid = (SELECT TOP 1 LeaID FROM Organizations WHERE Organization_ID = @orgid)
	IF (LEN(@leaid) > 0)
	BEGIN
		-- we have a district so we need to check for schools in that district in NCES
		SELECT DISTINCT 'R'+ CAST(Registration_ID AS VarChar) AS id, Registration_ID, NCESSCH, RegistrantName, 
		ContactFirstName, ContactLastName, ContactTitle, ContactEmail, EmailOptInOut, LocalAdminPassword, LocalSurveyPassword,
		ActivateEmailSent, Status 
		FROM Registrations
		WHERE Organization_ID = @orgid AND Status <> 'D'

		UNION
		-- only get the schools for this district from NCES that are not in 
		-- the registrations table
		SELECT 'O' + NCES_ID, 0, NCES_ID, Institut AS RegistrantName, '','','','','','','','', 'U' FROM NCES_PubPriv_Schools
		WHERE LeaID = @leaid
		AND NCES_ID NOT IN (SELECT DISTINCT NCESSCH FROM Registrations WHERE Organization_ID = @orgid AND NCESSCH IS NOT NULL)
		AND NCES_ID NOT IN (SELECT DISTINCT NCES_PrivateID FROM Registrations WHERE Organization_ID = @orgid AND NCES_PrivateID IS NOT NULL)
		ORDER BY RegistrantName
	END
	ELSE
	BEGIN
		-- not a public district so we only need to check the registrations table
		SELECT DISTINCT 'R'+ CAST(Registration_ID AS VarChar) AS id, Registration_ID, NCESSCH, RegistrantName, 
		ContactFirstName, ContactLastName, ContactTitle, ContactEmail, EmailOptInOut, LocalAdminPassword, LocalSurveyPassword,
		ActivateEmailSent, Status FROM Registrations
		WHERE Organization_ID = @orgid
	ORDER BY RegistrantName
	END
END
GO

