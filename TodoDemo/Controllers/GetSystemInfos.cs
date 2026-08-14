#if DEBUG
using Microsoft.AspNetCore.Mvc;
using TodoDemo.DTOs;
using TodoDemo.Services;

namespace TodoDemo.Controllers;

[Route("api/test/")]
public class GetSystemInfos(GetInfos infos) : CustomBaseController
{
    [HttpGet("getInfo")]
    public ActionResult<SystemInfoDto> Get()
    {
        return Ok(infos.GetSystemInfos());
    }
}
#endif