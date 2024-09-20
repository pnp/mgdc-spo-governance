using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.DependencyInjection;
using groveale.Services;

var host = new HostBuilder()
    .ConfigureFunctionsWebApplication()
    .ConfigureServices(services => {
        services.AddApplicationInsightsTelemetryWorkerService();
        services.ConfigureFunctionsApplicationInsights();

        services.AddHttpClient();
        // Register the SynapseService
        services.AddSingleton<IAdxService, AdxService>();

        // Register the SynapseService
        services.AddSingleton<ISynapseService, SynapseService>();
    })
    .Build();

host.Run();
