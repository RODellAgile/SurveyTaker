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
