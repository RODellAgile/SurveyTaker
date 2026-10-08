using System.Data;
using Dapper;
using Microsoft.Data.SqlClient;

namespace SurveyTaker.Data;

/// <summary>Calls to stored procedures in the Speakup (season) database.</summary>
public sealed class SpeakupDb(SqlConnections connections)
{
    // ---- Start-page checks -------------------------------------------------

    /// <summary>GetMaintenanceDate: all maintenance-window rows.</summary>
    public async Task<IReadOnlyList<MaintenanceWindow>> GetMaintenanceDateAsync(CancellationToken ct = default)
    {
        await using var cn = await connections.OpenSpeakupAsync(ct);
        return (await cn.QueryAsync<MaintenanceWindow>(Proc("GetMaintenanceDate", null, ct))).AsList();
    }

    /// <summary>GetSurveyDates: the season's open/close dates for a site key (the season year, e.g. "2026").</summary>
    public async Task<SurveyDates?> GetSurveyDatesAsync(string site, CancellationToken ct = default)
    {
        await using var cn = await connections.OpenSpeakupAsync(ct);
        return await cn.QueryFirstOrDefaultAsync<SurveyDates>(Proc("GetSurveyDates", new { site }, ct));
    }

    /// <summary>GetDistrictOpenClose: district-specific window or manual status; null when the district has none.</summary>
    public async Task<DistrictOpenClose?> GetDistrictOpenCloseAsync(int organizationId, CancellationToken ct = default)
    {
        await using var cn = await connections.OpenSpeakupAsync(ct);
        return await cn.QueryFirstOrDefaultAsync<DistrictOpenClose>(Proc("GetDistrictOpenClose", new { orgid = organizationId }, ct));
    }

    /// <summary>GetOrganizationInfo by district link code (first result set only).</summary>
    public async Task<OrganizationInfo?> GetOrganizationByLinkCodeAsync(string linkCode, CancellationToken ct = default)
    {
        await using var cn = await connections.OpenSpeakupAsync(ct);
        await using var grid = await cn.QueryMultipleAsync(Proc("GetOrganizationInfo", new { linkcode = linkCode }, ct));
        return await grid.ReadFirstOrDefaultAsync<OrganizationInfo>();
    }

    /// <summary>GetDescriptorText: editable text block by key; null when missing.</summary>
    public async Task<string?> GetDescriptorTextAsync(string descriptor, CancellationToken ct = default)
    {
        await using var cn = await connections.OpenSpeakupAsync(ct);
        var row = await cn.QueryFirstOrDefaultAsync(Proc("GetDescriptorText", new { descriptor }, ct));
        return row?.TextContent as string;
    }

    /// <summary>LogEntryPoint: records how a respondent arrived (EntryLog).</summary>
    public async Task LogEntryPointAsync(string entryPoint, string? orgLinkCode = null, string? regLinkCode = null,
        int? registrationId = null, int? surveyId = null, CancellationToken ct = default)
    {
        await using var cn = await connections.OpenSpeakupAsync(ct);
        await cn.ExecuteAsync(Proc("LogEntryPoint", new
        {
            orglinkcode = orgLinkCode,
            reglinkcode = regLinkCode,
            regid = registrationId,
            survid = surveyId,
            entrypoint = entryPoint,
        }, ct));
    }

    // ---- Taking a survey ---------------------------------------------------

    /// <summary>StartNewSurvey: inserts the users_surveys row and returns the new taken_survey_id.</summary>
    public async Task<int> StartNewSurveyAsync(NewSurvey s, CancellationToken ct = default)
    {
        await using var cn = await connections.OpenSpeakupAsync(ct);
        // The proc returns SELECT @@IDENTITY, which comes back as decimal.
        var id = await cn.ExecuteScalarAsync<decimal>(Proc("StartNewSurvey", new
        {
            surveyid = s.SurveyId,
            organizationid = s.OrganizationId,
            registrationid = s.RegistrationId,
            surveyname = s.SurveyName,
            surveytitle = s.SurveyTitle,
            surveytype = s.SurveyType,
            quesperpage = s.QuesPerPage,
            ip = s.Ip,
        }, ct));
        return (int)id;
    }

    /// <summary>GetRestartInfo: the users_surveys row for a taken-survey ID, or null.</summary>
    public async Task<TakenSurvey?> GetRestartInfoAsync(int takenSurveyId, CancellationToken ct = default)
    {
        await using var cn = await connections.OpenSpeakupAsync(ct);
        return await cn.QuerySingleOrDefaultAsync<TakenSurvey>(Proc("GetRestartInfo", new { takensurveyid = takenSurveyId }, ct));
    }

    /// <summary>UpdateK2GrpCnt: saves the group-survey respondent count.</summary>
    public async Task UpdateK2GrpCntAsync(int takenSurveyId, int count, CancellationToken ct = default)
    {
        await using var cn = await connections.OpenSpeakupAsync(ct);
        await cn.ExecuteAsync(Proc("UpdateK2GrpCnt", new { takensurveyid = takenSurveyId, k2grpcnt = count }, ct));
    }

    /// <summary>RetrievePartialSurvey: answers saved so far (from answersDaily).</summary>
    public async Task<IReadOnlyList<Answer>> RetrievePartialSurveyAsync(int takenSurveyId, CancellationToken ct = default)
    {
        await using var cn = await connections.OpenSpeakupAsync(ct);
        return (await cn.QueryAsync<Answer>(Proc("RetrievePartialSurvey", new { takensurveyid = takenSurveyId }, ct))).AsList();
    }

    /// <summary>
    /// Replaces the saved answers for the given questions: DeleteQuestion for each question, then one
    /// SaveAnswer per row, all in one transaction (the legacy app did this without a transaction).
    /// </summary>
    public async Task SaveQuestionAnswersAsync(int takenSurveyId, IReadOnlyCollection<int> questionIds,
        IEnumerable<Answer> answers, CancellationToken ct = default)
    {
        await using var cn = await connections.OpenSpeakupAsync(ct);
        await using var tx = (SqlTransaction)await cn.BeginTransactionAsync(ct);
        foreach (var questionId in questionIds)
            await cn.ExecuteAsync(Proc("DeleteQuestion", new { TakenSurveyID = takenSurveyId, QuestionID = questionId }, ct, tx));
        foreach (var a in answers)
            await cn.ExecuteAsync(Proc("SaveAnswer", new
            {
                TakenSurveyID = takenSurveyId,
                QuestionID = a.QuestionId,
                OptionID = a.OptionId,
                OptionValue = new DbString { Value = a.OptionValue, IsAnsi = true, Length = 4000 },
            }, ct, tx));
        await tx.CommitAsync(ct);
    }

    /// <summary>UpdateSurveyProgress: page reached, question offset, and high-water mark of questions completed.</summary>
    public async Task UpdateSurveyProgressAsync(int takenSurveyId, int quesOffset, int page, int quesCompleted, CancellationToken ct = default)
    {
        await using var cn = await connections.OpenSpeakupAsync(ct);
        await cn.ExecuteAsync(Proc("UpdateSurveyProgress", new
        {
            takensurveyid = takenSurveyId,
            quesoffset = quesOffset,
            page,
            quescompleted = quesCompleted,
        }, ct));
    }

    /// <summary>MarkSurveyCompleted: sets Completed = 'YES'.</summary>
    public async Task MarkSurveyCompletedAsync(int takenSurveyId, int quesCompleted, CancellationToken ct = default)
    {
        await using var cn = await connections.OpenSpeakupAsync(ct);
        await cn.ExecuteAsync(Proc("MarkSurveyCompleted", new { takensurveyid = takenSurveyId, quescompleted = quesCompleted }, ct));
    }

    private static CommandDefinition Proc(string name, object? args, CancellationToken ct, IDbTransaction? tx = null) =>
        new(name, args, transaction: tx, commandType: CommandType.StoredProcedure, cancellationToken: ct);
}
