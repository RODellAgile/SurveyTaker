-- Source: Speakup2026_2027.dbo.GetInstInDistrict (scripted from local restore 2026-10-08)
-- =============================================
-- Author:		Bob O'Dell
-- Create date: 08/18/2013
-- Modified:	08/30/2013
--				10/02/2016 - Added 'C' as status to skip
--				11/14/2017 - Added RegistrantType to results
--				07/27/2019 - Added LinkCode to results
--				02/19/2021 - Added RegistrantType to order by - will put the district at the top of the list
-- Description:	Get a list of buildings in a district
-- =============================================
CREATE PROCEDURE [dbo].[GetInstInDistrict]
	@orgid int
AS
BEGIN
	-- Get the district information
	SELECT organization_id AS id, orgname AS instname, mailcity, mailstate, mailzip, 
	contactfirstname, contactlastname, contacttitle, contactemail, LinkCode
	FROM Organizations
	WHERE organization_id = @orgid
	-- Get the information about the schools in the district
	SELECT registration_id AS id, registrantname AS instname, registrantType, mailcity, mailstate, mailzip, 
	contactfirstname, contactlastname, contacttitle, contactemail, LinkCode
	FROM Registrations
	WHERE organization_id = @orgid AND organization_id IS NOT NULL AND status NOT IN ('X','D','C')
	ORDER BY registrantType, registrantname
END
GO

