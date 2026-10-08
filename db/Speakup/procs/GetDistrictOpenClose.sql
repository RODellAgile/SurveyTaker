-- Source: Speakup2026_2027.dbo.GetDistrictOpenClose (scripted from local restore 2026-10-08)
-- =============================================
-- Author:		Bob O'Dell
-- Create date: 07/27/2019
-- Modified:
-- Description: Retrieve the Open and Closes or Manual Status of survey taking for a district
-- =============================================
CREATE PROCEDURE GetDistrictOpenClose 
	@orgid INT
AS
BEGIN
	SELECT * FROM DistrictOpenClose WHERE Organization_ID = @orgid;
END
GO

