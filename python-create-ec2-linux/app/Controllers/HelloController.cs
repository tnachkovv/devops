using Microsoft.AspNetCore.Mvc;

namespace SimpleDotNetApp.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class HelloController : ControllerBase
    {
        [HttpGet]
        public ActionResult<string> Get()
        {
            return "Hello from the .NET Core app!";
        }
    }
}
