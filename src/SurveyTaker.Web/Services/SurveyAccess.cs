using Microsoft.Extensions.Options;
using SurveyTaker.Data;

namespace SurveyTaker.Web.Services;

/// <summary>
/// Which survey may be started for an organization. Active surveys (ChkSurveyId: archive = 0) for everyone, as
/// before. With Survey:DevelopmentSurveys on (after the Survey Building cutover), the test organization may also
/// start Development surveys (SurveyBank Status 'D', archive 1). Nobody else can, whatever the link says.
/// </summary>
public sealed class SurveyAccess(SurveyBankDb surveyBank, IOptions<SurveyOptions> options)
{
    public bool ShowsDevelopmentSurveys(int organizationId) =>
        options.Value.DevelopmentSurveys && organizationId == options.Value.TestOrganizationId;

    /// <summary>The survey if this organization may start it, else null. IsDevelopment marks a test-only survey.</summary>
    public async Task<ActiveSurvey?> FindStartableAsync(int surveyId, int organizationId, CancellationToken ct = default)
    {
        if (await surveyBank.ChkSurveyIdAsync(surveyId, ct) is { } active) return active;
        return ShowsDevelopmentSurveys(organizationId) ? await surveyBank.GetDevelopmentSurveyAsync(surveyId, ct) : null;
    }

    /// <summary>Development surveys for the test organization's picker; empty for everyone else.</summary>
    public async Task<IReadOnlyList<DevelopmentSurvey>> DevelopmentSurveysAsync(int organizationId, CancellationToken ct = default) =>
        ShowsDevelopmentSurveys(organizationId) ? await surveyBank.GetDevelopmentSurveysAsync(ct) : [];
}
