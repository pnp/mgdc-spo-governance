# SPO Governance with MGDC

## The Problem
M365 service owners and SharePoint admins require enhanced analytics and insights to understand how their organisations utilise SharePoint and the wider M365 ecosystem. Two key areas that are of focus are understanding oversharing (both internal and external) and storage utlisation. These two activities are possible with traditional technologies, PowerShell, Graph, CSOM but to get item level detail required robust code to handle throttling and can take a long time to perform

## The Solution
 As tenants grow larger the way we manage them must change too. There is huge amount of coloration data and insights in the tenant but extracting this data and obtaining the insight has been a challenge. MGDC addresses this challenge. Microsoft Graph Data Connect (MGDC) for SharePoint provides rich datasets directly to a an Azure subscription. From here, anything is possible, you can then create custom applications, reports, and dashboards using tools like Azure Synapse and Power BI.

- **Enterprise Focus:** Emphasizes security and compliance for enterprise customers.
- **Comprehensive Data Stories:** Data is persisted, enabling future analysis without the need for point-in-time scripted snapshots. A data warehouse approach
- **Target Audience:** Designed for data professionals who will build with these datasets.
- **Scalability:** Handles large-scale data (billions of rows). No throttling!


## In this Repo

There are two core solutions in this repo, these solution are Azure Synapse pipeline templates that can be used to extract the required datasets using MGDC for SharePoint to support the oversharing and storage capacity scenarios. These pipeline handle the extraction of SPO data from MGDC into a Azure Data Lake storage account, the pipelines handle "deltas" to help promote that adoption MGDC is not a one time activity. This should be something that is scheduled to run either weekly or bi weekly to ensure the datasets can be used to support on going governance of SPO.

The following two lists detail some of the insights that that can be obtained using the MGDC datasets for SharePoint

### Insights on Storage Capacity

- **Largest SharePoint Sites:** Identify which SharePoint sites consume the most storage.
- **Storage Usage by Site Type:** Determine which types of sites (e.g., team sites, communication sites) use the most storage.
- **Current Storage for Sensitive Sites:** Assess the current storage allocation for sites marked as sensitive.
- **Storage Usage by File Versioning:** Calculate how much storage is occupied by previous versions of files across all sites.
- **Recent Site Updates:** Identify which sites have been updated in the last few months.
- **Sites with Single Ownership:** Find sites that currently have only one owner assigned.
- **Sites Created Over Two Years Ago:** Count the number of sites that were created more than two years ago.
- **Inactive Sites:** Determine how many sites have not been updated or changed in the last year.
- **Large Sites:** Identify sites that have more than 1TB of files.
- **File Types with Highest Storage Footprint:** Analyze which file types (e.g., documents, images, videos) contribute the most to the overall storage footprint across SPO.
- **Largest Individual Files:** Identify the largest individual files stored across all sites.
- **Files with the Most Versions:** Find files that have the highest number of versions.
- **Files Not Accessed in Over a Year:** Identify files that have not been accessed in over a year.
- **Duplicate Files:** Detect and quantify duplicate files across all sites to optimize storage usage.

### Insights on Oversharing

- **Detection of Oversharing:** Find instances where the Everyone Except External User claim has been used across SPO, at item level
- **Find Overshared Sites / Teams:** Identity "public" sites with the Everyone Except External User claim in group membership
- **External Sharing Activity:** Identify if external sharing is happening.
- **Sensitive Data Sharing:** Assess if sensitive data is being shared.
- **Sharing Volume by Sensitivity Label:** Quantify sharing activity per sensitivity label.
- **Sensitive Data with External Users:** Evaluate if sensitive data is being shared with external users.
- **External Domains for Sharing:** Identify which external domains are being shared with.
- **Most Shared Sites:** Determine which sites have been shared the most.
- **Roles and Levels of Sharing:** Analyze the roles and levels of sharing being utilized.
- **User Permissions:** Identify the permissions assigned to specific users.
- **Most Shared File Extensions:** Determine which file extensions are most frequently shared.
- **Sharing at Different Levels:** Assess the volume of sharing at the web, folder, list, or file level.


## Getting Started

If you are new to MGDC for SharePoint I would suggest following this [guide](https://techcommunity.microsoft.com/t5/microsoft-graph-data-connect-for/step-by-step-gather-a-detailed-dataset-on-sharepoint-sites-using/ba-p/4070563) written by Jose Barreto. This will help you to get all the prerequisite M365 configuration switched on and Azure technology provisioned to allow you to execute your first MGDC data pull.

## Forecasting Cost

MGDC does have a cost. This is $0.75 per 1000 object for all SharePoint datasets except Files. The files dataset has a cost of $0.75 per 50000 objects, so 50x cheaper. It can be difficult to estimate costs for tenant. Total site objects is quite easy to obtain but other datasets are not. We have two pipelines that can be used to provide accurate forecasts without incurring MGDC costs.

* [Capacity Forecast](storage/forecast)
* [Oversharing Forecast](oversharing/forecast)


## Getting Insights

Now you have followed Jose's guide and are happy with your forecast it's time to deploy the pipelines and obtain the full datasets

* [Capacity Pipeline](storage)
* [Oversharing Pipeline](oversharing)


## Automating Pipeline Trigger

To really turn this into the all singing and dancing SharePoint data warehouse. We need to automate the execution of our pipeline. The following Azure function solutions can help you achieve this.

* [PowerShell Timer Trigger](utils/timer-trigger-powershell)
* [C# Timer Trigger](utils/timer-trigger-csharp)
* [C# Http Trigger](utils/http-trigger-csharp)


## Issues

Please report any issues by raising an [issue](https://github.com/pnp/mgdc-spo-governance/issues/new/choose).

## Contributing

We 💖 to accept contributions.

Check out our [Contribution guidelines](/CONTRIBUTING.md) for guidance on how to contribute. 

If you want to get involved with helping us enhance MGDC SPO Governance, whether that is suggesting or adding new functionality, updating our documentation or fixing bugs, we would love to hear from you.

## Special Thanks

Special thanks to those below who have helped build this awesome solution.

- [@groveale](https://github.com/groveale)
- Pete Williams

## Support

This solution is open-source and community provided with no active community providing support for it. This solution is maintained by both Microsoft employees and community contributors and is not a Microsoft provided solution so there is no SLA or direct support for this from Microsoft. Please report any issues by raising an [issue](https://github.com/pnp/mgdc-spo-governance/issues/new/choose).

## Microsoft 365 & Power Platform Community

MGDC SPO Governance is a Microsoft 365 & Power Platform Community (PnP) project. Microsoft 365 & Power Platform Community is a virtual team consisting of Microsoft employees and community members focused on helping the community make the best use of Microsoft products. MGDC SPO Governance is an open-source project not affiliated with Microsoft and not covered by Microsoft support. If you experience any issues using MGDC SPO Governance, please submit an issue in the [issues list](https://github.com/pnp/mgdc-spo-governance/issues).

## "Sharing is Caring"

![Parker PnP](./docs/res/parker-pnp.png)

## Disclaimer

**THIS CODE IS PROVIDED AS IS WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING ANY IMPLIED WARRANTIES OF FITNESS FOR A PARTICULAR PURPOSE, MERCHANTABILITY, OR NON-INFRINGEMENT.**

## Code of Conduct

This repository has adopted the Microsoft Open Source Code of Conduct. For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact opencode@microsoft.com with any additional questions or comments.


