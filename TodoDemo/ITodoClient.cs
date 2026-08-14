namespace TodoDemo;

public interface ITodoClient
{
    Task TodoAdded(Todo todo);
    Task TodoUpdated(Todo todo);
    Task TodoDeleted(Guid id);
}