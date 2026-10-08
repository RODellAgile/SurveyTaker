-- Source: Speakup2026_2027.dbo.GetRegDistbyDate (scripted 2026-10-08)
-- =============================================
-- Author:		Bob O'Dell
-- Create date: 11/28/2010
-- Modified:	08/09/2011
--				09/15/2017 - added logic to check update date as well as submit date
--				08/07/2018 - Changed check by date to RegisterDate from SubmitDate
--				08/23/2018 - Added 3 fields to the basic information returned and then added a result set for the start and end dates for the district
-- Description:	Get District Registrations within a specified Date Range
-- =============================================
CREATE PROCEDURE [dbo].[GetRegDistbyDate] 
	@startdate datetime,
	@enddate datetime
AS
BEGIN
	-- First get all of the pertinent organization information needed for display
	-- Put it into a temp file so we can pull associated t
	SELECT organization_id, orgname, ContactFirstName, ContactLastName, ContactEmail, AdminPassword, mailstate, 
	ApprovalRequired, HopeToAccomplish,	registerdate, submitdate, updatedate
	INTO #orgs
	FROM Organizations
	WHERE REGISTERDATE >= @startdate AND REGISTERDATE <= @enddate
	AND status = 'A';

	-- return all of the organization information
	SELECT * FROM #orgs
	ORDER BY mailstate, orgname;

	-- Now get and return all of the timeperiod information
	SELECT * FROM OrgRegTimePeriod
	WHERE Organization_ID IN (SELECT Organization_ID FROM #orgs)
	ORDER BY PeriodCode;
END
GO

