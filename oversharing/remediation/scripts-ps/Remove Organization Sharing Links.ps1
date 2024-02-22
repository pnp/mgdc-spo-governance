
#################################################
# Remove Organization Sharing Links.ps1
# Author: Pete Williams CSA Modern Work Microsoft
# Version: 1.0
# Date: 15th February 2024
#################################################

#################
# Script Overview 
#################

# This script is used to remove the organization sharing links from the files and folders in the SharePoint sites. 
# The script reads the input from a CSV file and then removes the sharing links from the files and folders in the SharePoint sites. 
# The script uses the PnP PowerShell cmdlets to connect to the SharePoint sites and remove the sharing links. 
# The script also outputs the results to a CSV file.

#################
# Prerequisites
#################

# This script requires version 3.0.1711.0 or higher due to the PNP Cmdlets used
# Install the latest version of the PnP PowerShell Cmdlets
# Install-module pnp.powershell

###########################
# App Registration Creation
###########################

# In order to avoid throttling issues and ensure that all the sites can be accessed without any authentication issues..
# It is recommended to run this script under the context of an app registration.
# Create a new Azure App Registration with the following permissions:
# Microsoft Graph API Permissions  - Sites.FullControl.All - remember to grant admin consent
# SharePoint API Permissions - Sites.FullControl.All - remember to grant admin consent

# Next you will need to create a self-signed certificate and upload it to the app registration
# $cert = New-PnPAzureCertificate -OutPfx "DefineYourPath\Cert\PnPCert.pfx" -OutCert "DefineYourPath\Cert\PnPCert.cer" -CertificatePassword (ConvertTo-SecureString -String "password" -AsPlainText -Force)

# After you have created the certificate, you will need to upload it to the app registration

# Once all this is in place you can update the variables below and run the script

# It is possible to run this script using the Connect-PnPOnline cmdlet with the -Credentials parameter
# However this is not recommended as it will require the user to authenticate to each site that the script connects to.
# The user will need to have the necessary permissions to access the sites and remove the permissions.
# This will cause the script to run slower and may cause issues with throttling.
# It is recommended to use an app registration to run this script.

# If you choose to run this script using the -Credentials parameter
# You will need to uncomment the line that sets the $creds variable (line 44)
# You will need to uncomment line 120
# You will need to comment out line 125

# $creds = Get-Credential

###############################################################################
# The following variables need to be updated with your app registration details
###############################################################################

#Provide the app registration ID (Application ID) (client ID), this is the ID of the app registration that you created in the Azure AD portal
$appId = "d72fdd41-8a4c-4805-b402-470aa637e2f1"

#Provide the tenant ID, this is the ID of the Azure AD tenant that you want to run the script against
$tenantId = "47814e7e-54bb-4192-98af-7949e514b0a8"

#Provide the path to the PFX certificate file
$pfxPath = "C:\Users\pwilli\OneDrive - Microsoft\Desktop\Cert\PnPCert.pfx"

#Provide the password to the PFX certificate file
$pfxPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force

#Provide the path to the CSV file that contains the organisation sharing links that you want to remove
$sharinglinkscsvpath = "C:\Users\pwilli\OneDrive - Microsoft\Desktop\MGDC\CSV\Organization Links.csv"

##############################################
# Tell the user what the script is going to do
##############################################

# Get the start time so that we can calculate the duration of the script
$startTime = Get-Date

# Tell the user that the execution of the script has started
Write-Host ""
write-host "Starting the Remove Organization Sharing Links Script" -ForegroundColor Cyan
Write-Host ""

# Get the current date and time, we will use this to create a unique file name for the output file
$timestamp = Get-Date -Format 'dddd dd MMMM - HHmmss'

# Define the output data array, we will use this to store success and failures of the operations before exporting the contents of this array to a CSV file
$outputData = @()

# Tell the user that the script has started and when it started
Write-Host "Script started at: $currentDateTime"

# Import the data from CSV file, this csv file contains the organisation sharing links that we want to remove
$links = Import-Csv -Path $sharinglinkscsvpath

# Count the number of items within the CSV file that have an item type of 'File', this tells us how many organisation sharing links we have to remove from files
$fileSharingLinks = ($links | Where-Object { $_.'ITEM TYPE' -eq 'File' }).Count

# Count the number of items within the CSV file that have an item type of 'Folder', this tells us how many organisation sharing links we have to remove from folders
$folderSharingLinks = ($links | Where-Object { $_.'ITEM TYPE' -eq 'Folder' }).Count

# Tell the user what was found in the CSV file and therefore what will be processed
Write-host ""
Write-Host -NoNewline "We found and will now attempt to work on "
Write-Host -NoNewline -ForegroundColor Green $fileSharingLinks
Write-Host -NoNewline " file(s) with organisation sharing links in the CSV file "
Write-Host ""
Write-Host -NoNewline "And we found and will now attempt to work on "
Write-Host -NoNewline -ForegroundColor Green $folderSharingLinks
Write-Host " folder(s) with organisation sharing links in the CSV file "
Write-Host ""

# Output the sharing links found in the CSV file in a formatted table so the user can see what will be processed
$links | Format-Table -Property Site, 'Item Type', 'Item URL', 'Link ID'
Write-Host ""

##############################################
# Start attempting to remove the sharing links 
##############################################

# Loop through each item in the CSV file
# For each item, connect to the site and remove the sharing link
foreach ($link in $links) {
    
    # Create separation between each item in the console by writing a line of dashes
    Write-Host ""
    Write-Host "-----------------------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host ""

    # Connect-PnPOnline -Url $link.'SITE URL' -Credentials $creds

    # Connect to the site using the app registration and the PFX certificate
    Connect-PnPOnline -Url $link.'SITE URL' -ClientId $appId -Tenant $tenantId -CertificatePath $pfxPath -CertificatePassword $pfxPassword
  
    # Tell the user that we are connecting to the site
    Write-Host $link.SITE
    Write-Host ""
    Write-Host -NoNewline "Connected to site: ".PadRight(25) -ForegroundColor Green
    Write-Host -NoNewline "$($link.'SITE URL')"
        
    Write-Host "" # Empty line for spacing
   
    # Tell the user that we are processing the item
    Write-Host ""
    Write-Host -NoNewline "Processing item: ".PadRight(25) -ForegroundColor Gray
    Write-Host "$($link.'ITEM URL')" -ForegroundColor Gray
    Write-Host "" # Empty line for spacing

    # Store the item URL and the link ID in variables
    # Chop up the item URL to get the file URL
    $itemurl = $link.'ITEM URL'
    $fileUrl = $itemUrl.Split('/', 3)[2]
    $linkID = $link.'LINK ID'

   # Check if the item is a file or a folder and remove the sharing link

   # If the item is a file, remove the sharing link
   if ($link.'ITEM TYPE' -eq 'File') {
    
    try {
        # Remove the sharing link from the file
        Remove-PnPFileSharingLink -FileUrl $fileUrl -Identity $linkID -Force

        # Tell the user that the sharing link was removed successfully
        write-host "Successfully Removed File Organisation Sharing Link" -ForegroundColor Green

        # Add the output to the output data array so that we can export it to a CSV file later
        $outputData += New-Object PSObject -Property @{
            'Site URL' = $link.'SITE URL'
            'Item URL' = $itemurl
            'Completed Action' = 'Removed File Organisation Sharing Link'
            'Status' = 'Success'
        }
    } 
    catch {

        # Tell the user that the sharing link was not removed successfully
        write-host "Failed to Remove the specified File Organisation Sharing Link" -ForegroundColor Red
        write-host "" 
        write-host $_.Exception.Message

        # Add the output to the output data array so that we can export it to a CSV file later
        $outputData += New-Object PSObject -Property @{
            'Site URL' = $link.'SITE URL'
            'Item URL' = $itemurl
            'Completed Action' = 'Failed to Remove the specified File Organisation Sharing Link'
            'Status' = 'Failed'
            'Error' = $_.Exception.Message
        }
    }
} 

# If the item is a folder, remove the sharing link
elseif 

($link.'ITEM TYPE' -eq 'Folder') {
   
    try {
        # Remove the sharing link from the folder
        Remove-PnPFolderSharingLink -Folder $fileUrl -Identity $linkID -Force

        # Tell the user that the sharing link was removed successfully
        write-host "Successfully Removed Folder Organisation Sharing Link" -ForegroundColor Green

        # Add the output to the output data array so that we can export it to a CSV file later
        $outputData += New-Object PSObject -Property @{
            'Site URL' = $link.'SITE URL'
            'Item URL' = $itemurl
            'Completed Action' = 'Successfully Removed Folder Organisation Sharing Link'
            'Status' = 'Success'
        }
    } 
    
    catch {
        
        # Tell the user that the sharing link was not removed successfully
        write-host "Failed to Remove the specified Folder Organisation Sharing Link" -ForegroundColor Red
        write-host "" # Empty line for spacing
        write-host $_.Exception.Message

        # Add the output to the output data array so that we can export it to a CSV file later
        $outputData += New-Object PSObject -Property @{
            'Site URL' = $link.'SITE URL'
            'Item URL' = $itemurl
            'Completed Action' = 'Failed to Remove the specified Folder Organisation Sharing Link'
            'Status' = 'Failed' 
            'Error' = $_.Exception.Message
        }
    }
} 

    else {
    
    # Tell the user that the item type is unknown
    Write-Host "Unknown item type for URL: $itemurl"
}

    Disconnect-PnPOnline
 }

# Export the output to a CSV file
# Define the output file path
$outputFilePath = "C:\Users\pwilli\OneDrive - Microsoft\Desktop\MGDC\Output\Organisation Sharing Links Removal Output_$timestamp.csv"

# Export the output data to a CSV file
$outputData | Select-Object 'Site URL','Item URL', 'Status','Completed Action', 'Error' | Export-Csv -Path $outputFilePath -NoTypeInformation

# Get the end time so that we can calculate the duration of the script
$endTime = Get-Date

# Calculate the duration of the script
$totalTime = $endTime - $startTime

Write-host ""
Write-Output "The script took: $($totalTime.Minutes) minute(s) and $($totalTime.Seconds) second(s) to run"

# Display a message to the user
Write-Host "" 
Write-Host -NoNewline "The output has been written to a CSV file at "
Write-Host -ForegroundColor Green $outputFilePath
Write-Host ""
