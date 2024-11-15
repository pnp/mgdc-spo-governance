using System;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using Azure.Identity;
using Azure.Core;
using Microsoft.AspNetCore.Mvc;
using System.Text.Json;
using groveale.Services;
using Google.Protobuf.WellKnownTypes;


namespace groveale
{
    public class TriggerPipeline
    {
        private readonly ILogger _logger;
        private readonly IAdxService _adxService;
        private readonly ISynapseService _synapseService;

        public TriggerPipeline(ILoggerFactory loggerFactory, IAdxService adxService, ISynapseService synapseService)
        {
            _logger = loggerFactory.CreateLogger<TriggerPipeline>();
            _adxService = adxService;
            _synapseService = synapseService;
            
        }

        [Function("TriggerPipeline")]
        public async Task Run([TimerTrigger("0 0 3 * * 1")] TimerInfo myTimer)
        {
            _logger.LogInformation($"C# Timer trigger function executed at: {DateTime.Now}");
            
            if (myTimer.ScheduleStatus is not null)
            {
                _logger.LogInformation($"Next timer schedule at: {myTimer.ScheduleStatus.Next}");
            }

            await _synapseService.TriggerPipelineAsync();

            var additionalPipelineName = Environment.GetEnvironmentVariable("ADDITIONAL_PIPELINE_NAME");

            if (!String.IsNullOrEmpty(additionalPipelineName))
            {
                await _synapseService.TriggerAdditionalPipelineAsync(additionalPipelineName);
            }

            var turnOnADX = Environment.GetEnvironmentVariable("TURN_ON_ADX");

            if (turnOnADX == "true")
            {
                await _adxService.StartAdxClusterAsync();
            }
        }
    }
}
