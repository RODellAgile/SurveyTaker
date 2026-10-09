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
    public async Task GetRegistrationByLinkCode_FindsSchoolAndItsDistrict()
    {
        await using var cn = new Microsoft.Data.SqlClient.SqlConnection(LocalDb.Options.Speakup);
        var (code, regId, orgId) = await Dapper.SqlMapper.QueryFirstAsync<(string, int, int)>(cn,
            "SELECT TOP 1 LinkCode, Registration_ID, Organization_ID FROM Registrations WHERE LinkCode IS NOT NULL AND Organization_ID IS NOT NULL ORDER BY Registration_ID DESC");

        var school = await _db.GetRegistrationByLinkCodeAsync(code);
        Assert.NotNull(school);
        Assert.Equal(regId, school.RegistrationId);
        Assert.Equal(orgId, school.OrganizationId);

        Assert.Null(await _db.GetRegistrationByLinkCodeAsync("ZZZZ-not-a-code"));
    }

    [Fact]
    public async Task DistrictLookups_ReturnOnlySafeColumnsAndMatchByIdOrCode()
    {
        // 34245 = Lawrence County Schools (AL), link code DKYW, in the 2026-10-08 restore
        var byId = await _db.GetOrganizationByIdAsync(34245);
        var byCode = await _db.GetOrganizationByLinkCodeAsync("DKYW");
        Assert.NotNull(byId);
        Assert.NotNull(byCode);
        Assert.Equal(byId.OrganizationId, byCode.OrganizationId);
        Assert.Equal("AL", byId.MailState);
        Assert.Null(await _db.GetOrganizationByLinkCodeAsync("NOPE1"));
    }

    [Fact]
    public async Task SchoolPicker_ListsOpenSchoolsInTheDistrict()
    {
        var schools = await _db.GetSchoolsForSurveyAsync(34245);
        Assert.NotEmpty(schools);
        Assert.Contains(schools, s => s.RegistrationId == 145777); // Hatton High School
        Assert.All(schools, s => Assert.False(string.IsNullOrEmpty(s.RegistrantName)));
    }

    [Fact]
    public async Task SurveyPickers_ReturnTypesAndSurveysForTheDistrict()
    {
        var types = await _db.GetSurveyTypesAsync(34245, "SUACTIVE");
        Assert.Contains(types, t => t.SurveyType == "STUDENT");
        var surveys = await _db.GetSurveyListAsync(34245, "STUDENT", "SUACTIVE");
        Assert.NotEmpty(surveys);
        Assert.All(surveys, s => Assert.Equal("STUDENT", s.SurveyType));
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
