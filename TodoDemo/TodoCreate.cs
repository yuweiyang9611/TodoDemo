using System.ComponentModel.DataAnnotations;

namespace TodoDemo;

public sealed record TodoCreate(
    [Required, StringLength(200, MinimumLength = 1)] string Title);
