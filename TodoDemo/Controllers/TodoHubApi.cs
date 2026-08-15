using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using TodoDemo.Repositories;

namespace TodoDemo.Controllers;

[Route("api/todos")]
public sealed class TodoHubApi(
    IHubContext<TodoHub, ITodoClient> hub,
    ITodoRepository repository)
    : CustomBaseController
{
    [HttpGet]
    [ProducesResponseType<IReadOnlyList<Todo>>(StatusCodes.Status200OK)]
    public ActionResult<IReadOnlyList<Todo>> GetAllTodos()
    {
        return Ok(repository.GetAll());
    }

    [HttpGet("{id:guid}")]
    [ProducesResponseType<Todo>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public ActionResult<Todo> GetById(Guid id)
    {
        var todo = repository.Get(id);
        return todo is null ? NotFound() : Ok(todo);
    }

    [HttpPost]
    [ProducesResponseType<Todo>(StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<Todo>> AddNewToTodoList([FromBody] TodoCreate request)
    {
        var title = request.Title.Trim();
        if (title.Length == 0)
        {
            ModelState.AddModelError(nameof(request.Title), "Title cannot contain only whitespace.");
            return ValidationProblem(ModelState);
        }

        var todo = repository.Add(title);
        await hub.Clients.All.TodoAdded(todo);
        return CreatedAtAction(nameof(GetById), new { id = todo.Id }, todo);
    }

    [HttpPut("{id:guid}/toggle")]
    [ProducesResponseType<Todo>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<Todo>> Toggle(Guid id)
    {
        var updated = repository.Toggle(id);
        if (updated is null)
        {
            return NotFound();
        }

        await hub.Clients.All.TodoUpdated(updated);
        return Ok(updated);
    }

    [HttpDelete("{id:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(Guid id)
    {
        if (!repository.Delete(id))
        {
            return NotFound();
        }

        await hub.Clients.All.TodoDeleted(id);
        return NoContent();
    }
}
