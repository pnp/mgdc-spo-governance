using System;
using System.Net.Http;
using System.Text.Json;
using System.Threading.Tasks;
using Azure.Core;
using Azure.Identity;
using Microsoft.Extensions.Logging;


namespace groveale.Services
{
    
    public interface ISynapseService
    {
        Task TriggerPipelineAsync();
    }

    public class SynapseService : ISynapseService
    {
        private readonly HttpClient _client;
        private readonly ILogger<SynapseService> _logger;
        private readonly DefaultAzureCredential _credential;
        private readonly string _workspaceName;
        private readonly string _pipelineName;
        private readonly string _storageAccountName;
        private readonly string _storageContainerName;
        private readonly int _deltaDays;

        public SynapseService(HttpClient client, ILogger<SynapseService> logger)
        {
            _client = client;
            _logger = logger;
            _credential = new DefaultAzureCredential();

            // From environment variables
            _workspaceName = Environment.GetEnvironmentVariable("WORKSPACE_NAME");
            _pipelineName = Environment.GetEnvironmentVariable("PIPELINE_NAME");
            _storageAccountName = Environment.GetEnvironmentVariable("STORAGE_ACCOUNT_NAME");
            _storageContainerName = Environment.GetEnvironmentVariable("STORAGE_CONTAINER_NAME");
            _deltaDays = int.Parse(Environment.GetEnvironmentVariable("DELTA_DAYS"));
        }

        public async Task TriggerPipelineAsync()
        {
            // Workout start and end time (endtime is 3 days before now at 00:00) - (starttime is $deltaDays days before endtime at 00:00)
            string endTime = DateTime.UtcNow.AddDays(-3).ToString("yyyy-MM-dd") + "T00:00:00Z";
            string startTime = DateTime.Parse(endTime).AddDays(-_deltaDays).ToString("yyyy-MM-dd") + "T00:00:00Z";

            var apiVersion = "2020-12-01";
            var url = $"https://{_workspaceName}.dev.azuresynapse.net/pipelines/{_pipelineName}/createRun/?api-version={apiVersion}";

            var tokenRequestContextOG = new TokenRequestContext(new[] { "https://dev.azuresynapse.net/.default" });

            // Get an access token for the Synapse REST API.
            var token = await _credential.GetTokenAsync(tokenRequestContextOG);

            // Set the necessary headers for the HTTP request.
            _client.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", token.Token);

            var payload = new
            {
                StartTime = startTime,
                EndTime = endTime,
                StorageAccountName = _storageAccountName,
                StorageContainerName = _storageContainerName
            };

            string json = JsonSerializer.Serialize(payload);
            var content = new StringContent(json, System.Text.Encoding.UTF8, "application/json");

            var response = await _client.PostAsync(url, content);

            if (response.IsSuccessStatusCode)
            {
                _logger.LogInformation($"Pipeline triggered successfully");
            }
            else
            {
                _logger.LogError($"Failed to start pipeline: {response.StatusCode}");
            }
        }
    }
}