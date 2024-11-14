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
$clientId = $env:AZURE_CLIENT_ID
$tenantId = $env:AZURE_TENANT_ID
$clientSecret = $env:AZURE_CLIENT_SECRET
$storageContainerName = $env:STORAGE_CONTAINER_NAME
$storageAccountName = $env:STORAGE_ACCOUNT_NAME

## NEW
$combinedFolderName = $env:COMBINED_FOLDER_NAME

# Check if running locally
if ($env:AZURE_CLIENT_ID -and $env:AZURE_TENANT_ID -and $env:AZURE_CLIENT_SECRET) {
    # Authenticate using service principal for local testing
    $AzureContext = Connect-AzAccount -ServicePrincipal -Credential (New-Object System.Management.Automation.PSCredential($env:AZURE_CLIENT_ID, ($env:AZURE_CLIENT_SECRET | ConvertTo-SecureString -AsPlainText -Force))) -Tenant $env:AZURE_TENANT_ID
    ## Set the current subscription
} else {
    # Assume managed identity when running in Azure
    $AzureContext = Connect-AzAccount -Identity
}

$storageContext = New-AzStorageContext -StorageAccountName $storageAccountName -UseConnectedAccount

# List and delete the blobs in the "combined" directory
$blobs = Get-AzStorageBlob -Container $storageContainerName -Blob "$combinedFolderName/*" -Context $storageContext

Write-Host "Found $($blobs.Count) blobs in the '$combinedFolderName' directory."

$blobs | Remove-AzStorageBlob