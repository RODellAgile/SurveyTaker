using Microsoft.Extensions.Options;
using SurveyTaker.Data;
using SurveyTaker.Web.Components;
using SurveyTaker.Web.Services;

var builder = WebApplication.CreateBuilder(args);

// Static server rendering only: no SignalR circuit, every request rebuilt from the database.
builder.Services.AddRazorComponents();

builder.Services.Configure<SeasonOptions>(builder.Configuration.GetSection("Season"));
builder.Services.Configure<SurveyOptions>(builder.Configuration.GetSection("Survey"));
builder.Services.Configure<DatabaseOptions>(builder.Configuration.GetSection("ConnectionStrings"));

builder.Services.AddSingleton(sp => new SqlConnections(sp.GetRequiredService<IOptions<DatabaseOptions>>().Value));
builder.Services.AddSingleton<SpeakupDb>();
builder.Services.AddSingleton<SurveyBankDb>();
builder.Services.AddSingleton<SurveyLinks>();
builder.Services.AddSingleton(TimeProvider.System);
builder.Services.AddSingleton<OpenCheck>();
builder.Services.AddSingleton<SurveyLoader>();
builder.Services.AddSingleton<SurveyLog>();
builder.Services.AddSingleton<SurveyStarter>();
builder.Services.AddSingleton<SurveyAccess>();
builder.Services.AddMemoryCache();
builder.Services.AddHttpContextAccessor();

var app = builder.Build();

if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error", createScopeForErrors: true);
    app.UseHsts();
}
app.UseStatusCodePagesWithReExecute("/not-found", createScopeForStatusCodePages: true);
app.UseHttpsRedirection();

// Survey pages must never be indexed or previewed into search results (legacy TSI URLs were).
app.Use((ctx, next) =>
{
    ctx.Response.Headers["X-Robots-Tag"] = "noindex, nofollow";
    return next();
});

app.UseAntiforgery();

app.MapStaticAssets();
app.MapGet("/theme", (HttpContext http, string? mode, string? @return) => Theme.Set(http, mode, @return));
app.MapRazorComponents<App>();

app.Run();

// Exposed for integration tests (WebApplicationFactory).
public partial class Program;
