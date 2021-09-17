<#
.SYNOPSIS

This is a simple utility for capturing backups of Hyper-V virtual machines either in cluster or in multiple independent hosts.

.DESCRIPTION

Interates through specified hypervisors and virtual machines creating a snapshot and copying off the vhd/vhdx associated to the specified destination. Does not use the export-vm function so only a copy of the harddisk is retained. This is done to prevent double hop kerberos errors and permission issues associated with machine accounts across smb/cifs shares.

.EXAMPLE

./BackupVMwithProgress-Param.ps1 -hypervisors HV01,HV02 -backupVMs SRV-01,SRV-02 -backupAll $false -backupLocation "C:\Backups\" -enableCleanup $true -backupRetention 14 -testMode $false

.NOTES

Defaults to a test mode if -testMode not set to $false. The example above copies from hypervisors hv01 and hv02 vm's srv-01 and srv-02 to c:\backups\ and removes any folders in that destination older than 14 days.

.LINK

https://fikesmedia.com
#>


#
#-----------------------------------------
# Christopher Fikes - FikesMedia
# Clustered Hyper-V Image Level Backups
# 
# Add Hyper-V servers to hypervisors array
# and remote location to push backups for
# selective backups change backupAll and
# add servers to backupVMs array. This 
# only creates copies of the disk images 
# and not configuration files.
#-----------------------------------------
#

param(
    [Parameter(Position = 0)]
	[bool]$testMode = $true,
    [string[]]$hypervisors,
	[string[]]$backupVMs,
    [bool]$backupAll = $false,
	[string]$backupLocation,
	[bool]$enableCleanup = $false,
	[int]$backupRetention = 14
)

if ($hypervisors -eq $null -Or ($backupVMs -eq $null -And $backupAll -eq $false) -Or $backupLocation -eq $null) {
}
	

# Enable console test mode. Does not backup, only test.
#$testMode = $true

# This is the list of the hypervisors you want to backup. @("Server1","Server2")
#$hypervisors = @("srv-w16h00")

# Backup all or just some VM's. $true = All, $false = Enables VM List 
#$backupAll = $true

# List of VM's you wish to backup, only if list enabled. @("VM1","VM2")
#$backupVMs = @("SRV-W19SC")

# Remote location to store backups. Example: \\server\share
#$backupLocation = "F:\Hyper-V Backups\"

# Backup Retention Deletion Rights. 
# BE CAREFUL ENABLING THIS, IT FORCE DELETES.
# LEAVING IT SET TO FALSE WILL DRY RUN TO ALLOW VIEWING.
#$enableCleanup = $false

# Basic Retention Policy, keep backup X days.
#$backupRetention = 14

# Snapshot name format
$backupSnapshot = "$(Get-Date -Format yyyyMMdd)-Backup"

# Setup Event Logging
if ([System.Diagnostics.EventLog]::SourceExists("FikesMedia.HVBackups") -eq $false) {
    New-EventLog -LogName Application -Source "FikesMedia.HVBackups"
}

function Copy-File {
    param (
        [string]$Path,
        [string]$Destination,
        [switch]$Overwrite
    )

    $files = Get-ChildItem $Path -Recurse -File
    $source = (Resolve-Path (Split-Path $Path)).ProviderPath
    $Destination = (Resolve-Path $Destination).ProviderPath

    [long]$allbytes = ($files | measure -Sum length).Sum
    [long]$total1 = 0 # bytes done

    $index = 0
    $filescount = $files.Count
    $sw1 = [System.Diagnostics.Stopwatch]::StartNew()
    foreach ($file in $files) {
        $filefullname = $file.fullname
        
        $index++

        # build destination path for this file
        $destdir = Join-Path $Destination $($(Split-Path $filefullname).Replace($source, ''))

        # if it doesn't exist, create it
        if (!(Test-Path $destdir)) {
            $null = md $destdir
        }

        # if the file.txt already exists, rename it to file-1.txt and so on
        $num = 1
        $base = $file.name -replace "$($file.extension)$"
        $ext = $file.extension
        $destfile = Join-Path $destdir "$base$ext"

        if (!$overwrite) {
            while (Test-Path $destfile) {
                $destfile = Join-Path $destdir "$base-$num$ext"
                $num++
            }
        }

        $ffile = [io.file]::OpenRead($filefullname)
        $DestinationFile = [io.file]::Create($destfile)

        $sw2 = [System.Diagnostics.Stopwatch]::StartNew()
        [byte[]]$buff = New-Object byte[] (4096 * 1024) # 4MB?
        [long]$total2 = [long]$count = 0

        do {
            # copy src file to dst file, so many bytes at a time
            $count = $ffile.Read($buff, 0, $buff.Length)
            $DestinationFile.Write($buff, 0, $count)

            # this is just write-progress
            # uses stopwatch instead of get-date to determine how long is left
            $total2 += $count
            $total1 += $count
            if ($ffile.Length -gt 1) {
                $pctcomp2 = $total2 / $ffile.Length * 100
            } else {
                $pctcomp2 = 100
            }
            [int]$secselapsed2 = [int]($sw2.elapsedmilliseconds.ToString()) / 1000
            if ($secselapsed2 -ne 0) {
                [single]$xferrate = $total2 / $secselapsed2 / 1mb
            } else {
                [single]$xferrate = 0.0
            }
            if ($total % 1mb -eq 0) {
                if ($pctcomp2 -gt 0) {
                    [int]$secsleft2 = $secselapsed2 / $pctcomp2 * 100 - $secselapsed2
                } else {
                    [int]$secsleft2 = 0
                }
                $pctcomp1 = $total1 / $allbytes * 100
                [int]$secselapsed1 = [int]($sw1.elapsedmilliseconds.ToString()) / 1000
                if ($pctcomp1 -gt 0) {
                    [int]$secsleft1 = $secselapsed1 / $pctcomp1 * 100 - $secselapsed1
                } else {
                    [int]$secsleft1 = 0
                }
                $WrPrgParam1 = @{
                    Id = 1
                    Activity = "$('{0:N2}' -f $pctcomp1)% $index of $filescount ($($filescount - $index) left)"
                    Status = $filefullname
                    PercentComplete = $pctcomp1
                    SecondsRemaining = $secsleft1
                }
                Write-Progress @WrPrgParam1
                $WPparams2 = @{
                    Id = 2
                    Activity = (('{0:N2}' -f $pctcomp2) + '% Copying file @ ' + '{0:n2}' -f $xferrate + ' MB/s')
                    Status = $destfile
                    PercentComplete = $pctcomp2
                    SecondsRemaining = $secsleft2
                }
                Write-Progress @WPparams2
            }
        } while ($count -gt 0)

        $sw2.Stop()
        $sw2.Reset()
        $ffile.Close()
        $DestinationFile.Close()
    }
	
    $sw1.Stop()
    $sw1.Reset()
}

function backupHVVM {

    $hypervisor = $args[0]
    $vm = $args[1]
	
	# Check VM for existing snapshots and skip if exist.
	$checkSnapshot = Get-VMSnapshot -ComputerName $args[0] -VMName $args[1]
	
	if (!$checkSnapshot) {
		# Grab running VHD before Checkpoint
		$remoteVHDPath = $(get-vm -computer $hypervisor -name $vm | Select-Object vmid | get-vhd -ComputerName $hypervisor | Select-Object -ExpandProperty Path)
		# Start Logging
		$messageLog = "Start Backup of " + $vm + " on hypervisor " + $hypervisor + "to " + $backupLocation
		Write-EventLog -LogName Application -Source "FikesMedia.HVBackups" -EntryType Information -EventId 1 -Message $messageLog
		# Create SnapShot
		$messageLog = "Creating SnapShot " + $backupSnapshot + " for " + $vm
		Write-EventLog -LogName Application -Source "FikesMedia.HVBackups" -EntryType Information -EventId 1 -Message $messageLog
		if ($testMode -eq $false) {
			Get-VM -Computer $hypervisor -Name $vm | Checkpoint-VM -SnapshotName $backupSnapshot
		}
		# Copy VHD to Backup Location
		$messageLog = "Starting copy of " + $backupSnapshot + " for " + $vm
		Write-EventLog -LogName Application -Source "FikesMedia.HVBackups" -EntryType Information -EventId 1 -Message $messageLog
		$backupDest = $backupLocation+$backupSnapshot+"\"
		# Create Archive Folder if Needed 
		if (!(Test-Path $backupDest -PathType Container)) {
			New-Item -ItemType Directory -Force -Path $backupDest
		}
		# Loop Through VHDs
		Foreach ($vhd in $remoteVHDPath) {
			$vhd = $vhd.Replace(":","$").insert(0,"\\"+$hypervisor+"\")
			if ($testMode -eq $false) {
				Copy-Item $vhd -Destination $backupDest 
			} else {
				Write-Host "File Copy for" $vm "to" $backupDest "would occur."
			}
		}
		$messageLog = "Copy finished " + $backupSnapshot + " for " + $vm
		Write-EventLog -LogName Application -Source "FikesMedia.HVBackups" -EntryType Information -EventId 1 -Message $messageLog
		# Remove Snapshot
		$messageLog =  "Removing Snapshot " + $backupSnapshot + " for " + $vm
		Write-EventLog -LogName Application -Source "FikesMedia.HVBackups" -EntryType Information -EventId 1 -Message $messageLog
		Get-VM -Computer $hypervisor -Name $vm | Get-VMSnapshot -Name $backupSnapshot |  Remove-VMSnapshot
		# Complete Message
		$messageLog =  "Backup finished " + $backupSnapshot + " for " + $vm + " on " + $hypervisor
		Write-EventLog -LogName Application -Source "FikesMedia.HVBackups" -EntryType Information -EventId 1 -Message $messageLog
	} Else {
		Write-Host "!!! Backup Skipped for VM '$vm' due to existing snapshot on $hypervisor."
		$messageLog = "Backup Skipped for " + $vm + " due to existing snapshot on " + $hypervisor + "."
		Write-EventLog -LogName Application -Source "FikesMedia.HVBackups" -EntryType Warning -EventId 1 -Message $messageLog
	}
}

function cleanUpBackups {
	if ($enableCleanup -eq $false) {
		Write-Host "Dry run on backup retention."
		Get-ChildItem "$backupLocation" |? { $_.psiscontainer -and $_.lastwritetime -le (Get-Date).adddays(-$backupRetention) } |% { Remove-Item $_ -force -whatif }
	}
	if ($enableCleanup -eq $true) {
		Write-Host "Running backup retention policy."
		Get-ChildItem -Path "$backupLocation" -Directory | where {$_.LastWriteTime -le $(get-date).Adddays(-$backupRetention)} | Remove-Item -recurse -force
	}
}

# Backup list of VMs
if ($backupAll -eq $false) {
    Write-Host "Backing up list of VMs"
    Foreach ($hypervisor in $hypervisors) {
        $vmList = $(Get-VM -ComputerName $hypervisor | Select-Object -ExpandProperty Name)
        Foreach ($backupVM in $backupVMs){
            if ($vmList -contains $backupVM){
                Write-Host "Backing up" $backupVM "on hypervisor" $hypervisor "to" $backupLocation
                backupHVVM $hypervisor $backupVM
            }
        }
    }
	cleanUpBackups
}

# Backup all VMs
if ($backupAll -eq $true) {
    Write-Host "Backing up All VMs"
    Foreach ($hypervisor in $hypervisors) {
        $vmList = $(Get-VM -ComputerName $hypervisor | Select-Object -ExpandProperty Name)
        Foreach ($backupVM in $vmList){
            Write-Host "Backing up" $backupVM "on hypervisor" $hypervisor "to" $backupLocation
            backupHVVM $hypervisor $backupVM
        }
    }
	cleanUpBackups
}

