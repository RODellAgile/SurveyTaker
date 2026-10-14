namespace SurveyTaker.Web.Services;

/// <summary>"Season" config section.</summary>
public sealed class SeasonOptions
{
    /// <summary>Site key for GetSurveyDates, e.g. "2026".</summary>
    public string SurveyYear { get; set; } = "";

    /// <summary>Display year, e.g. "2026-27". Survey title is "Speak Up " + TextYear.</summary>
    public string TextYear { get; set; } = "";

    /// <summary>
    /// Time zone the season/district dates are written in. Legacy compared against the server's local clock
    /// (Pacific); Azure servers run on UTC, so the zone is explicit.
    /// </summary>
    public string TimeZone { get; set; } = "Pacific Standard Time";

    public string SurveyTitle => "Speak Up " + TextYear;

    /// <summary>"2026-27" -> "26-27" (the completion page says "Speak Up 26-27").</summary>
    public string ShortYear => TextYear.Length > 2 ? TextYear[2..] : TextYear;
}

/// <summary>"Survey" config section.</summary>
public sealed class SurveyOptions
{
    /// <summary>
    /// Secret used to sign survey links (TSI + check value). Long random string; from environment or
    /// user-secrets in production, never committed. Changing it invalidates in-progress links.
    /// </summary>
    public string LinkKey { get; set; } = "";

    /// <summary>Questions per page for new surveys (Bob: one per page).</summary>
    public int QuesPerPage { get; set; } = 1;

    /// <summary>Legacy Web Forms site (https://speakup2026.tomorrow.org). Survey traffic is NOT sent there (Bob, 2026-10-08).</summary>
    public string LegacyBaseUrl { get; set; } = "";

    /// <summary>Default survey deck for the survey-type and survey pickers (legacy Sites.DefaultDeck).</summary>
    public string DefaultDeck { get; set; } = "SUACTIVE";

    /// <summary>
    /// Placeholder district and school that /Q/ quick-start surveys are recorded under (legacy QuickSurveyStart:
    /// 73021 "Targeted Survey District" / 252487 "Targeted Survey School").
    /// </summary>
    public int QuickStartOrganizationId { get; set; } = 73021;
    public int QuickStartRegistrationId { get; set; } = 252487;

    /// <summary>Sponsors shown in the full footer, in order. Logos live in wwwroot/img/sponsors; a sponsor without
    /// a LogoUrl shows as a text placeholder. Change the list each season in settings, no code change.</summary>
    public List<Sponsor> Sponsors { get; set; } = [];
}

public sealed class Sponsor
{
    public string Name { get; set; } = "";
    public string? LogoUrl { get; set; }
    public string? Link { get; set; }
}
