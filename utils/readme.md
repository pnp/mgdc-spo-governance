# Scheduling Utils

Azure Synapse Studio supports scheduling of pipelines. However we need to dynamically change our pipeline parameters at each run. This is not supported. To be able to trigger the pipeline with dynamic parameters on a schedule we need to make use of the synapse REST APIs.

## Timer-Trigger-PowerShell Function deployment

## Timer-Trigger-C# Function deployment

Create an Azure function with the below configuration.

Notable settings.
* .NET Runtime
* Version 8 (LTS), isolated worker model
* Windows

![Create Azure Function](/docs/res/AFCreate.png)

If you create with the these settings you will have a storage account, app service plan and app insights created for you as well as the Function app. 

The resource group should contain similar to the below

![Azure Function Resources](/docs/res/AFResources.png)

#### Function Identity

We will give the Azure function an Entra assigned managed identity. With this identity, the function can be granted access to the Synapse Workspace to enable it to trigger the pipeline.

![Azure Function Identity](/docs/res/AFIdentitity.png)

After assigning the function a managed identity we can provide access to the synapse workspace. Open Synapse studio and go to the manage tab > Access Control and click `+ Add` to open the Add Role Assignment window

![Azure Function Access](/docs/res/AFProvideAccess.png)

In the Add Role Assignment window, leave the scope as workspace and role as `Synapse Admin`. Search for you Azure functions managed identity using the resource name in the select user box. Click Apply once you have selected the managed identity.

![Azure Function Admin Access](/docs/res/AFAdminAccess.png)

The function will now be able to trigger the pipeline using the REST API.

#### Function code deployment

The function code can be found [here](/utils/timer-trigger-csharp). It is recommended to clone or download the repo.

It includes one function. The function is configured to be executed weekly (on a Monday at 3AM UTC). It simply triggers the pipeline using the synapse rest API.

There are numerous ways to deploy function code to Azure. They are detailed here - [Deployment technologies in Azure Functions | Microsoft Learn](https://learn.microsoft.com/en-us/azure/azure-functions/functions-deployment-technologies?tabs=windows)

An easy option is to use the Azure Function Extension in `vscode`. This requires the users to sign into their Microsoft account that has access to the provisioned Azure resources.

From the Azure Function extension window click deploy form the bottom menu window

![Azure Function Deploy](/docs/res/AFDeploy.png)

This opens a dialogue that enables you to select the Azure Function you have just created.

After clicking you will see a confirmation window

![Azure Function Confirmation](/docs/res/AFConfirmDeploy.png)

This will kick off the deployment process of building and uploading your compiled function to your Azure resource. Once complete you should see a confirmation message in the `vscode` terminal

![Azure Function Deployment Success](/docs/res/AFDeploymentComplete.png)

#### Function Config

The function app contains some config variables. These can either be entered into the portal or added via the `vscode` extension

```json
{
    "WORKSPACE_NAME": "synapse-mgdc-us",
    "PIPELINE_NAME": "Oversharing_LowCode",
    "STORAGE_CONTAINER_NAME": "oversharing-lowcode",
    "STORAGE_ACCOUNT_NAME": "agmgdcstorage",
    "DELTA_DAYS": "7"
}
```

| Key                    | Value                    | Description                                      |
|------------------------|--------------------------|--------------------------------------------------|
| `WORKSPACE_NAME`       | `synapse-mgdc-us`        | The name of the Synapse workspace                |
| `PIPELINE_NAME`        | `Oversharing_LowCode`    | The name of the pipeline                         |
| `STORAGE_CONTAINER_NAME`| `oversharing-lowcode`   | The name of the storage container                |
| `STORAGE_ACCOUNT_NAME` | `agmgdcstorage`          | The name of the storage account                  |
| `DELTA_DAYS`           | `7`                      | The number of days for the delta calculation     |

Open up the extension, find the function in your list or resource. Expand and right click the app settings. Clicking upload local settings will upload the settings values from the `local.settings.json` files

> [!NOTE]  
> The repo includes a `local.settings.json.sample` file. Use this to create a local settings file for your environment

![Azure Function Upload Config](/docs/res/AFUploadConfig.png)

The Azure function is now configured.

#### Testing the Azure Function

To test the function, navigate to the function resource in the Azure portal and click on the listed function.

![Azure Function In Azure](/docs/res/AFTestFunction.png)

This will bring you to the Code + Test function menu. From here click `Test/Run` to open `Test/Run` menu, simply click Run and you should see a 202 response. You should also see a run Id the logs.

> [!NOTE]  
> If you see a warning for CORS, simply navigate to the CORS blade on the Azure Function, the required config will be added and you should be able to go back and execute the test. 

![Test the Azure Function from the portal](/docs/res/AFTestFunctionRun.png)

Finally go and check Synapse Studio for a running pipeline. The runId should match what you saw in the Azure function logs.

![Test the Azure Function from the portal](/docs/res/AFTestFunctionTrigger.png)

This will now execute on a schedule and keep your MGDC data up-to-date. Feel free to adjust the schedule to work for you. 
