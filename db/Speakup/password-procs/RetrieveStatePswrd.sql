-- Source: Speakup2026_2027.dbo.RetrieveStatePswrd (scripted 2026-10-08)
-- =============================================
-- Author:		Bob O'Dell
-- Create date: 10/13/2012
-- Modified:
-- Description:	Retrieve the contact, contact email and passwords for a state
--				emtpy result set returned if state not in state passwords
-- =============================================
CREATE PROCEDURE [dbo].[RetrieveStatePswrd] 
	@state varchar(50) -- state 2 char abbreviation
AS
BEGIN
	SELECT * FROM statepasswords
	WHERE state = @state
END
GO

