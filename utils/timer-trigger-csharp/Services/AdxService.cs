using System;
using System.Net.Http;
using System.Threading.Tasks;
using Azure.Core;
using Azure.Identity;
using Microsoft.Extensions.Logging;

namespace groveale.Services
{
    
    public interface IAdxService
    {
        Task StartAdxClusterAsync();
        Task<string> StopAdxClusterAsync();
    }
    public class AdxService : IAdxService
    {
        private readonly HttpClient _client;
        private readonly ILogger<AdxService> _logger;
        private readonly DefaultAzureCredential _credential;
        private readonly string _token;
        private readonly string _baseUrl;

        public AdxService(HttpClient client, ILogger<AdxService> logger)
        {
            _client = client;
            _logger = logger;

            var credential = new DefaultAzureCredential();
            var tokenRequestContextADX = new TokenRequestContext(new[] { "https://management.azure.com/.default" });
            var tokenADX = credential.GetToken(tokenRequestContextADX);
            _token = tokenADX.Token;

            _client.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", _token);

            var adxClusterName = Environment.GetEnvironmentVariable("ADX_CLUSTER_NAME");
            var adxResourceGroupName = Environment.GetEnvironmentVariable("ADX_RESOURCE_GROUP_NAME");
            var adxSubscriptionId = Environment.GetEnvironmentVariable("ADX_SUBSCRIPTION_ID");

            _baseUrl = $"https://management.azure.com/subscriptions/{adxSubscriptionId}/resourceGroups/{adxResourceGroupName}/providers/Microsoft.Kusto/clusters/{adxClusterName}";
        }

        private string GetAdxUrl(string action)
        {
            return $"{_baseUrl}/{action}?api-version=2023-08-15";
        }

        public async Task StartAdxClusterAsync()
        {
            _logger.LogInformation("ADX should be turned on");

            var adxUrl = GetAdxUrl("start");

            var responseADX = await _client.PostAsync(adxUrl, null);

            if (responseADX.IsSuccessStatusCode)
            {
                _logger.LogInformation("ADX cluster started successfully");
            }
            else
            {
                _logger.LogError($"Failed to start ADX cluster: {responseADX.StatusCode}");
            }
        }

        public async Task<string> StopAdxClusterAsync()
        {
            _logger.LogInformation("ADX should be turned off");

            var adxUrl = GetAdxUrl("stop");

            var responseADX = await _client.PostAsync(adxUrl, null);

            if (responseADX.IsSuccessStatusCode)
            {
                _logger.LogInformation("ADX cluster stopped successfully");
               return "ADX cluster stopped successfully"; 
            }
            else
            {
                _logger.LogError($"Failed to stop ADX cluster: {responseADX.StatusCode}");
                return $"Failed to stop ADX cluster: {responseADX.StatusCode}";
            }
        }
    }
        
}