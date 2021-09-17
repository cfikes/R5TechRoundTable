#YOUTUBE RESTRICTED ZONE CREATION
$Global:dnsServer = $null

function AddZones($server) {
	$status.text = "Creating Restricted Zones"
	Start-Sleep -m 500
	Add-DnsServerPrimaryZone -Name "www.youtube.com" -Computer $server -ReplicationScope "Forest" -PassThru
	Add-DnsServerPrimaryZone -Name "m.youtube.com" -Computer $server -ReplicationScope "Forest" -PassThru
	Add-DnsServerPrimaryZone -Name "youtube.googleapis.com" -Computer $server -ReplicationScope "Forest" -PassThru	
	Add-DnsServerPrimaryZone -Name "youtubei.googleapis.com" -Computer $server -ReplicationScope "Forest" -PassThru	
	Add-DnsServerPrimaryZone -Name "www.youtube-nocookie.com" -Computer $server -ReplicationScope "Forest" -PassThru	
	$status.text = "Restricted Zones Created"
	Start-Sleep -m 1500
	$status.text = "Creating A Records"
	Add-DnsServerResourceRecordA -Name "@" -ZoneName "www.youtube.com" -ComputerName $server -AllowUpdateAny -IPv4Address "216.239.38.120" -TimeToLive 00:05:00
	Add-DnsServerResourceRecordA -Name "@" -ZoneName "m.youtube.com" -ComputerName $server -AllowUpdateAny -IPv4Address "216.239.38.120" -TimeToLive 00:05:00
	Add-DnsServerResourceRecordA -Name "@" -ZoneName "youtube.googleapis.com" -ComputerName $server -AllowUpdateAny -IPv4Address "216.239.38.120" -TimeToLive 00:05:00
	Add-DnsServerResourceRecordA -Name "@" -ZoneName "youtubei.googleapis.com" -ComputerName $server -AllowUpdateAny -IPv4Address "216.239.38.120" -TimeToLive 00:05:00
	Add-DnsServerResourceRecordA -Name "@" -ZoneName "www.youtube-nocookie.com" -ComputerName $server -AllowUpdateAny -IPv4Address "216.239.38.120" -TimeToLive 00:05:00
	$status.text = "Operation Complete. YouTube is Locked."   
}

function populateDNS {
	$Global:dnsServer = Get-ADDomainController | select -expandproperty ipv4address
	$dns_server.Text = $Global:dnsServer
	Write-Host "Detected DNS Server"
}

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$Form = New-Object system.Windows.Forms.Form
$Form.ClientSize = '375,150'
$Form.text = "YouTube Zone Creation"
$Form.TopMost = $false

$btnRun  = New-Object system.Windows.Forms.Button
$btnRun.text = "Create YouTube Zones"
$btnRun.width = 340
$btnRun.height = 30
$btnRun.location = New-Object System.Drawing.Point(16,100)
$btnRun.Font = 'Microsoft Sans Serif,10'

$dns_server = New-Object system.Windows.Forms.TextBox
$dns_server.multiline = $false
$dns_server.text = "$dnsServer"
$dns_server.width = 168
$dns_server.height = 20
$dns_server.location = New-Object System.Drawing.Point(16,35)
$dns_server.Font = 'Microsoft Sans Serif,10'
$dns_server.Text = ""

$DNSLabel = New-Object system.Windows.Forms.Label
$DNSLabel.text = "DNS Server"
$DNSLabel.AutoSize = $true
$DNSLabel.width = 25
$DNSLabel.height = 10
$DNSLabel.location = New-Object System.Drawing.Point(16,12)
$DNSLabel.Font = 'Microsoft Sans Serif,10'

$btnDetect = New-Object system.Windows.Forms.Button
$btnDetect.text = "Detect DNS Server"
$btnDetect.width = 168
$btnDetect.height = 24
$btnDetect.location = New-Object System.Drawing.Point(189,35)
$btnDetect.Font = 'Microsoft Sans Serif,10'

$status = New-Object system.Windows.Forms.Label
$status.text = "Ready       (GUI will freeze in process.)"
$status.AutoSize = $false
$status.width = 300
$status.height = 20
$status.location = New-Object System.Drawing.Point(16,70)
$status.Font = 'Microsoft Sans Serif,10'

$Form.controls.AddRange(@($btnRun,$dns_server,$DNSLabel,$btnDetect,$status))

$btnRun.Add_Click({ AddZones $dns_server.Text })
$btnDetect.Add_Click({ populateDNS })

[void]$Form.ShowDialog()