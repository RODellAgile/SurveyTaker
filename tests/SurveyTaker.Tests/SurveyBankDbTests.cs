using SurveyTaker.Data;

namespace SurveyTaker.Tests;

// Integration tests against the local SurveyBank restore. Survey IDs are from the 2026-10-08 restore:
// 169 = Alabama Speak Up 3-5 (active, most-taken), 174 = Alabama K-2 group survey, 6 = archived.
public class SurveyBankDbTests
{
    private readonly SurveyBankDb _db = new(LocalDb.Connections);

    [Fact]
    public async Task ChkSurveyId_ReturnsActiveSurvey()
    {
        var s = await _db.ChkSurveyIdAsync(169);
        Assert.NotNull(s);
        Assert.Equal("STUDENT", s.SurveyType);
    }

    [Fact]
    public async Task ChkSurveyId_ReturnsNullForArchivedSurvey()
    {
        Assert.Null(await _db.ChkSurveyIdAsync(6));
    }

    [Fact]
    public async Task GetSurveyDesc_ReadsGroupFlag()
    {
        var s = await _db.GetSurveyDescAsync(174);
        Assert.NotNull(s);
        Assert.Equal(174, s.SurveyId);
        Assert.True(s.GroupSurvey);
    }

    [Fact]
    public async Task GetSurveyToTake_ReturnsQuestionsAndTheirOptions()
    {
        var def = await _db.GetSurveyToTakeAsync(169);

        Assert.NotEmpty(def.Questions);
        Assert.NotEmpty(def.Options);
        Assert.All(def.Questions, q => Assert.False(string.IsNullOrEmpty(q.QuestionType)));
        var questionIds = def.Questions.Select(q => q.QuestionId).ToHashSet();
        Assert.All(def.Options, o => Assert.Contains(o.QuestionId, questionIds));
        Assert.Equal(def.Questions.OrderBy(q => q.QuestionSort).Select(q => q.QuestionSort), def.Questions.Select(q => q.QuestionSort));
    }
}
