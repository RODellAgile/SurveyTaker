-- Source: Speakup2026_2027.dbo.LogEntryPoint (scripted from local restore 2026-10-08)
-- =============================================
-- Author:		Bob O'Dell
-- Create date: 09/28/2019
-- Modified:
-- Description:	Keep track of how users are entering to take a survey
-- =============================================
CREATE PROCEDURE LogEntryPoint 
	@orglinkcode varchar(5) = null, -- could have org or reg linkcode or a registration id
	@reglinkcode varchar(5) = null,
	@regid int = null,
	@survid int = null, -- many entry points will not have survey id
	@entrypoint varchar(50) -- the setting to null is in case I mess up a call
AS
BEGIN
	INSERT INTO EntryLog (OrgLinkCode, RegLinkCode, Registration_ID, Survey_ID, EntryPoint, EntryDate)
	VALUES (@orglinkcode, @reglinkcode, @regid, @survid, @entrypoint, GETDATE());
END
GO

