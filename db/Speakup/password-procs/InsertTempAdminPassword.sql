-- Source: Speakup2026_2027.dbo.InsertTempAdminPassword (scripted 2026-10-08)
-- =============================================
-- Author:		Bob O'Dell
-- Create date: 08/28/2024
-- Description:	Insert a new Admin password for district or school.  This does not mark AdminPassword_Changed so that this password will need to be updated by the user
-- =============================================
CREATE PROCEDURE [dbo].[InsertTempAdminPassword] 
	@newpassword NVARCHAR(50),
	@orgid INT = NULL, -- if a district this will be set and not null
	@regid INT = NULL -- if a school this will be set and not null
AS
BEGIN
	DECLARE @success bit;
	IF @orgid IS NOT NULL
	BEGIN
		UPDATE Organizations SET AdminPassword = @newpassword
		WHERE Organization_ID = @orgid;
		IF @@ROWCOUNT = 1
			SET @success = 1;
		ELSE
			SET @success = 0; -- return false if we didn't update anything - or somehow updated more than one
	END
	ELSE IF @regid IS NOT NULL
	BEGIN
		UPDATE Registrations SET LocalAdminPassword = @newpassword
		WHERE Registration_ID = @regid;
		IF @@ROWCOUNT = 1
			SET @success = 1;
		ELSE
			SET @success = 0; -- return false if we didn't update anything - or somehow updated more than one
	END
	ELSE
	BEGIN
		SET @success = 0; -- if both were null return unsuccessful
	END
	SELECT @success AS RetVal
END
GO

