-- Source: Speakup2026_2027.dbo.GetStatePasswords (scripted 2026-10-08)
-- =============================================
-- Author:		Bob O'Dell
-- Create date: 09/01/2012
-- Modified: 
-- Description:	Retrieve the state passwords and contacts
-- =============================================
CREATE PROCEDURE [dbo].[GetStatePasswords]
	@state varchar(2)
AS
BEGIN
	SELECT * FROM StatePasswords WHERE State = @state;
END
GO

