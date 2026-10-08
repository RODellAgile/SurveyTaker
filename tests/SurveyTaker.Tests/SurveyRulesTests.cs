using SurveyTaker.Data;

namespace SurveyTaker.Tests;

public class SurveyRulesTests
{
    private static SurveyQuestion Q(int sort) => new() { QuestionSort = sort };
    private static SurveyOption O(int id, string text) => new() { OptionId = id, OptionText = text };

    [Fact]
    public void OnePerPage_GridRowsShareAPage()
    {
        // sorts: 1, 2, 2, 2 (a three-row grid), 3
        var pages = SurveyRules.AssignPages([Q(1), Q(2), Q(2), Q(2), Q(3)], 1);
        Assert.Equal([1, 2, 2, 2, 3], pages);
    }

    [Fact]
    public void FivePerPage_IsBySortRangeNotCount()
    {
        // Legacy boundaries are sort values 6, 11, ... — the 7-row grid at sort 3 doesn't push anything off page 1.
        var qs = new List<SurveyQuestion> { Q(1), Q(2) };
        qs.AddRange(Enumerable.Repeat(0, 7).Select(_ => Q(3)));
        qs.AddRange([Q(4), Q(5), Q(6), Q(10), Q(11)]);
        var pages = SurveyRules.AssignPages(qs, 5);
        Assert.Equal([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 3], pages);
    }

    [Fact]
    public void SortGaps_StillAdvanceOnePageAtATime()
    {
        // Legacy quirk: a jump in sort values only moves one page, so 1-per-page stays one sort per page.
        Assert.Equal([1, 2, 3], SurveyRules.AssignPages([Q(1), Q(5), Q(9)], 1));
    }

    [Theory]
    [InlineData("Other (please specify)")]
    [InlineData("  other:")]
    [InlineData("OTRO")]
    [InlineData("Otra razón")]
    public void FindOther_MatchesStartsWith(string text)
    {
        Assert.Equal(9, SurveyRules.FindOtherOptionId([O(1, "Yes"), O(9, text)]));
    }

    [Fact]
    public void FindOther_LastMatchWins_AndNullWhenNone()
    {
        Assert.Equal(3, SurveyRules.FindOtherOptionId([O(2, "Other A"), O(3, "Other B")]));
        Assert.Null(SurveyRules.FindOtherOptionId([O(1, "Yes"), O(2, "No")]));
    }
}

public class LoggingAndProgressTests
{
    [Fact]
    public void QuestionsBeforePage_CountsRowsOnEarlierPages()
    {
        int[] pages = [1, 2, 2, 2, 3];
        Assert.Equal(0, SurveyRules.QuestionsBeforePage(pages, 1));
        Assert.Equal(1, SurveyRules.QuestionsBeforePage(pages, 2));
        Assert.Equal(4, SurveyRules.QuestionsBeforePage(pages, 3));
        Assert.Equal(5, SurveyRules.QuestionsBeforePage(pages, 4)); // past the end = total rows
    }

    [Fact]
    public async Task LogEntryEnhanced_WritesAndTruncatesLongValues()
    {
        var marker = "ST.Test." + Guid.NewGuid().ToString("N")[..12];
        await new SpeakupDb(LocalDb.Connections).LogEntryEnhancedAsync(
            new LogEntry(marker, "Test", "DEBUG", UserAgent: new string('x', 500), EntryText: "integration test"));

        await using var cn = new Microsoft.Data.SqlClient.SqlConnection(LocalDb.Options.Speakup);
        var ua = await Dapper.SqlMapper.QuerySingleAsync<string>(cn, "SELECT HTTP_User_Agent FROM SpeakupLog WHERE Page_File = @marker", new { marker });
        Assert.Equal(200, ua.Length);
        await Dapper.SqlMapper.ExecuteAsync(cn, "DELETE FROM SpeakupLog WHERE Page_File = @marker", new { marker });
    }

    [Fact]
    public async Task LogEntryEnhanced_AcceptsEntryWithNoText()
    {
        // SpeakupLog.EntryText is NOT NULL; found when the completion page's log row was silently dropped.
        var marker = "ST.Test." + Guid.NewGuid().ToString("N")[..12];
        await new SpeakupDb(LocalDb.Connections).LogEntryEnhancedAsync(new LogEntry(marker, "Test", "LOG"));

        await using var cn = new Microsoft.Data.SqlClient.SqlConnection(LocalDb.Options.Speakup);
        Assert.Equal(1, await Dapper.SqlMapper.ExecuteScalarAsync<int>(cn, "SELECT COUNT(*) FROM SpeakupLog WHERE Page_File = @marker", new { marker }));
        await Dapper.SqlMapper.ExecuteAsync(cn, "DELETE FROM SpeakupLog WHERE Page_File = @marker", new { marker });
    }
}
