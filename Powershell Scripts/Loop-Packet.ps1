Param ([int]$Count=60)

function Send-UdpDatagram {
    Param ([string] $EndPoint, 
    [int] $Port, 
    [string] $Message)

    $IP = [System.Net.Dns]::GetHostAddresses($EndPoint) 
    $Address = [System.Net.IPAddress]::Parse($IP) 
    $EndPoints = New-Object System.Net.IPEndPoint($Address, $Port) 
    $Socket = New-Object System.Net.Sockets.UDPClient 
    $EncodedText = [Text.Encoding]::ASCII.GetBytes($Message) 
    $SendMessage = $Socket.Send($EncodedText, $EncodedText.Length, $EndPoints) 
    $Socket.Close() 
} 

function Test-Loop {
    Param ([int] $Count)
    $Run = 0
    While ($Run -le $Count) {
        Send-UdpDatagram -EndPoint "255.255.255.255" -Port 8125 -Message "$Run"
        Start-Sleep 1   
        $Run++
    }
}

Test-Loop -Count $Count
