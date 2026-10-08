-- Source: Speakup2026_2027.dbo.GetOrganizationInfo (scripted from local restore 2026-10-08)
-- =============================================
-- Author:		Bob O'Dell
-- Create date: 5/24/2009
-- Modified:	12/24/3018 - Added in results sets for optional information and changed structure of lookup
--				07/28/2019 - Added parameter of linkcode which is the alternative to organization_id
-- Description:	Bring back all of the information for an Organization located
--				in the Organizations Table based on type of ID such as LeaId or Org_Id
-- =============================================
CREATE PROCEDURE [dbo].[GetOrganizationInfo] 
	@orgid int = 0,
	@linkcode varchar(10) = NULL,
	@leaid varchar(20) = ''
AS
BEGIN
	IF @orgid = 0 AND @linkcode IS NOT NULL
		BEGIN
			SELECT @orgid = Organization_ID FROM Organizations WHERE linkcode = @linkcode ;
		END
	ELSE IF @orgid = 0 -- must be leaid though not used much any more
		BEGIN
			SELECT @orgid = Organization_ID FROM Organizations WHERE leaid = @leaid;
		END

	SELECT o.*, i.District_Students, i.ulocal FROM Organizations o
	LEFT OUTER JOIN Institution.dbo.Institution i ON i.INST_UID = o.INST_UID
	 WHERE o.Organization_ID = @orgid;
    SELECT * FROM OrgRegAdditionalTools WHERE organization_id = @orgid;
    SELECT * FROM OrgRegAudience WHERE organization_id = @orgid;
    SELECT * FROM OrgRegTimePeriod WHERE organization_id = @orgid;
    SELECT * FROM AddlWeeklyEmails WHERE organization_id = @orgid;
END
GO

