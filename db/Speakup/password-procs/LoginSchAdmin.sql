-- Source: Speakup2026_2027.dbo.LoginSchAdmin (scripted 2026-10-08)
-- =============================================
-- Author:		Bob O'Dell
-- Create date: 10/02/2014
-- Modified:	05/08/2015
--				04/07/2016 Updated password from varchar to nvarchar
--				05/11/2016 changed password back to varchar
--				09/15/2016 changed logic to check for case sensitive password
--				06/25/2018 update the registerdate as well as status when making activating a school or district
--				07/12/2018 set a return parameter to indicate whether the user was registered. 
--				07/26/2018 added organization id to the return for a building
--				08/03/2018 dealt with issue of IsRegistered not always in result set
--				08/08/2018 set look up to prefer an email address in org over in reg
--				08/23/2018 changed the logic so even if email address was in org, if password not found we try registrations if email exists there
--				09/05/2018 fixed issue where @orgnumFound could be NULL
--				09/18/2019 added registeremailsent to return for login - 0 if not found
--				09/23/2021 adding loging of last access date and count of number of accesses, also added return of date password changed
--				03/13/2022 added two additional checks to see if the email address is in the additional log-ins for the district or school - those log-ins are manually managed
-- Description:	Login a school administrator, returning type of organization district (ORG) or building (REG)
--				as well as detailed info if it fails (such as email address not present or bad password) 
-- =============================================
CREATE PROCEDURE [dbo].[LoginSchAdmin] 
	@email varchar(75),
	@password varchar(20),
	@isregistered bit = 0
AS
BEGIN
	DECLARE @cntOrgEmail int, @cntRegEmail int, @cntOrgEmailAddl int, @cntRegEmailAddl int, @orgid int, @regid int, @orgnumFound int, @regnumFound int, @status char(1), @regemailsent bit, @passwordupdated datetime;
	SELECT @cntOrgEmail = COUNT(*) FROM Organizations WHERE ContactEmail = @email;
	SELECT @cntRegEmail = COUNT(*) FROM Registrations WHERE ContactEmail = @email;
	SELECT @cntOrgEmailAddl = COUNT(*) FROM LogIn_Additional WHERE Organization_ID IS NOT NULL AND Email_Address = @email;
	SELECT @cntRegEmailAddl = COUNT(*) FROM LogIn_Additional WHERE Registration_ID IS NOT NULL AND Email_Address = @email;
	IF @cntOrgEmail = 0 AND @cntRegEmail = 0 AND @cntOrgEmailAddl = 0 AND @cntRegEmailAddl = 0
		SELECT 'EMAILNOTFOUND' AS Result;
	ELSE
		BEGIN -- The order of the ifs give precedence to organization emails since that is the last place looked at
			IF @cntOrgEmail > 0 -- if we have district records with that email
				BEGIN
					SELECT @orgid = Organization_ID, @status = Status, @regemailsent = RegisterEmailSent, @passwordupdated = AdminPassword_Changed
					FROM Organizations
					WHERE ContactEmail = @email
					--AND CONVERT(varbinary(20), AdminPassword) = CONVERT(varbinary(20),@password)
					AND AdminPassword = @password COLLATE SQL_Latin1_General_CP1_CS_AS
					AND Status NOT IN ('D', 'X');

					SET @orgnumFound = @@ROWCOUNT;
					IF @orgnumFound = 0  -- password doesn't match for the email address specified
						SELECT 'PASSWORDFAIL' AS Result, 'ORG' AS WhereFound, 0 AS IsRegistered, 0 AS RegisterEmailSent, NULL AS AdminPassword_Changed;
					IF @orgnumFound = 1 -- this is the good one
						BEGIN
							IF @status = 'U' -- if last year's contacts successfully logs in activate the district
								BEGIN
									SET @isregistered = 0
									UPDATE Organizations SET REGISTERDATE=GETDATE(), Status='A' WHERE Organization_ID = @orgid
									-- Set status to allow individual school contact to register UNLESS
									-- They've already registered ('A') or the school is closed ('X' or 'D')
									UPDATE Registrations SET REGISTERDATE=GETDATE(), Status = 'B' WHERE Organization_ID = @orgid
										AND Status NOT IN ('X', 'D', 'A')
								END
							ELSE
								SET @isregistered = 1
							UPDATE Organizations SET Contact_AccessCount = Contact_AccessCount+1, Contact_LastAccess = GETDATE() WHERE Organization_ID = @orgid
							SELECT @orgid AS Organization_Id, 'SUCCESS' AS Result, 'ORG' AS WhereFound, @isregistered AS IsRegistered, 
							@regemailsent AS RegisterEmailSent, @passwordupdated AS AdminPassword_Changed;
						END
					IF @orgnumFound > 1 -- unlikely but treat multiple emails with same password as an error
						SELECT 'MULTIPLEEMAILS' AS Result, 'ORG' AS WhereFound, 0 AS IsRegistered, 0 AS RegisterEmailSent, NULL AS AdminPassword_Changed;
				END

			-- Added March 13, 2022 for additional log-ins - follows the format of the original log-in but registeremailsent and adminpassword_changed aren't relevent
			ELSE IF @cntOrgEmailAddl > 0 -- only try this if the email address wasn't in orgs
				BEGIN
					SELECT @orgid = o.Organization_ID, @status = o.Status, @regemailsent = o.RegisterEmailSent, @passwordupdated = o.AdminPassword_Changed
					FROM Organizations o
					JOIN Login_Additional a ON a.Organization_ID = o.Organization_ID
					WHERE a.Email_Address = @email
					--AND CONVERT(varbinary(20), AdminPassword) = CONVERT(varbinary(20),@password)
					AND a.Password = @password COLLATE SQL_Latin1_General_CP1_CS_AS
					AND o.Status NOT IN ('D', 'X');

					SET @orgnumFound = @@ROWCOUNT;
					IF @orgnumFound = 0  -- password doesn't match for the email address specified
						SELECT 'PASSWORDFAIL' AS Result, 'ORGADDL' AS WhereFound, 0 AS IsRegistered, 0 AS RegisterEmailSent, NULL AS AdminPassword_Changed;
					IF @orgnumFound = 1 -- this is the good one
						BEGIN
							IF @status = 'U' -- if last year's contacts successfully logs in activate the district
								BEGIN
									SET @isregistered = 0
									UPDATE Organizations SET REGISTERDATE=GETDATE(), Status='A' WHERE Organization_ID = @orgid
									-- Set status to allow individual school contact to register UNLESS
									-- They've already registered ('A') or the school is closed ('X' or 'D')
									UPDATE Registrations SET REGISTERDATE=GETDATE(), Status = 'B' WHERE Organization_ID = @orgid
										AND Status NOT IN ('X', 'D', 'A')
								END
							ELSE
								SET @isregistered = 1
							UPDATE Organizations SET Contact_AccessCount = Contact_AccessCount+1, Contact_LastAccess = GETDATE() WHERE Organization_ID = @orgid
							SELECT @orgid AS Organization_Id, 'SUCCESS' AS Result, 'ORG' AS WhereFound, @isregistered AS IsRegistered, 
							@regemailsent AS RegisterEmailSent, @passwordupdated AS AdminPassword_Changed;
						END
					IF @orgnumFound > 1 -- unlikely but treat multiple emails with same password as an error
						SELECT 'MULTIPLEEMAILS' AS Result, 'ORG' AS WhereFound, 0 AS IsRegistered, 0 AS RegisterEmailSent, NULL AS AdminPassword_Changed;
				END

			IF @cntRegEmail > 0 AND (@orgnumFound = 0 OR @orgnumFound IS NULL)  -- if we have building records with that email and didn't match to a organization email and password
				BEGIN
					SELECT @regid = Registration_ID, @orgid = Organization_ID, @status = Status, @regemailsent = RegisterEmailSent, @passwordupdated = AdminPassword_Changed
					FROM Registrations
					WHERE ContactEmail = @email
					--AND CONVERT(varbinary(50), LocalAdminPassword) = CONVERT(varbinary(50),@password)
					AND LocalAdminPassword = @password COLLATE SQL_Latin1_General_CP1_CS_AS
					AND Status NOT IN ('D', 'X');

					SET @regnumFound = @@ROWCOUNT;
					IF @regnumFound = 0  -- password doesn't match for the email address specified
						SELECT 'PASSWORDFAIL' AS Result, 'REG' AS WhereFound, 0 AS IsRegistered, 0 AS RegisterEmailSent, NULL AS AdminPassword_Changed;
					IF @regnumFound = 1 -- this is the good one
						BEGIN
							 -- if last year's contacts successfully logs in activate the building if it isn't activate
							 -- 'B' means the district has been activated, but the building has not yet been individually activated
							IF @status = 'U' OR @status = 'B'
								BEGIN
									SET @isregistered = 0
									UPDATE Registrations SET REGISTERDATE=GETDATE(), Status = 'A' WHERE Registration_ID = @regid
								END
							ELSE
								SET @isregistered = 1
							UPDATE Registrations SET Contact_AccessCount = Contact_AccessCount+1, Contact_LastAccess = GETDATE() WHERE Registration_ID = @regid
							SELECT @regid AS Registration_Id, @orgid AS Organization_ID, 'SUCCESS' AS Result, 'REG' AS WhereFound, @isregistered AS IsRegistered, 
							@regemailsent AS RegisterEmailSent, @passwordupdated AS AdminPassword_Changed;
						END
					IF @regnumFound > 1 -- unlikely but treat multiple emails with same password as an error
						SELECT 'MULTIPLEEMAILS' AS Result, 'REG' AS WhereFound, 0 AS IsRegistered, 0 AS RegisterEmailSent, NULL AS AdminPassword_Changed;
				END

			ELSE IF @cntRegEmailAddl > 0 AND (@orgnumFound = 0 OR @orgnumFound IS NULL)  -- if we have building records with that email and didn't match to a organization email and password
				BEGIN
					SELECT @regid = r.Registration_ID, @orgid = r.Organization_ID, @status = r.Status, @regemailsent = r.RegisterEmailSent, @passwordupdated = r.AdminPassword_Changed
					FROM Registrations r
					JOIN Login_Additional a ON a.Registration_ID = r.Registration_ID
					WHERE a.Email_Address = @email
					--AND CONVERT(varbinary(20), AdminPassword) = CONVERT(varbinary(20),@password)
					AND a.Password = @password COLLATE SQL_Latin1_General_CP1_CS_AS
					AND r.Status NOT IN ('D', 'X');

					SET @regnumFound = @@ROWCOUNT;
					IF @regnumFound = 0  -- password doesn't match for the email address specified
						SELECT 'PASSWORDFAIL' AS Result, 'REG' AS WhereFound, 0 AS IsRegistered, 0 AS RegisterEmailSent, NULL AS AdminPassword_Changed;
					IF @regnumFound = 1 -- this is the good one
						BEGIN
							 -- if last year's contacts successfully logs in activate the building if it isn't activate
							 -- 'B' means the district has been activated, but the building has not yet been individually activated
							IF @status = 'U' OR @status = 'B'
								BEGIN
									SET @isregistered = 0
									UPDATE Registrations SET REGISTERDATE=GETDATE(), Status = 'A' WHERE Registration_ID = @regid
								END
							ELSE
								SET @isregistered = 1
							UPDATE Registrations SET Contact_AccessCount = Contact_AccessCount+1, Contact_LastAccess = GETDATE() WHERE Registration_ID = @regid
							SELECT @regid AS Registration_Id, @orgid AS Organization_ID, 'SUCCESS' AS Result, 'REG' AS WhereFound, @isregistered AS IsRegistered, 
							@regemailsent AS RegisterEmailSent, @passwordupdated AS AdminPassword_Changed;
						END
					IF @regnumFound > 1 -- unlikely but treat multiple emails with same password as an error
						SELECT 'MULTIPLEEMAILS' AS Result, 'REG' AS WhereFound, 0 AS IsRegistered, 0 AS RegisterEmailSent, NULL AS AdminPassword_Changed;
				END


		END
END
GO

