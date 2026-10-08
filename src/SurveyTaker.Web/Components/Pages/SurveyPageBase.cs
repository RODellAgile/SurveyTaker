using Microsoft.AspNetCore.Components;
using SurveyTaker.Web.Services;

namespace SurveyTaker.Web.Components.Pages;

/// <summary>
/// Shared plumbing for pages reached with ?TSI=&amp;k=: verifies the signed link and loads the survey from the
/// database. Pages check <see cref="Ctx"/> (null = show <see cref="Problem"/>).
/// </summary>
public abstract class SurveyPageBase : ComponentBase
{
    [Inject] protected SurveyLoader Loader { get; set; } = default!;
    [Inject] protected SurveyLinks Links { get; set; } = default!;
    [Inject] protected SurveyLog Log { get; set; } = default!;
    [Inject] protected NavigationManager Nav { get; set; } = default!;

    [CascadingParameter] protected HttpContext HttpContext { get; set; } = default!;

    [SupplyParameterFromQuery(Name = "TSI")] public int? Tsi { get; set; }
    [SupplyParameterFromQuery(Name = "k")] public string? Check { get; set; }

    protected SurveyContext? Ctx { get; private set; }
    protected string? Problem { get; private set; }
    protected bool Es => Ctx?.IsSpanish ?? false;
    protected string T(string id) => Texts.Get(id, Es);

    /// <summary>Page name for SpeakupLog (prefixed "ST." by SurveyLog).</summary>
    protected abstract string LogPage { get; }

    /// <summary>Loads the survey; returns false (with Problem set) when the link is bad or the survey is missing.</summary>
    protected async Task<bool> LoadSurveyAsync(bool allowCompleted = false)
    {
        if (Tsi is not int tsi || !Links.IsValid(tsi, Check))
        {
            await Log.Info(LogPage, "Load", "TSI", Tsi?.ToString(), "Missing or invalid link check value");
            Problem = Texts.Get("LinkProblem", false);
            return false;
        }

        Ctx = await Loader.LoadAsync(tsi);
        if (Ctx is null)
        {
            await Log.Error(LogPage, "Load", "TSI", tsi.ToString(), "Taken survey or survey definition not found");
            Problem = Texts.Get("LinkProblem", false);
            return false;
        }

        if (Ctx.Taken.IsCompleted && !allowCompleted)
        {
            Problem = T("AlreadyDone");
            return false;
        }
        return true;
    }

    protected void Fail(string message) { Problem = message; Ctx = null; }

    protected void Go(string page) => Nav.NavigateTo(Links.Url(page, Ctx!.TakenSurveyId));
}
