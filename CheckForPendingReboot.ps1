<#
CheckForRebootPending script
v 1.0
Script uses existing SvrList.csv to query register on servers to determin if a reboot is pending

#>


function CheckRebootStatus
{
param ([object]$hostname)
$session = New-PSSession -ComputerName $hostname -EA Stop
Invoke-Command -Session $session -ArgumentList @($hostname) -ScriptBlock {
    if (Get-Item "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" -EA Ignore)
        {
            Return $true
        }
        else
        {
            Return $false
        }
    }
}

##
## MAIN
##

$serverList = "SvrList.csv"
$hostArg = Import-Csv -Path .\$serverList
#$numOfHostArgs = $hostArg.length
Write-Host "Reading list of servers from $serverList" -ForegroundColor Cyan

foreach ($svr in $hostArg.ServerName) {
    $result = CheckRebootStatus -hostName $Svr
    Write-Host "$Svr - Need Reboot: " -NoNewline
    if ($result)
    {
        Write-Host $result -ForegroundColor Cyan
    }
    else
    {
        Write-Host $result -ForegroundColor Red
    }
}
