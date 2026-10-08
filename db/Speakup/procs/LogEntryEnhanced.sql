-- Source: Speakup2026_2027.dbo.LogEntryEnhanced (scripted from local restore 2026-10-08)
-- =============================================
-- Author:		Bob O'Dell
-- Create date: 12/09/2009
-- Modified:	12/12/2011
-- Description:	Place an Enhanced Log Entry into the Speakup Log Table
-- =============================================
CREATE PROCEDURE [dbo].[LogEntryEnhanced]
	@Page_File varchar(50), -- Name of Web Page or other File making the entry
	@Method varchar(50), -- Method in page/file making the entry
	@EntryType varchar(20), -- DEBUG, ERROR, STATUS, SQL
	@IP varchar(50) = null, -- IP Address of the user associated with the error - REMOTE_ADDR
	@Referer varchar(200) = null, -- URL that called the page - HTTP_REFERER
	@UserAgent varchar(200)= null, -- Description of the browser or agent in use by the user - HTTP_USER_AGENT
	@ValueName varchar(50) = null, -- Name of the ID or parameter involved
	@Value varchar(100) = null, -- value of the id or parameter involved in the log entry
	@EntryText varchar(MAX) = null -- Message, System Error Message, parameters, SQL
AS
BEGIN
	INSERT INTO SpeakupLog (Page_File, Method, EntryType, IP, HTTP_Referer, HTTP_User_Agent, ValueName, Value, EntryText)
	VALUES (@Page_File, @Method, @EntryType,@IP, @Referer, @UserAgent, @ValueName, @Value, @EntryText)
END
GO

