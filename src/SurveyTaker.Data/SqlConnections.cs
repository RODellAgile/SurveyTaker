using Dapper;
using Microsoft.Data.SqlClient;

namespace SurveyTaker.Data;

/// <summary>Connection strings for the two databases, bound from the "ConnectionStrings" config section.</summary>
public sealed class DatabaseOptions
{
    public string Speakup { get; set; } = "";
    public string SurveyBank { get; set; } = "";
}

/// <summary>Opens connections to the Speakup and SurveyBank databases.</summary>
public sealed class SqlConnections
{
    private readonly DatabaseOptions _options;

    static SqlConnections()
    {
        // Lets Dapper map taken_survey_id -> TakenSurveyId, etc.
        DefaultTypeMap.MatchNamesWithUnderscores = true;
    }

    public SqlConnections(DatabaseOptions options)
    {
        if (string.IsNullOrWhiteSpace(options.Speakup) || string.IsNullOrWhiteSpace(options.SurveyBank))
            throw new InvalidOperationException("ConnectionStrings:Speakup and ConnectionStrings:SurveyBank must both be configured.");
        _options = options;
    }

    public async Task<SqlConnection> OpenSpeakupAsync(CancellationToken ct = default) => await OpenAsync(_options.Speakup, ct);

    public async Task<SqlConnection> OpenSurveyBankAsync(CancellationToken ct = default) => await OpenAsync(_options.SurveyBank, ct);

    private static async Task<SqlConnection> OpenAsync(string connectionString, CancellationToken ct)
    {
        var cn = new SqlConnection(connectionString);
        await cn.OpenAsync(ct);
        return cn;
    }
}
