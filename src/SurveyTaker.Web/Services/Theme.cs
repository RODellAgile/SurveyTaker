namespace SurveyTaker.Web.Services;

/// <summary>
/// Light / dark / auto theme, remembered in a cookie. No JavaScript: the header links go to /theme, which sets
/// the cookie and redirects back. "auto" (or no cookie) follows the device setting via prefers-color-scheme.
/// </summary>
public static class Theme
{
    public const string Cookie = "st-theme";
    public static readonly string[] Modes = ["light", "dark", "auto"];

    /// <summary>The visitor's choice: "light", "dark" or "auto".</summary>
    public static string Current(HttpContext? http) =>
        http?.Request.Cookies[Cookie] is { } v && Modes.Contains(v) ? v : "auto";

    /// <summary>Value for the html data-theme attribute; null for auto (CSS media query decides).</summary>
    public static string? DataTheme(HttpContext? http) => Current(http) is "auto" ? null : Current(http);

    /// <summary>GET /theme?mode=dark&amp;return=/questions?TSI=...: sets the cookie, then goes back to a local URL.</summary>
    public static IResult Set(HttpContext http, string? mode, string? @return)
    {
        mode = Modes.Contains(mode) ? mode : "auto";
        http.Response.Cookies.Append(Cookie, mode!, new CookieOptions
        {
            Expires = DateTimeOffset.UtcNow.AddYears(1), HttpOnly = true, Secure = http.Request.IsHttps,
            SameSite = SameSiteMode.Lax, IsEssential = true,
        });
        // Only same-site paths, never an absolute URL (no open redirect).
        var target = !string.IsNullOrEmpty(@return) && @return.StartsWith('/') && !@return.StartsWith("//") && !@return.StartsWith("/\\")
            ? @return : "/";
        return Results.LocalRedirect(target);
    }
}
