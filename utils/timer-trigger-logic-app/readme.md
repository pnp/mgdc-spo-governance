# Timer-Trigger-Logic App Deployment

Logic App workflows are a great way to provide automation scenarios, and
in the case of calling Synapse Pipelines it's very easy. Due to the
nature of the data in MGDC, we need to call the pipeline with a specific
set of dates. If the provided dates are the same, then a full pull is
initiated. If the dates are different, a delta pull is initiated. The
below example will walk through the configuration of a workflow that
does a delta pull once a month.

## Create Logic App to call Pipeline Trigger

### Create a new Logic App

| Header 1 | Header 2 | Header 3 |
|----------|----------|----------|
| Row 1    | This content<br>spans two lines | Data |
| Row 2    | Single line | Data |

| 1.  Create a new Logic App | Name it what you'd like, for example: <br/> *MGDCSPOKickoffSynapsePipeline*|

### Trigger to Run

+------------------------------+----------------------------------------------------+
| 1.  Select **Add a Trigger** | ![](media/image1.png){width="2.1148786089238847in" |
|                              | height="0.46881561679790024in"}                    |
+==============================+====================================================+
| 2.  Type *recurrence* into   | ![](media/image2.png){width="2.97in"               |
|     the **search** field and | height="1.47in"}                                   |
|     select **Recurrence** in |                                                    |
|     the Schedule connector   |                                                    |
+------------------------------+----------------------------------------------------+
| 3.  Set the **Interval** to  | ![](media/image3.png){width="2.85in"               |
|     *1*                      | height="0.53in"}                                   |
+------------------------------+----------------------------------------------------+
| 4.  Set the **Frequency** to | ![](media/image4.png){width="3.06292760279965in"   |
|     *Month*                  | height="0.5834142607174103in"}                     |
+------------------------------+----------------------------------------------------+
| 5.  Set the **Time Zone** to | ![](media/image5.png){width="3.11in"               |
|     (UTC-05:00) Eastern Time | height="0.27in"}                                   |
|     (US & Canada)            |                                                    |
|                              | Or whichever time zone makes sense for you         |
+------------------------------+----------------------------------------------------+
| 6.  Set the **Start Time**   | ![](media/image6.png){width="3.01in"               |
|     to                       | height="0.26in"}                                   |
|                              |                                                    |
|                              | Choose the 5^th^ of the month, due to the date     |
|                              | restrictions of MGDC needing the range to be at    |
|                              | least 2 days prior                                 |
+------------------------------+----------------------------------------------------+
| 7.  Rename the action to:    | *Recurrence - Monthly*                             |
+------------------------------+----------------------------------------------------+

### Add an Action for the Date Last Month -- Compose / Data Operations

+-----------------------------+---------------------------------------------------+
| 1.  Add an Action 🡪 Data    | ![](media/image7.png){width="3.0in"               |
|     Operations 🡪 Compose    | height="1.52in"}                                  |
+=============================+===================================================+
| 2.  Use the following       | *addToTime(utcNow(),-1,\'month\',\'yyyy-MM-dd\')* |
|     formula to get the last |                                                   |
|     month's date            |                                                   |
+-----------------------------+---------------------------------------------------+
| 3.  Rename the action to:   | *Compose Last Month Date*                         |
+-----------------------------+---------------------------------------------------+
| 4.  Save the Logic App      |                                                   |
+-----------------------------+---------------------------------------------------+

5.  Add an Action for the Start of Last Month

+-----------------------------+-----------------------------------------------------------+
| 1.  Add an Action 🡪 Data    | ![A screenshot of a computer AI-generated content may be  |
|     Operations 🡪 Compose    | incorrect.](media/image7.png){width="3.0in"               |
|                             | height="1.52in"}                                          |
+=============================+===========================================================+
| 2.  Use the following       | *startOfMonth(outputs*                                    |
|     formula to get the      |                                                           |
|     start of last month's   | *(\'Compose_Last_Month_Date\'),\'yyyy-MM-ddTHH:mm:ssZ\')* |
|     date/time               |                                                           |
+-----------------------------+-----------------------------------------------------------+
| 3.  Rename the action to:   | *Compose Start of Last Month*                             |
+-----------------------------+-----------------------------------------------------------+
| 4.  Save the Logic App      |                                                           |
+-----------------------------+-----------------------------------------------------------+

6.  Add an Action for the End of Last Month

+-----------------------------+-------------------------------------------------------+
| 1.  Add an Action 🡪 Data    | ![A screenshot of a computer AI-generated content may |
|     Operations 🡪 Compose    | be incorrect.](media/image7.png){width="3.0in"        |
|                             | height="1.52in"}                                      |
+=============================+=======================================================+
| 2.  Use the following       | *formatDateTime(subtractFromTime*                     |
|     formula to get the end  |                                                       |
|     of last month's         | *(startOfMonth(addToTime(outputs*                     |
|     date/time               |                                                       |
|                             | *(\'Compose_Last_Month_Date\')*                       |
|                             |                                                       |
|                             | *,1,\'month\')),1,\'day\'),\'yyyy-MM-ddTHH:mm:ssZ\')* |
+-----------------------------+-------------------------------------------------------+
| 3.  Rename the action to:   | *Compose End of Last Month*                           |
+-----------------------------+-------------------------------------------------------+
| 4.  Save the Logic App      |                                                       |
+-----------------------------+-------------------------------------------------------+

7.  Add an Action to call the Synapse Pipeline Endpoint for Storage

+----------------------------------------+---------------------------------------+
| 1.  Add an Action 🡪 HTTP 🡪 HTTP        | ![](media/image8.png){width="3.01in"  |
|                                        | height="1.54in"}                      |
+========================================+=======================================+
| 2.  For the **URI**, use the following | *https://*                            |
|     format, making sure to account for |                                       |
|     your Synapse Workspace name and    | *{workspace                           |
|     Pipeline name                      | name}.dev.azuresynapse.net/*          |
|                                        |                                       |
|                                        | *pipelines/{pipeline name}/*          |
|                                        |                                       |
|                                        | *createRun?api-version=2020-12-01*    |
+----------------------------------------+---------------------------------------+
| 3.  For the **Method**, select *POST*  |                                       |
+----------------------------------------+---------------------------------------+
| 4.  For the first **Header key**,      | *Content-Type*                        |
|     enter                              |                                       |
+----------------------------------------+---------------------------------------+
| 5.  For the first **Header value**,    | *application/json*                    |
|     enter                              |                                       |
+----------------------------------------+---------------------------------------+
| 6.  For the **Body** field, add the    | *{\                                   |
|     following JSON structure, noting   | \"StartTime\": \"{output from Compose |
|     the relevant dates from prior      | Start of Last Month}\",\              |
|     actions and the StorageAccountName | \"EndTime\": \"{output from Compose   |
|     and StorageContainerName           | End of Last Month}\",\                |
|                                        | \"StorageAccountName\": \"{Storage    |
|                                        | Account Name}\",\                     |
|                                        | \"StorageContainerName\": \"{Storage  |
|                                        | Container Name}\"\                    |
|                                        | }*                                    |
+----------------------------------------+---------------------------------------+
| 7.  For the **Advanced Parameters**,   | ![](media/image9.png){width="2.39in"  |
|     select *Authentication*            | height="0.44in"}                      |
+----------------------------------------+---------------------------------------+
| 8.  For the **Authentication** section | ![](media/image10.png){width="2.89in" |
|     that appears, value the following: | height="1.42in"}                      |
|                                        |                                       |
|     a.  **Authentication Type** =      |                                       |
|         *Managed Identity*             |                                       |
|                                        |                                       |
|     b.  **Managed Identity** =         |                                       |
|         *System-assigned managed       |                                       |
|         identity*                      |                                       |
|                                        |                                       |
|     c.  **Audience** =                 |                                       |
|         *https://dev.azuresynapse.net* |                                       |
+----------------------------------------+---------------------------------------+
| 9.  Rename the action to:              | *HTTP -- Call Storage Synapse         |
|                                        | Pipeline*                             |
+----------------------------------------+---------------------------------------+
| 10. Save the Logic App                 |                                       |
+----------------------------------------+---------------------------------------+

8.  Add an Action to call the Synapse Pipeline Endpoint for Oversharing

+----------------------------------------+-----------------------------------------------+
| 1.  Add an Action 🡪 HTTP 🡪 HTTP        | ![A screenshot of a computer AI-generated     |
|                                        | content may be                                |
|                                        | incorrect.](media/image8.png){width="3.01in"  |
|                                        | height="1.54in"}                              |
+========================================+===============================================+
| 2.  For the **URI**, use the following | *https://*                                    |
|     format, making sure to account for |                                               |
|     your Synapse Workspace name and    | *{workspace name}.dev.azuresynapse.net/*      |
|     Pipeline name                      |                                               |
|                                        | *pipelines/{pipeline name}/*                  |
|                                        |                                               |
|                                        | *createRun?api-version=2020-12-01*            |
+----------------------------------------+-----------------------------------------------+
| 3.  For the **Method**, select *POST*  |                                               |
+----------------------------------------+-----------------------------------------------+
| 4.  For the first **Header key**,      | *Content-Type*                                |
|     enter                              |                                               |
+----------------------------------------+-----------------------------------------------+
| 5.  For the first **Header value**,    | *application/json*                            |
|     enter                              |                                               |
+----------------------------------------+-----------------------------------------------+
| 6.  For the **Body** field, add the    | *{\                                           |
|     following JSON structure, noting   | \"StartTime\": \"{output from Compose Start   |
|     the relevant dates from prior      | of Last Month}\",\                            |
|     actions and the StorageAccountName | \"EndTime\": \"{output from Compose End of    |
|     and StorageContainerName           | Last Month}\",\                               |
|                                        | \"StorageAccountName\": \"{Storage Account    |
|                                        | Name}\",\                                     |
|                                        | \"StorageContainerName\": \"{Storage          |
|                                        | Container Name}\"\                            |
|                                        | }*                                            |
+----------------------------------------+-----------------------------------------------+
| 7.  For the **Advanced Parameters**,   | ![A white rectangular object with black lines |
|     select *Authentication*            | AI-generated content may be                   |
|                                        | incorrect.](media/image9.png){width="2.39in"  |
|                                        | height="0.44in"}                              |
+----------------------------------------+-----------------------------------------------+
| 8.  For the **Authentication** section | ![A screenshot of a computer AI-generated     |
|     that appears, value the following: | content may be                                |
|                                        | incorrect.](media/image10.png){width="2.89in" |
|     a.  **Authentication Type** =      | height="1.42in"}                              |
|         *Managed Identity*             |                                               |
|                                        |                                               |
|     b.  **Managed Identity** =         |                                               |
|         *System-assigned managed       |                                               |
|         identity*                      |                                               |
|                                        |                                               |
|     c.  **Audience** =                 |                                               |
|         *https://dev.azuresynapse.net* |                                               |
+----------------------------------------+-----------------------------------------------+
| 9.  Rename the action to:              | *HTTP -- Call Oversharing Synapse Pipeline*   |
+----------------------------------------+-----------------------------------------------+
| 10. Save the Logic App                 |                                               |
+----------------------------------------+-----------------------------------------------+

9.  Set Up the System Managed Identity for the Logic App

+-----------------------------+----------------------------------------+
| 1.  From the **Overview**   |                                        |
|     page of the Logic App,  |                                        |
|     select *Settings* 🡪     |                                        |
|     *Identity*              |                                        |
+=============================+========================================+
| 2.  Set the **Status** to   | ![](media/image11.png){width="0.76in"  |
|     *On*                    | height="0.27in"}                       |
+-----------------------------+----------------------------------------+
| 3.  Note the                | ![](media/image12.png){width="2.2in"   |
|     Object/Principal Id     | height="0.29in"}                       |
+-----------------------------+----------------------------------------+
| 4.  Save the Identity       |                                        |
|     settings                |                                        |
+-----------------------------+----------------------------------------+

10. Give the Logic App Access to the Synapse Workspace

+---------------------------------------------------------+----------------------------------------+
| 1.  From the **Overview** page of the of the Synapse    | ![](media/image13.png){width="1.63in"  |
|     Workspace, open Synapse Studio                      | height="0.75in"}                       |
+=========================================================+========================================+
| 2.  Select                                              |                                        |
|     ![](media/image14.png){width="0.3020833333333333in" |                                        |
|     height="0.2604166666666667in"}**Manage** 🡪 **Access |                                        |
|     Control (Security)**                                |                                        |
+---------------------------------------------------------+----------------------------------------+
| 3.  From the **displayed Access Control** page, select  |                                        |
|     **+Add**                                            |                                        |
+---------------------------------------------------------+----------------------------------------+
| 4.  In the resultant **Add Role Assignment** pane       | ![](media/image15.png){width="3.08in"  |
|                                                         | height="1.95in"}                       |
|     a.  **Scope** = *Workspace*                         |                                        |
|                                                         |                                        |
|     b.  **Role** = *Synapse Credential User*            |                                        |
|                                                         |                                        |
|     c.  **Select User**: *Name of your Logic App*       |                                        |
+---------------------------------------------------------+----------------------------------------+
| 5.  Select **Apply**                                    |                                        |
+---------------------------------------------------------+----------------------------------------+
| 6.  The following should appear in the **Access         | ![](media/image16.png){width="2.99in"  |
|     Control** list                                      | height="0.2in"}                        |
+---------------------------------------------------------+----------------------------------------+
