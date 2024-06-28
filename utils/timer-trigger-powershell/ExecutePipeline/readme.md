# TimerTrigger - PowerShell

The `TimerTrigger` makes it incredibly easy to have your functions executed on a schedule. This sample demonstrates a simple use case of calling your function every 5 minutes.

## How it works

For a `TimerTrigger` to work, you provide a schedule in the form of a [cron expression](https://en.wikipedia.org/wiki/Cron#CRON_expression)(See the link for full details). A cron expression is a string with 6 separate expressions which represent a given schedule via patterns. The pattern we use to represent every 5 minutes is `0 */5 * * * *`. This, in plain text, means: "When seconds is equal to 0, minutes is divisible by 5, for any hour, day of the month, month, day of the week, or year".

## Auth

To run this locally you will need an app registration that has Synapse Admin on the workspace. You will also need to populate the local.settings.json file with the following three environment variables

```json
"AZURE_CLIENT_ID": "95f40c8c-6311-484b-b6a8-9ddd71f2ed12",
"AZURE_CLIENT_SECRET": "OK",
"AZURE_TENANT_ID": "f4b2a7fc-780d-4ba9-b9ed-c49cc068365f",
```

For production, simply enable a managed identity for the function. Now provide the functions identity Synapse admin on the workspace. Ensure that the above auth variables are not added to prod


## Variables

As well as the above auth variables, the following synapse config details are required. These

```json
"WORKSPACE_NAME": "ag-mgdc-syanpse",
"PIPELINE_NAME": "Sites_Permissions_SPGroups_Top1",
```

The following pipeline variables are required, this is what will be passed to the pipeline as parameters

```json
"STORAGE_CONTAINER_NAME": "forecast",
"STORAGE_ACCOUNT_NAME": "agmgdcstorage",
```

Finally the delta days variable is used by the function to build the start data. End date is hardcoded as 3 days before execution day. Start date is this end date - the delta days. This should align with the functions schedule

``` json
"DELTA_DAYS": "7"
```



