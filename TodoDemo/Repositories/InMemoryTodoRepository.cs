using System.Collections.Concurrent;

namespace TodoDemo.Repositories;

public sealed class InMemoryTodoRepository : ITodoRepository
{
    private readonly ConcurrentDictionary<Guid, Todo> _todos = new();

    public IReadOnlyList<Todo> GetAll()
    {
        return _todos.Values
            .OrderBy(todo => todo.Title, StringComparer.OrdinalIgnoreCase)
            .ThenBy(todo => todo.Id)
            .ToArray();
    }

    public Todo? Get(Guid id)
    {
        return _todos.GetValueOrDefault(id);
    }

    public Todo Add(string title)
    {
        var todo = new Todo(Guid.NewGuid(), title, false);
        if (!_todos.TryAdd(todo.Id, todo))
        {
            throw new InvalidOperationException("Unable to allocate a unique todo identifier.");
        }

        return todo;
    }

    public Todo? Toggle(Guid id)
    {
        while (_todos.TryGetValue(id, out var current))
        {
            var updated = current with { IsDone = !current.IsDone };
            if (_todos.TryUpdate(id, updated, current))
            {
                return updated;
            }
        }

        return null;
    }

    public bool Delete(Guid id)
    {
        return _todos.TryRemove(id, out _);
    }
}
