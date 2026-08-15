using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Mvc.Testing;

namespace TodoDemo.Tests;

[TestClass]
public sealed class TodoApiTests
{
    [TestMethod]
    public async Task Create_ReturnsUsableLocationAndTrimmedTodo()
    {
        using var application = new WebApplicationFactory<TodoHub>();
        using var client = application.CreateClient();

        var response = await client.PostAsJsonAsync(
            "/api/todos",
            new TodoCreate("  integration test  "));

        Assert.AreEqual(HttpStatusCode.Created, response.StatusCode);
        Assert.IsNotNull(response.Headers.Location);

        var created = await response.Content.ReadFromJsonAsync<Todo>();
        Assert.IsNotNull(created);
        Assert.AreEqual("integration test", created.Title);
        Assert.AreNotEqual(Guid.Empty, created.Id);

        var fetched = await client.GetFromJsonAsync<Todo>(response.Headers.Location);
        Assert.AreEqual(created, fetched);
    }

    [TestMethod]
    public async Task Create_WithWhitespaceTitle_ReturnsBadRequest()
    {
        using var application = new WebApplicationFactory<TodoHub>();
        using var client = application.CreateClient();

        var response = await client.PostAsJsonAsync(
            "/api/todos",
            new TodoCreate("   "));

        Assert.AreEqual(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [TestMethod]
    public async Task Cors_AllowsConfiguredOriginAndRejectsPrefixLookalike()
    {
        using var application = new WebApplicationFactory<TodoHub>();
        using var client = application.CreateClient();

        using var allowedRequest = new HttpRequestMessage(HttpMethod.Get, "/health");
        allowedRequest.Headers.Add("Origin", "http://127.0.0.1:3000");
        var allowedResponse = await client.SendAsync(allowedRequest);

        Assert.IsTrue(allowedResponse.Headers.TryGetValues(
            "Access-Control-Allow-Origin",
            out var allowedOrigins));
        CollectionAssert.Contains(
            allowedOrigins.ToArray(),
            "http://127.0.0.1:3000");

        using var blockedRequest = new HttpRequestMessage(HttpMethod.Get, "/health");
        blockedRequest.Headers.Add("Origin", "http://localhost.evil.example");
        var blockedResponse = await client.SendAsync(blockedRequest);

        Assert.IsFalse(blockedResponse.Headers.Contains("Access-Control-Allow-Origin"));
    }
}
