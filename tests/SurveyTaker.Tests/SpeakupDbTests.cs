using SurveyTaker.Data;

namespace SurveyTaker.Tests;

// Integration tests against the local Speakup2026_2027 restore.
public class SpeakupDbTests
{
    private readonly SpeakupDb _db = new(LocalDb.Connections);

    [Fact]
    public async Task GetSurveyDates_FindsCurrentSeason()
    {
        var dates = await _db.GetSurveyDatesAsync("2026");
        Assert.NotNull(dates);
        Assert.NotNull(dates.OpenDate);
        Assert.True(dates.DistrictCloseDate > dates.OpenDate);
    }

    [Fact]
    public async Task GetMaintenanceDate_ReturnsRows()
    {
        Assert.NotEmpty(await _db.GetMaintenanceDateAsync());
    }

    [Fact]
    public async Task SurveyLifecycle_WritesAndReadsBack()
    {
        var tsi = await _db.StartNewSurveyAsync(new NewSurvey(
            SurveyId: 174, OrganizationId: 0, RegistrationId: 0,
            SurveyName: "TEST - SurveyTaker integration", SurveyTitle: "Speak Up 2026-27",
            SurveyType: "STUDENT", QuesPerPage: 1, Ip: "127.0.0.1"));
        try
        {
            Assert.True(tsi > 0);

            var started = await _db.GetRestartInfoAsync(tsi);
            Assert.NotNull(started);
            Assert.Equal(174, started.SurveyId);
            Assert.Equal(1, started.QuesPerPage);
            Assert.Equal(-1, started.StartQuesOffset); // proc marks "not yet started" with -1
            Assert.False(started.IsCompleted);

            await _db.UpdateK2GrpCntAsync(tsi, 22);

            // First save of question 1 (two options) and a text question.
            await _db.SaveQuestionAnswersAsync(tsi, [1, 2],
                [new Answer(1, 10, null), new Answer(1, 11, null), new Answer(2, null, "hello")]);
            // Re-saving question 1 must replace its rows, not add to them.
            await _db.SaveQuestionAnswersAsync(tsi, [1], [new Answer(1, 12, "other text")]);

            var answers = await _db.RetrievePartialSurveyAsync(tsi);
            Assert.Equal(2, answers.Count);
            Assert.Contains(new Answer(1, 12, "other text"), answers);
            Assert.Contains(new Answer(2, null, "hello"), answers);

            await _db.UpdateSurveyProgressAsync(tsi, quesOffset: 1, page: 2, quesCompleted: 2);
            await _db.MarkSurveyCompletedAsync(tsi, quesCompleted: 2);

            var done = await _db.GetRestartInfoAsync(tsi);
            Assert.NotNull(done);
            Assert.Equal(22, done.K2GrpCnt);
            Assert.Equal(2, done.SurveyPage);
            Assert.Equal(2, done.QuesCompleted);
            Assert.True(done.IsCompleted);
        }
        finally
        {
            await LocalDb.DeleteTestSurveyAsync(tsi);
        }
    }
}
