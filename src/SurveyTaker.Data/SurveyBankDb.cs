using System.Data;
using Dapper;

namespace SurveyTaker.Data;

/// <summary>Read-only calls to stored procedures in the SurveyBank database.</summary>
public sealed class SurveyBankDb(SqlConnections connections)
{
    /// <summary>ChkSurveyId: returns the survey if it exists and is not archived, else null.</summary>
    public async Task<ActiveSurvey?> ChkSurveyIdAsync(int surveyId, CancellationToken ct = default)
    {
        await using var cn = await connections.OpenSurveyBankAsync(ct);
        return await cn.QuerySingleOrDefaultAsync<ActiveSurvey>(Proc("ChkSurveyId", new { surveyid = surveyId }, ct));
    }

    // ---- Development surveys (SpeakupAdmin's Survey Building; only after the cutover adds surveys.Status) ----
    // Plain SELECTs on surveys (SurveyTaker's login already reads it for the pickers). Callers check the
    // Survey:DevelopmentSurveys setting first: before the cutover the Status column doesn't exist.

    /// <summary>The survey if it's in Development (Status 'D'), else null.</summary>
    public async Task<ActiveSurvey?> GetDevelopmentSurveyAsync(int surveyId, CancellationToken ct = default)
    {
        await using var cn = await connections.OpenSurveyBankAsync(ct);
        var row = await cn.QuerySingleOrDefaultAsync<(string? Name, string? SurveyType)?>(new CommandDefinition(
            "SELECT name, survey_type FROM surveys WHERE survey_id = @surveyId AND Status = 'D'", new { surveyId }, cancellationToken: ct));
        return row is { } r ? new ActiveSurvey(r.Name, r.SurveyType) { IsDevelopment = true } : null;
    }

    /// <summary>Every Development survey, by type and sort order.</summary>
    public async Task<IReadOnlyList<DevelopmentSurvey>> GetDevelopmentSurveysAsync(CancellationToken ct = default)
    {
        await using var cn = await connections.OpenSurveyBankAsync(ct);
        return (await cn.QueryAsync<DevelopmentSurvey>(new CommandDefinition(
            "SELECT survey_id AS SurveyId, name AS Name, survey_type AS SurveyType FROM surveys WHERE Status = 'D' ORDER BY survey_type, sort_order, name",
            cancellationToken: ct))).AsList();
    }

    /// <summary>GetSurveyDesc: survey header (name, type, intro, group flag), archived or not.</summary>
    public async Task<SurveyInfo?> GetSurveyDescAsync(int surveyId, CancellationToken ct = default)
    {
        await using var cn = await connections.OpenSurveyBankAsync(ct);
        return await cn.QuerySingleOrDefaultAsync<SurveyInfo>(Proc("GetSurveyDesc", new { surveyid = surveyId }, ct));
    }

    /// <summary>GetSurveyToTake: active questions (ordered by Question_Sort, sort_grid) and their active options.</summary>
    public async Task<SurveyDefinition> GetSurveyToTakeAsync(int surveyId, CancellationToken ct = default)
    {
        await using var cn = await connections.OpenSurveyBankAsync(ct);
        await using var grid = await cn.QueryMultipleAsync(Proc("GetSurveyToTake", new { survey = surveyId }, ct));
        var questions = (await grid.ReadAsync<SurveyQuestion>()).AsList();
        var options = (await grid.ReadAsync<SurveyOption>()).AsList();
        return new SurveyDefinition(questions, options);
    }

    private static CommandDefinition Proc(string name, object args, CancellationToken ct) =>
        new(name, args, commandType: CommandType.StoredProcedure, cancellationToken: ct);
}
