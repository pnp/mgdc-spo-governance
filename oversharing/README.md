# Oversharing

The oversharing pipeline has been developed with the following in mind.

**SPO Permission Analysis**: The oversharing pipeline provides comprehensive SharePoint Online (SPO) permission analysis. This ensures that all internal user claims are accurately identified while also including external user claims, group membership and powerful role based claims such as everyone except external users

**Delta Pulls for Efficient Cost Management**: The tool supports delta pulls, allowing for efficient cost management by only retrieving changes since the last data pull. This reduces the MGDC costs and ensures up-to-date information without unnecessary data processing.

**Copilot Readiness**: Designed with Copilot readiness in mind, the provided dashboard highlights potential areas of concern for rolling out M365 Copilot. This ensures that your organization is prepared for the future of intelligent data management and collaboration.

**Use Cases**: Ideal for organizations looking to optimize their SharePoint Online permissions, the pipeline + PowerBI dashboard helps in identifying all permission objects across SPO. This is particularly useful for security audits, compliance checks, and overall data governance.

## Prereqs

### Forecast - IMPORTANT!

Please go and run the `Oversharing Forecast` pipeline before running this one. This will ensure you have full visibility of all MGDC costs associated with the solution before you run it.

Further details can be found [here](/oversharing/forecast/README.md)

### Import the Low Code Oversharing Pipeline

Login to your Synapse Studio and import the pipeline.

1. Download the [Oversharing_LowCode.zip](/oversharing/Oversharing_LowCode.zip)

![Download Oversharing Pipeline](/docs/res/DLOPipeline.png)

2. From the Home menu, navigate to `Integrate`

![Integrate Menu](/docs/res/IntegrateMenu.png)

3. Import the pipeline from the + button. Browse to the downloaded pipeline template.

![Import Pipeline](/docs/res/ImportPipeline.png)

4. Select your Linked Services (created following [Jose's blog](https://techcommunity.microsoft.com/t5/microsoft-graph-data-connect-for/step-by-step-gather-a-detailed-dataset-on-sharepoint-sites-using/ba-p/4070563)) and click Open Pipeline. This will import 1 pipeline, 4 datasets and 1 notebook into your Synapse Studio.

![Open Pipeline](/docs/res/OpenOPipeline.png)

5. Click Publish all > Publish

![Publish](/docs/res/PublishOPipeline.png)

## Trigger a Full Pull

Great you are now ready to execute the pipeline to obtain a full snapshot. To obtain a full snapshot we need to execute a full pull. To achieve this we need to provide both the same start and end date to the pipeline

1. Navigate to the Integrate Menu and select the `Oversharing_LowCode` pipeline. Click `Add Trigger` > `Trigger now`

![Trigger Pipeline](/docs/res/TriggerOPipeline.png)

2. Populate full pull parameters and click `OK`. (`StartTime` and `EndTime` the same)

![Populate Full Pull Parameters](/docs/res/OverFullPullTrigger.png)

3. Navigate to the Monitor tab to see the execution details. Wait for the pipeline to `Complete`. Typically this will be 25 minutes.

![Monitor](/docs/res/OverPipelineExecution.png)

4. Once complete we can check the storage account for extracted data. - If you're pipeline failed then please check the [Troubleshooting Section](/docs/Troubleshooting.md)

![Pipeline Complete](/docs/res/OFPipelineComplete.png)

5. If the pipeline `Succeeded`, then navigate to your storage account using the Azure Portal and check for data lake. Click on the container blade and open the container you inputted for the StorageContainerName parameter for the pipeline run

There should be three folders in the root container. A fourth `deleted` folder will be added when you perform a delta pull

**latest** - this hold the latest version of the processed dataset. PowerBI is hooked up to this folder. More on this later

```
/ latest / permissions / *.json
/ latest / datasetname / *.json
```

**raw** - this holds all the data that is pulled from MGDC in it's unprocessed form.

```
/ raw / permissions / 2024 / 07 / 01 / 13ff9026-d8e7-452d-8369-675ad3793842 / *.json
/ raw / datasetname / YYYY / MM / DD / RunId / *.json
```

**temp** - this holds a copy of the latest that is used for merging with deltas in future runs. 

```
/ temp / permissions / *.json
/ temp / datasetname / *.json

```

>[!Note]  
> The dates we use in the folder hierarchy is from the end date parameter. 


6. Check that you have data in the latest folder for each dataset. If so we can attempt to hook up the PowerBI template

![Data in the Latest folder](/docs/res/OverDataLakeFullPull.png)

## Hook up with PowerBI Template

As part of this solution, there is a sample PowerBI template that can be used visualize and explore the MGDC data.

>[!Note]  
> Hopefully you already downloaded PowerBI desktop when following [Jose's blog](https://techcommunity.microsoft.com/t5/microsoft-graph-data-connect-for/step-by-step-gather-a-detailed-dataset-on-sharepoint-sites-using/ba-p/4070563) to get started with MGDC. If not in can be downloaded from [here](https://www.microsoft.com/en-us/power-platform/products/power-bi/downloads).

1. Download the [OversharingLowCode.pbit](/oversharing/OversharingLowCode.pbit) from this repo.

![Download PowerBI template](/docs/res/OverPBIDL.png)

>[!Note]  
> The PowerBI was built for an earlier version of the pipeline. It will be updated but some visuals may currently missing.

2. Open the PowerBI template, you should be presented with the following parameter screen. Please click on the dropdown next to the `Load` button and click `Edit`

![Edit PowerBI Parameter Screen](/docs/res/PBIParamsScreen.png)

3. Now update the data sources configured to point to your storage account. 

![Edit PowerBI data source](/docs/res/PBIUpdateDataSources.png)

4. Update the following four datasources (m365groups can be ignored)

* `https://mgdcag3.dfs.core.windows.net/oversharing-lowcode/latest/permissions`
* `https://mgdcag3.dfs.core.windows.net/oversharing-lowcode/latest/sites`
* `https://mgdcag3.dfs.core.windows.net/oversharing-lowcode/latest/spogroupdetails`
* `https://mgdcag3.dfs.core.windows.net/oversharing-lowcode/latest/spogroupmembers`

You can just update the storage account name and container to map what you have configured

![Edit data sources](/docs/res/PBIStorageAccountConfig.png)

5. Edit Permissions for each of the four in use datasources. You will need to obtain an account key from the storage account in the Azure Portal

![Obtain Storage Account Key](/docs/res/PBIStorageAccountKey.png)

6. Copy the key and go back to the the datasource settings tab in PBI. Click on the one of the datasources and click the `Edit Permissions` button

![Edit Permissions](/docs/res/PBIEditDSPermissions.png)

7. Click `Edit` under the credential header. This will open credential window, change to account key and paste in the storage account key you copied from the Azure portal. Click Save.

![Save Account Key](/docs/res/PBISaveAccountKEy.png)

8. Repeat for the other datasets and close the data source settings menu and close the power query window.

9. Refresh the PowerBI dashboard using the refresh button. You should see the datasets load and the visuals update to reflect your data

![Refresh the PowerBI data](/docs/res/PBIRefreshdata.png)

>[!Note]  
> Please see video that walks through the PowerBI report. 
> Video to be recorded


## Trigger a Delta Pull

Now we have our initial pull and can see this in PowerBI we need to keep this data up-to-date. This will allow us to validate the success of any interventions or remediation activities that we perform.

To achieve this we can perform a `delta pull`

1. Open synapse studio and navigate to the Integrate Menu and select the `Oversharing_LowCode` pipeline. Click `Add Trigger` > `Trigger now`

![Trigger Pipeline](/docs/res/TriggerOPipeline.png)

2. Populate full pull parameters and click `OK`. (`StartTime` and `EndTime` are different)

![Populate Full Pull Parameters](/docs/res/ODPipelineTrigger.png)

3. Navigate to the Monitor tab to see the execution details. Wait for the pipeline to `Complete`. Typically this will be 25 minutes.

![Monitor](/docs/res/OverPipelineExecution.png)

4. Once complete we can check the storage account for extracted data. - If you're pipeline failed then please check the [Troubleshooting Section](/docs/Troubleshooting.md)

![Pipeline Complete](/docs/res/OFPipelineComplete.png)

5. If the pipeline `Succeeded`, then navigate to your storage account using the Azure Portal and check for data lake. Click on the container blade and open the container you inputted for the StorageContainerName parameter for the pipeline run

There should be four folders in the root container.

**deleted** - this holds all the deleted objects so you can track what has been deleted int he tenant

```
/ deleted / permissions / *.json
/ deleted / datasetname / *.json

```

**latest** - this hold the latest version of the processed dataset. PowerBI is hooked up to this folder.

```
/ latest / permissions / *.json
/ latest / datasetname / *.json
```

**raw** - this holds all the data that is pulled from MGDC in it's unprocessed form.

```
/ raw / permissions / 2024 / 07 / 01 / 13ff9026-d8e7-452d-8369-675ad3793842 / *.json
/ raw / datasetname / YYYY / MM / DD / RunId / *.json
```

**temp** - this holds a copy of the latest that is used for merging with deltas in future runs. 

```
/ temp / permissions / *.json
/ temp / datasetname / *.json

```

>[!Note]  
> The dates we use in the folder hierarchy is from the end date parameter. 


6. Check that you have data in the latest folder for each dataset. The old latest should have been overwritten.

![Data in the Latest folder](/docs/res/OverDataLakeDeltaPull.png)

7. Go back to the PowerBI report and refresh the data! PowerBI will reload the data from the newly updated latest folders!

## Scheduling

Now you have successfully ran a full pull and delta, it's time to set up some auto scheduling. Please navigate to [Scheduling](/utils/readme.md)