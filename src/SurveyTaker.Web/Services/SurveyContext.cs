using Microsoft.Extensions.Caching.Memory;
using SurveyTaker.Data;

namespace SurveyTaker.Web.Services;

/// <summary>One displayed item: a single question, or a grid whose rows share a Question_Sort.</summary>
public sealed class PageItem
{
    public required int QuestionSort { get; init; }
    public required IReadOnlyList<SurveyQuestion> Rows { get; init; }
    public SurveyQuestion First => Rows[0];
    public string Type => (First.QuestionType ?? "").Trim().ToLowerInvariant();
    public bool IsGrid => Type is "likertgrid" or "grid";
}

/// <summary>Everything about one taken survey, rebuilt from the database on each request (no session state).</summary>
public sealed class SurveyContext
{
    public required TakenSurvey Taken { get; init; }
    public required SurveyInfo Survey { get; init; }
    public required SurveyDefinition Definition { get; init; }
    public required int[] Pages { get; init; }
    public required ILookup<int, SurveyOption> OptionsByQuestion { get; init; }

    public int TakenSurveyId => Taken.TakenSurveyId;
    public int TotalPages => Pages.Length == 0 ? 0 : Pages[^1];
    public int TotalQuestionRows => Definition.Questions.Count;
    public bool IsSpanish => Texts.IsSpanish(Taken.SurveyType ?? Survey.SurveyType);
    public bool IsGroup => Survey.GroupSurvey;
    public int? GroupCount => Taken.K2GrpCnt is > 0 ? Taken.K2GrpCnt : null;

    /// <summary>Page to show: the stored SurveyPage, or 1 for a survey not yet started; clamped to the survey.</summary>
    public int CurrentPage => Math.Clamp(Taken.SurveyPage is > 0 ? Taken.SurveyPage.Value : 1, 1, Math.Max(1, TotalPages));

    public IEnumerable<SurveyOption> OptionsFor(int questionId) => OptionsByQuestion[questionId];

    /// <summary>Items on a page, grids grouped, in survey order.</summary>
    public IReadOnlyList<PageItem> ItemsOnPage(int page) =>
        Definition.Questions
            .Where((_, i) => Pages[i] == page)
            .GroupBy(q => q.QuestionSort)
            .Select(g => new PageItem { QuestionSort = g.Key, Rows = g.ToList() })
            .ToList();
}

/// <summary>Loads a <see cref="SurveyContext"/>. Survey definitions are cached briefly; answers and progress never are.</summary>
public sealed class SurveyLoader(SpeakupDb speakup, SurveyBankDb surveyBank, IMemoryCache cache)
{
    private static readonly TimeSpan DefinitionLifetime = TimeSpan.FromMinutes(10);

    public async Task<SurveyContext?> LoadAsync(int tsi, CancellationToken ct = default)
    {
        var taken = await speakup.GetRestartInfoAsync(tsi, ct);
        if (taken?.SurveyId is not int surveyId)
            return null;

        var survey = await cache.GetOrCreateAsync(("desc", surveyId), e =>
        {
            e.AbsoluteExpirationRelativeToNow = DefinitionLifetime;
            return surveyBank.GetSurveyDescAsync(surveyId, ct);
        });
        var definition = await cache.GetOrCreateAsync(("def", surveyId), e =>
        {
            e.AbsoluteExpirationRelativeToNow = DefinitionLifetime;
            return surveyBank.GetSurveyToTakeAsync(surveyId, ct);
        });
        if (survey is null || definition is null)
            return null;

        // Honor the stored per-page setting so surveys started by the legacy app (5 per page) resume on the same pages.
        var perPage = taken.QuesPerPage > 0 ? taken.QuesPerPage : 1;
        return new SurveyContext
        {
            Taken = taken,
            Survey = survey,
            Definition = definition,
            Pages = SurveyRules.AssignPages(definition.Questions, perPage),
            OptionsByQuestion = definition.Options.ToLookup(o => o.QuestionId),
        };
    }
}
