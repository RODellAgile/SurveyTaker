using Microsoft.Extensions.Options;
using SurveyTaker.Data;

namespace SurveyTaker.Web.Services;

public enum OpenStatus { Open, Maintenance, SeasonClosed, DistrictClosed }

public sealed record OpenResult(OpenStatus Status, string? Message = null, DateTime? AvailableAt = null)
{
    public bool IsOpen => Status == OpenStatus.Open;
}

/// <summary>The legacy start-page checks, in the same order: maintenance window, season dates, district window.</summary>
public sealed class OpenCheck(SpeakupDb db, IOptions<SeasonOptions> season, TimeProvider clock)
{
    private DateTime Now() =>
        TimeZoneInfo.ConvertTime(clock.GetUtcNow(), TimeZoneInfo.FindSystemTimeZoneById(season.Value.TimeZone)).DateTime;

    /// <summary>Maintenance window and season dates (no district).</summary>
    public async Task<OpenResult> SiteAsync(CancellationToken ct = default)
    {
        var now = Now();

        foreach (var m in await db.GetMaintenanceDateAsync(ct))
            if (m.MaintenanceStart < now && m.MaintenanceEnd > now)
                return new OpenResult(OpenStatus.Maintenance, AvailableAt: m.MaintenanceEnd);

        var dates = await db.GetSurveyDatesAsync(season.Value.SurveyYear, ct);
        if (dates is null || dates.OpenDate > now || dates.DistrictCloseDate < now)
            return new OpenResult(OpenStatus.SeasonClosed);

        return new OpenResult(OpenStatus.Open);
    }

    /// <summary>District-specific window (legacy CheckDistrictSurveyOpen).</summary>
    public async Task<OpenResult> DistrictAsync(int organizationId, CancellationToken ct = default)
    {
        var d = await db.GetDistrictOpenCloseAsync(organizationId, ct);
        if (d is null || (d.OpenDate is null && d.SurveyStatus is null))
            return new OpenResult(OpenStatus.Open);

        if (d.SurveyStatus is bool manual)
            return manual
                ? new OpenResult(OpenStatus.Open)
                : new OpenResult(OpenStatus.DistrictClosed, "Your district does not currently have survey taking open.");

        var today = Now();
        var open = d.OpenDate!.Value.Date.AddSeconds(1);
        var close = d.CloseDate is DateTime c ? c.Date.AddDays(1).AddSeconds(-1) : DateTime.MaxValue;
        if (open <= today && close >= today)
            return new OpenResult(OpenStatus.Open);

        var message = !string.IsNullOrWhiteSpace(d.ClosedMessage)
            ? d.ClosedMessage
            : $"You may only take surveys from {open:MMMM dd, yyyy} until {close:MMMM dd, yyyy}. " +
              "If you believe this survey to be closed in error, please contact your Speak Up primary contact.";
        return new OpenResult(OpenStatus.DistrictClosed, message);
    }
}
