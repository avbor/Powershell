<#
.SYNOPSIS
Creating millions of files in parallel jobs.

.DESCRIPTION
Creating millions of files will help in testing some of the storage functions.
I.e. file system limitations.
May use a lot of memory ;)

.PARAMETER Path
Path to target folder

.PARAMETER FileCount
Presets of pair "File cound" and "Files per job" (10M, 15M, 500, 20)

.PARAMETER CustomFileCount
Custom number of file. If SplitStep not not specified, default value (500 000) used.

.PARAMETER SplitStep
Files per job. CustomFileCount \ SplitStep = total jobs count.

.EXAMPLE
Create-Bulk_of_Files.ps1 -Path \\server1\share\test -FileCount 10M
Create 10 000 000 files in \\server1\share\test. 500 000 per job, total 20 jobs

.EXAMPLE
Create-Bulk_of_Files.ps1 -Path \\server1\share\test -FileCount 15M
Create 15 000 000 files in \\server1\share\test. 750 000 per job, total 20 jobs

.EXAMPLE
Create-Bulk_of_Files.ps1 -Path \\server1\share\test -CustomFileCount 100000 -SplitStep 50000
Create 100 000 files in \\server1\share\test. 50 000 per job, total 2 jobs

.NOTES
Alexander V Borisov
B&N Bank 2018

.LINK
http://www.binbank.ru
#>

[CmdletBinding(DefaultParameterSetName="All")]

Param (
    [Parameter(Position=0,Mandatory=$true)]$Path,
    [Parameter(ParameterSetName = "PreSet",Position=0,Mandatory=$false)][ValidateSet("20","500","10M","15M")]$FileCount,
    [Parameter(ParameterSetName = "Custom",Position=0,Mandatory=$false)][int]$CustomFileCount,
    [Parameter(ParameterSetName = "Custom",Position=1,Mandatory=$false)][int]$SplitStep=500000
)

function CreateFiles ($dArr, $path) {
    $job = {
        param($arr,$pth)
        foreach ($num in $arr) {
            try {$null = New-Item -Path $pth -Name ([string]$num + ".txt") -ItemType "file" -Value $num -Force -ErrorAction Stop}
            catch {Write-Output $_.Exception.Message; Write-Output "Exit!"; exit}
        }
        Write-Output ("`tCreated " + $arr.Count + " files")
    }
    foreach ($mil in $dArr) {
        $null = Start-Job -ScriptBlock $job -ArgumentList ($mil, $path)
        $mil = $null
    }
}

function SplitArray ([int]$start=1, [int]$end, [int]$step=500000) {
    [array]$full = @([int]$start..[int]$end)
    $fLen = $full.length
    $arrs = @()
    for ($i = 0; $i -lt $fLen; $i += $step) {
        if ($i + ($step - 1) -gt $fLen) {
            $arrs += ,($full[$i]..$full[$fLen - 1])
        }
        else {
            $arrs += ,($full[$i]..$full[$i + ($step - 1)])
        }
    }
    Write-Output $arrs
    $arrs = $null
    $full = $null
}

if ($FileCount -eq "20" -and !$CustomFileCount) {
    $count = SplitArray -end 20 -step 10
    CreateFiles -dArr $count -path $Path
    $count = $null
}
elseif ($FileCount -eq "500" -and !$CustomFileCount) {
    $count = SplitArray -end 500 -step 100
    CreateFiles -dArr $count -path $Path
    $count = $null
}
elseif ($FileCount -eq "10M" -and !$CustomFileCount) {
    $count = SplitArray -end 10000000 -step 500000
    CreateFiles -dArr $count -path $Path
    $count = $null
}
elseif ($FileCount -eq "15M" -and !$CustomFileCount) {
    $count = SplitArray -end 15000000 -step 750000
    CreateFiles -dArr $count -path $Path
    $count = $null
}
elseif ($CustomFileCount) {
    $cust = SplitArray -end $CustomFileCount -step $SplitStep
    CreateFiles -dArr $cust -path $Path
}
else {
    Write-Output "Usage: `n`tGet-Help Create-Bulk_of_Files.ps1"; exit
}

Write-Output ("`n" + [string](Get-Job).Count + " jobs started")
Write-Output "Working..."

$result = Get-Job | Wait-Job | Receive-Job -AutoRemoveJob -Wait -WriteJobInResults | Format-Table Name,State -AutoSize -HideTableHeaders
Write-Output ("`nResults:" + ($result | Out-String).TrimEnd() + "`n")