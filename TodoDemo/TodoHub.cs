using Microsoft.AspNetCore.SignalR;

namespace TodoDemo;

public class TodoHub : Hub<ITodoClient>
{
}