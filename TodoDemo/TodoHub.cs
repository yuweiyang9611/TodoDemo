using Microsoft.AspNetCore.SignalR;

namespace TodoDemo;

public sealed class TodoHub : Hub<ITodoClient>
{
}
