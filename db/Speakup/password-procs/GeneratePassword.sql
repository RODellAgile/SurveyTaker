-- Source: Speakup2026_2027.dbo.GeneratePassword (scripted 2026-10-08)
-- =============================================
-- Author:		Bob O'Dell	
-- Create date: 04/04/2019
-- Description:	Generate a random password
-- =============================================
CREATE PROCEDURE GeneratePassword 
    @len int,
    @min tinyint = 48,
    @range tinyint = 74,
    @exclude varchar(50) = '0:;<=>?@O[]`^\/',
    @output varchar(50) output
AS

	declare @char char
    set @output = ''
 
    while @len > 0 begin
       select @char = char(round(rand() * @range + @min, 0))
       if charindex(@char, @exclude) = 0 
	   begin
           set @output += @char
           set @len = @len - 1
       end
END
GO

