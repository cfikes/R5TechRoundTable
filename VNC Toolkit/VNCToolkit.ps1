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
    [string]$VNCLocal="FikesMediaVNC.msi",
    [Parameter(ParameterSetName='Installation',Mandatory=$false)]
    [string]$VNCDownload = "https://github.com/FikesMedia/releases/blob/main/FikesMediaVNC/2.8.79/FikesMediaVNC.msi?raw=true",
    [Parameter(ParameterSetName='Installation',Mandatory=$false)]
    [string]$DeploymentCache="C:\Users\Public\Documents\Deployments",
    [Parameter(ParameterSetName='Removal',Mandatory=$false)]
    [switch]$Remove,
    [Parameter(ParameterSetName='MenuClick',Mandatory=$false)]
    [switch]$MenuClick,
    [Parameter(ParameterSetName='MenuClick',Mandatory=$false)]
    [string]$MenuAction,
    [Parameter(Mandatory=$false)]
    [string]$ComputerName
)
$ScriptVersion = "1.3 Client Tools"

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
    Write-Host "`nRemoving installation." -ForegroundColor Green
    Try {
        Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            $Deployment = Get-WmiObject -Class Win32_Product | Where-Object{$_.Name -eq "TightVNC"}
            $Deployment.Uninstall() | Out-Null
        }
    }
    Catch {
        Write-Host "Error Removing Deployment!" -ForegroundColor Red
        Write-Host $_
    }
    
    # Clear Remote Cache
    Try {
      Remove-Item -Path "$($DeploymentSMB)\$($VNCLocal)" -Force -Verbose
    }
    Catch {
        Write-Host "Error Removing Cache!" -ForegroundColor Red
        Write-Host $_
    }
    exit
}

function Deploy() {
    Write-Host "Do NOT close this window." -ForegroundColor Yellow
    Write-Host "Doing so will cancel the deployment process.`n" -ForegroundColor Yellow
    Write-Host "Instance for: " -ForegroundColor Green -NoNewline
    Write-Host "$($ComputerName)`n"
    Write-Host "Begining deployment." -ForegroundColor Green
    Try {
        # Test Local Cache
        if ((Test-Path -Path $CachePath) -eq $False) {
            Write-Host "Deployment cache missing." -ForegroundColor Green
            # Download Installation
            Try {
                Write-Host "Downloading installation." -ForegroundColor Green
                Invoke-WebRequest -URI $VNCDownload -OutFile $CachePath
                While ((Test-Path -Path $CachePath) -eq $False) {
                    Write-host "Waiting"
                }
            }
            Catch {
                Write-Host "Error Downloading File!"  -ForegroundColor Red
                Write-Host $_
            }
        }

        # Create Deployment Cache
        Try {
            Invoke-Command -ComputerName $ComputerName -ScriptBlock {
                param($DeploymentCache)
	            New-Item -ItemType Directory -Path $DeploymentCache -Force | Out-Null
            } -ArgumentList $DeploymentCache
        }
        Catch {
            Write-Host "Error Creating Deployment Cache!" -ForegroundColor Red
            Write-Host $_
        }

        # Copy To Deployment Cache
        Try {
            Write-Host "Copying installation files."-ForegroundColor Green
            Copy-Item -Path $CachePath -Destination $DeploymentSMB -Force
        }
        Catch {
            Write-Host "Error Copying Installation!" -ForegroundColor Red
            Write-Host $_
        }

        # Start Deployment
        Try {
            Write-Host "Begining installation." -ForegroundColor Green
            Invoke-Command -ComputerName $ComputerName -ScriptBlock {
                param($CachePath, $VNCPass)
	            Start-Process "msiexec.exe" -ArgumentList "/i $($CachePath) /quiet /norestart ADDLOCAL=`"Server,Viewer`" SERVER_REGISTER_AS_SERVICE=1 SERVER_ADD_FIREWALL_EXCEPTION=1 SERVER_ALLOW_SAS=1 SET_USEVNCAUTHENTICATION=1 VALUE_OF_USEVNCAUTHENTICATION=1 SET_ACCEPTHTTPCONNECTIONS=1 VALUE_OF_ACCEPTHTTPCONNECTIONS=0 SET_REMOVEWALLPAPER=0 SET_PASSWORD=1 VALUE_OF_PASSWORD=`"$($VNCPass)`"" -Wait
            } -ArgumentList ($CachePath, $VNCPass)
        }
        Catch {
            Write-Host "Error Installing Deployment!" -ForegroundColor Red
            Write-Host $_
        }
        
    }
    Catch {
        Write-Host "There were errors completing the deploymnet!" -ForegroundColor Red
        Write-Host $_
    }
}

function Connect() {
    Write-Host "Connecting to $($ComputerName)" -ForegroundColor Green
    Start-Process -FilePath "C:\Program Files\FikesMediaVNC\tvnviewer.exe" -ArgumentList "`"$($ComputerName)`" -password=$($VNCPass) -scale=auto" -Wait
}

function InstallViewer(){
    Write-Host "Missing Requirements, Installing FikesMediaVNC." -ForegroundColor Yellow
    # Download Cache
    Try {
        New-Item -ItemType Directory -Path $DeploymentCache -Force | Out-Null
        Invoke-WebRequest -URI $VNCDownload -OutFile "$($CachePath)"
    }
    Catch {
        Write-Host "Error Downloading File!" -ForegroundColor Red
    }

    # Install From Cache
    Try {
        Start-Process "msiexec.exe" -ArgumentList "/i $($CachePath) /quiet /norestart ADDLOCAL=`"Viewer`"" -Verb RunAs -Wait
    }
    Catch {
        Write-Host "Error Installing Viewer!" -ForegroundColor Red
    }
}

function MenuClick_OpenSMB(){
    Start-Process "Explorer.exe" "\\$($ComputerListBox.SelectedItem)\C$\"
}

function MenuClick_UpdateGPO(){
    Try {
        if($PSVersionTable.psversion.Major -le 5){
            Start-Process powershell.exe -ArgumentList "-NoExit Invoke-Command -ComputerName $($ComputerListBox.SelectedItem) -ScriptBlock {Write-Host `"Updating policies on $($ComputerListBox.SelectedItem)`" -ForegroundColor Green;gpupdate.exe /Force};exit" -Verb RunAs
        } else {
            #Executes in PS5 Until Fixed
            Start-Process powershell.exe -ArgumentList "-NoExit Invoke-Command -ComputerName $($ComputerListBox.SelectedItem) -ScriptBlock {Write-Host `"Updating policies on $($ComputerListBox.SelectedItem)`" -ForegroundColor Green;gpupdate.exe /Force};exit" -Verb RunAs
        }
    }
    Catch {
        Write-Host "Error Updating Policy!" -ForegroundColor Red
        Write-Host $_
    }
}

function MenuClick_PurgeVNC(){
    Try {
        if($PSVersionTable.psversion.Major -le 5){
                Start-Process powershell.exe -ArgumentList "-file `"$($ScriptPath)`" -ComputerName $($ComputerName) -Remove" -Verb RunAs -wait
            } else {
                Start-Process pwsh.exe -ArgumentList "-file `"$($ScriptPath)`" -ComputerName $($ComputerName) -Remove" -Verb RunAs -wait
            }
    }
    Catch {
        Write-Host "Error Removing!" -ForegroundColor Red
        Write-Host $_
    }
}

function MenuClick_RemoteConsole() {
    Write-Host "Connecting to $($ComputerName) Remote PowerShell" -ForegroundColor Green
    if($PSVersionTable.psversion.Major -le 5){
        Start-Process powershell.exe -ArgumentList "-NoExit Enter-PSSession -ComputerName $($ComputerListBox.SelectedItem)" -Verb RunAs
    } else {
        #Executes in PS5 Until Fixed
        Start-Process powershell.exe -ArgumentList "-NoExit Enter-PSSession -ComputerName $($ComputerListBox.SelectedItem)" -Verb RunAs
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
            Write-Host "Could Not Elevate Privileges." -ForegroundColor Red
            Write-Host "Cannot run from standard user prompt, please run as administrator. REMOVAL" -ForegroundColor Red
            Write-Host $_
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
            Write-Host "Could Not Elevate Privileges." -ForegroundColor Red
            Write-Host "Cannot run from standard user prompt, please run as administrator. INSTALLATION" -ForegroundColor Red
            Write-Host $_
        }
    }
}


# Is Admin
if ($Remove.IsPresent) {
    Try {
        # Manual Removal -Remove -ComputerName ""
        Removal
        exit
    }
    Catch {
        Write-Host "REMOVAL ERROR " $_
    }
} elseif ($Install.IsPresent) {
    Try { 
        Deploy 
    } 
    Catch {

    }
    Try { 
        Connect 
    } 
    Catch { 

    }
    Try { 
        Removal 
    } 
    Catch { 

    }
} elseif($MenuClick.IsPresent) {

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
        Title="AD VNC Toolkit" Height="640" Width="540"
		ResizeMode="NoResize">
    <Grid>
        <ListBox x:Name="ComputerList" HorizontalAlignment="Left" Margin="10,10,0,0" VerticalAlignment="Top" Width="256" MinHeight="400" Height="594">
        <ListBox.Resources>

        <!--Defines a context menu-->
        <ContextMenu x:Key="ClientMenu">
            <MenuItem x:Name="MenuSMBOpen" Header="SMB Open C$"/>
            <MenuItem x:Name="MenuUpdateGPO" Header="Update Group Policy"/>
            <MenuItem x:Name="MenuPSConsole" Header="Open PowerShell Console"/>
			<MenuItem x:Name="MenuPurgeVNC" Header="Purge VNC"/>
        </ContextMenu>

        <!--Sets a context menu for each ListBoxItem in the current ListBox-->
        <Style TargetType="{x:Type ListBoxItem}">
             <Setter Property="ContextMenu" Value="{StaticResource ClientMenu}"/>
        </Style>

        </ListBox.Resources>
        </ListBox>
        <TabControl HorizontalAlignment="Left" Height="594" Margin="271,10,0,0" VerticalAlignment="Top" Width="255">
            <TabItem Header="VNC Connect">
                <Grid Background="#FFE5E5E5">
                    <TextBlock HorizontalAlignment="Left" Margin="10,292,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Height="501" Width="229"><Run Text="This tool initially requires internet connectivity to setup deployment caches."/><LineBreak/><Run/><LineBreak/><Run Text="Clicking Connect:"/><LineBreak/><Run Text="1) Connect to remote machine."/><LineBreak/><Run Text="2) Download the installation"/><LineBreak/><Run Text="3) Install using a random password"/><LineBreak/><Run Text="4) Connect using the random password"/><LineBreak/><Run/><LineBreak/><Run Text="Upon Disconnect:"/><LineBreak/><Run Text="1) Connect to remote machine"/><LineBreak/><Run Text="2) Uninstall the TightVNC server"/><LineBreak/><Run Text="3) Delete installation cache"/><LineBreak/><Run Text=""/><LineBreak/><Run/><LineBreak/><Run Text=""/><LineBreak/><Run Text=""/></TextBlock>
                    <Button x:Name="ConnectBTN" Content="Deploy and Connect" HorizontalAlignment="Left" Margin="10,516,0,0" VerticalAlignment="Top" Width="229" Height="40"/>
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
    Try {
        BuildList
    } Catch {
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

# Menu Interactions

# Remote PowerShell
$MainWindow.FindName("MenuPSConsole").add_click({
    Try {
        MenuClick_RemoteConsole
    }
    Catch {

    }
})

# Open C$
$MainWindow.FindName("MenuSMBOpen").add_click({
    Try {
        MenuClick_OpenSMB
    }
    Catch {

    }
})

# Update GPO
$MainWindow.FindName("MenuUpdateGPO").add_click({
    Try {
        MenuClick_UpdateGPO
    }
    Catch {

    }

})

# Purge VNC
$MainWindow.FindName("MenuPurgeVNC").add_click({
    Try {
        MenuClick_PurgeVNC
    }
    Catch {

    }

})



Write-Host "------------------------------------------------" -ForegroundColor Green
Write-Host "|  AD VNC Toolkit                              |" -ForegroundColor Green
Write-Host "|  https://github.com/cfikes/R5TechRoundTable  |" -ForegroundColor Green
Write-Host "------------------------------------------------" -ForegroundColor Green
Write-Host "Version: $($ScriptVersion)"  -ForegroundColor Green
Write-Host "`nClosing this windows will close the application."

# Check for Requirements and Install
if ((Test-Path -Path "C:\Program Files\FikesMediaVNC\tvnviewer.exe") -eq $false) {
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