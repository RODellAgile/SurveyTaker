namespace SurveyTaker.Data;

/// <summary>Rules ported from the legacy SpeakupQuestions page that must behave identically.</summary>
public static class SurveyRules
{
    /// <summary>
    /// Assigns a page number to each question, exactly as legacy LoadSurvey did. Pages are ranges of
    /// Question_Sort values, not counts of questions: page 1 holds sorts below 1 + quesPerPage, and each
    /// time a sort reaches the next boundary a new page starts and the boundary moves up by quesPerPage.
    /// Grid sub-rows share a Question_Sort, so they always land on the same page. Questions must be in
    /// GetSurveyToTake order (Question_Sort, sort_grid).
    /// </summary>
    public static int[] AssignPages(IReadOnlyList<SurveyQuestion> questions, int quesPerPage)
    {
        if (quesPerPage < 1)
            throw new ArgumentOutOfRangeException(nameof(quesPerPage), quesPerPage, "Must be at least 1.");

        var pages = new int[questions.Count];
        var page = 1;
        var nextPage = 1 + quesPerPage;
        for (var i = 0; i < questions.Count; i++)
        {
            if (questions[i].QuestionSort >= nextPage)
            {
                page++;
                nextPage += quesPerPage;
            }
            pages[i] = page;
        }
        return pages;
    }

    /// <summary>
    /// The "Other" option of a question, matched as in the legacy interim fix (commit a994e51, 2026-09-27):
    /// option text, trimmed and upper-cased, starts with OTHER or OTR. Options are scanned in proc order and the
    /// last match wins. Null when no option matches.
    /// </summary>
    public static int? FindOtherOptionId(IEnumerable<SurveyOption> optionsForQuestion)
    {
        int? otherId = null;
        foreach (var o in optionsForQuestion)
        {
            var t = (o.OptionText ?? "").Trim().ToUpperInvariant();
            if (t.StartsWith("OTHER", StringComparison.Ordinal) || t.StartsWith("OTR", StringComparison.Ordinal))
                otherId = o.OptionId;
        }
        return otherId;
    }
}
