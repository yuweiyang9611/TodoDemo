using System.Collections.Concurrent;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;

namespace TodoDemo.Controllers;

[Route("api/todos/")]
public class TodoHubApi(IHubContext<TodoHub, ITodoClient> hub,
    ConcurrentDictionary<Guid, Todo> todos)
    : CustomBaseController
{
    [HttpGet]
    public Task<ActionResult<List<Todo>>> GetAllTodos()
    {
        var re = todos.Values.OrderBy(t => t.Id).ToList();
        return Task.FromResult<ActionResult<List<Todo>>>(re);
    }

    [HttpPost]
    public async Task<ActionResult<Todo>> AddNewToTodoList([FromBody] TodoCreate req)
    {
        var id = Guid.NewGuid();
        var todo = new Todo(id, req.Title, false);
        todos[id] = todo;
        await hub.Clients.All.TodoAdded(todo);
        // 标准API的写法，添加东西后要：
        // 发出201状态码，返回新添加的对象，这个对象的访问地址
        return Created($"/api/todos/{id}", todo);
    }

    [HttpPut("{id:guid}/toggle")]
    public async Task<ActionResult<Todo>> Update([FromRoute(Name = "id")] Guid id)
    {
        if (!todos.TryGetValue(id, out var old)) return NotFound();
        // C# 9 引入的「记录类型（record）」的新语法
        // 创建一个现有对象的副本并修改部分属性，返回这个新创建的对象
        // 这种方法可以保证原对象保持不变
        var updated = old with
        {
            IsDone = !old.IsDone
        };
        todos[id] = updated;
        await hub.Clients.All.TodoUpdated(updated);
        return Ok(updated);
    }

    [HttpDelete("{id:guid}")]
    public async Task<ActionResult> Delete([FromRoute(Name = "id")] Guid id)
    {
        if (!todos.TryRemove(id, out _)) return NotFound();
        await hub.Clients.All.TodoDeleted(id);
        return NoContent();
    }
}