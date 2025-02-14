# Trigger via Logic App
*work in progress...*
Leveraging an Azure Logic App is one way to provide an automated scenario to schedule and call a pipeline.  Given that Azure Synapse has REST endpoints, we can easily create a scheduled process. With the current setup we can perform full pulls, or delta pulls, from MGDC.  The walkthrough below will result in the creation of a logic app that will run on a once-a-month schedule, and perform a delta pull.
## Create a Logic App to Call Pipeline Trigger
### 1. Create a Logic App to the Pipeline Trigger
| 1. Create a new [Azure Logic App](https://learn.microsoft.com/en-us/azure/logic-apps/logic-apps-overview) | Name it what you’d like, for example: *MGDCSPOKickoffSynapsePipeline* |
|-----|-----|
### 2. Create a Trigger to Kick Off the Workflow
| 1. Select Add a Trigger |![alt](../docs/res/LogicApp1.png)|
|-----|-----|