using SurveyTaker.Data;

namespace SurveyTaker.Web.Services;

/// <summary>
/// Writes page events to SpeakupLog (LogEntryEnhanced), the table Bob searches. Page_File is prefixed "ST."
/// so new-app rows are distinguishable from legacy ones. Never throws: a logging failure goes to ILogger only.
/// </summary>
public sealed class SurveyLog(SpeakupDb db, IHttpContextAccessor http, ILogger<SurveyLog> logger)
{
    public Task Info(string page, string method, string? valueName = null, string? value = null, string? text = null) =>
        Write(page, method, "LOG", valueName, value, text);

    public Task Error(string page, string method, string? valueName = null, string? value = null, string? text = null) =>
        Write(page, method, "ERROR", valueName, value, text);

    private async Task Write(string page, string method, string type, string? valueName, string? value, string? text)
    {
        var ctx = http.HttpContext;
        var entry = new LogEntry(
            PageFile: "ST." + page,
            Method: method,
            EntryType: type,
            Ip: ctx?.Connection.RemoteIpAddress?.ToString(),
            Referer: ctx?.Request.Headers.Referer.ToString(),
            UserAgent: ctx?.Request.Headers.UserAgent.ToString(),
            ValueName: valueName,
            Value: value,
            EntryText: text);

        if (type == "ERROR")
            logger.LogError("{Page}.{Method} {ValueName}={Value}: {Text}", page, method, valueName, value, text);

        try
        {
            await db.LogEntryEnhancedAsync(entry);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "SpeakupLog write failed for {Page}.{Method}", page, method);
        }
    }
}
