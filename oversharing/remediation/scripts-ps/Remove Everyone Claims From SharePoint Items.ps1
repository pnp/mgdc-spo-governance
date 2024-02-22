
#################################################
# Remove Everyone Claims From SharePoint Items.ps1
# Author: Pete Williams CSA Modern Work Microsoft
# Version: 1.0
# Date: 19th February 2024
#################################################

#################
# Script Overview 
#################

# This script is used to remove the "Everyone" and "Everyone Except External Users" claims and the associated permissions from SharePoint items (For example files and folders). 
# The script reads an input from a CSV file and then removes the everyone claims specified in the CSV file from the relevant SharePoint items. 
# The script uses the PnP PowerShell cmdlets to connect to the SharePoint sites and remove the everyone claims from SharePoint items.
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
$csvpath = "C:\Users\pwilli\OneDrive - Microsoft\Desktop\MGDC\CSV\Everyone Items.csv"

##############################################
# Tell the user what the script is going to do
##############################################

# Tell the user that the execution of the script has started
Write-Host ""
write-host "Starting the Remove Everyone Claims From SharePoint Items Script" -ForegroundColor Cyan
Write-Host ""

# Get the current date and time, we will use this to create a unique file name for the output file
$timestamp = Get-Date -Format 'dddd dd MMMM - HHmmss'

# Output the current date and time
Write-Host "Script started at: $timestamp" -ForegroundColor Cyan

# Import data from CSV file, this file contains the details of the sites and files that we are going to work on
$unsorteditems = Import-Csv -Path $csvpath
$items = $unsorteditems | Sort-Object -Property 'ITEM URL' -Descending

# Calculate distinct counts of files, folders, and lists
$distinctFilesCount = ($items | Where-Object { $_.'ITEM TYPE' -eq 'File' } | Select-Object -Property 'item url' -Unique).Count
$distinctFoldersCount = ($items | Where-Object { $_.'ITEM TYPE' -eq 'Folder' } | Select-Object -Property 'item url' -Unique).Count
$distinctListsCount = ($items | Where-Object { $_.'ITEM TYPE' -eq 'List' } | Select-Object -Property 'item url' -Unique).Count


# Tell the user how many sites and groups have been found in the CSV file
Write-host ""
Write-Host -NoNewline "We found "
Write-Host -NoNewline -ForegroundColor Green $distinctFilesCount
Write-Host -NoNewline " files "
Write-Host ""
Write-Host -NoNewline "We found "
Write-Host -NoNewline -ForegroundColor Green $distinctFoldersCount
Write-Host -NoNewline " folders "
Write-Host ""
Write-Host -NoNewline "We found "
Write-Host -NoNewline -ForegroundColor Green $distinctListsCount
Write-Host -NoNewline " lists "

# Output the sites and groups found in the CSV file in a formatted table so the user can see clearly what the script is going to work on
$items | Format-Table -Property SITE, 'ITEM TYPE', 'ITEM URL', 'EVERYONE GROUP', 'ROLE DEFINITION'
Write-Host ""

###########################################################################
# Start attempting to remove the everyone claims from the SharePoint groups 
###########################################################################

# Get the start time so that we can calculate the duration of the script
$startTime = Get-Date

# Define your SharePoint Online admin URL
$adminUrl = "https://officedevdemos-admin.sharepoint.com"

# Connect to the SharePoint Online admin center so that we can retrieve the "Everyone Except External Users" and "Everyone" groups
Connect-PnPOnline -Url $adminUrl -ClientId $appId -Tenant $tenantId -CertificatePath $pfxPath -CertificatePassword $pfxPassword

# Define your credentials
# $cred = Get-Credential

#Get the Everyone Except External Users group object for the tenant
$EEEGroup = Get-PnPUser -Identity "c:0-.f|rolemanager|spo-grid-all-users/$tenantId"

#Get the Everyone group object for the tenant
$EGroup = Get-PnPUser -Identity "c:0(.s|true"

# Initialize counters and arrays to store the items from which the permissions were removed
$fileCount = 0
$listCount = 0
$folderCount = 0
$outputData = @()

# Loop through each item in the CSV file 
# For each item, connect to the site, determine the claim, determine the role, and remove the permissions
foreach ($item in $items) {
    
    # Connect to the site
    Write-Host ""
    Write-Host ""
    Write-Host "" # Empty line for spacing
    Write-Host "-----------------------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host ""
    Connect-PnPOnline -Url $item.'SITEURL' -ClientId $appId -Tenant $tenantId -CertificatePath $pfxPath -CertificatePassword $pfxPassword
    Write-Host $item.SITE
    Write-Host ""
    Write-Host -NoNewline "Connected to site: ".PadRight(25) -ForegroundColor Green
    Write-Host -NoNewline "$($item.'SITEURL')"
        
    Write-Host "" # Empty line for spacing
   
    Write-Host ""
    Write-Host -NoNewline "Processing item: ".PadRight(25) -ForegroundColor Gray
    Write-Host "$($item.'ITEM URL')" -ForegroundColor Gray
    Write-Host "" # Empty line for spacing


    # Determine the claim from the CSV file that we are going to work on and remove from the SharePoint item
    $claimFriendlyName = $item.'Everyone Group'.Trim().ToLower()
    $claim = if ($claimFriendlyName -eq 'everyone') { $EGroup.LoginName } else { $EEEGroup.LoginName }

    # Tell the user which claim we have found in the csv file and are therfore going to try and remove from the item
    Write-Host -NoNewline "Group to be removed: ".PadRight(25) -ForegroundColor Gray
    Write-Host "$claimFriendlyName" -ForegroundColor Gray
    Write-Host "" # Empty line for spacing

    # Determine the role definition that we need to remove from the SharePoint item
    $roleDefinition = $item.'ROLE DEFINITION'.Trim().ToLower()
    $role = if ($roleDefinition -eq 'contribute') { 'Edit' } else { $roleDefinition }

    # Is this actually needed?
    # Replace spaces in the item URL with %20
    # $itemUrl = $item.'ITEM URL'.Replace(' ', '%20')
    # $Url = $item.'ITEM URL'.Replace(' ', '%20')

    # Split the URL into component parts so that we know how to address the items through the PnP cmdlets
    $urlParts = $Item.'ITEM URL'.Split('/')

    # Set some variables of the current CSV file item we are working on so that we can use them in the output and inform the user of the progress
    $itemtype = $item.'ITEM TYPE'.Trim().ToLower()
    $currentitem = $item.'ITEM URL'
    $currentegroup = $item.'EVERYONE GROUP'
    
    # Check what type of item we are working with then step into the relevant block of code
    # If it's a file, remove the permissions

    if ($itemtype -eq 'file') {

        # It's a file
        $listName = $urlParts[3].Replace('%20', ' ')
        $fileName = $urlParts[-1].Replace('%20', ' ')
        Write-Host -NoNewline "Processing file: ".PadRight(25) -ForegroundColor Gray
        Write-Host "$fileName"
        Write-Host "" # Empty line for spacing
        Write-Host -NoNewline "List or Library: ".PadRight(25) -ForegroundColor Gray
        Write-Host "$listName" -ForegroundColor Gray
        Write-Host "" # Empty line for spacing

        # Get the item ID as this is needed to remove the permissions when using the Set-PnpListItemPermission cmdlet
        $itemId = (Get-PnPListItem -List $listName -Query "<View><Query><Where><Eq><FieldRef Name='FileLeafRef'/><Value Type='File'>$fileName</Value></Eq></Where></Query></View>").Id

        try {
            
        # Try and remove the permissions for the file

        Set-PnPListItemPermission -List $listName -Identity $itemId -User $claim -RemoveRole $role -ErrorAction Stop
        Write-Host -NoNewline "Item Type:".PadRight(25) -ForegroundColor Gray
        Write-Host $item.'ITEM TYPE' -ForegroundColor Gray
        Write-Host ""
        Write-Host -NoNewline "Status:".PadRight(25)
        Write-Host "Permission Successfuly Removed" -ForegroundColor Green
        Write-Host "" # Empty line for spacing

        # If we were successful, increment the file counter and add the item to the output data
        $fileCount++ 
        $outputData += New-Object PSObject -Property @{GroupRemoved = $item.'EVERYONE GROUP';PreviousPermission=$role; ItemType="File";ItemURL=$item.'ITEM URL'} # Add to output data
        } 
        
       # If we were not successful, catch the error and inform the user
        catch 
        {
        # Catch any errors
        Write-Host ("Issue found: ".PadRight(25)) -NoNewline -ForegroundColor Gray
        Write-Host -NoNewline "Unable to remove permission for item " -ForegroundColor Yellow
        Write-Host -NoNewline $currentitem -ForegroundColor Yellow
        Write-Host -NoNewline " in list " -ForegroundColor Yellow
        Write-Host -NoNewline $listName -ForegroundColor Yellow
        Write-Host -NoNewline  " $_." 
        Write-Host ""
        Write-Host ""
        Write-Host ("Possible cause: ".PadRight(25)) -NoNewline -ForegroundColor Gray
        Write-Host -NoNewline "This could be because the $currentegroup is not present on this item"
        }
              
        } 
        
        # If it's a list, remove the permissions
        elseif ($itemtype -eq 'list'){
        
            # It's a list so inform the user and then try and remove the permissions
            $site = $item.SITE
            $listName = $urlParts[3].Replace('%20', ' ')
            Write-Host -NoNewline "Processing list: ".PadRight(25) -ForegroundColor Gray
            Write-Host "$($urlParts[-1])"
            # Empty line for spacing
            Write-Host "" 

            Try
            {
            
            # Try and remove the permissions for the list
            Set-PnPListPermission -Identity $urlParts[-1] -User $claim -RemoveRole $role -ErrorAction Stop
            Write-Host -NoNewline "Status: ".PadRight(25) -ForegroundColor Gray
            Write-Host "Permission removed for list".PadRight(25) -ForegroundColor Green
            # Empty line for spacing
            Write-Host "" 

            # If we were successful, increment the list counter and add the item to the output data
            $listCount++ 
            $outputData += New-Object PSObject -Property @{GroupRemoved = $item.'EVERYONE GROUP';PreviousPermission=$role; ItemType="List";ItemURL=$item.'ITEM URL'} 
            
            }

            # If we were not successful, catch the error and inform the user
            Catch
            {
            
            # Catch any errors
            Write-Host -NoNewline "Unable to remove permission" -ForegroundColor Yellow
            Write-Host -NoNewline " for item "
            Write-Host -NoNewline $listName -ForegroundColor Yellow
            Write-Host -NoNewline " in "
            Write-Host -NoNewline $site -ForegroundColor Yellow
            Write-Host " $_. This could be because the $currentegroup is not present on this item"

            
            }
      }
      
      # If we get to this stage we know that the item is a folder so we will attempt to remove the lists permissions
      else 
      
      {
            # It's a folder
            $listName = $urlParts[3].Replace('%20', ' ')
            Write-Host -NoNewline "Processing folder: ".PadRight(25) -ForegroundColor Gray
            Write-Host -NoNewline "$($urlParts[-1])" -ForegroundColor Green
            Write-Host -NoNewline " in list: " -ForegroundColor Gray
            Write-Host "$($listname)"
            Write-Host "" # Empty line for spacing
            write-host "-------------------" -ForegroundColor Gray
            Write-Host "" # Empty line for spacing

            $folderPath = $urlParts[3..($urlParts.Length - 1)] -join '/'

            # Try and remove the permissions for the folder
            Try{
            
            Set-PnPFolderPermission -List $listName -Identity $folderPath -User $claim -RemoveRole $role -ErrorAction Stop
            Set-PnPFolderPermission -List $listName -Identity $folderPath -User $claim -RemoveRole 'Limited Access' -ErrorAction Stop

            Write-Host -NoNewline "Status: ".PadRight(25) -ForegroundColor Gray
            Write-Host "Permission checked and/or removed for folder" -ForegroundColor Green
            Write-Host "" # Empty line for spacing

            $folderCount++ # Increment the folder counter
            $outputData += New-Object PSObject -Property @{GroupRemoved = $item.'EVERYONE GROUP';PreviousPermission=$role; ItemType="File";ItemURL=$item.'ITEM URL'} # Add to output data

            
            }

            Catch{
            
            # Catch any errors
            Write-Host ("Issue found: ".PadRight(25)) -NoNewline -ForegroundColor Gray
            Write-Host -NoNewline "Unable to remove permission for folder " -ForegroundColor Yellow
            Write-Host -NoNewline $folderpath -ForegroundColor Yellow
            Write-Host -NoNewline " in list " -ForegroundColor Yellow
            Write-Host -NoNewline $listName -ForegroundColor Yellow
            Write-Host -NoNewline  " $_." 
            Write-Host ""
            Write-Host ""
            Write-Host ("Possible cause: ".PadRight(25)) -NoNewline -ForegroundColor Gray
            Write-Host -NoNewline "This could be because the $currentegroup is not present on this item"
                       
            }


        }
    }

    # Disconnect from the site
    Disconnect-PnPOnline
    Write-Host ""
    Write-Host ""
    Write-Host "-----------------------------------------------------------------------------------" -ForegroundColor DarkGray




write-host ""
Write-Host "Process completed." -ForegroundColor Green
# Output the final counts
Write-Host ""
Write-Host -NoNewline "Successfully removed permissions from "
Write-Host -NoNewline -ForegroundColor Green $fileCount
Write-Host -NoNewline " files, "
Write-Host -NoNewline -ForegroundColor Green $listCount
Write-Host -NoNewline " lists, and "
Write-Host -NoNewline -ForegroundColor Green $folderCount
Write-Host " folders."
Write-Host ""

# Output the items from which the permissions were removed
Write-Host ""
Write-Host "We removed permissions from the following items:"
$outputData | Format-Table -Property GroupRemoved, PreviousPermission, ItemType, ItemURL
Write-Host ""

# Get the current date and time
$timestamp = Get-Date -Format 'dddd dd MMMM - HHmmss'

# Define the output file path
$outputFilePath = "C:\Users\pwilli\OneDrive - Microsoft\Desktop\Permission Removal Output_$timestamp.csv"

# Export the output data to a CSV file
$outputData | Export-Csv -Path $outputFilePath -NoTypeInformation

# Display a message to the user
Write-Host "" # New blank line
Write-Host -NoNewline "The output has been written to a CSV file at "
Write-Host -ForegroundColor Green $outputFilePath

Write-Host "Process completed." -ForegroundColor Green

# Get the end time so that we can calculate the duration of the script
$endTime = Get-Date

# Calculate the duration of the script
$totalTime = $endTime - $startTime

Write-Output "The script took: $($totalTime.Minutes) minute(s) and $($totalTime.Seconds) second(s) to run"