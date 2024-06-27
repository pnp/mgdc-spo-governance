# Input bindings are passed in via param block.
param($Timer)

# Get the current universal time in the default string format
$currentUTCtime = (Get-Date).ToUniversalTime()

# The 'IsPastDue' porperty is 'true' when the current function invocation is later than scheduled.
if ($Timer.IsPastDue) {
    Write-Host "PowerShell timer is running late!"
}

# Write an information log with the current time.
Write-Host "PowerShell timer trigger function ran! TIME: $currentUTCtime"

## Read envrioment varaibles
# $clientId = $env:AZURE_CLIENT_ID
# $tenantId = $env:AZURE_TENANT_ID
# $clientSecret = $env:AZURE_CLIENT_SECRET
$workspaceName = $env:WORKSPACE_NAME
$pipelineName = $env:PIPELINE_NAME
$storageContainerName = $env:STORAGE_CONTAINER_NAME
$storageAccountName = $env:STORAGE_ACCOUNT_NAME
$deltaDays = $env:DELTA_DAYS

## Workout start and end time (endtime is 3 days before now at 00:00) - (starttime is $deltaDays days before endtime at 00:00)
$endTime = (Get-Date).AddDays(-3).ToString("yyyy-MM-ddT00:00:00Z")
$startTime = (Get-Date).AddDays(-3).AddDays(-$deltaDays).ToString("yyyy-MM-ddT00:00:00Z")

## Build the URL
$apiVersion = "2020-12-01";
$url = "https://$($workspaceName).dev.azuresynapse.net/pipelines/$($pipelineName)/createRun/?api-version=$($apiVersion)";

# Check if running locally
if ($env:AZURE_CLIENT_ID -and $env:AZURE_TENANT_ID -and $env:AZURE_CLIENT_SECRET) {
    # Authenticate using service principal for local testing
    $AzureContext = Connect-AzAccount -ServicePrincipal -Credential (New-Object System.Management.Automation.PSCredential($env:AZURE_CLIENT_ID, ($env:AZURE_CLIENT_SECRET | ConvertTo-SecureString -AsPlainText -Force))) -Tenant $env:AZURE_TENANT_ID
} else {
    # Assume managed identity when running in Azure
    $AzureContext = Connect-AzAccount -Identity
}

# Define the scope for Azure Synapse
$scope = "https://dev.azuresynapse.net"

# Get the access token for Azure Synapse
$accessToken = (Get-AzAccessToken -ResourceUrl $scope).Token

# Prepare the HTTP request headers with the access token
$headers = @{
    Authorization = "Bearer $accessToken"
}

# Create the payload
$payload = @{
    startTime = $startTime
    endTime = $endTime
    storageAccountName = $storageAccountName
    storageContainerName = $storageContainerName
}

# convert to JSON
$json = $payload | ConvertTo-Json

# Use Invoke-RestMethod for the POST request
try {
    $response = Invoke-RestMethod -Uri $url -Method Post -Body $json -ContentType "application/json" -Headers $headers

    # If the request is successful, log and return the run ID
    $runId = $response.runId
    Write-Host "Pipeline run ID: $runId"
}
catch {
    # If the request fails, log the error
    Write-Error "Failed to start pipeline: $_.Exception.Response.StatusCode.Value__"
}