-- Source: Speakup2026_2027.dbo.LoginForReports (scripted 2026-10-08)
-- =============================================
-- Author:		Bob O'Dell
-- Create date: 02/12/2019
-- Modified:	
-- Description:	Allows access to reports just using the password, skipping the email address
-- =============================================
CREATE PROCEDURE [dbo].[LoginForReports] 
	@password VARCHAR(20),
	@orgid INT = NULL,
	@regid INT = NULL
AS
BEGIN
	DECLARE @found varchar(20) = 'NOTFOUND';

	IF @orgid IS NOT NULL
	BEGIN
		SELECT * INTO #temp FROM Organizations WHERE Organization_ID = @orgid AND AdminPassword = @password;
		IF @@ROWCOUNT > 0 
			SET @found = 'FOUND'; 
	END
	ELSE IF @regid IS NOT NULL
	BEGIN
		-- first see if it is an organization password being used for a building
		SELECT r.* INTO #temp2 FROM Registrations r 
		JOIN Organizations o ON o.Organization_ID = r.Organization_ID
		WHERE r.Registration_ID = @regid AND o.AdminPassword = @password;
		IF @@ROWCOUNT > 0 
			SET @found = 'FOUND'; 
		ELSE
			BEGIN
				SELECT * INTO #temp3 FROM Registrations 
				WHERE Registration_ID = @regid AND LocalAdminPassword = @password;
				IF @@ROWCOUNT > 0
					SET @found = 'FOUND'; 
			END
	END

	SELECT @found AS Result;
END
GO

