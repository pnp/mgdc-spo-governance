# Storage

The storage pipeline has been developed with the following in mind.

**SPO Storage Analysis**: The storage analysis pipeline delivers an extensive SharePoint Online (SPO) storage analysis. This ensures that all storage usage is meticulously accounted for, including detailed insights into individual site collections, document libraries, and specific file sizes. The analysis also incorporates trends in storage consumption over time, identifies unused or duplicate files, and provides recommendations for optimizing storage allocation and usage efficiency

**Delta Pulls for Efficient Cost Management**: The tool supports delta pulls, allowing for efficient cost management by only retrieving changes since the last data pull. This reduces the MGDC costs and ensures up-to-date information without unnecessary data processing.

## Prereqs

### Forecast - IMPORTANT!

Please go and run the `Storage Forecast` pipeline before running this one. This will ensure you have full visibility of all MGDC costs associated with the solution before you run it.

Further details can be found [here](/storage/forecast/README.md)

### Import the Low Code Storage Pipeline

Login to your Synapse Studio and import the pipeline.

1. Download the [StorageExploration_LowCode.zip](/storage/StorageExploration_LowCode.zip)

![Download Storage Pipeline](/docs/res/DLOPipeline.png)

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

1. Navigate to the Integrate Menu and select the `Oversharing_LowCode.zip` pipeline. Click `Add Trigger` > `Trigger now`

![Trigger Pipeline](/docs/res/TriggerOPipeline.png)

2. Populate full pull parameters and click `OK`. (`StartTime` and `EndTime` the same)

![Populate Full Pull Parameters](/docs/res/OverFullPullTrigger.png)

3. Navigate to the Monitor tab to see the execution details. Wait for the pipeline to `Complete`. Typically this will be 25 minutes.

![Monitor](/docs/res/OverPipelineExecution.png)

4. Once complete we can check the storage account for extracted data. - If you're pipeline failed then please check the [Troubleshooting Section](/docs/Troubleshooting.md)

![Pipeline Complete](/docs/res/OFPipelineComplete.png)

5. If the pipeline `Succeeded`, then navigate to your storage account using the Azure Portal and check for data lake. Click on the container blade and open the container you inputted for the StorageContainerName parameter for the pipeline run

There should be thee folders in the root container. A fourth `deleted` folder will be added when you perform a delta pull

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

todo - Rework PowerBI

## Trigger a Delta Pull



 include PowerBI hook up, delta pull. Then link to scheduling