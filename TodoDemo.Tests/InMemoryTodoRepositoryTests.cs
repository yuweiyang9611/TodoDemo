using TodoDemo.Repositories;

namespace TodoDemo.Tests;

[TestClass]
public sealed class InMemoryTodoRepositoryTests
{
    [TestMethod]
    public void Add_StoresTodoAsNotDone()
    {
        var repository = new InMemoryTodoRepository();

        var todo = repository.Add("Learn records");

        Assert.AreNotEqual(Guid.Empty, todo.Id);
        Assert.AreEqual("Learn records", todo.Title);
        Assert.IsFalse(todo.IsDone);
        Assert.AreEqual(todo, repository.Get(todo.Id));
    }

    [TestMethod]
    public void Toggle_WhenCalledConcurrently_DoesNotLoseUpdates()
    {
        var repository = new InMemoryTodoRepository();
        var todo = repository.Add("Learn concurrency");

        Parallel.For(0, 1_000, _ => repository.Toggle(todo.Id));

        var current = repository.Get(todo.Id);
        Assert.IsNotNull(current);
        Assert.IsFalse(current.IsDone);
    }

    [TestMethod]
    public void Delete_ExistingTodo_RemovesItExactlyOnce()
    {
        var repository = new InMemoryTodoRepository();
        var todo = repository.Add("Learn REST");

        Assert.IsTrue(repository.Delete(todo.Id));
        Assert.IsFalse(repository.Delete(todo.Id));
        Assert.IsNull(repository.Get(todo.Id));
    }
}
