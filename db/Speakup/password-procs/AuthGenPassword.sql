-- Source: Speakup2026_2027.dbo.AuthGenPassword (scripted 2026-10-08)
-- =============================================
-- Author:		Bob O'Dell
-- Create date: 06/22/2021
-- Modified:
-- Description:	Generate a 10 character password following one of two patterns
--				Staff may wish to generate a password that is sent to users.  This password will need to be reset by the user
-- =============================================
create PROCEDURE [dbo].[AuthGenPassword] 
	
AS
BEGIN

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


	-- The rules for the password are such it must include upper case letters, lower case letters, numbers and a special character
	-- At this time we have two different patterns we use

	-- Determine which pattern to use
	DECLARE @pattern DECIMAL, @password CHAR(10);
	SET @pattern = RAND() *1;

	-- Set up legal characters for the password
	DECLARE @lowercase char(25);
	DECLARE @uppercase char(25);
	DECLARE @numeric char(8);
	DECLARE @special char(7);

	SET @lowercase = 'abcdefghijkmnpqrstuvwxyz';
	SET @uppercase = 'ABCDEFGHIJKMNPQRSTUVWXYZ';
	SET @numeric = '23456789';
	SET @special = '!@#$%&';


	IF @pattern = 0 
		BEGIN
			-- pattern is LC, LC, UC, UC, N, N, N, UC, UC, SPEC
			SET @password = SUBSTRING(@lowercase, CAST(ROUND(RAND() * 23, 0) + 1 AS INT), 1)
			 + SUBSTRING(@lowercase, CAST(ROUND(RAND() * 23, 0) + 1 AS INT), 1)
			 + SUBSTRING(@uppercase, CAST(ROUND(RAND() * 23, 0) + 1 AS INT), 1)
			 + SUBSTRING(@uppercase, CAST(ROUND(RAND() * 23, 0) + 1 AS INT), 1)
			 + SUBSTRING(@numeric, CAST(ROUND(RAND() * 7, 0) + 1 AS INT), 1)
			 + SUBSTRING(@numeric, CAST(ROUND(RAND() * 7, 0) + 1 AS INT), 1)
			 + SUBSTRING(@numeric, CAST(ROUND(RAND() * 7, 0) + 1 AS INT), 1)
			 + SUBSTRING(@lowercase, CAST(ROUND(RAND() * 23, 0) + 1 AS INT), 1)
			 + SUBSTRING(@lowercase, CAST(ROUND(RAND() * 23, 0) + 1 AS INT), 1)
			 + SUBSTRING(@special, CAST(ROUND(RAND() * 5, 0) + 1 AS INT), 1)
			;
		END
	ELSE
		BEGIN
			-- pattern is SPEC, UC, LC, N, N, N, N, UC, LC, N
			SET @password = SUBSTRING(@special, CAST(ROUND(RAND() * 5, 0) + 1 AS INT), 1)
			 + SUBSTRING(@uppercase, CAST(ROUND(RAND() * 23, 0) + 1 AS INT), 1)
			 + SUBSTRING(@lowercase, CAST(ROUND(RAND() * 23, 0) + 1 AS INT), 1)
			 + SUBSTRING(@numeric, CAST(ROUND(RAND() * 7, 0) + 1 AS INT), 1)
			 + SUBSTRING(@numeric, CAST(ROUND(RAND() * 7, 0) + 1 AS INT), 1)
			 + SUBSTRING(@numeric, CAST(ROUND(RAND() * 7, 0) + 1 AS INT), 1)
			 + SUBSTRING(@numeric, CAST(ROUND(RAND() * 7, 0) + 1 AS INT), 1)
			 + SUBSTRING(@uppercase, CAST(ROUND(RAND() * 23, 0) + 1 AS INT), 1)
			 + SUBSTRING(@lowercase, CAST(ROUND(RAND() * 23, 0) + 1 AS INT), 1)
			 + SUBSTRING(@numeric, CAST(ROUND(RAND() * 5, 0) + 1 AS INT), 1)
			;
		END
    
	SELECT @password AS Password;
END
GO

