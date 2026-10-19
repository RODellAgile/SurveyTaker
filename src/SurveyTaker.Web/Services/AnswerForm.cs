using SurveyTaker.Data;

namespace SurveyTaker.Web.Services;

/// <summary>
/// Form field names and the conversion between posted fields and answer rows, following the legacy save
/// rules documented in db/README.md. Field names:
///   q{qid}        selected option id(s) – radio, checkbox, likert, likertgrid, grid
///   o{qid}        "Other" text – radioother, checkboxother
///   t{qid}        text answer
///   i{qid}_{oid}  integer answer per option
///   d{qid}        dropdown value
/// </summary>
public static class AnswerForm
{
    public static string Select(int qid) => $"q{qid}";
    public static string Other(int qid) => $"o{qid}";
    public static string Text(int qid) => $"t{qid}";
    public static string Integer(int qid, int oid) => $"i{qid}_{oid}";
    public static string Dropdown(int qid) => $"d{qid}";

    public sealed record Result(List<Answer> Answers, Dictionary<int, string> Errors);

    /// <param name="form">Posted values by field name (empty array when absent).</param>
    /// <param name="enforceRequired">False for Back: answers are saved but required questions don't block.</param>
    public static Result Read(SurveyContext ctx, IReadOnlyList<PageItem> items, Func<string, string[]> form, bool enforceRequired = true)
    {
        var answers = new List<Answer>();
        var errors = new Dictionary<int, string>();
        var es = ctx.IsSpanish;

        foreach (var item in items)
        foreach (var q in item.Rows)
        {
            var qid = q.QuestionId;
            var options = ctx.OptionsFor(qid).ToList();
            var before = answers.Count;
            var type = (q.QuestionType ?? "").Trim().ToLowerInvariant();

            switch (type)
            {
                case "radio" or "likert":
                {
                    if (FirstInt(form(Select(qid))) is int sel && options.Any(o => o.OptionId == sel))
                        answers.Add(new Answer(qid, sel, null));
                    break;
                }
                case "radioother":
                {
                    // One answer. Other text counts only when Other itself is the selected radio; with any other choice
                    // the text is dropped (Speak Up team, 2026-10-19; replaces the legacy "typed text wins").
                    var otherId = SurveyRules.FindOtherOptionId(options);
                    if (FirstInt(form(Select(qid))) is int sel && options.Any(o => o.OptionId == sel))
                        answers.Add(new Answer(qid, sel, sel == otherId ? NullIfEmpty(Trimmed(form(Other(qid)))) : null));
                    break;
                }
                case "checkbox" or "likertgrid" or "grid":
                {
                    var selected = Ints(form(Select(qid)));
                    // likertgrid RADIO rows allow one choice; the browser enforces it, keep the first if tampered.
                    if (type == "likertgrid" && !IsCheckGrid(q))
                        selected = selected.Take(1).ToHashSet();
                    foreach (var o in options.Where(o => selected.Contains(o.OptionId)))
                        answers.Add(new Answer(qid, o.OptionId, null));
                    break;
                }
                case "checkboxother":
                {
                    var selected = Ints(form(Select(qid)));
                    var otherText = Trimmed(form(Other(qid)));
                    var otherId = SurveyRules.FindOtherOptionId(options);
                    // Any number of choices. Other text is kept only when Other is ticked (Speak Up team, 2026-10-19).
                    foreach (var o in options.Where(o => selected.Contains(o.OptionId)))
                        answers.Add(new Answer(qid, o.OptionId, o.OptionId == otherId ? NullIfEmpty(otherText) : null));
                    break;
                }
                case "integer":
                {
                    // One row per option, even when blank (legacy; reports expect it).
                    foreach (var o in options)
                    {
                        var raw = Trimmed(form(Integer(qid, o.OptionId)));
                        answers.Add(new Answer(qid, o.OptionId, NullIfEmpty(raw)));
                        if (raw.Length == 0 || errors.ContainsKey(qid))
                            continue;
                        if (!int.TryParse(raw, out var n) || n < 0)
                            errors[qid] = es ? "Por favor, introduzca solo números enteros." : "Please enter whole numbers only.";
                        else if (ctx.GroupCount is int max && n > max)
                            errors[qid] = es
                                ? $"Cada número debe ser {max} o menos (el número de estudiantes en su grupo)."
                                : $"Each number must be {max} or less (the number of people in your group).";
                    }
                    break;
                }
                case "text":
                {
                    // Untrimmed, and saved even when blank (legacy).
                    var text = form(Text(qid)).FirstOrDefault() ?? "";
                    if (text.Length > 4000) text = text[..4000];
                    answers.Add(new Answer(qid, null, NullIfEmpty(text)));
                    break;
                }
                case "dropdownlist":
                {
                    // Always saved, even when nothing was chosen (legacy).
                    answers.Add(new Answer(qid, FirstInt(form(Dropdown(qid))), null));
                    break;
                }
                default:
                    // verticalgrid and unknown types: no active questions use them; nothing to save.
                    break;
            }

            if (enforceRequired && q.Required && !errors.ContainsKey(qid) && !answers.Skip(before).Any(a => a.OptionId is not null || a.OptionValue is not null))
                errors[qid] = es ? "Esta pregunta requiere una respuesta." : "This question requires an answer.";
        }

        return new Result(answers, errors);
    }

    public static bool IsCheckGrid(SurveyQuestion q) =>
        string.Equals(q.GridAnswerType?.Trim(), "CHECK", StringComparison.OrdinalIgnoreCase);

    private static string Trimmed(string[] values) => (values.FirstOrDefault() ?? "").Trim();
    private static string? NullIfEmpty(string s) => s.Length == 0 ? null : s;
    private static int? FirstInt(string[] values) => int.TryParse(values.FirstOrDefault(), out var n) ? n : null;
    private static HashSet<int> Ints(string[] values) => values.Select(v => int.TryParse(v, out var n) ? n : (int?)null).OfType<int>().ToHashSet();
}
