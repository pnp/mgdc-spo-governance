using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using System.Net.Http;
using Azure.Identity;
using Azure.Core;

namespace groveale
{
    public static class TriggerPipeline
    {
        private static readonly HttpClient client = new HttpClient();

        [FunctionName("TriggerPipeline")]
        public static async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Anonymous, "get", "post", Route = null)] HttpRequest req,
            ILogger log)
        {
            log.LogInformation("C# HTTP trigger function processed a request.");

            // pipeline parameters
            string startTime = req.Query["startTime"];
            string endTime = req.Query["endTime"];
            string storageAccountName = req.Query["storageAccountName"];
            string storageContainerName = req.Query["storageContainerName"];

            string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
            dynamic data = JsonConvert.DeserializeObject(requestBody);
            startTime = startTime ?? data?.startTime;
            endTime = endTime ?? data?.endTime;
            storageAccountName = storageAccountName ?? data?.storageAccountName;
            storageContainerName = storageContainerName ?? data?.storageContainerName;

            // From environment variables
            var workspaceName = Environment.GetEnvironmentVariable("workspaceName");
            var pipelineName = Environment.GetEnvironmentVariable("pipelineName");
            var apiVersion = "2020-12-01";

            var url = $"https://{workspaceName}.dev.azuresynapse.net/pipelines/{pipelineName}/?api-version={apiVersion}";

            // Create an instance of DefaultAzureCredential.
            // if you are running this function locally, you need to set the following environment variables:
            // AZURE_CLIENT_ID, AZURE_TENANT_ID, AZURE_CLIENT_SECRET
            var credential = new DefaultAzureCredential();

            //var tokenRequestContextOG = new TokenRequestContext(new[] { "https://dev.azuresynapse.net/.default" });
            var tokenRequestContext = new TokenRequestContext(scopes: new string[] { $"https://{workspaceName}.dev.azuresynapse.net/.default" });

            // Get an access token for the Synapse REST API.
            var token = await credential.GetTokenAsync(tokenRequestContext);

            // Set the necessary headers for the HTTP request.
            client.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", token.Token);

            // Create an anonymous object for the JSON payload (pipeline parmeters).
            var payload = new
            {
                startTime = startTime,
                endTime = endTime,
                storageAccountName = storageAccountName,
                storageContainerName = storageContainerName
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
                log.LogInformation($"Pipeline run ID: {runId}");

                return new OkObjectResult($"Pipeline run ID: {runId}");
            }
            else
            {
                log.LogError($"Failed to start pipeline: {response.StatusCode}");

                return new BadRequestObjectResult($"Failed to start pipeline: {response.StatusCode}");
            }

            
        }
    }
}
