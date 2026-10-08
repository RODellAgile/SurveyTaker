-- Source: Speakup2026_2027.dbo.GetFullyActiveStates (scripted 2026-10-08)
-- =============================================
-- Author:		Bob O'Dell
-- Create date: 10/08/2012
-- Modified:
-- Description:	Obtain a list of states found in the state password table
-- =============================================
CREATE PROCEDURE [dbo].[GetFullyActiveStates]
AS
BEGIN
	SELECT state_abbr, state_name FROM States	
	WHERE state_abbr IN (SELECT state FROM StatePasswords);
END
GO

