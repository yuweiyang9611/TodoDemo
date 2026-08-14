using System.Collections.Concurrent;
using TodoDemo;
using TodoDemo.Services;
using Serilog;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddControllers();
builder.Services.AddSwaggerGen();

builder.Services.AddLogging(loggingBuilder => loggingBuilder.AddSerilog(dispose: true));
builder.Services.AddSingleton<ConcurrentDictionary<Guid, Todo>>(_ => new ConcurrentDictionary<Guid, Todo>());

builder.Services.AddGetInfosServices();

builder.Services.AddCors(cors =>
    cors.AddDefaultPolicy(policy => policy.SetIsOriginAllowed(IsLocalhost)
        .AllowCredentials().AllowAnyHeader().AllowAnyMethod()));

builder.Services.AddSignalR();

var app = builder.Build();

app.UseCors();
app.MapControllers();
app.MapHub<TodoHub>("/todoHub");

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.Run();

return;

// 判断是否为Localhost
bool IsLocalhost(string origin)
{
    var result = origin.StartsWith("http://localhost") ||
                 origin.StartsWith("http://127.0.0.1") ||
                 origin.StartsWith("https://localhost") ||
                 origin.StartsWith("https://127.0.0.1");
    return result;
}