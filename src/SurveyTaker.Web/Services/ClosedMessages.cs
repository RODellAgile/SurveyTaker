namespace SurveyTaker.Web.Services;

/// <summary>Title and HTML text for the closed/maintenance notices on the start pages.</summary>
public static class ClosedMessages
{
    private const string Contact = " Questions? <a href=\"mailto:speakup@tomorrow.org\">Contact the Speak Up team</a>.";

    public static (string Title, string Html) For(OpenResult r) => r.Status switch
    {
        OpenStatus.Maintenance => ("Speak Up is down for maintenance",
            $"Please try again after {r.AvailableAt:MMMM d, yyyy h:mm tt}. Thank you for your patience."),
        OpenStatus.SeasonClosed => ("Speak Up is closed",
            "Survey taking is not open at this time. Thank you for your interest in Speak Up."),
        _ => ("Survey taking is closed for your district", r.Message + Contact),
    };

    public static (string Title, string Html) BadLink(string what) =>
        ($"We couldn't find that {what}", "Please check the link you were given." + Contact);

    public static (string Title, string Html) SurveyNotAvailable() =>
        ("This survey isn't available", "The survey in this link is not active. Please check the link you were given.");
}
