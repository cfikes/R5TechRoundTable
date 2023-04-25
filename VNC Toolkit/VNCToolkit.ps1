<#
.SYNOPSIS

TightVNC Gui Deployment Tool 

.DESCRIPTION

Downloads TightVNC, creates deployment caches and deploys to remote machine with set password.

.EXAMPLE

./VNCToolkit.ps1

.NOTES

Must be admin to deploy and remove

.LINK

https://fikesmedia.com
#>

# Parameters
[CmdletBinding(DefaultParameterSetName="GUI")]
param(
    [Parameter(ParameterSetName='Installation',Mandatory=$false)]
    [switch]$Install,
    [Parameter(ParameterSetName='Installation',Mandatory=$false)]
    [string]$VNCPass,
    [Parameter(ParameterSetName='Installation',Mandatory=$false)]
    [string]$VNCLocal="TightVNC.msi",
    [Parameter(ParameterSetName='Installation',Mandatory=$false)]
    [string]$VNCDownload = "https://www.tightvnc.com/download/2.8.63/tightvnc-2.8.63-gpl-setup-64bit.msi",
    [Parameter(ParameterSetName='Installation',Mandatory=$false)]
    [string]$DeploymentCache="C:\Users\Public\Documents\Deployments",
    [Parameter(ParameterSetName='Removal',Mandatory=$false)]
    [switch]$Remove,
    [Parameter(Mandatory=$false)]
    [string]$ComputerName
)

$CachePath = "$($DeploymentCache)\$($VNCLocal)"
$ScriptPath = "$(Get-Location)\VNCToolkit.ps1"
$DeploymentSMB = "\\$($ComputerName)\C$\Users\Public\Documents\Deployments"



# Generate Secure Password
Function Get-RandomPassword {
    #define parameters
    param([int]$PasswordLength = 8)
    #ASCII Character set for Password
    $CharacterSet = @{
            Uppercase   = (97..122) | Get-Random -Count 10 | % {[char]$_}
            Lowercase   = (65..90)  | Get-Random -Count 10 | % {[char]$_}
            Numeric     = (48..57)  | Get-Random -Count 10 | % {[char]$_}
    } 
    #Frame Random Password from given character set
    $StringSet = $CharacterSet.Uppercase + $CharacterSet.Lowercase + $CharacterSet.Numeric 
    -join(Get-Random -Count $PasswordLength -InputObject $StringSet)
}

function BuildList() {
    $Computers = Get-ADComputer -Filter * | Select-Object -ExpandProperty Name | Sort-Object
    ForEach($Computer in $Computers) {
        $ComputerListBox.Items.Add($Computer)
    }
    # Scroll List to top
    $ComputerListBox.SelectedIndex = 0;
    $ComputerListBox.ScrollIntoView($ComputerListBox.SelectedItem) ;
}

function Removal() {
    # Begin Removal
    Write-Host "Removing from $($ComputerName)" 
    try {
        Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            $Deployment = Get-WmiObject -Class Win32_Product | Where-Object{$_.Name -eq "TightVNC"}
            $Deployment.Uninstall() | Out-Null
        }
    }
    Catch {
        Write-Host "Error Removing Deployment"
    }
    
    # Clear Remote Cache
    try {
      Remove-Item -Path "$($DeploymentSMB)\$($VNCLocal)" -Force -Verbose
    }
    catch {
        Write-Host "Error Removing Cache"
    }
    exit
}

function Deploy() {
    try {
        # Test Local Cache
        if ((Test-Path -Path $CachePath) -eq $False) {
            # Download Installation
            try {
                Invoke-WebRequest -URI $VNCDownload -OutFile $CachePath
                While ((Test-Path -Path $CachePath) -eq $False) {
                    Write-host "Waiting"
                }
            }
            catch {
                Write-Host "Error Downloading File"
            }
        }

        # Create Deployment Cache
        try {
            Invoke-Command -ComputerName $ComputerName -ScriptBlock {
                param($DeploymentCache)
	            New-Item -ItemType Directory -Path $DeploymentCache -Force | Out-Null
            } -ArgumentList $DeploymentCache
        }
        catch {
            Write-Host "Error Creating Deployment Cache"
        }

        # Copy To Deployment Cache
        try {
            Write-Host "Copying Installation to $($ComputerName)"
            Copy-Item -Path $CachePath -Destination $DeploymentSMB -Force
        }
        catch {
            Write-Host "Error Copying Installation"
        }

        # Start Deployment
        try {
            Invoke-Command -ComputerName $ComputerName -ScriptBlock {
                param($CachePath, $VNCPass)
	            Start-Process "msiexec.exe" -ArgumentList "/i $($CachePath) /quiet /norestart ADDLOCAL=`"Server,Viewer`" SERVER_REGISTER_AS_SERVICE=1 SERVER_ADD_FIREWALL_EXCEPTION=1 SERVER_ALLOW_SAS=1 SET_USEVNCAUTHENTICATION=1 VALUE_OF_USEVNCAUTHENTICATION=1 SET_ACCEPTHTTPCONNECTIONS=1 VALUE_OF_ACCEPTHTTPCONNECTIONS=0 SET_PASSWORD=1 VALUE_OF_PASSWORD=`"$($VNCPass)`"" -Wait
            } -ArgumentList ($CachePath, $VNCPass)
        }
        Catch {
            Write-Host "Error Installing Deployment"
        }
        
    }
    catch {
        Write-Host "There were errors completing the deploymnet."
    }
}

function Connect() {
    Write-Host "Connecting to $($ComputerName)"
    Start-Process -FilePath "C:\Program Files\TightVNC\tvnviewer.exe" -ArgumentList "`"$($ComputerName)`" -password=$($VNCPass) -scale=auto" -Wait
}

function InstallViewer(){
    # Download Cache
    try {
        New-Item -ItemType Directory -Path $DeploymentCache -Force | Out-Null
        Invoke-WebRequest -URI $VNCDownload -OutFile "$($CachePath)"
    }
    catch {
        Write-Host "Error Downloading File"
    }

    # Install From Cache
    try {
        Start-Process "msiexec.exe" -ArgumentList "/i $($CachePath) /quiet /norestart ADDLOCAL=`"Viewer`"" -Verb RunAs -Wait
    }
    catch {
        Write-Host "Error Installing Viewer"
    }
}


# Check Prompt Elevation
$CurrentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())

# Is Not Admin
if ($CurrentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) -ne "True") {
    if ($Remove.IsPresent) {
        Try {
            Write-Host "Attempting to elevate privileges."
            if($PSVersionTable.psversion.Major -le 5){
                Start-Process powershell.exe -ArgumentList "-file `"$($ScriptPath)`" -ComputerName $($ComputerName) -Remove" -Verb RunAs 
            } else {
                Start-Process pwsh.exe -ArgumentList "-file `"$($ScriptPath)`" -ComputerName $($ComputerName) -Remove" -Verb RunAs 
            }
        }
        Catch {
            Write-Host "Could Not Elevate Privileges."
            Write-Host "Cannot run from standard user prompt, please run as administrator. REMOVAL"
        }
    } elseif ($Install.IsPresent) {
        Try {
            Write-Host "Attempting to elevate privileges."
            if($PSVersionTable.psversion.Major -le 5){
                Start-Process powershell.exe $-ArgumentList "-file `"$($ScriptPath)`" -ComputerName $($ComputerName) -VNCPass $($VNCPass) -Install" -Verb RunAs 
            } else {
                Start-Process pwsh.exe -ArgumentList "-file `"$($ScriptPath)`" -ComputerName $($ComputerName) -VNCPass $($VNCPass) -Install" -Verb RunAs 
            }
        }
        Catch {
            Write-Host "Could Not Elevate Privileges."
            Write-Host "Cannot run from standard user prompt, please run as administrator. INSTALLATION"
        }
    }
}


# Is Admin
if ($Remove.IsPresent) {
    Try {
        Removal
        exit
    }
    Catch {
        Write-Host "REMOVAL ERROR " $_
    }
} elseif ($Install.IsPresent) {
    try { Deploy } catch { Write-Host "Install Error " $_ }
    try { Connect } catch { Write-Host "Connection Error " $_ }
    try { Removal } catch { Write-Host "Removal Error " $_ }
}


# Add Assemblies for XAML
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

# XAML Window
[xml]$XAML = @"
<Window x:Class="JustForForms.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:JustForForms"
        mc:Ignorable="d"
        Title="VNC Toolkit" Height="640" Width="540"
		ResizeMode="NoResize">
    <Grid>
        <ListBox x:Name="ComputerList" HorizontalAlignment="Left" Margin="10,10,0,0" VerticalAlignment="Top" Width="256" MinHeight="400" Height="594"/>
        <TabControl HorizontalAlignment="Left" Height="594" Margin="271,10,0,0" VerticalAlignment="Top" Width="255">
            <TabItem Header="Connect">
                <Grid Background="#FFE5E5E5">
                    <TextBlock HorizontalAlignment="Left" Margin="10,10,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Height="501" Width="229"><Run Text="This tool requires internet connectivity on both the client and server."/><LineBreak/><Run/><LineBreak/><Run Text="Clicking Connect will"/><LineBreak/><Run Text="1) Connect to remote machine."/><LineBreak/><Run Text="2) Download the installation"/><LineBreak/><Run Text="3) Install using a random password"/><LineBreak/><Run Text="4) Delete installation cache"/><LineBreak/><Run Text="5) Connect using the random password"/><LineBreak/><Run/><LineBreak/><Run Text="Upon Disconnect"/><LineBreak/><Run Text="1) Connect to remote machine"/><LineBreak/><Run Text="2) Uninstall the TightVNC server"/><LineBreak/><Run Text=""/><LineBreak/><Run/><LineBreak/><Run Text=""/><LineBreak/><Run Text=""/></TextBlock>
                    <Button x:Name="ConnectBTN" Content="Connect" HorizontalAlignment="Left" Margin="10,516,0,0" VerticalAlignment="Top" Width="229" Height="40"/>
                </Grid>
            </TabItem>
        </TabControl>
    </Grid>
</Window>
"@

$XAML.Window.RemoveAttribute('x:Class')
$XAML.Window.RemoveAttribute('mc:Ignorable')
$XAMLReader = New-Object System.Xml.XmlNodeReader $XAML
$MainWindow = [Windows.Markup.XamlReader]::Load($XAMLReader)

# Create UI Elements
$XAML.SelectNodes("//*[@Name]") | ForEach-Object{Set-Variable -Name ($_.Name) -Value $MainWindow.FindName($_.Name)}

# Define ListBox
$ComputerListBox = $MainWindow.FindName("ComputerList")


# Generate Secure Password
Function Get-RandomPassword {
    #define parameters
    param([int]$PasswordLength = 8)
 
    #ASCII Character set for Password
    $CharacterSet = @{
            Uppercase   = (97..122) | Get-Random -Count 10 | % {[char]$_}
            Lowercase   = (65..90)  | Get-Random -Count 10 | % {[char]$_}
            Numeric     = (48..57)  | Get-Random -Count 10 | % {[char]$_}
    }
 
    #Frame Random Password from given character set
    $StringSet = $CharacterSet.Uppercase + $CharacterSet.Lowercase + $CharacterSet.Numeric 
    -join(Get-Random -Count $PasswordLength -InputObject $StringSet)
}

function BuildList() {
    $Computers = Get-ADComputer -Filter * | Select-Object -ExpandProperty Name | Sort-Object
    ForEach($Computer in $Computers) {
        $ComputerListBox.Items.Add($Computer)
    }
    # Scroll List to top
    $ComputerListBox.SelectedIndex = 0;
    $ComputerListBox.ScrollIntoView($ComputerListBox.SelectedItem) ;
}



<# Initialization #>
$MainWindow.Add_ContentRendered({
    <# Import Settings From XML #>
    try {
        BuildList
    } catch {
    }

})

<# Window Interaction #>
$MainWindow.FindName("ConnectBTN").add_click({
    if ([string]::IsNullOrEmpty($ComputerListBox.SelectedItem) ) {
        [System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')
        [System.Windows.Forms.MessageBox]::Show('You must select a machine to connect.','ERROR')
    } else {
        # Deploy and Connect V5
        if($PSVersionTable.psversion.Major -le 5){
            # Test Connection
            if (Test-Connection $ComputerListBox.SelectedItem -Protocol WSMan -Count 1) {
                Start-Process Powershell.exe -ArgumentList "-file `"$($ScriptPath)`" -ComputerName $($ComputerListBox.SelectedItem) -VNCPass $(Get-RandomPassword -PasswordLength 8) -Install" -Verb RunAs
            } else {
                [System.Windows.MessageBox]::Show("Could not connect to $($ComputerListBox.SelectedItem)")
            }
        } 
        # Deploy and Connect V7
        else {
            # Test Connection
            if (Test-Connection -TargetName $ComputerListBox.SelectedItem -TimeoutSeconds 1 -Count 1) {
                Start-Process pwsh.exe -ArgumentList "-file `"$($ScriptPath)`" -ComputerName $($ComputerListBox.SelectedItem) -VNCPass $(Get-RandomPassword -PasswordLength 8) -Install" -Verb RunAs
            } else {
                [System.Windows.MessageBox]::Show("Could not connect to $($ComputerListBox.SelectedItem)")
            }
        }
    }
})


# Check for Requirements and Install
if ((Test-Path -Path "C:\Program Files\TightVNC\tvnviewer.exe") -eq $false) {
    Write-Host "Missing Requirements, Installing TVNViewer."
    InstallViewer
}


# Hide the console window
Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("Kernel32.dll")]
public static extern IntPtr GetConsoleWindow();

[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);'

[Console.Window]::ShowWindow([Console.Window]::GetConsoleWindow(), 0) | Out-Null

# Show MainWindow
$MainWindow.ShowDialog() | Out-Null