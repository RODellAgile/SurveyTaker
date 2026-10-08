-- Source: Speakup2026_2027.dbo.ChangePassword (scripted 2026-10-08)
-- =============================================
-- Author:		Bob O'Dell
-- Create date: 09/23/2021
-- Description:	Change the Password for contact, either an organization (district) or registration (building)
-- =============================================
create PROCEDURE [dbo].[ChangePassword] 
	@newpassword NVARCHAR(50),
	@orgid INT = NULL, -- if a district this will be set and not null
	@regid INT = NULL -- if a school this will be set and not null
AS
BEGIN
	DECLARE @success bit;
	IF @orgid IS NOT NULL
	BEGIN
		UPDATE Organizations SET AdminPassword = @newpassword, AdminPassword_Changed = GETDATE()
		WHERE Organization_ID = @orgid;
		IF @@ROWCOUNT = 1
			SET @success = 1;
		ELSE
			SET @success = 0; -- return false if we didn't update anything - or somehow updated more than one
	END
	ELSE IF @regid IS NOT NULL
	BEGIN
		UPDATE Registrations SET LocalAdminPassword = @newpassword, AdminPassword_Changed = GETDATE()
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

