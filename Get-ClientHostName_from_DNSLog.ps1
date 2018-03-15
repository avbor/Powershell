# Get-ClientHostName_from_DNSLog.ps1

### Settings ###
$dnsSrv = "10.0.0.1"
$outFilePath = "dns_clients.txt"
$logFiles = @(
    "\\srv-1\c$\DNS_Logs\dns.log",
    "\\srv-2\c$\DNS_Logs\dns.log",
    "\\srv-3\c$\DNS_Logs\dns.log"
)
################

function GetNames ($logFile, $dnsHost) {
    Write-Host -NoNewline "Searching for IPs..." -Separator ""
    $ips = (((Select-String -Path $logFile -Pattern ".* Rcv (\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}) .*").matches | `
            ForEach-Object {$_.Groups[1].Value}) | Sort-Object | Get-Unique)
    $names = @()
    Write-Host -ForegroundColor Green "Done!"
    Write-Host "Found " $ips.Count " IP addresses" -Separator ""
    Write-Host -NoNewline "Getting hostnames..."
    foreach ($ip in $ips) {
        $names += (Resolve-DnsName -Server $dnsHost -Name $ip -ErrorAction SilentlyContinue).NameHost
    }
    Write-Output $names
    $ips = $null
    $names = $null
}

$time = Measure-Command {
    $Results = @()
    foreach ($file in $logFiles) {
        Write-Host "Processing file: " $file " ..." -Separator ""
        Write-Host "Size:" ((Get-Item -Path $file).Length / 1MB) "MBytes"
        try {$fileResults = (GetNames -logFile $file -dnsHost $dnsSrv)}
        catch {Write-Host -ForegroundColor Red $_; Exit}
        $Results += $fileResults
        Write-Host -ForegroundColor Green "Done!" -Separator ""
        Write-Host "Found " $fileResults.Count " hostnames`n" -Separator ""
        $fileResults = $null
    }
}

$Results = $Results | Sort-Object | Get-Unique
Write-Host "Found total:" $Results.Count
Write-Host "Time wasted:" $time

$Results | Out-File $outFilePath -Force
$Results = $null