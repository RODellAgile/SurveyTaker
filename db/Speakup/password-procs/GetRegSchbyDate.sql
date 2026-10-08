-- Source: Speakup2026_2027.dbo.GetRegSchbyDate (scripted 2026-10-08)
-- =============================================
-- Author:		Bob O'Dell
-- Create date: 11/28/2010
-- Modified:	05/08/2015
--				09/15/2016 - Added updatedate to return
--				08/07/2018 - Changed check by date to RegisterDate from SubmitDate
--				08/23/2018 - Added 3 fields to the basic information returned and then added a result set for the start and end dates for the school
-- Description:	Get School Registrations within a specified Date Range
-- =============================================
CREATE PROCEDURE [dbo].[GetRegSchbyDate] 
	@startdate datetime,
	@enddate datetime
AS
BEGIN
	-- First get all of the pertinent organization information needed for display
	-- Put it into a temp file so we can pull associated t
	SELECT organization_id, registration_id, registrantname, LocalAdminPassword, ContactFirstName, ContactLastName, ContactEmail, mailstate, 
	ApprovalRequired, HopeToAccomplish,	registerdate, submitdate, updatedate 
	INTO #regs
	FROM Registrations
	WHERE REGISTERDATE >= @startdate AND REGISTERDATE <= @enddate
	AND status = 'A'
	--AND status IN ('A','B')

	-- return all of the organization information
	SELECT * FROM #regs
	ORDER BY mailstate, registrantname

	-- Now get and return all of the timeperiod information
	SELECT * FROM OrgRegTimePeriod
	WHERE Registration_ID IN (SELECT Registration_ID FROM #regs)
	Order By PeriodCode;
END
GO

