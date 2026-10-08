-- Source: Speakup2026_2027.dbo.UpdateState (scripted 2026-10-08)
-- =============================================
-- Author:		Bob O'Dell
-- Create date: 09/01/2012
-- Modified:
-- Description:	Update the state passwords and contact or enter them if this
--				state didn't have any (only district and school were used)
-- =============================================
CREATE PROCEDURE [dbo].[UpdateState] 
	@state varchar(2),
	@survpswrd varchar(20),
	@adminpswrd varchar(20),
	@contactemail varchar(100)
AS
BEGIN
	-- We handle this input a little differently.  This proc makes the determination whether or not
	-- the state information is in the database.  If not it inserts it, is it is - it updates it
	DECLARE @existsCnt int;
	SELECT @existsCnt = COUNT(*) FROM StatePasswords WHERE State = @state;

	IF @existsCnt = 0
		BEGIN
			INSERT INTO StatePasswords (State, SurveyPassword, AdminPassword, ContactEmail, Modified)
			VALUES (@state, @survpswrd, @adminpswrd, @contactemail, GETDATE());
		END
	ELSE -- state exists so update it
		BEGIN
			UPDATE StatePasswords SET
				SurveyPassword = @survpswrd,
				AdminPassword = @adminpswrd,
				ContactEmail = @contactemail,
				Modified = GETDATE()
			WHERE State = @state;
		END
END
GO

