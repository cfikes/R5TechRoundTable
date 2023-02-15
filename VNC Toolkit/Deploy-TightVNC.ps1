<#
.SYNOPSIS

TightVNC Sever Deployment Tool 

.DESCRIPTION

Downloads TightVNC, creates deployment caches and deploys to remote machine with set password.

.EXAMPLE

./Deploy-TightVNC.ps1 -ComputerName RemoteMachine01 -VNCPassword P@ssw0rd

.NOTES

Must be ran from elevated prompt.

.LINK

https://fikesmedia.com
#>

# Required Parameters
[CmdletBinding(DefaultParameterSetName="Installation")]
param(
    [Parameter(ParameterSetName='Installation', Position=0)]
    [string]$VNCDownload = "https://www.tightvnc.com/download/2.8.63/tightvnc-2.8.63-gpl-setup-64bit.msi",
	[Parameter(Mandatory=$true)]
    [string]$ComputerName,
    [Parameter(ParameterSetName='Installation',Mandatory=$true)]
    [string]$VNCPassword,
    [Parameter(ParameterSetName='Removal',Mandatory=$false)]
    [switch]$Remove
)


$VNCLocal = "TightVNC.msi"
$DeploymentCache = "C:\Users\Public\Documents\Deployments"
$DeploymentSMB = "\\$($ComputerName)\" + $($DeploymentCache.replace(':','$'))


# Check Prompt Elevation
$CurrentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if ($CurrentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) -ne "True") {
    Write-Host "Attempting to elevate privileges."
    if($Remove.IsPresent) {
        Try {
            Start-Process Powershell.exe $MyInvocation.MyCommand.Path -ArgumentList "-ComputerName $($ComputerName) -Remove" -Verb RunAs 
        }
        Catch {
            Write-Host "Could Not Elevate Privileges."
            Write-Host "Cannot run from standard user prompt, please run as administrator."
            exit
        }
    } else {
        Try {
            Start-Process Powershell.exe $MyInvocation.MyCommand.Path -ArgumentList "-ComputerName $($ComputerName) -VNCPassword `"$($VNCPassword)`"" -Verb RunAs
        }
        Catch {
            Write-Host "Could Not Elevate Privileges."
            Write-Host "Cannot run from standard user prompt, please run as administrator."
            exit
        } 
    }
    
    
}

if($Remove){
    # Begin Removal
    Write-Host "Removing"
    # Start Deployment      
    try {
        Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            $Deployment = Get-WmiObject -Class Win32_Product | Where-Object{$_.Name -eq "TightVNC"}
            $Deployment.Uninstall()
        }
    }
    Catch {
        Write-Host "Error Removing Deployment"
        exit
    }
} else {
    # Begin Deployment
    try {

        # Download Installation
        try {
            Invoke-WebRequest -URI $VNCDownload -OutFile $VNCLocal
            While ((Test-Path -Path "TightVNC.msi") -eq $False) {
                Write-host "Waiting"
                
            }
        }
        catch {
            Write-Host "Error Downloading File"
            exit
        }

        # Create Deployment Cache
        try {
            Invoke-Command -ComputerName $ComputerName -ScriptBlock {
                param($DeploymentCache)
	            New-Item -ItemType Directory -Path $DeploymentCache -Force 	
            } -ArgumentList $DeploymentCache
        }
        catch {
            Write-Host "Error Creating Deployment Cache"
            exit
        }

        # Copy To Deployment Cache
        try {
            Copy-Item -Path $VNCLocal -Destination "\\$($ComputerName)\c$\Users\Public\Documents\Deployments"
        }
        catch {
            Write-Host "Error Copying Installation"
            exit
        }

        # Start Deployment
        try {
            Invoke-Command -ComputerName $ComputerName -ScriptBlock {
                param($DeploymentCache, $VNCPassword)
	            (Start-Process "msiexec.exe" -ArgumentList "/i $($DeploymentCache)\tightvnc.msi /quiet /norestart ADDLOCAL=`"Server,Viewer`" SERVER_REGISTER_AS_SERVICE=1 SERVER_ADD_FIREWALL_EXCEPTION=1 SERVER_ALLOW_SAS=1 SET_USEVNCAUTHENTICATION=1 VALUE_OF_USEVNCAUTHENTICATION=1 SET_ACCEPTHTTPCONNECTIONS=1 VALUE_OF_ACCEPTHTTPCONNECTIONS=0 SET_PASSWORD=1 VALUE_OF_PASSWORD=`"$($VNCPassword)`"" -Wait -Passthru).ExitCode
            } -ArgumentList ($DeploymentCache, $VNCPassword)
        }
        Catch {
            Write-Host "Error Installing Deployment"
            exit
        }

    }
    catch {
        Write-Host "There were errors completing the deploymnet."
    }
    # Cleanup
    finally {
        Remove-Item $VNCLocal
    }

}

