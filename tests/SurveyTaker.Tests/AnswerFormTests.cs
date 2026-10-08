using SurveyTaker.Data;
using SurveyTaker.Web.Services;

namespace SurveyTaker.Tests;

// The legacy save rules (db/README.md, "Saving a page"), checked without a database.
public class AnswerFormTests
{
    private static SurveyContext Ctx(SurveyQuestion q, IEnumerable<SurveyOption> options, int? groupCount = null, string type = "STUDENT") => new()
    {
        Taken = new TakenSurvey { TakenSurveyId = 1, SurveyId = 1, SurveyType = type, K2GrpCnt = groupCount, QuesPerPage = 1 },
        Survey = new SurveyInfo { SurveyId = 1, GroupSurvey = groupCount is not null, SurveyType = type },
        Definition = new SurveyDefinition([q], options.ToList()),
        Pages = [1],
        OptionsByQuestion = options.ToLookup(o => o.QuestionId),
    };

    private static SurveyQuestion Q(string type, bool required = false) =>
        new() { QuestionId = 7, QuestionType = type, QuestionSort = 1, Required = required };

    private static readonly SurveyOption[] YesNoOther =
    [
        new() { QuestionId = 7, OptionId = 1, OptionText = "Yes" },
        new() { QuestionId = 7, OptionId = 2, OptionText = "No" },
        new() { QuestionId = 7, OptionId = 3, OptionText = "Other (please specify)" },
    ];

    private static AnswerForm.Result Read(SurveyContext ctx, Dictionary<string, string[]> form, bool enforceRequired = true) =>
        AnswerForm.Read(ctx, ctx.ItemsOnPage(1), name => form.GetValueOrDefault(name, []), enforceRequired);

    [Fact]
    public void CheckboxOther_TypedTextWithoutTick_SavesOther()
    {
        var r = Read(Ctx(Q("checkboxother"), YesNoOther), new() { ["q7"] = ["1"], ["o7"] = ["  my answer "] });
        Assert.Equal([new Answer(7, 1, null), new Answer(7, 3, "my answer")], r.Answers);
    }

    [Fact]
    public void CheckboxOther_TickedWithoutText_SavesOtherWithNullValue()
    {
        var r = Read(Ctx(Q("checkboxother"), YesNoOther), new() { ["q7"] = ["3"] });
        Assert.Equal([new Answer(7, 3, null)], r.Answers);
    }

    [Fact]
    public void RadioOther_TypedTextWinsOverSelectedRadio()
    {
        var r = Read(Ctx(Q("radioother"), YesNoOther), new() { ["q7"] = ["1"], ["o7"] = ["something else"] });
        Assert.Equal([new Answer(7, 3, "something else")], r.Answers);
    }

    [Fact]
    public void Radio_IgnoresOptionIdsNotInTheQuestion()
    {
        var r = Read(Ctx(Q("radio"), YesNoOther), new() { ["q7"] = ["999"] });
        Assert.Empty(r.Answers);
    }

    [Fact]
    public void Integer_SavesARowPerOptionEvenWhenBlank()
    {
        var r = Read(Ctx(Q("integer"), YesNoOther), new() { ["i7_1"] = ["4"] });
        Assert.Equal([new Answer(7, 1, "4"), new Answer(7, 2, null), new Answer(7, 3, null)], r.Answers);
        Assert.Empty(r.Errors);
    }

    [Fact]
    public void Integer_GroupSurvey_RejectsValuesAboveGroupCount()
    {
        var r = Read(Ctx(Q("integer"), YesNoOther, groupCount: 20), new() { ["i7_1"] = ["21"] });
        Assert.True(r.Errors.ContainsKey(7));
    }

    [Fact]
    public void Integer_RejectsNonNumbers()
    {
        var r = Read(Ctx(Q("integer"), YesNoOther), new() { ["i7_1"] = ["lots"] });
        Assert.True(r.Errors.ContainsKey(7));
    }

    [Fact]
    public void Text_BlankStillSavesARow()
    {
        var r = Read(Ctx(Q("text"), []), new());
        Assert.Equal([new Answer(7, null, null)], r.Answers);
    }

    [Fact]
    public void Required_BlocksNextButNotBack()
    {
        var ctx = Ctx(Q("radio", required: true), YesNoOther);
        Assert.True(Read(ctx, new()).Errors.ContainsKey(7));
        Assert.Empty(Read(ctx, new(), enforceRequired: false).Errors);
    }

    [Fact]
    public void Spanish_SurveyTypesUseSpanishMessages()
    {
        var r = Read(Ctx(Q("integer"), YesNoOther, type: "STUSPAN"), new() { ["i7_1"] = ["x"] });
        Assert.StartsWith("Por favor", r.Errors[7]);
    }
}
