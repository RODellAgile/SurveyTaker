using System.Security.Cryptography;
using System.Text;
using Microsoft.Extensions.Options;

namespace SurveyTaker.Web.Services;

/// <summary>
/// Survey URLs carry the taken-survey ID (TSI) plus a check value "k" = HMAC of the TSI. Without the key,
/// changing the TSI in the URL no longer opens someone else's survey (a known hole in the legacy app).
/// The stored procedures still take the plain integer.
/// </summary>
public sealed class SurveyLinks
{
    private readonly byte[] _key;

    public SurveyLinks(IOptions<SurveyOptions> options)
    {
        var key = options.Value.LinkKey;
        if (string.IsNullOrWhiteSpace(key) || key.Length < 32)
            throw new InvalidOperationException("Survey:LinkKey must be configured (at least 32 characters).");
        _key = Encoding.UTF8.GetBytes(key);
    }

    public string Check(int tsi)
    {
        var mac = HMACSHA256.HashData(_key, Encoding.ASCII.GetBytes(tsi.ToString()));
        return Base64UrlEncode(mac.AsSpan(0, 12));
    }

    public bool IsValid(int tsi, string? check) =>
        check is not null &&
        CryptographicOperations.FixedTimeEquals(Encoding.ASCII.GetBytes(Check(tsi)), Encoding.ASCII.GetBytes(check));

    /// <summary>Relative URL for a survey page, e.g. Url("questions", 123) → "questions?TSI=123&amp;k=…".</summary>
    public string Url(string page, int tsi) => $"{page}?TSI={tsi}&k={Check(tsi)}";

    private static string Base64UrlEncode(ReadOnlySpan<byte> bytes) =>
        Convert.ToBase64String(bytes).TrimEnd('=').Replace('+', '-').Replace('/', '_');
}
