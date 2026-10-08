-- Source: Speakup2026_2027.dbo.ChkSETDAPassword (scripted 2026-10-08)
-- =============================================
-- Author:		Bob O'Dell
-- Create date: 03/06/2010
-- Modified:
-- Description:	Authenticate a SETDA member for access to reports
-- =============================================
create PROCEDURE [dbo].[ChkSETDAPassword] 
	@stateabbrev varchar(20),
	@password varchar(20)
AS
BEGIN
	SELECT * FROM SETDA_user
	WHERE state_abbr = @stateabbrev
	AND CONVERT(varbinary(20),Password) = CONVERT(varbinary(20),@password)
	AND Password = @password
END
GO

