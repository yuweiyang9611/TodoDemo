namespace TodoDemo.Repositories;

public interface ITodoRepository
{
    IReadOnlyList<Todo> GetAll();
    Todo? Get(Guid id);
    Todo Add(string title);
    Todo? Toggle(Guid id);
    bool Delete(Guid id);
}
