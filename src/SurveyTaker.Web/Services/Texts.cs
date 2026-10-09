namespace SurveyTaker.Web.Services;

/// <summary>
/// Screen text by string ID, English and Spanish. Spanish is used for survey types STUSPAN and FAMSPAN.
/// Kept in one place so more languages can be added later (or moved to .resx) without touching pages.
/// </summary>
public static class Texts
{
    public static bool IsSpanish(string? surveyType) =>
        surveyType?.Trim().ToUpperInvariant() is "STUSPAN" or "FAMSPAN";

    public static string Get(string id, bool spanish) =>
        (spanish ? Es : En).TryGetValue(id, out var s) ? s : En.GetValueOrDefault(id, id);

    private static readonly Dictionary<string, string> En = new()
    {
        ["Start"] = "Start Speak Up",
        ["Next"] = "Next",
        ["Back"] = "Back",
        ["Finish"] = "Finish",
        ["Continue"] = "Continue",
        ["District"] = "District",
        ["School"] = "School",
        ["Survey"] = "Survey",
        ["ConfirmPrompt"] = "Please confirm this is your school and survey, then start.",
        ["NotRight"] = "If this is not your school or survey, please check the link you were given.",
        ["QuestionCount"] = "The survey consists of {0} questions.",
        ["PageOf"] = "Question {0} of {1}",
        ["Other"] = "Other (please specify)",
        ["SelectOne"] = "Please select",
        ["GroupPrompt"] = "How many people are in the group taking this survey together?",
        ["GroupHelp"] = "Enter a number from 2 to 999.",
        ["GroupInvalid"] = "Please enter a number from 2 to 999.",
        ["FixErrors"] = "Please correct the highlighted questions.",
        ["ThankYou"] = "Thank you!",
        ["ThankYouBody"] = "Thank you for being a part of Speak Up {0}! If you would like to learn more about Project Tomorrow, visit our website ",
        ["AlreadyDone"] = "This survey has already been completed. Thank you!",
        ["LinkProblem"] = "We couldn't open this survey. Please use the link you were originally given.",
    };

    private static readonly Dictionary<string, string> Es = new()
    {
        ["Start"] = "Empiece \"Speak Up\"",
        ["Next"] = "Siguiente",
        ["Back"] = "Atrás",
        ["Finish"] = "Terminar",
        ["Continue"] = "Continuar",
        ["District"] = "Distrito",
        ["School"] = "Escuela",
        ["Survey"] = "Encuesta",
        ["ConfirmPrompt"] = "Por favor, confirme que esta es su escuela y encuesta, y luego empiece.",
        ["NotRight"] = "Si esta no es su escuela o encuesta, por favor revise el enlace que recibió.",
        ["QuestionCount"] = "La encuesta consiste de {0} preguntas.",
        ["PageOf"] = "Pregunta {0} de {1}",
        ["Other"] = "Otro (por favor especifique)",
        ["SelectOne"] = "Por favor seleccione",
        ["GroupPrompt"] = "¿Cuántas personas hay en el grupo que toma esta encuesta juntos?",
        ["GroupHelp"] = "Escriba un número del 2 al 999.",
        ["GroupInvalid"] = "Por favor escriba un número del 2 al 999.",
        ["FixErrors"] = "Por favor corrija las preguntas señaladas.",
        ["ThankYou"] = "¡Gracias!",
        ["ThankYouBody"] = "¡Gracias por participar en Speak Up {0}! Si desea saber más sobre Project Tomorrow, visite nuestro sitio web ",
        ["AlreadyDone"] = "Esta encuesta ya fue completada. ¡Gracias!",
        ["LinkProblem"] = "No pudimos abrir esta encuesta. Por favor use el enlace que recibió originalmente.",
    };
}
