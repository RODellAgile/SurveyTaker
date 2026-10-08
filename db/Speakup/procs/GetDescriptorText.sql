-- Source: Speakup2026_2027.dbo.GetDescriptorText (scripted from local restore 2026-10-08)
-- =============================================
-- Author:		Bob O'Dell
-- Create date: 07/15/2019
-- Modified:	
-- Description:	Pulls the extended text for a stored and editable text field in the system
-- =============================================
CREATE PROCEDURE GetDescriptorText 
	@descriptor varchar(100)
AS
BEGIN
	SELECT * 
	FROM DescriptorText
	WHERE Descriptor = @descriptor;
END
GO

