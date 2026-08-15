namespace TodoDemo;

public sealed record Todo(Guid Id,
    string Title,
    bool IsDone);
