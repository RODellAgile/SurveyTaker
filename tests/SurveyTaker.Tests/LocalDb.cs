using Dapper;
using Microsoft.Data.SqlClient;
using SurveyTaker.Data;

namespace SurveyTaker.Tests;

/// <summary>
/// Connections to the developer's local restored databases (Windows auth).
/// Override with SURVEYTAKER_TEST_SPEAKUP / SURVEYTAKER_TEST_SURVEYBANK. Never point these at production.
/// </summary>
public static class LocalDb
{
    public static readonly DatabaseOptions Options = new()
    {
        Speakup = Environment.GetEnvironmentVariable("SURVEYTAKER_TEST_SPEAKUP")
            ?? "Server=localhost;Database=Speakup2026_2027;Integrated Security=true;TrustServerCertificate=true",
        SurveyBank = Environment.GetEnvironmentVariable("SURVEYTAKER_TEST_SURVEYBANK")
            ?? "Server=localhost;Database=SurveyBank;Integrated Security=true;TrustServerCertificate=true",
    };

    public static readonly SqlConnections Connections = new(Options);

    /// <summary>Removes a test survey's rows. Only for local test data — production never deletes users_surveys.</summary>
    public static async Task DeleteTestSurveyAsync(int takenSurveyId)
    {
        await using var cn = new SqlConnection(Options.Speakup);
        await cn.ExecuteAsync(
            "DELETE FROM answersDaily WHERE taken_survey_id = @id; DELETE FROM users_surveys WHERE taken_survey_id = @id;",
            new { id = takenSurveyId });
    }
}
