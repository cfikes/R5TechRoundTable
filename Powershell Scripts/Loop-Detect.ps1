function Get-UdpDatagram {
    param( $address="Any", [int] $Port=8125 )

    $MessageArray = @()
    


    try {
        $Endpoint = new-object System.Net.IPEndPoint( [IPAddress]::$address, $Port )
        $UdpClient = new-object System.Net.Sockets.UdpClient $Port
    }
    catch {
        throw $_
        exit -1
    }

    Write-Host "Press ESC to stop the Loop Detection Server ..." -fore Yellow
    Write-Host ""
    while( $true ) {
        if( $host.ui.RawUi.KeyAvailable )
        {
            $key = $host.ui.RawUI.ReadKey( "NoEcho,IncludeKeyUp,IncludeKeyDown" )
            if( $key.VirtualKeyCode -eq 27 )
            {	break	}
        }

        if( $UdpClient.Available ) {
            $content = $UdpClient.Receive( [ref]$Endpoint )
            #$LoopCheck = "$($Endpoint.Address.IPAddressToString):$($endpoint.Port) $([Text.Encoding]::ASCII.GetString($content))"
            #Write-Host "$($Endpoint.Address.IPAddressToString):$($endpoint.Port) $([Text.Encoding]::ASCII.GetString($content))"
            $MessageArray = $MessageArray + $([Text.Encoding]::ASCII.GetString($content))
            $TestArray = @()
            $MessageArray | Select-Object -Unique | ForEach-Object { $TestArray = $TestArray + $_ }
            If($MessageArray.Length -ne $TestArray.Length) {
                Write-Host "Loop Detected with Packet" $MessageArray[-1] "Server Stopped ..." -fore Red
                break
            }
            
        }
    }
    $UdpClient.Close( )
}


Get-UdpDatagram