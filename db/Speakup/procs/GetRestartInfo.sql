-- Source: Speakup2026_2027.dbo.GetRestartInfo (scripted from local restore 2026-10-08)
-- =============================================
-- Author:		Bob O'Dell
-- Create date: 11/11/2009
-- Modified:	09/11/2010
-- Description:	Retrieve Information Needed to Restart a Survey if the Session Variables get Lost
-- =============================================
create PROCEDURE [dbo].[GetRestartInfo] 
	@takensurveyid int
AS
BEGIN
	SELECT * FROM users_surveys
	WHERE taken_survey_id = @takensurveyid
END
GO

