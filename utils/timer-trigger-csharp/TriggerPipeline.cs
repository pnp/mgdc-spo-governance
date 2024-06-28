using System;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace groverale
{
    public class TriggerPipeline
    {
        private readonly ILogger _logger;

        public TriggerPipeline(ILoggerFactory loggerFactory)
        {
            _logger = loggerFactory.CreateLogger<TriggerPipeline>();
        }

        [Function("TriggerPipeline")]
        public void Run([TimerTrigger("0 0 3 * * 1")] TimerInfo myTimer)
        {
            _logger.LogInformation($"C# Timer trigger function executed at: {DateTime.Now}");
            
            if (myTimer.ScheduleStatus is not null)
            {
                _logger.LogInformation($"Next timer schedule at: {myTimer.ScheduleStatus.Next}");
            }

            
        }
    }
}
