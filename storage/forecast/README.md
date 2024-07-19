# Forecasting Cost

A very important part of adopting any solution is understanding what it will cost. Whilst we will have some residual Azure costs, these will be negligible compared to MGDC costs. There has been a pipeline written to extract the total object counts in each dataset required for the Capacity scenario, this being Sites and Files.

## Prereqs

Currently, the forecasting pipeline requires a Spark pool to execute the notebook that is used to pull out the total objects from the job metadata that is returned to the storage account on successful execution of MGDC. Future aspirations are to have a different process extract this info and serve up in some form of web interface. But for now you need a Spark pool. Sorry! If you already have a spark pool in your Synapse workspace then great you can use this.

### Spark Pool

You can create a spark pool directly from your Synapse Workspace resource in the Azure portal

1. Create Spark Pool

![Create Spark Pool](/docs/res/CreateSparkPool.png)

2. Provide your spark pool a name and a size. Small will be more than adequate for the forecast

![Complete configuration details](/docs/res/SparkPoolDetails.png)

3. Review and Create > Create

### Import the forecast Pipeline

Login to your Synapse Studio and import the pipeline.

1. Download the [Storage_Top1.zip](/storage/forecast/Storage_Top1.zip)

![Download Storage Forecast Pipeline](/docs/res/DownloadStoreageForecastPipeline.png)

2. From the Home menu, navigate to `Integrate`

![Integrate Menu](/docs/res/IntegrateMenu.png)

3. Import the pipeline from the + button. Browse to the downloaded pipeline template.

![Import Pipeline](/docs/res/ImportPipeline.png)

4. Select your Linked Services (created following [Jose's blog](https://techcommunity.microsoft.com/t5/microsoft-graph-data-connect-for/step-by-step-gather-a-detailed-dataset-on-sharepoint-sites-using/ba-p/4070563)) and click Open Pipeline. This will import 1 pipeline, 4 datasets and 1 notebook into your Synapse Studio.

![Open Pipeline](/docs/res/OpenSFPipeline.png)

5. Before publishing, navigate to the Forecast Notebook, under the develop tab and ensure that a spark pool has been selected in the `Attach to` dropdown

![Open Pipeline](/docs/res/AttachTo.png)

6. Click Publish all > Publish

![Publish](/docs/res/PublishSFPipeline.png)


## Forecast for Full Pull

Great you are now ready to execute the pipeline to obtain a forecast. To obtain a full pull we need to provide both the same start and end date.

1. Navigate to the Integrate Menu and select the `Storage_Top1` pipeline. Click `Add Trigger` > `Trigger now`

![Trigger Pipeline](/docs/res/TriggerSFPipeline.png)

2. Populate full pull parameters and click `OK`

![Populate Full Pull Parameters](/docs/res/SFFullPullTrigger.png)

3. Navigate to the Monitor tab to see the execution details. Wait for the pipeline to `Complete`. Typically this will be 25 minutes.

![Monitor](/docs/res/SFPipelineExecution.png)

4. Once complete we can check the details extracted int he notebook

todo

## Forecast for Delta Pull

Great you are now ready to execute the pipeline to obtain a delta forecast. To obtain a delta pull we need to provide a different start and end date.

1. Navigate to the Integrate Menu and select the `Storage_Top1` pipeline. Click `Add Trigger` > `Trigger now`

![Trigger Pipeline](/docs/res/TriggerSFPipeline.png)

2. Populate parameters and click `OK`. Notice that the dates are 7 days apart. This timescale should be ajusted for the expected cadence. i.e. if running bi-weekly then get a delta forecast for a 14 day period.

![Populate Full Pull Parameters](/docs/res/SFDeltaPullTrigger.png)

3. Navigate to the Monitor tab to see the execution details. Wait for the pipeline to `Complete`. Typically this will be 25 minutes.

![Monitor](/docs/res/SFPipelineExecution.png)

4. Once complete we can check the details extracted int he notebook

todo