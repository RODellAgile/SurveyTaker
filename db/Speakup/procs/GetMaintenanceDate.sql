-- Source: Speakup2026_2027.dbo.GetMaintenanceDate (scripted from local restore 2026-10-08)
-- =============================================
-- Author:		Bob O'Dell
-- Create date: 06/18/2020
-- Description:	Get the maintenance date and time if any
-- =============================================
CREATE PROCEDURE GetMaintenanceDate 
AS
BEGIN
	SELECT * FROM Maintenance
END
GO

