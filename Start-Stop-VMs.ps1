<#
Name: Start-Stop-VMs.ps1
Version: 2
Author: Abbia Zacharia
Purpose: This script is used to start and stop all VMs in the specified resource group
Description:
Version Control:
Prerequisites:
Configurations:
#>

#==================================================================================

# Transcript logging
    Write-Host "`nTurning on transcript for troubleshooting" -ForegroundColor Yellow
    New-Item -Path $PSScriptRoot -Name "Logs" -ItemType Directory -Force
    $logpath = $PSScriptRoot + '\Logs\' + 'StartStopVMs' + ".log"
    Start-Transcript -Path $logpath -Append -Force

if (Get-Module -ListAvailable -Name Az*) 
{
    Write-Host "AZ PS module is already installed" -ForegroundColor Yellow
}
else 
{
    Install-Module Az -Force
    Write-Host "Script has just installed AZ PS module on your computer" -ForegroundColor Green
}

Write-Host "`nPls authenticate to continue.." -ForegroundColor Yellow
Login-AzAccount 
Write-Host "Authentication succeeded" -ForegroundColor Green
Write-Host "Listing subscriptions.." -ForegroundColor Yellow

$Subscriptions = Get-AzSubscription
if (!($Subscriptions)) 
{
    Write-Host "Login failed or no subscriptions found. Pls logout using Remove-AzureAccount -Name [username] and try again" -ForegroundColor Red
    exit
}

try 
{    
    if ($Subscriptions.Length -gt 1) 
    {
        $i = 1
        $Subscriptions | % { Write-Host "$i) $($_.Name) - $($_.Id)"; $i++ }

        while ($true) 
        {
            Write-Host "Make sure you have sufficient permissions to start and stop VMs on this subscription" -ForegroundColor Red
            $input = Read-Host "Choose the subscription (1-$($Subscriptions.Length))"
            $intInput = -1
            if ([int]::TryParse($input, [ref]$intInput) -and ($intInput -ge 1 -and $intInput -le $Subscriptions.Length)) 
            {
                Select-AzSubscription -SubscriptionId $($Subscriptions.Get($intInput - 1).Id)
                $subscription = $Subscriptions.Get($intInput - 1)
                break;
            }
        }

    } 
    else 
    {
        $subscription = $Subscriptions
    }
}
catch 
{
    $subscription = $Subscriptions
}
Write-Host "Selected subscription" $subscription.Name -ForegroundColor Green
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3
Write-Host "`nListing all resource groups" -ForegroundColor Yellow
Get-AzResourceGroup | Select-Object -Property ResourceGroupName
$ResourceGroupName = Read-Host "Enter name of the resource group"
Write-Host "`nListing all VMs" -ForegroundColor Yellow
Get-AzVM -ResourceGroupName $ResourceGroupName | Select-Object -Property Name

function Choices
{

write-host "`nWhat do you want to do?" -ForegroundColor Red
$start = New-Object System.Management.Automation.Host.ChoiceDescription "&Start VMs","Description."
$stop = New-Object System.Management.Automation.Host.ChoiceDescription "&Stop VMs (and deallocate resources)","Description."
$stopst = New-Object System.Management.Automation.Host.ChoiceDescription "&Stop VMs (but stay provisioned)","Description."
$options = [System.Management.Automation.Host.ChoiceDescription[]]($start, $stop, $stopst)
$title = "What do you want to do?"
$message = "Choose action"
$result = $host.ui.PromptForChoice($title, $message, $options, 1)
switch ($result) {
0
{
Write-Host "This will take some time to complete.." -ForegroundColor Yellow
$vm = Get-AzVm -ResourceGroupName $ResourceGroupName | Start-AzVM
Write-Host "All VMs have been started" -ForegroundColor Green                                      
}
1
 {
Read-Host -Prompt "Warning! All VMs will be forcefully stopped (and deallocated) Press any key to continue"
Write-Host "This will take some time to complete.." -ForegroundColor Yellow
Get-AzVM -ResourceGroupName $ResourceGroupName | Stop-AzVM -Force 
Write-Host "All VMs have been been stopped and deallocated so you are no longer charged for the VM compute resources" -ForegroundColor Green
}
2
 {
Read-Host -Prompt "Warning! All VMs will be stopped. Press any key to continue"
Write-Host "This will take some time to complete.." -ForegroundColor Yellow
Get-AzVM -ResourceGroupName $ResourceGroupName | Stop-AzVM -StayProvisioned -Force
Write-Host "All VMs have been been stopped but you will be charged for the VM compute resources by the hour" -ForegroundColor Green
}
}
}
Choices
Stop-Transcript