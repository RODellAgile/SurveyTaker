-- Source: Speakup2026_2027.dbo.UpdateK2GrpCnt (scripted from local restore 2026-10-08)
-- =============================================
-- Author:		Bob O'Dell
-- Create date: 11/28/2009
-- Modified:	11/06/2010
-- Description:	Update the K2 student count for a single K2 Group Survey from teacher input
-- =============================================
CREATE PROCEDURE [dbo].[UpdateK2GrpCnt] 
	@takensurveyid int,
	@k2grpcnt int
AS
BEGIN
	-- Calculate the number of students and save
	UPDATE users_surveys 
	SET k2grpcnt = @k2grpcnt 
	WHERE taken_survey_id = @takensurveyid
END
GO

