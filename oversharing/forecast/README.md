# Forecasting Cost

A very important part of adopting any solution is understanding what it will cost. Whilst we will have some residual Azure costs, these will be negligible compared to MGDC costs. There has been a pipeline written to extract the total object counts in each dataset required for the Capacity scenario, this being Sites and Files.

## Prereqs

Currently, the forecasting pipeline requires a Spark pool to execute the notebook that is used to pull out the total objects from the job metadata that is returned to the storage account on successful execution of MGDC. Future aspirations are to have a different process extract this info and serve up in some form of web interface. But for now you need a Spark pool. Sorry! If you already have a spark pool in your Synapse workspace then great you can use this.

### MGDC App datasets

If you followed [Jose's blog](https://techcommunity.microsoft.com/t5/microsoft-graph-data-connect-for/step-by-step-gather-a-detailed-dataset-on-sharepoint-sites-using/ba-p/4070563) you should have an MGDC app that has permission to extract the Sites dataset.

For oversharing we need the following three datasets:

* Sites
* Permission
* SPOGroups

Please navigate to you MGDC app in the Azure portal and validate that the app has permission to extract these datasets. Remember that if you make any changes you will need to re-approve the app in the MAC (using another global admin account)

1. Navigate to the MGDC app in the Azure portal and select you app

![MGDC App Azure](/docs/res/MGDCAzure.png)

2. Validate the datasets under settings

![MGDC Oversharing Datasets](/docs/res/MGDCOverSharingDatasets.png)

3. NAvigate to MGDC apps in the Microsoft Admin Centre. Settings > Org Settings > Security & Privacy 

![MGDC MAC](/docs/res/MGDCMACApprove.png)

4. Approve (if required). Click and follow the approval flow.

![MGDC Update](/docs/res/MGDCUpdate.png)

### Spark Pool

You can create a spark pool directly from your Synapse Workspace resource in the Azure portal

1. Create Spark Pool

![Create Spark Pool](/docs/res/CreateSparkPool.png)

2. Provide your spark pool a name and a size. Small will be more than adequate for the forecast

![Complete configuration details](/docs/res/SparkPoolDetails.png)

3. Review and Create > Create

### Import the forecast Pipeline

Login to your Synapse Studio and import the pipeline.

1. Download the [Sites_Permissions_SPGroups_Top1.zip](/oversharing/forecast/Sites_Permissions_SPGroups_Top1.zip)

![Download Oversharing Forecast Pipeline](/docs/res/DLOFPipeline.png)

2. From the Home menu, navigate to `Integrate`

![Integrate Menu](/docs/res/IntegrateMenu.png)

3. Import the pipeline from the + button. Browse to the downloaded pipeline template.

![Import Pipeline](/docs/res/ImportPipeline.png)

4. Select your Linked Services (created following [Jose's blog](https://techcommunity.microsoft.com/t5/microsoft-graph-data-connect-for/step-by-step-gather-a-detailed-dataset-on-sharepoint-sites-using/ba-p/4070563)) and click Open Pipeline. This will import 1 pipeline, 4 datasets and 1 notebook into your Synapse Studio.

![Open Pipeline](/docs/res/OpenOFPipeline.png)

5. Before publishing, navigate to the Forecast Notebook, under the develop tab and ensure that a spark pool has been selected in the `Attach to` dropdown

![Open Pipeline](/docs/res/AttachToOf.png)

6. Click Publish all > Publish

![Publish](/docs/res/PublishOFPipeline.png)


## Forecast for Full Pull

Great you are now ready to execute the pipeline to obtain a forecast. To obtain a full pull we need to provide both the same start and end date.

1. Navigate to the Integrate Menu and select the `Sites_Permissions_SPGroups_Top1` pipeline. Click `Add Trigger` > `Trigger now`

![Trigger Pipeline](/docs/res/TriggerOFPipeline.png)

2. Populate full pull parameters and click `OK`

![Populate Full Pull Parameters](/docs/res/OFFullPullTrigger.png)

3. Navigate to the Monitor tab to see the execution details. Wait for the pipeline to `Complete`. Typically this will be 25 minutes.

![Monitor](/docs/res/OFPipelineExecution.png)

4. Once complete we can check the details extracted in the notebook - If you're pipeline failed then please check the [Troubleshooting Section](/docs/Troubleshooting.md)

![Pipeline Complete](/docs/res/OFPipelineComplete.png)

5. If the pipeline `Succeeded`, click on the pipeline run which will open the pipeline activity list. Hover over the notebook activity and click on the glasses icon. This will open the notebook snapshot

![Pipeline Complete](/docs/res/OFPiplineSucceded.png)

6. Scroll down to the bottom of the notebook until you see a table similar to the below

![Forecast Results](/docs/res/OFFullPullForecastResults.png)

We can now use the following formula to work out the MGDC cost of a full pull

$$
\text{Cost} = \frac{\text{Sites} + \text{Permissions} + \text{Groups}}{1000} \times 0.75
$$

## Forecast for Delta Pull

Great you are now ready to execute the pipeline to obtain a delta forecast. To obtain a delta pull we need to provide a different start and end date.

1. Navigate to the Integrate Menu and select the `Sites_Permissions_SPGroups_Top1` pipeline. Click `Add Trigger` > `Trigger now`

![Trigger Pipeline](/docs/res/TriggerOFPipeline.png)

2. Populate parameters and click `OK`. Notice that the dates are 7 days apart. This timescale should be ajusted for the expected cadence. i.e. if running bi-weekly then get a delta forecast for a 14 day period.

![Populate Full Pull Parameters](/docs/res/OFDeltaPullTrigger.png)

3. Navigate to the Monitor tab to see the execution details. Wait for the pipeline to `Complete`. Typically this will be 25 minutes.

![Monitor](/docs/res/OFPipelineExecution.png)

4. Once complete we can check the details extracted in the notebook - If you're pipeline failed then please check the [Troubleshooting Section](/docs/Troubleshooting.md)

![Pipeline Complete](/docs/res/OFPipelineComplete.png)

5. If the pipeline `Succeeded`, click on the pipeline run which will open the pipeline activity list. Hover over the notebook activity and click on the glasses icon. This will open the notebook snapshot

![Pipeline Complete](/docs/res/OFPiplineSucceded.png)

6. Scroll down to the bottom of the notebook until you see a table similar to the below

![Forecast Results](/docs/res/OFDeltaPullForecastResults.png)

We can now use the following formula to work out the ongoing monthly MGDC, the below example assumes weekly MGDC delta snapshots. Remember that the delta may fluctuate each week based on user activity

$$
\text{Monthly Cost} = \frac{\text{Sites} + \text{Permissions} + \text{Groups}}{1000} \times 4 \times 0.75
$$





