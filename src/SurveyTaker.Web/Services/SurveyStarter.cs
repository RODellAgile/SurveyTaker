using Microsoft.Extensions.Options;
using SurveyTaker.Data;

namespace SurveyTaker.Web.Services;

/// <summary>
/// Creates the users_surveys row for a confirmed school + survey and returns the intro URL. Shared by the /S/
/// and /D/ start pages so both write identical rows (legacy StartSurvey + GoToSurvey).
/// </summary>
public sealed class SurveyStarter(
    SpeakupDb speakup,
    SurveyBankDb surveyBank,
    SurveyLinks links,
    SurveyLog log,
    IOptions<SeasonOptions> season,
    IOptions<SurveyOptions> options)
{
    public async Task<string> StartAsync(HttpContext http, int organizationId, int registrationId, int surveyId, string logPage)
    {
        var desc = await surveyBank.GetSurveyDescAsync(surveyId)
                   ?? throw new InvalidOperationException($"Survey {surveyId} not found in SurveyBank.");

        var tsi = await speakup.StartNewSurveyAsync(new NewSurvey(
            SurveyId: surveyId,
            OrganizationId: organizationId,
            RegistrationId: registrationId,
            SurveyName: desc.Name ?? "",
            SurveyTitle: season.Value.SurveyTitle,
            SurveyType: desc.SurveyType ?? "",
            QuesPerPage: options.Value.QuesPerPage,
            Ip: http.Connection.RemoteIpAddress?.ToString() ?? ""));

        await log.Info(logPage, "StartSurvey", "orgId/regId/surveyId", $"{organizationId}/{registrationId}/{surveyId}", $"TSI {tsi}");

        http.Response.Cookies.Append("ProjectTomorrowSurvey", tsi.ToString(), new CookieOptions
        {
            Expires = DateTimeOffset.UtcNow.AddHours(3), HttpOnly = true, Secure = true, SameSite = SameSiteMode.Lax,
        });
        return links.Url("intro", tsi);
    }
}
