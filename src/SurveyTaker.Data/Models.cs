namespace SurveyTaker.Data;

// Shapes returned by the stored procedures. Property names match the column names
// (Dapper matches case-insensitively and with underscores removed). Procs that SELECT *
// map to classes with init properties, so added table columns don't break materialization.

/// <summary>Row from Speakup.dbo.Maintenance (GetMaintenanceDate).</summary>
public sealed class MaintenanceWindow
{
    public string? Site { get; init; }
    public DateTime? MaintenanceStart { get; init; }
    public DateTime? MaintenanceEnd { get; init; }
}

/// <summary>Row from Speakup.dbo.SurveyDates (GetSurveyDates).</summary>
public sealed class SurveyDates
{
    public string? Site { get; init; }
    public DateTime? RegistrationDate { get; init; }
    public DateTime? OpenDate { get; init; }
    public DateTime? CloseDate { get; init; }
    public DateTime? DistrictCloseDate { get; init; }
    public DateTime? ReportDate { get; init; }
    public DateTime? QuestionFrozenDate { get; init; }
}

/// <summary>Row from Speakup.dbo.DistrictOpenClose (GetDistrictOpenClose).</summary>
public sealed class DistrictOpenClose
{
    public int OrganizationId { get; init; }
    public DateTime? OpenDate { get; init; }
    public DateTime? CloseDate { get; init; }
    public bool? SurveyStatus { get; init; }
    public string? ClosedMessage { get; init; }
}

/// <summary>First result set of GetOrganizationInfo; only the columns the survey taker uses.</summary>
public sealed class OrganizationInfo
{
    public int OrganizationId { get; init; }
    public string? LinkCode { get; init; }
    public string? OrgName { get; init; }
    public string? MailCity { get; init; }
    public string? MailState { get; init; }
    public string? SurveyDeckCode { get; init; }
    public string? Status { get; init; }
}

/// <summary>School found by link code (legacy SchoolStart inline query on Registrations).</summary>
public sealed class SchoolRegistration
{
    public int? OrganizationId { get; init; }
    public int RegistrationId { get; init; }
    public string? RegistrantName { get; init; }
    public string? MailState { get; init; }
}

/// <summary>Survey header from SurveyBank.dbo.surveys (GetSurveyDesc).</summary>
public sealed class SurveyInfo
{
    public int SurveyId { get; init; }
    public int? RelatedSurveyId { get; init; }
    public string? Title { get; init; }
    public string? Name { get; init; }
    public int? TotalQuestions { get; init; }
    public string? SurveyType { get; init; }
    public bool GroupSurvey { get; init; }
    public string? Intro { get; init; }
    public string? Outro { get; init; }
    public bool? Archive { get; init; }
}

/// <summary>Result of ChkSurveyId: present only when the survey exists and is not archived.</summary>
public sealed record ActiveSurvey(string? Name, string? SurveyType);

/// <summary>First result set of GetSurveyToTake: one row per question (grid rows are separate questions sharing QuesGrid).</summary>
public sealed class SurveyQuestion
{
    public int QuestionId { get; init; }
    public int Reference { get; init; }
    public int Version { get; init; }
    public string? QuestionText { get; init; }
    public string? QuestionType { get; init; }
    public bool GroupQuestion { get; init; }
    public bool Required { get; init; }
    public string? QuesGrid { get; init; }
    public int? SortGrid { get; init; }
    public string? GridAnswerType { get; init; }
    public int? LikertScale { get; init; }
    public string? QuestionGridHeader { get; init; }
    public int QuestionSort { get; init; }
}

/// <summary>Second result set of GetSurveyToTake: one row per option.</summary>
public sealed class SurveyOption
{
    public int OptionId { get; init; }
    public int? RelatedOptionId { get; init; }
    public int QuestionId { get; init; }
    public string? OptionText { get; init; }
    public string? FilterGroup { get; init; }
    public int? OptionSort { get; init; }
}

public sealed record SurveyDefinition(IReadOnlyList<SurveyQuestion> Questions, IReadOnlyList<SurveyOption> Options);

/// <summary>Row from Speakup.dbo.users_surveys (GetRestartInfo).</summary>
public sealed class TakenSurvey
{
    public int TakenSurveyId { get; init; }
    public int? SurveyId { get; init; }
    public int? RelatedSurveyId { get; init; }
    public string? SurveyName { get; init; }
    public string? SurveyTitle { get; init; }
    public string? SurveyType { get; init; }
    public int StartQuesOffset { get; init; }
    public int QuesCompleted { get; init; }
    public int QuesPerPage { get; init; }
    public int? SurveyPage { get; init; }
    public int? OrganizationId { get; init; }
    public int? RegistrationId { get; init; }
    public int? K2GrpCnt { get; init; }
    public DateTime? TimeEntered { get; init; }
    public DateTime? LastUpdate { get; init; }
    public string? Completed { get; init; }

    public bool IsCompleted => string.Equals(Completed, "YES", StringComparison.OrdinalIgnoreCase);
}

/// <summary>Row from answersDaily (RetrievePartialSurvey) or a row to save (SaveAnswer).</summary>
public sealed record Answer(int QuestionId, int? OptionId, string? OptionValue);

/// <summary>Parameters for StartNewSurvey.</summary>
public sealed record NewSurvey(
    int SurveyId,
    int OrganizationId,
    int RegistrationId,
    string SurveyName,
    string SurveyTitle,
    string SurveyType,
    int QuesPerPage,
    string Ip);
