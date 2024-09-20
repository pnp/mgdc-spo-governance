using groveale.Services;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace groveale
{
    public class StopADX
    {
        private readonly ILogger<StopADX> _logger;
        private readonly IAdxService _adxService;

        public StopADX(ILogger<StopADX> logger, IAdxService adxService)
        {
            _logger = logger;
            _adxService = adxService;
        }

        [Function("StopADX")]
        public async Task<IActionResult> Run([HttpTrigger(AuthorizationLevel.Anonymous, "get", "post")] HttpRequest req)
        {
            _logger.LogInformation("C# HTTP trigger function processed a request.");

            string repsonse = await _adxService.StopAdxClusterAsync();

            return new OkObjectResult(repsonse);
        }
    }
}
