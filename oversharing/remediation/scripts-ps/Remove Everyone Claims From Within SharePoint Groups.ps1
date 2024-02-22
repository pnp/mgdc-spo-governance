##########################################################
# Remove Everyone Claims From Within SharePoint Groups.ps1
# Author: Pete Williams CSA Modern Work Microsoft
# Version: 1.0
# Date: 15th February 2024
##########################################################

#################
# Script Overview 
#################

# This script is used to remove the "Everyone" and "Everyone Except External Users" claims from within SharePoint groups (For example a site members group). 
# The script reads an input from a CSV file and then removes the everyone claims specified in the CSV file from the relevant SharePoint sites and groups. 
# The script uses the PnP PowerShell cmdlets to connect to the SharePoint sites and remove the everyone claims. 
# The script also outputs the results to a CSV file.

#################
# Prerequisites
#################

# This script requires the Pnp.PowerShell module to be installed.
# In order to install the PnP PowerShell module run the following command - Install-module pnp.powershell

###########################
# App Registration Creation
###########################

# In order to avoid throttling issues and ensure that all the sites and groups can be accessed without any authentication issues..
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
# You will need to uncomment the line that sets the $creds variable (line 51)
# You will need to uncomment line 143
# You will need to comment out line 146

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
$csvpath = "C:\Users\pwilli\OneDrive - Microsoft\Desktop\MGDC\CSV\Everyone Groups.csv"

################################################################
# The following variable needs to be updated with your tenant ID
################################################################

#Provide the tenant ID, this is the ID of the Azure AD tenant that you want to run the script against
$tenantId = "47814e7e-54bb-4192-98af-7949e514b0a8"

# Define your SharePoint Online admin URL
$adminUrl = "https://officedevdemos-admin.sharepoint.com"

# Ask the user for their credentials and store them in a variable called $cred
#$cred = Get-Credential

##############################################
# Tell the user what the script is going to do
##############################################

# Tell the user that the execution of the script has started
Write-Host ""
write-host "Starting the Remove Everyone Claims From Within SharePoint Groups Script" -ForegroundColor Cyan
Write-Host ""

# Get the current date and time, we will use this to create a unique file name for the output file
$timestamp = Get-Date -Format 'dddd dd MMMM - HHmmss'

# Import the data from CSV file, this csv file contains the details of the sites and groups that we are going to work on
$sitesAndGroups = Import-Csv -Path $csvpath

# Calculate distinct counts of sites and groups so that we can then tell the user how many have been found in the CSV file
$distinctSitesCount = ($sitesAndGroups | Select-Object -Property SiteURL -Unique).Count
$distinctGroupsCount = ($sitesAndGroups | Select-Object -Property GroupName -Unique).Count

# Tell the user how many sites and groups have been found in the CSV file
Write-host ""
Write-Host -NoNewline "We found "
Write-Host -NoNewline -ForegroundColor Green $distinctGroupsCount
Write-Host -NoNewline " groups in a total of "
Write-Host -NoNewline -ForegroundColor Green $distinctSitesCount
Write-Host " unique sites that we are going to work on."
Write-Host ""

# Output the sites and groups found in the CSV file in a formatted table so the user can see clearly what the script is going to work on
$sitesAndGroups | Format-Table -Property Site, GroupName, SiteURL
Write-Host ""

###########################################################################
# Start attempting to remove the everyone claims from the SharePoint groups 
###########################################################################

# Get the start time so that we can calculate the duration of the script
$startTime = Get-Date

# Connect to the SharePoint Online admin center so that we can retrieve the "Everyone Except External Users" and "Everyone" groups
Connect-PnPOnline -Url $adminUrl -ClientId $appId -Tenant $tenantId -CertificatePath $pfxPath -CertificatePassword $pfxPassword

# Get the Everyone Except External Users group object for the tenant and store it in a variable called $EEEGroup
$EEEGroup = Get-PnPUser -Identity "c:0-.f|rolemanager|spo-grid-all-users/$tenantId"

# Get the Everyone group object for the tenant and store it in a variable called $EGroup
$EGroup = Get-PnPUser -Identity "c:0(.s|true"

# Initialize counters and arrays to store the sites and groups from which the groups have been removed and not removed
$EEEGroupCount = 0
$EGroupCount = 0
$EEEGroupWithoutCount = 0
$EGroupWithoutCount = 0
$EEEGroupRemoved = @()
$EGroupRemoved = @()
$EEEGroupNotRemoved = @()
$EGroupNotRemoved = @()
$outputData = @()

# Loop through each item in the csv file
# For each item, connect to the site, get the group, and remove the "Everyone Except External Users" and/or "Everyone" claims
foreach ($item in $sitesAndGroups) {
    
    # Connect-PnPOnline -Url $item.SiteURL -Credentials $creds
    
    # Connect to the site using the app registration and the PFX certificate
    Connect-PnPOnline -Url $item.'SiteURL' -ClientId $appId -Tenant $tenantId -CertificatePath $pfxPath -CertificatePassword $pfxPassword

    # Tell the user which site and group we are working on
    Write-Host -NoNewline "Working on Site: "
    Write-Host -NoNewline -ForegroundColor Green $item.'Site'
    write-host ""
    Write-Host -NoNewline "GroupName: "
    Write-Host -NoNewline -ForegroundColor Green $item.'GroupName'
    Write-Host ""

    # Get the group object for the specified group. This will allow us to check if the "Everyone Except External Users" and "Everyone" groups are part of the specified group
    $group = Get-PnPGroup -Identity $item.'GroupName'

    # Switch based on the group that we want to remove as declared in GroupToRemove column in the CSV file
    switch ($item.'GroupToRemove') {
    
    'Everyone except external users' {
            
    # If the "Everyone except external users" group is part of the specified group, remove it
    if ($group.Users.LoginName -eq $EEEGroup.LoginName) {
        
        try {
            # Remove the claim from the group
            Remove-PnPGroupMember -Identity $item.'GroupName' -LoginName $EEEGroup.LoginName

            # Increment the $EEEGroupCount counter by 1 to count that we have successfully removed the "Everyone Except External Users" claim from the group
            $EEEGroupCount++ 

            # Add the item to the $EEEGroupRemoved array so that we can show this to the user at end of the script
            $EEEGroupRemoved += $item 

            # Write a message to the console to tell the user that we have removed the "Everyone Except External Users" claim from the group
            Write-Host -NoNewline "Removed 'Everyone Except External Users' from Group: "
            Write-Host -ForegroundColor Green $item.'GroupName'
            Write-Host ""
    
            # Add the site to the output array so that we can output the results to a CSV file
            $outputData += New-Object PSObject -Property @{
                'Site' = $item.'Site'
                'GroupName' = $item.'GroupName'
                'SiteURL' = $item.'SiteURL'
                'GroupRemoved' = 'Everyone Except External Users'
            }
        }
        catch {
            # Log the error to the outputData array so that we have a record of the failure in our output file
            $outputData += New-Object PSObject -Property @{
            'Site' = $item.'Site'
            'GroupName' = $item.'GroupName'
            'SiteURL' = $item.'SiteURL'
            'GroupRemoved' = $null
            'Status' = 'Failed' 
            'Error' = $_.Exception.Message
            }
        }

    }
    else {
         # If we get to this point, it means that the "Everyone Except External Users" claim was not found in the group

         # Increment the $EEEGroupWithoutCount counter by 1 to count that we have not removed the "Everyone Except External Users" claim from the group
         $EEEGroupWithoutCount++ 

         # Add the item to the $EEEGroupNotRemoved array so that we can show this to the user at end of the script
         $EEEGroupNotRemoved += $item

         # Write a message to the console to tell the user that we were unable to remove the "Everyone Except External Users" claim from the group
            Write-Host -NoNewline "Everyone Except External Users claim not found within: " -ForegroundColor DarkRed
            Write-Host $item.'GroupName'
            Write-Host ""
         
         # Add the site to the output array so that we can capture that the everyone claim was not found in the group and then output the results to a CSV file
         $outputData += New-Object PSObject -Property @{
        'Site' = $item.'Site'
        'GroupName' = $item.'GroupName'
        'SiteURL' = $item.'SiteURL'
        'GroupRemoved' = $null
        'Status' = 'Failed'
        'Error' = "'Everyone Except External Users' not found in group"
    }
    }}

    # If the group to remove is
    'Everyone' {

    # If the "Everyone" claim is part of the specified group, remove it
    if ($group.Users.LoginName -eq $EGroup.LoginName) {
        
        try {
            # Remove the claim from the group
            Remove-PnPGroupMember -Identity $item.'GroupName' -LoginName $EGroup.LoginName
            
            # Increment the $EGroupCount counter by 1 to count that we have successfully removed the "Everyone" claim from the group
            $EGroupCount++ 

            # Add the item to the $EGroupRemoved array so that we can show this to the user at end of the script
            $EGroupRemoved += $item 

            # Write a message to the console to tell the user that we have removed the "Everyone" claim from the group
            Write-Host -NoNewline "Removed 'Everyone' from Group: "
            Write-Host -ForegroundColor Green $item.'GroupName'
            Write-Host ""
    
            # Add the site to the output array so that we can output the results to a CSV file
            $outputData += New-Object PSObject -Property @{
                'Site' = $item.'Site'
                'GroupName' = $item.'GroupName'
                'SiteURL' = $item.'SiteURL'
                'GroupRemoved' = 'Everyone'
                'Status' = 'Success'
            }
        }
        catch {
             
            # Add the site and the failure to the output array so that we can output the results to a CSV file
             $outputData += New-Object PSObject -Property @{
                'Site' = $item.'Site'
                'GroupName' = $item.'GroupName'
                'SiteURL' = $item.'SiteURL'
                'GroupRemoved' = $null
                'Status' = 'Failed' 
                'Error' = $_.Exception.Message
            }
        }
      
    }

    else {
        # If we get to this point, it means that the "Everyone" claim was not found in the group
        # Increment the $EGroupWithoutCount counter by 1 to count that we have not removed the "Everyone" claim from the group
        $EGroupWithoutCount++

        # Add the item to the $EGroupNotRemoved array so that we can show this to the user at end of the script
        $EGroupNotRemoved += $item

        # Write a message to the console to tell the user that we were unable to remove the "Everyone" claim from the group        
            Write-Host -NoNewline "Everyone claim not found within: " -ForegroundColor DarkRed
            Write-Host $item.'GroupName'
            Write-Host ""

        # Add the site to the output array so that we can capture that the everyone claim was not found in the group and then output the results to a CSV file
        $outputData += New-Object PSObject -Property @{
        'Site' = $item.'Site'
        'GroupName' = $item.'GroupName'
        'SiteURL' = $item.'SiteURL'
        'GroupRemoved' = $null
        'Status' = 'Failed'
        'Error' = "'Everyone' not found in group"
    }
    }
    }
    default {}}

    # Disconnect from the site
    Disconnect-PnPOnline
}

# Tell the user how many groups we have removed the everyone claims from and how many we have not
# We will also output the groups that we have removed the everyone claims from and the groups that we have not

if ($EEGroupCount -gt 0) {
    Write-Host ""
    Write-Host -NoNewline "We removed '"
    Write-Host -NoNewline -ForegroundColor Gray "Everyone Except External Users"
    Write-Host -NoNewline "' from "
    Write-Host -NoNewline -ForegroundColor Green $EEEGroupCount
    Write-Host " groups:"

    $EEEGroupRemoved | Format-Table -Property Site, GroupName
    Write-Host ""
}

if ($EEEGroupWithoutCount -gt 0) {
    Write-Host ""
    Write-Host -NoNewline "We were unable to remove '"
    Write-Host -NoNewline -ForegroundColor DarkRed "Everyone Except External Users"
    Write-Host -NoNewline "' from "
    Write-Host -NoNewline -ForegroundColor DarkRed $EEEGroupWithoutCount
    Write-Host " groups as the everyone except external users claim was not found in these groups:"

    $EEEGroupNotRemoved | Format-Table -Property Site, GroupName
    Write-Host ""
}

if ($EGroupCount -gt 0) {
    Write-Host ""
    Write-Host -NoNewline "We removed '"
    Write-Host -NoNewline -ForegroundColor Gray "Everyone"
    Write-Host -NoNewline "' from "
    Write-Host -NoNewline -ForegroundColor Green $EGroupCount
    Write-Host " groups:"

    $EGroupRemoved | Format-Table -Property Site, GroupName
    Write-Host ""
}

if ($EGroupWithoutCount -gt 0) {
    Write-Host ""
    Write-Host -NoNewline "We were unable to remove '"
    Write-Host -NoNewline -ForegroundColor DarkRed "Everyone"
    Write-Host -NoNewline "' from "
    Write-Host -NoNewline -ForegroundColor DarkRed $EGroupWithoutCount
    Write-Host " groups as the everyone except external users claim was not found in these groups:"
    
    $EGroupNotRemoved | Format-Table -Property Site, GroupName
    Write-Host ""
}

# Get the current date and time as we will use this to create a unique file name for the output file
$timestamp = Get-Date -Format 'dddd dd MMMM - HHmmss'

# Output the sites and groups found in the CSV file in a formatted table so the user can see clearly what the script is going to work on
$outputData | Format-Table -Property Site, GroupName, GroupRemoved, Status, Error, SiteURL
Write-Host ""

# Define the output file path
$outputFilePath = "C:\Users\pwilli\OneDrive - Microsoft\Desktop\MGDC\Output\Everyone Group Removal Output_$timestamp.csv"

# Export the output data to a CSV file
$outputData | Select-Object 'Site','SiteURL', 'Status','GroupRemoved', 'Error', 'GroupName' |Export-Csv -Path $outputFilePath -NoTypeInformation

# Display a message to the user
Write-Host "" # New blank line
Write-Host -NoNewline "The output has been written to a CSV file at "
Write-Host -ForegroundColor Green $outputFilePath
Write-Host "" # New blank line

# Get the end time so that we can calculate the duration of the script
$endTime = Get-Date

# Calculate the duration of the script
$totalTime = $endTime - $startTime

Write-Output "The script took: $($totalTime.Minutes) minute(s) and $($totalTime.Seconds) second(s) to run"

# Tell the user that the execution of the script has finished
Write-Host ""
Write-Host "Finished the Remove Everyone Claims From Within SharePoint Groups Script" -ForegroundColor Green
Write-Host ""