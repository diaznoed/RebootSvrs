Function PSLog($zstring)
## Function to write results to screen and log file
    {
    $logTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Output "$logTime $logTZ - $zstring" | Out-File $log -append
    Write-Host "$logTime $logTZ - $zstring"
    }

##
## Main
##

#
# CSV for each server and service to manipulate
#
$serverList = "SvrList.csv"
$hostArg = Import-Csv -Path .\$serverList
$numOfHostArgs = $hostArg.length
PSLog "Reading list of servers from $serverList"
Write-Host "Reading list of servers from $serverList" -ForegroundColor Cyan

# Setup Log File
$logDate = Get-Date -Format "yyyy-MM-dd-hhmm"
$log = ".\Reboot-$logDate.txt"

# Are you sure you want to run this script?
for ($z = 0; $z -lt $numOfHostArgs; $z++) {
    Write-host $hostArg.ServerName[$z] -ForegroundColor Cyan
    }
$logTZ = (Get-TimeZone).id
Write-Host "This script stops and reboots all Servers listed above." -ForegroundColor Red
Read-Host -Prompt "Press any key to continue or CTRL+C to quit"

##
## Reboot Servers koop
##

for ($i = 0; $i -lt $numOfHostArgs; $i++)
    {
    $hostStr = $hostArg.ServerName[$i]
    $svcStr = $hostArg.Service[$i]
    (Get-Service -ComputerName $hostStr -Name $svcStr).Stop()
    PSLog "Stopping target service on ", $hostStr
    Start-Sleep 25
    $Str1 = (Get-Service -ComputerName $hostStr -Name $svcStr).DisplayName
    $Str2 = (Get-Service -ComputerName $hostStr -Name $svcStr).Status
    PSLog "Server", $hostStr, "- Service:", $Str1, "- Status:", $Str2
    Start-Sleep 5
    PSLog "Rebooting: ", $hostStr
    Restart-Computer -ComputerName $hostStr -Force
    }

Write-Host "Rebooted last server, waiting 10 seconds..."
## Fancy way to display count down timer.
$x=1
$xDelay = 10
For ($i = 1; $i -le $xDelay; $i++)
    {
    If ($i -eq $xDelay)
        {
        Write-Host "$i "
        }
    Else
        {
        Write-Host -NoNewline "$i "
        }
    Start-Sleep 1
    }

## Ping Thang v2
$x=1
$maxp = 15
$pingDelay = 15
$goodTestNetCon = 0
$badTestNetCon = 0

$startTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

##
## Observe servers/services after reboot
##

Do 
    {
    PSLog "- - Iteration $x of $maxp with $pingDelay sec delay - - -"
    For ($i = 0; $i -lt $numOfHostArgs; $i++)
        {
        $str1 = $hostArg.ServerName[$i]
        $cmdRslt = Test-NetConnection -ComputerName $str1 -InformationLevel Quiet
        ## Output to screen and log of results, differnet format for fail.
        if ($cmdRslt)
            {
            $str2 = "$str1 - Pass"
            PSLog $str2
            $goodTestNetCon++
            }
        else
            {
            $str2 = "* * NetConnection test to $str1 - Fail * *" 
            PSLog $str2
            $badTestNetCon++
            }
        }
    If ($x -lt $maxp)
        {
        ## Output delay counter to screen only, no line feed unless last counter.
        For ($i = 1; $i -le $pingDelay; $i++)
            {
            If ($i -eq $pingDelay)
                {
                Write-Host "$i "
                }
            Else
                {
                Write-Host -NoNewline "$i "
                }
            Start-Sleep 1
            }
        }
    $x++
    }
    While ($x -le $maxp)

PSLog "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - --- - - - - - - - - -"

## Report final services status 

for ($i = 0; $i -lt $numOfHostArgs; $i++)
    {
    $hostStr = $hostArg.ServerName[$i]
    $svcStr = $hostArg.Service[$i]
    $Str1 = (Get-Service -ComputerName $hostStr -Name $svcStr -ErrorAction SilentlyContinue).DisplayName
    if ($Str1 -eq $null)
    {
        Write-Host "Service: " -ForegroundColor Red -NoNewline
        Write-host $svcStr -ForegroundColor Yellow -NoNewline
        Write-Host " not found on server " -ForegroundColor Red -NoNewline
        Write-Host $hostStr -ForegroundColor Yellow
        PSLog "Service: $svcStr not found on server $hostStr"
    }
    else
    {
        $Str2 = (Get-Service -ComputerName $hostStr -Name $svcStr).Status
        Write-Host "Server:" $hostStr -ForegroundColor Green -NoNewline
        Write-Host " - Service:" $Str1 -ForegroundColor Yellow -NoNewline
        Write-Host " - Status:" $Str2 -ForegroundColor Green
        PSLog "Server: $hostStr - Service: $Str1 - Status: $Str2"
    }
}
Write-Host " - Good Connections: " $goodTestNetCon
Write-Host " - Bad Connections:" $badTestNetCon
####