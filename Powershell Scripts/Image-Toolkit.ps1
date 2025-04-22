# Script: CaptureAndRestoreWizard.ps1
# Purpose: A wizard for restoring WIM images to UEFI systems with automatic disk partitioning and boot configuration.

# Function to partition and format the disk for UEFI systems
function Partition-Format-Disk {
    param(
        [string]$DiskNumber
    )

    Write-Host "Partitioning and formatting disk $DiskNumber..."

    # Create EFI partition (100MB, FAT32)
    $partition1 = New-Partition -DiskNumber $DiskNumber -Size 100MB -AssignDriveLetter
    Format-Volume -DriveLetter $partition1.DriveLetter -FileSystem FAT32 -Confirm:$false
    Set-Partition -DriveLetter $partition1.DriveLetter -IsActive $true  # Set active partition for UEFI

    # Create the Windows partition (NTFS)
    $partition2 = New-Partition -DiskNumber $DiskNumber -UseMaximumSize -AssignDriveLetter
    Format-Volume -DriveLetter $partition2.DriveLetter -FileSystem NTFS -Confirm:$false

    Write-Host "Disk $DiskNumber has been partitioned and formatted."

    # Return the drive letter of the NTFS partition for the restore operation
    return $partition2.DriveLetter
}

# Function to restore a WIM image (UEFI bootable)
function Restore-WIM {
    param(
        [string]$SourceWIM,
        [string]$TargetDiskNumber,
        [int]$Index
    )

    # Partition and format the disk before restoring the WIM
    $windowsPartitionDriveLetter = Partition-Format-Disk -DiskNumber $TargetDiskNumber

    Write-Host "Restoring WIM image $SourceWIM to disk $TargetDiskNumber..."

    # Apply the WIM image to the Windows partition
    dism /Apply-Image /ImageFile:$SourceWIM /Index:$Index /ApplyDir:$windowsPartitionDriveLetter
    if ($?) {
        Write-Host "Restore successful to disk $TargetDiskNumber"
    } else {
        Write-Host "Failed to restore WIM image."
        return
    }

    # For UEFI booting, copy the boot files to the EFI partition
    bcdboot "$windowsPartitionDriveLetter\Windows" /s $windowsPartitionDriveLetter /f UEFI
    Write-Host "Boot files copied for UEFI boot."

    Write-Host "Disk $TargetDiskNumber is now bootable with the restored WIM image."
}

# Function to get the list of disks (excluding system drives)
function Get-DiskSelection {
    $disks = Get-WmiObject Win32_DiskDrive | Where-Object { $_.MediaType -eq "Fixed hard disk media" }
    
    # Display disks with a number, model, and size
    $counter = 1
    $disks | ForEach-Object {
        $diskSizeGB = [math]::round($_.Size / 1GB, 2)  # Convert size to GB and round it
        Write-Host "$counter. $($_.Model) - $diskSizeGB GB"
        $counter++
    }

    # Prompt the user to choose a disk number
    $diskChoice = Read-Host "Choose a disk number to restore the WIM image (e.g., 1)"
    return $disks[$diskChoice - 1]  # Adjust for 0-based index
}

# Function to get the list of WIM files from the selected path
function Get-WIMFileSelection {
    param([string]$Path)

    $wimFiles = Get-ChildItem -Path $Path -Filter "*.wim"
    $wimFiles | ForEach-Object { Write-Host "$($_.Name)" }
    $wimChoice = Read-Host "Choose a WIM file number to restore (e.g., 0)"
    return $wimFiles[$wimChoice]
}

# Welcome Screen
function Welcome-Screen {
    Write-Host "==============================================="
    Write-Host "   Welcome to the WIM Capture and Restore Wizard!"
    Write-Host "==============================================="
    $continue = Read-Host "Do you want to continue? (Y/N)"
    if ($continue -eq "Y") {
        Main-Menu
    } else {
        Write-Host "Goodbye!"
    }
}

# Main Menu to select Capture or Restore
function Main-Menu {
    Write-Host "`nChoose an option:"
    Write-Host "1. Capture a WIM image"
    Write-Host "2. Restore a WIM image"
    Write-Host "3. Exit"
    $operation = Read-Host "Enter your choice (1, 2, or 3)"
    
    if ($operation -eq "1") {
        Capture-Flow
    } elseif ($operation -eq "2") {
        Restore-Flow
    } elseif ($operation -eq "3") {
        Write-Host "Exiting the wizard. Goodbye!"
    } else {
        Write-Host "Invalid choice. Please select 1, 2, or 3."
        Main-Menu
    }
}

# Flow for Capture (Create WIM image)
function Capture-Flow {
    Write-Host "`n--- Capture a WIM Image ---"
    $sourceDrive = Get-DriveSelection
    $destinationType = Read-Host "Do you want to save the image to (1) Disk or (2) SMB Share?"

    if ($destinationType -eq "1") {
        $destinationDrive = Get-DriveSelection
        $destinationPath = "$destinationDrive\$($sourceDrive.DeviceID)-$($sourceDrive.VolumeName).wim"
    } elseif ($destinationType -eq "2") {
        $destinationPath = Read-Host "Enter the SMB share path (e.g., \\server\share)"
        $SMBUserName = Read-Host "Enter your SMB username"
        $SMBPassword = Read-Host "Enter your SMB password" -AsSecureString
    }

    $imageName = Read-Host "Enter the name for the WIM image"
    Write-Host "`nYou chose:"
    Write-Host "Source Drive: $($sourceDrive.DeviceID)"
    Write-Host "Destination Path: $destinationPath"
    Write-Host "Image Name: $imageName"
    $confirm = Read-Host "Do you want to proceed? (Y/N)"

    if ($confirm -eq "Y") {
        Capture-WIM -SourceDrive $sourceDrive.DeviceID -DestinationPath $destinationPath -ImageName $imageName -ImageDescription "Captured Windows Image"
        Write-Host "Process completed!"
    } else {
        Write-Host "Returning to main menu."
        Main-Menu
    }
}

# Flow for Restore (Deploy WIM image)
function Restore-Flow {
    Write-Host "`n--- Restore a WIM Image ---"
    $sourceType = Read-Host "Is the source WIM file on (1) Disk or (2) SMB Share?"

    if ($sourceType -eq "1") {
        $sourcePath = Read-Host "Enter the path to the folder containing the WIM file"
    } elseif ($sourceType -eq "2") {
        $sourcePath = Read-Host "Enter the SMB share path (e.g., \\server\share)"
        $SMBUserName = Read-Host "Enter your SMB username"
        $SMBPassword = Read-Host "Enter your SMB password" -AsSecureString
    }

    $wimFile = Get-WIMFileSelection -Path $sourcePath
    $targetDisk = Get-DiskSelection
    Write-Host "`nYou chose:"
    Write-Host "WIM File: $wimFile"
    Write-Host "Target Disk: $targetDisk"
    $confirm = Read-Host "Do you want to proceed? (Y/N)"

    if ($confirm -eq "Y") {
        Restore-WIM -SourceWIM $wimFile.FullName -TargetDiskNumber $targetDisk.PNPDeviceID -Index 1
        Write-Host "Process completed!"
    } else {
        Write-Host "Returning to main menu."
        Main-Menu
    }
}

# Start the wizard
Welcome-Screen
