
Param
(
    [Parameter(Position=0,Mandatory = $false)]$Path="hostnames.txt",
    [Parameter(Position=1,Mandatory = $false)]$Port="22",
    [Parameter(Position=2,Mandatory = $false)]$Timeout=100
)

function Test-Port ($addr, $tport, $time) {
    $tcp = New-Object System.Net.Sockets.TcpClient
    $conn = $tcp.BeginConnect($addr, $tport, $null, $null)
    $wait = $conn.AsyncWaitHandle.WaitOne($time, $false) 
    if (!$wait) {Write-Output $false}
    else {
        $error.clear()
        try {$tcp.EndConnect($conn)}
        catch {Write-Output $false; return}
        Write-Output $true
    }
}

Write-Output ("Port " + $Port + " is open on the following hosts:`n")
Get-Content $Path | ForEach-Object {
    if((Test-Port -addr $_ -tport $Port -time $Timeout)) {
        $_
    }
}