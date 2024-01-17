# mgdc-spo-governance
Use the MGDC datasets to enable SharePoint admins / service owners to make data driven decisions around general SPO governance

### **Introduction**

Microsoft Graph Data Connect (MGDC) allows developers to extract data from Microsoft 365 for use in other applications. This guide will walk you through the process of setting up MGDC and running your first data extraction.

### **Prerequisites**

Before you begin, you’ll need:

1. An Office 365 tenant with administrative access.
2. An Azure subscription linked to the above tenant. 
3. Access to Azure Synapse Studio

### **Step 1: Enable MGDC in M365 tenant**

First step, we need to enable MGDC in our tenant. 

1. Navigate to the Admin Centre portal.
2. Open Settings > Org Settings > Services Tab
3. Scroll down and look for Microsoft Graph Data Connect. Or click [here](https://admin.microsoft.com/#/Settings/Services/:/Settings/L1/O365DataPlan)
4. Check "Turn on Microsoft Graph Data Connect on..." Also enable SPO and OneDrive Datasets. 
5. Click Save!

> [!NOTE]  
> After enabling it can take upto a few days for the datasets to be avalible in MGDC
### **Step 2: Set up the Apps 

We will need to create an app registration in Entra. This app registration will be tied to an MGDC app (created in the Azure subscription). This is how the billing and authorization / permissions work.

#### 2.1 Create an App Registration in Entra

1. Navigate to the Azure Portal
2. Click on Microsoft Entra Id
3. Click Add > App Registration. Give this a name. Something like MGDC-oversharing. 
4. Click Register!

> [!NOTE]  
> We will need to come back and generate a secret but let's not do that yet.

#### 2.2 Create a Resource Group and Storage Account
We need a resource group for the MGDC app and a storage account. We will also grant the App Id above a role on our storage account so that it has permission to copy the MGDC data to it.

Resource Group
1. Azure Portal > Resource Groups
2. Create +
3. Give it a name and region. Choose the same region as your M365 tenant
4. Create! 

> [!IMPORTANT]  
> The region must match your tenant otherwise MGDC will fail to copy the data. The error message won't indicate that you are in the wrong region. But if the copy is taking longer than 30 minutes you can be pretty confident you are in the wrong region

Storage Account
1. Azure Portal > Storage Accounts
2. Create + 
3. Choose the resource group just created
4. Give it a name and let it inherit the same region
5. Leave everything else default and go to the Advanced tab
6. Check Enable hierarchical namespace. Leave everything else
7. Review > Create!

Storage Account Access Policy
1. From the newly created storage account go to IAM blade
2. Click + Add > Role Assignment on the IAM menu
3. Search for "Storage Blob Data Contributor".
4. Select the role and click Next
5. Click on add members and search your app reg you created in Step 2.1
6. Select the app and click Review + assign
7. You should see an Azure notification for the role being successfully assigned

Create a Container
1. Now click on the Container blade
2. In the container menu slick + Container and give it the name sites

> [!Info]  
> This is where the raw data from MGDC will end up!
#### 2.3 Create an MGDC App in Azure Subscription

1. Go back to the Azure Portal
2. Search for "MGDC". You should see "Microsoft Graph Data Connect" listed as a service in your search results
3. Click Add. 
4. Fill out the instance details: 
	**App Id:** Select the App Id you just created.
	**Description:** Oversharing Dashboard 
	**Publish Type:** Single-Tenant
	**Compute Type:** Azure Synapse
	**Activity Type:** Copy Activity
5. Fill out the project details:
	Select your Sub, if using my tenant go for "Microsoft Azure Sponsorship 2"
	**Resource Group**: Use the one you just created.
	**Destination Type:** Azure Storage Account
	**Storage Account:** Use the one you just created.
	**Storage Account Uri**: Select the uri with .dfs from the dropdown
6. Click Next: Datasets!
7. Datasets, select the following two datasets. For columns choose All
	BasicDataSet_v0.SharePointSites_v1
	BasicDataSet_v0.SharePointPermissions_v1
	BasicDataSet_v0.SharePointGroups_v1
8. Review + Create!

> [!NOTE]  
> You can update the datasets that your app will request access to at any time. It's worth having a browse of the datasets to see if there is anything you think could be useful!

### **Step 3: Approve the MGDC app in Admin Centre**

1. Navigate back to M365 Admin Centre
2. Open Settings > Org Settings > Security & privacy Tab
3. Click MGDC apps or use this [link](https://admin.microsoft.com/#/Settings/MGDCAdminCenter)
4. You should see your app listed here with status "Pending Approval"
5. Click the app and follow the approval workflow

> [!Oops]  
> You will need to login with another admin account to approve the app! If you are in mine or Pete's tenant then ask us to go in and approve for you!
### **Step 4: Importing the Synapse Pipeline

Next, we will import a pipeline in Azure Synapse. The is a preconfigured pipeline that contains the configuration to pull the three dataset and a notebook to handle delta pulls.

 If you don't have a Synapse Analytics Workspace then please create one following the steps below. If you already do have one then please skip ahead to step 4.1
#### 4.1 Create a Synapse Analytics Workspace

1. Go back to the Azure Portal
2. Search for "synapse". You should see "Azure Synapse Analytics" listed as a service in your search results
3. Click Create +
4. Choose the Resource group created earlier
5. Leave managed resource group blank
6. Give your workspace a name and leave the region (pre populated from your resource group)
7. Choose the storage account created earlier as your Data Lake Storage
8. Create a new file system name, called `synapse-analytics`. This creates a container in the storage account that is used by the workspace to hold app and config files.
9. Review + Create

#### 4.2 Create an Apache Synapse Spark Pool

The spark pool is need to execute the notebook included in the pipeline.

 If you don't have an Apache Spark pool associated with  your Analytics Workspace then please create one following the steps below. If you already do have one then please skip ahead to step 4.3

1. Open your newly created Synapse Analytics Workspace
2. Click `+ New Apache Spark pool` button
	**Name**: sparkpoolag
    Node size: Small
    Autoscale: Enabled
4. Review + Create
5. Create
#### 4.3 Import Pipeline

Before proceeding, please download the pipeline template [Sites_Permissions_Groups.zip](oversharing/Sites_Permissions_Groups.zip) from the repo.

Now click on your Synapse Analytics Workspace and Open Synapse Studio.

1. Open the Integrate Menu from the left rail
2. Click on the add new resources button (+) and choose `Import from pipeline teamplte`
3. Browse to downloaded pipeline template and click Open. This will open pipeline preview page
4. If you already have an M365 linked service then select it from first drop down. If not, in the first Linked service drop down click "+ New"
    **Name**: Microsoft365
    **Service Principal Id**: app id from earlier (Entra app registration not MGDC app)
    **Service Principal Key**: Create a secret for the app reg (in Entra) and enter it here
7. Test Connection - Hopefully this works!
8. Click create. 
9. Now in the second linked service drown (datalake), dot not select the default. This will not work, click "+ New" and create a new linked service
    **Name**: AzureDataLakeStorage
    **Authentication type**: Service Principal
    **Account selection method**: From Azure Sub
    **Storage Account**: From earlier
    **Authentication**: 
		**Tenant**: Your tenant Id
		**Service Principal Id**: App reg from earlier
		**Cred Type:** Key
		**Service Principal Key**: You can use the same secret, but if you haven't saved that. Good on you, go and get another! Or user Windows Key + V to access your clipboard history 😎
10. Test Connection - Hopefully this works, if not give me a shout!
11. Click create. You should now be able to click the `Open pipeline` button
12. This will open the Pipeline, before publishing. Open up the notebook from the Develop tab. If you see a warning banner relating to a missing configured spark pool. Please select your newly created spark pool from the dropdown
13. Now, your last step is to `Publish all`. This will save the imported Pipeline to your Synapse Workspace.

 >[!Note]  
> If you get a publishing error, ensure you have opened up the notebook and selected the spark pool associated with your workspace

### **Step 5: Execute the Pipeline

Now that we have everything set up we can perform a full pull of the datasets.

#### 5.1 Perform a Full Pull

1. Click `Add trigger` > `Trigger now` in the top banner of the open Pipeline
2. Fill out the flyout menu to match your environment
3. You may need to go and create a container in your storage account
    **StartTime**: 2024-01-01T00:00:00Z
    **EndTime**: 2024-01-01T00:00:00Z
    **StorageAccountName**: From earlier
    **StorageContainerName**: From just now
    **SparkPoolName**: From very recently
    **RetainForHistoricTrending**: true

4. Once the parameter values has been entered click OK

>[!Note]  
> An equal start and end date indicates to MGDC that we are performing a full pull. If you have only just enable MGDC you may need to wait a few days before you can pull the data

5. You can now go to the monitor tab and view the progress of the pipeline run 

#### 5.2 Check the datalake

Navigate to your storage account in the Azure portal. Click on the container blade and open the container you inputted for the StorageContainerName parameter in the previous step

There should be three folders in the root

**archive** - this holds a copy of the latest that is used for merging with deltas in future runs. It also optionally contains a copy of all processed data. The ReatinForHistoricTrending parameter

```
/ archive / latest / permissions / *.json
/ archive / latest / datasetname / *.json

Optional
/ archive / permissions / 2024 / 01 / 01 / 13ff9026-d8e7-452d-8369-675ad3793842 / *.json
/ archive / datasetname / YYYY / MM / DD / RunId / *.json
```

**latest** - this hold the latest version of the processed dataset. PowerBI is hooked up to this folder

```
/ latest / permissions / *.json
/ latest / datasetname / *.json
```

**raw** - this holds all the data that is pulled from MGDC it it's unprocessed form.


```
/ raw / permissions / 2024 / 01 / 01 / 13ff9026-d8e7-452d-8369-675ad3793842 / *.json
/ raw / datasetname / YYYY / MM / DD / RunId / *.json
```

>[!Note]  
> The dates we use in the folder hierarchy is from the end date parameter. 
#### 5.3 Perform a Delta Pull

Now we have a pull in our storage account we can perform a delta pull to request any updated objects from MGDC.

1.  Click `Add trigger` > `Trigger now` in the top banner of the open Pipeline
2. Fill out the flyout menu to match your environment
    **StartTime**: 2024-01-01T00:00:00Z
    **EndTime**: 2024-01-10T00:00:00Z
    **StorageAccountName**: From earlier
    **StorageContainerName**: From just now
    **SparkPoolName**: From very recently
    **RetainForHistoricTrending**: true

>[!Note]  
> A different start and end date indicates to MGDC that we are performing a delta pull. For delta pulls you want your start date to be the end date of your last pull

3. You can now go to the monitor tab and view the progress of the pipeline run 

### Troubleshooting

If you see the an error when the pipeline attempts to execute the runbook. Something similar to the following:

```
errorCode": "6002", "message": "java.nio.file.AccessDeniedException: Operation failed: \"This request is not authorized to perform this operation using this permission.\
```

This will be because the workspace does not have `Storage Blob Data Contributor` role to the storage account. This is unlikely to happen, unless you reuse and existing storage account.
