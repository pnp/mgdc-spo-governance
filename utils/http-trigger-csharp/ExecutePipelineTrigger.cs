using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using System.Net.Http;
using Azure.Identity;
using Azure.Core;

namespace groverale
{
    public class ExecutePipelineTrigger
    {
        private readonly ILogger<ExecutePipelineTrigger> _logger;
        private static readonly HttpClient client = new HttpClient();

        public ExecutePipelineTrigger(ILogger<ExecutePipelineTrigger> logger)
        {
            _logger = logger;
        }

        [Function("ExecutePipelineTrigger")]
        public async Task<IActionResult> Run([HttpTrigger(AuthorizationLevel.Admin, "get", "post")] HttpRequest req)
        {
            _logger.LogInformation("C# HTTP trigger function processed a request.");

            // From environment variables
            var workspaceName = Environment.GetEnvironmentVariable("WORKSPACE_NAME");
            var pipelineName = Environment.GetEnvironmentVariable("PIPELINE_NAME");
            var storageAccountName = Environment.GetEnvironmentVariable("STORAGE_CONTAINER_NAME");
            var storageContainerName = Environment.GetEnvironmentVariable("STORAGE_ACCOUNT_NAME");
            var deltaDays = int.Parse(Environment.GetEnvironmentVariable("DELTA_DAYS"));

            // Workout start and end time (endtime is 3 days before now at 00:00) - (starttime is $deltaDays days before endtime at 00:00)
            string endTime = DateTime.UtcNow.AddDays(-3).ToString("yyyy-MM-dd") + "T00:00:00Z";
            string startTime = DateTime.Parse(endTime).AddDays(-deltaDays).ToString("yyyy-MM-dd") + "T00:00:00Z";

            var apiVersion = "2020-12-01";

            var url = $"https://{workspaceName}.dev.azuresynapse.net/pipelines/{pipelineName}/createRun/?api-version={apiVersion}";

            // Create an instance of DefaultAzureCredential.
            // if you are running this function locally, you need to set the following environment variables:
            // AZURE_CLIENT_ID, AZURE_TENANT_ID, AZURE_CLIENT_SECRET
            var credential = new DefaultAzureCredential();

            var tokenRequestContextOG = new TokenRequestContext(new[] { "https://dev.azuresynapse.net/.default" });
            //var tokenRequestContext = new TokenRequestContext(scopes: new string[] { $"https://{workspaceName}.dev.azuresynapse.net/.default" });

            // Get an access token for the Synapse REST API.
            var token = await credential.GetTokenAsync(tokenRequestContextOG);

            // Set the necessary headers for the HTTP request.
            client.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", token.Token);

            // Create an anonymous object for the JSON payload (pipeline parmeters).
            var payload = new
            {
                StartTime = startTime,
                EndTime = endTime,
                StorageAccountName = storageAccountName,
                StorageContainerName = storageContainerName
            };

            // Serialize the object to a JSON string.
            string json = JsonConvert.SerializeObject(payload);

            // Create a StringContent object for the request body.
            var content = new StringContent(json, System.Text.Encoding.UTF8, "application/json");

            // Make the POST request to the Synapse REST API.
            var response = await client.PostAsync(url, content);

            // Handle the response from the Synapse REST API.
            if (response.IsSuccessStatusCode)
            {
                var responseContent = await response.Content.ReadAsStringAsync();
                var runId = JsonConvert.DeserializeObject<dynamic>(responseContent).runId;
                _logger.LogInformation($"Pipeline run ID: {runId}");

                return new OkObjectResult($"Pipeline run ID: {runId}");
            }
            else
            {
                _logger.LogError($"Failed to start pipeline: {response.StatusCode}");

                return new BadRequestObjectResult($"Failed to start pipeline: {response.StatusCode}");
            }
        }
    }
}
