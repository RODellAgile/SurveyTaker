-- Source: Speakup2026_2027.dbo.UpdateRegion (scripted 2026-10-08)
-- =============================================
-- Author:		Bob O'Dell
-- Create date: 11/04/2024
-- Modified:
-- Description:	Inserts or updates the base record for a region (reporting)
-- =============================================
CREATE PROCEDURE [dbo].[UpdateRegion]
	@oldregionid varchar(20),
	@newregionid varchar(20),
	@regionname varchar(100),
	@desc varchar(2000),
	@contactlastname varchar(100),
	@contactfirstname varchar(100),
	@email varchar(100),
	@password varchar(20),
	@status varchar(10),
	@updatetype varchar(10)
AS
BEGIN
	DECLARE @result varchar(10), @uid INT;
	IF @updatetype = 'INSERT' -- insert region
	BEGIN
		SELECT @uid = uid FROM Regions WHERE region_id = @newregionid;
		IF @@ROWCOUNT > 0 SET @result = 'EXISTS';
		ELSE
		BEGIN
			INSERT INTO Regions (Region_id, Region_Name, Description, Contact_LastName, Contact_FirstName, Login_EmailAddress, Login_Password, Status)
			VALUES (@newregionid, @regionname, @desc, @contactlastname, @contactfirstname, @email, @password, @status)
			SET @result = 'SUCCESS';
		END
	END
	ELSE
	BEGIN
		UPDATE Regions SET
			Region_ID = @newregionid,
			Region_Name = @regionname, 
			Description = @desc, 
			Contact_LastName = @contactlastname, 
			Contact_FirstName = @contactfirstname, 
			Login_EmailAddress = @email, 
			Login_Password = @password, 
			Status = @status
			WHERE Region_id = @oldregionid;
			SET @result = 'SUCCESS';	
	END
	SELECT @result AS Result
END
GO

