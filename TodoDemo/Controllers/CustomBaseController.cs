using Microsoft.AspNetCore.Mvc;

namespace TodoDemo.Controllers;

[ApiController]
[Produces("application/json")]
public abstract class CustomBaseController : ControllerBase
{
}
