namespace TodoDemo;

public record Todo(Guid Id,
    string Title,
    bool IsDone);