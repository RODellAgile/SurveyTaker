using Dapper;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Options;
using SurveyTaker.Data;
using SurveyTaker.Web.Services;

namespace SurveyTaker.Tests;

// Development surveys (SpeakupAdmin Survey Building), against the local restores: needs SurveyBank surveys.Status
// (SpeakupAdmin db/surveybank-status-and-audit.sql) and MarkTestSurveyTake (db/Speakup/procs/). A Development copy of
// survey 169 is created and removed here.
public class DevelopmentSurveyTests
{
    private const int TestOrg = 25669, OtherOrg = 34245;
    private static readonly SurveyBankDb Bank = new(LocalDb.Connections);
    private static readonly SpeakupDb Speakup = new(LocalDb.Connections);

    private static SurveyAccess Access(bool on) =>
        new(Bank, Options.Create(new SurveyOptions { DevelopmentSurveys = on, TestOrganizationId = TestOrg }));

    private static async Task<int> CreateDevelopmentCopyAsync()
    {
        await using var cn = new SqlConnection(LocalDb.Options.SurveyBank);
        return await cn.ExecuteScalarAsync<int>("""
            INSERT INTO surveys (title, name, total_questions, survey_type, Group_With, GroupSurvey, intro, outro, sort_order, archive, Include, Exclude, u_date, c_date, Status)
            SELECT title, 'Unit test development survey', total_questions, survey_type, Group_With, GroupSurvey, intro, outro, sort_order, 1, Include, Exclude, GETDATE(), GETDATE(), 'D'
            FROM surveys WHERE survey_id = 169;
            SELECT CAST(SCOPE_IDENTITY() AS int);
            """);
    }

    private static async Task DeleteSurveyAsync(int id)
    {
        await using var cn = new SqlConnection(LocalDb.Options.SurveyBank);
        await cn.ExecuteAsync("DELETE FROM surveys WHERE survey_id = @id", new { id });
    }

    [Fact]
    public async Task OnlyTheTestOrganization_CanStartADevelopmentSurvey_AndOnlyWhenSwitchedOn()
    {
        var dev = await CreateDevelopmentCopyAsync();
        try
        {
            var found = await Access(on: true).FindStartableAsync(dev, TestOrg);
            Assert.NotNull(found);
            Assert.True(found.IsDevelopment);
            Assert.Null(await Access(on: true).FindStartableAsync(dev, OtherOrg));
            Assert.Null(await Access(on: false).FindStartableAsync(dev, TestOrg));      // before the cutover

            Assert.Contains(await Access(on: true).DevelopmentSurveysAsync(TestOrg), s => s.SurveyId == dev);
            Assert.Empty(await Access(on: true).DevelopmentSurveysAsync(OtherOrg));
            Assert.Empty(await Access(on: false).DevelopmentSurveysAsync(TestOrg));
        }
        finally { await DeleteSurveyAsync(dev); }
    }

    [Fact]
    public async Task ActiveSurveys_AreUnchanged_ForEveryone()
    {
        foreach (var org in new[] { TestOrg, OtherOrg })
        {
            var s = await Access(on: true).FindStartableAsync(169, org);
            Assert.NotNull(s);
            Assert.False(s.IsDevelopment);
        }
        Assert.Null(await Access(on: true).FindStartableAsync(6, TestOrg));   // archived/inactive: nobody
    }

    [Fact]
    public async Task MarkTestSurveyTake_SetsUseSurveyZero_OnlyForTheMatchingOrganization()
    {
        var tsi = await Speakup.StartNewSurveyAsync(new NewSurvey(169, TestOrg, 107261, "Unit test", "Speak Up 2026-27", "STUDENT", 1, "127.0.0.1"));
        try
        {
            Assert.Equal(0, await Speakup.MarkTestSurveyTakeAsync(tsi, OtherOrg));   // wrong organization: untouched
            await using var cn = new SqlConnection(LocalDb.Options.Speakup);
            Assert.Equal(1, await cn.ExecuteScalarAsync<int>("SELECT CAST(UseSurvey AS int) FROM users_surveys WHERE TAKEN_SURVEY_ID = @tsi", new { tsi }));
            Assert.Equal(1, await Speakup.MarkTestSurveyTakeAsync(tsi, TestOrg));
            Assert.Equal(0, await cn.ExecuteScalarAsync<int>("SELECT CAST(UseSurvey AS int) FROM users_surveys WHERE TAKEN_SURVEY_ID = @tsi", new { tsi }));
        }
        finally { await LocalDb.DeleteTestSurveyAsync(tsi); }
    }
}
