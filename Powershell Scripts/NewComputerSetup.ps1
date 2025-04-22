




function ShowSoftwareInstallWindow {
    # Software list defined as a JSON string
    $jsonSoftwareList = '[
    {"Name": "Google Chrome", "Id": "Google.Chrome"},
    {"Name": "Firefox", "Id": "Mozilla.Firefox"},
    {"Name": "Firefox ESR", "Id": "Mozilla.Firefox.ESR"},
    {"Name": "Notepad++", "Id": "Notepad++"},
    {"Name": "Google Drive" , "Id": "Google.Drive"},
    {"Name": "VLC", "Id": "videolan.vlc"},
    {"Name": "7-Zip", "Id": "7zip.7zip"},
    {"Name": "Acrobat Reader", "Id": "Adobe.Acrobat.Reader.64-bit"},
    {"Name": "LibreOffice", "Id": "LibreOffice.LibreOffice"}
    ]'
    $softwareList = ConvertFrom-Json -InputObject $jsonSoftwareList | Sort-Object -Property Name

    $xamlInstall = @"
    <Window
        xmlns='http://schemas.microsoft.com/winfx/2006/xaml/presentation'
        xmlns:x='http://schemas.microsoft.com/winfx/2006/xaml'
        Title='Install Software' Height='350' Width='450'
        WindowStartupLocation='CenterScreen'>
        <StackPanel>
            <Label Content='Select Software to Install:' FontWeight='Bold'/>
            <ListBox x:Name='listSoftware' Height='200' Margin='10'/>
            <Button x:Name='installButton' Content='Install Selected Software' Height='40' Margin='10'/>
        </StackPanel>
    </Window>
"@

    $readerInstall = New-Object System.Xml.XmlNodeReader ([System.Xml.XmlDocument]$xamlInstall)
    $windowInstall = [System.Windows.Markup.XamlReader]::Load($readerInstall)

    # Get the ListBox and Button controls
    $listSoftware = $windowInstall.FindName("listSoftware")
    $installButton = $windowInstall.FindName("installButton")

    # Dynamically add checkboxes to the ListBox for each software item
    foreach ($software in $softwareList) {
        $checkBox = New-Object System.Windows.Controls.CheckBox
        $checkBox.Content = $software.Name
        $checkBox.Tag = $software.Id
        $listSoftware.Items.Add($checkBox)
    }

    # Add click event handler for the installation button
    $installButton.Add_Click({
        $selectedSoftware = $listSoftware.Items | Where-Object { $_.IsChecked }
        if ($selectedSoftware.Count -eq 0) {
            [System.Windows.MessageBox]::Show("Please select at least one software to install.", "No Selection", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        } else {
            foreach ($checkBox in $selectedSoftware) {
                Start-Process "winget" -ArgumentList "install --id $($checkBox.Tag) -e" -Wait
            }
            [System.Windows.MessageBox]::Show("Installation completed.")
        }
    })

    # Show the installation window
    $windowInstall.ShowDialog() | Out-Null
}



    

function InstallWindowsUpdates {
    # XAML for the Windows Update GUI
    $xamlUpdates = @"
    <Window
        xmlns='http://schemas.microsoft.com/winfx/2006/xaml/presentation'
        xmlns:x='http://schemas.microsoft.com/winfx/2006/xaml'
        Title='Windows Update' Height='450' Width='650'
        WindowStartupLocation='CenterScreen'>
        <StackPanel Margin='10'>
            <Label Content='Windows Update' FontWeight='Bold' FontSize='16' Margin='0,0,0,10'/>
            <Label Content='Click "Check for Updates" to scan for available updates.'/>
            <ProgressBar x:Name='progressBar' Height='20' Margin='0,20,0,20' IsIndeterminate='False' Visibility='Hidden'/>
            <Button x:Name='btnCheckUpdates' Content='Check for Updates' Height='40' Margin='0,10,0,0'/>
            <Button x:Name='btnInstallUpdates' Content='Install Updates' Height='40' Margin='0,10,0,0' IsEnabled='False'/>
            <ListBox x:Name='listUpdates' Height='140' Margin='0,20,0,0'/>
        </StackPanel>
    </Window>
"@

    $readerUpdates = New-Object System.Xml.XmlNodeReader ([System.Xml.XmlDocument]$xamlUpdates)
    $windowUpdates = [System.Windows.Markup.XamlReader]::Load($readerUpdates)

    # Get controls from the GUI
    $progressBar = $windowUpdates.FindName("progressBar")
    $btnCheckUpdates = $windowUpdates.FindName("btnCheckUpdates")
    $btnInstallUpdates = $windowUpdates.FindName("btnInstallUpdates")
    $listUpdates = $windowUpdates.FindName("listUpdates")

    # Ensure PSWindowsUpdate module is installed
    if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
        Install-Module -Name PSWindowsUpdate -Force -SkipPublisherCheck
    }

    # Function to toggle progress bar visibility
    function ToggleProgressBar {
        param($visible)
        $progressBar.Dispatcher.Invoke({
            $progressBar.Visibility = if ($visible) { 'Visible' } else { 'Hidden' }
            $progressBar.IsIndeterminate = $visible
        })
    }

    # Function to update the ListBox
    function UpdateListBox {
        param($updateText)
        $listUpdates.Dispatcher.Invoke({
            $listUpdates.Items.Add($updateText)
        })
    }

    # Event to check for updates
    $btnCheckUpdates.Add_Click({
        ToggleProgressBar $true
        $listUpdates.Dispatcher.Invoke({ $listUpdates.Items.Clear() })
        $btnInstallUpdates.Dispatcher.Invoke({ $btnInstallUpdates.IsEnabled = $false })

        Start-Job -ScriptBlock {
            Import-Module PSWindowsUpdate
            try {
                # Fetch updates one at a time
                $updates = Get-WindowsUpdate -AcceptAll -ErrorAction Stop
                foreach ($update in $updates) {
                    Write-Output $update
                }
            } catch {
                Write-Output $_
            }
        } | ForEach-Object {
            Receive-Job -Job $_ -Wait -AutoRemoveJob | ForEach-Object {
                if ($_ -is [System.Management.Automation.ErrorRecord]) {
                    [System.Windows.MessageBox]::Show("Failed to check for updates. Error: $($_.Exception.Message)", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
                } else {
                    $listUpdates.Dispatcher.Invoke({
                        $listUpdates.Items.Add("$($_.Title) [KB$($_.KBArticle)]")
                    })
                }
            }
        }

        ToggleProgressBar $false

        # Enable Install button if updates are listed
        if ($listUpdates.Items.Count -gt 0) {
            $btnInstallUpdates.Dispatcher.Invoke({ $btnInstallUpdates.IsEnabled = $true })
        }
    })

    # Event to install updates
    $btnInstallUpdates.Add_Click({
        ToggleProgressBar $true

        Start-Job -ScriptBlock {
            Import-Module PSWindowsUpdate
            try {
                # Install updates without forcing reboot
                Install-WindowsUpdate -AcceptAll -IgnoreReboot -ErrorAction Stop
            } catch {
                Write-Output $_
            }
        } | Receive-Job -Wait -AutoRemoveJob -OutVariable installResult

        ToggleProgressBar $false

        if ($installResult -is [System.Management.Automation.ErrorRecord]) {
            [System.Windows.MessageBox]::Show("Failed to install updates. Error: $($installResult.Exception.Message)", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
        } else {
            [System.Windows.MessageBox]::Show("Updates have been installed. A reboot may be required.", "Success", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
        }
    })

    # Show the updates window
    $windowUpdates.ShowDialog() | Out-Null
}


# Function: ShowProgressWindow
function ShowProgressWindow($title, $message) {
    $xamlProgress = @"
    <Window
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="$title" Height="200" Width="400"
        WindowStartupLocation="CenterScreen">
        <StackPanel>
            <Label Content="$message" FontSize="16" HorizontalAlignment="Center" Margin="10"/>
            <ProgressBar IsIndeterminate="True" Height="20" Margin="10"/>
        </StackPanel>
    </Window>
"@
    $readerProgress = New-Object System.Xml.XmlNodeReader ([System.Xml.XmlDocument]$xamlProgress)
    $windowProgress = [System.Windows.Markup.XamlReader]::Load($readerProgress)

    $null = $windowProgress.Show()
    return $windowProgress
}



function InstallDrivers {
    # Simulate driver installation
    [System.Windows.MessageBox]::Show("Installing drivers...Placeholder")
}

function ShowJoinDomainWindow {
    $xamlJoinDomain = @"
    <Window
        xmlns='http://schemas.microsoft.com/winfx/2006/xaml/presentation'
        xmlns:x='http://schemas.microsoft.com/winfx/2006/xaml'
        Title='Join Domain' Height='450' Width='450'
        WindowStartupLocation='CenterScreen'>
        <StackPanel Margin='10'>
            <Label Content='Domain Name:' FontWeight='Bold'/>
            <TextBox x:Name='txtDomain' Height='30' Margin='0,5,0,15'/>
            <Label Content='Computer Name:' FontWeight='Bold'/>
            <TextBox x:Name='txtComputerName' Height='30' Margin='0,5,0,15'/>
            <Label Content='Username:' FontWeight='Bold'/>
            <TextBox x:Name='txtUsername' Height='30' Margin='0,5,0,15'/>
            <Label Content='Password:' FontWeight='Bold'/>
            <PasswordBox x:Name='txtPassword' Height='30' Margin='0,5,0,15'/>
            <Button x:Name='joinButton' Content='Join Domain' Height='40' Margin='0,20,0,0'/>
        </StackPanel>
    </Window>
"@

    $readerJoinDomain = New-Object System.Xml.XmlNodeReader ([System.Xml.XmlDocument]$xamlJoinDomain)
    $windowJoinDomain = [System.Windows.Markup.XamlReader]::Load($readerJoinDomain)

    if (-not $windowJoinDomain) {
        throw "Failed to load the Join Domain window."
    }

    $txtDomain = $windowJoinDomain.FindName("txtDomain")
    $txtComputerName = $windowJoinDomain.FindName("txtComputerName")
    $txtUsername = $windowJoinDomain.FindName("txtUsername")
    $txtPassword = $windowJoinDomain.FindName("txtPassword")
    $joinButton = $windowJoinDomain.FindName("joinButton")

    if (-not $txtDomain -or -not $txtComputerName -or -not $txtUsername -or -not $txtPassword -or -not $joinButton) {
        throw "One or more controls could not be found in the Join Domain window."
    }

    $joinButton.Add_Click({
        $domain = $txtDomain.Text
        $computerName = $txtComputerName.Text
        $username = $txtUsername.Text
        $password = $txtPassword.Password

        if ([string]::IsNullOrWhiteSpace($domain) -or
            [string]::IsNullOrWhiteSpace($computerName) -or
            [string]::IsNullOrWhiteSpace($username) -or
            [string]::IsNullOrWhiteSpace($password)) {
            [System.Windows.MessageBox]::Show("All fields are required.", "Validation Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
            return
        }

        try {
            $securePassword = ConvertTo-SecureString $password -AsPlainText -Force
            $cred = New-Object System.Management.Automation.PSCredential ($username, $securePassword)
            Add-Computer -DomainName $domain -NewName $computerName -Credential $cred -Restart -ErrorAction Stop
            [System.Windows.MessageBox]::Show("Successfully joined the domain.", "Success", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
            $windowJoinDomain.Close()
        } catch {
            [System.Windows.MessageBox]::Show("Failed to join the domain. Error: $($_.Exception.Message)", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
        }
    })

    $windowJoinDomain.ShowDialog() | Out-Null
}


# Self-Elevation Check at the Start of the Script
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    # If not running as admin, relaunch the script as admin
    $scriptPath = $MyInvocation.MyCommand.Definition
    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
    Start-Process -FilePath "powershell.exe" -ArgumentList $arguments -Verb RunAs
    Exit
}


# Load required assemblies
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore

# Main Window XAML
$xamlMain = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="System Setup Utility" Height="350" Width="450"
    WindowStartupLocation="CenterScreen">
    <StackPanel VerticalAlignment="Center">
        <Button x:Name="btnInstallSoftware" Content="Install Software" Height="40" Margin="20" />
        <Button x:Name="btnWindowsUpdate" Content="Install Windows Updates" Height="40" Margin="20" />
        <Button x:Name="btnDriverInstall" Content="Install Drivers" Height="40" Margin="20" />
        <Button x:Name="btnJoinDomain" Content="Join Domain" Height="40" Margin="20" />
    </StackPanel>
</Window>
"@


# Load the main window
$readerMain = New-Object System.Xml.XmlNodeReader ([System.Xml.XmlDocument]$xamlMain)
$windowMain = [System.Windows.Markup.XamlReader]::Load($readerMain)

# Map buttons and add event handlers
$btnInstallSoftware = $windowMain.FindName("btnInstallSoftware")
$btnWindowsUpdate = $windowMain.FindName("btnWindowsUpdate")
$btnDriverInstall = $windowMain.FindName("btnDriverInstall")
$btnJoinDomain = $windowMain.FindName("btnJoinDomain")

$btnInstallSoftware.Add_Click({ ShowSoftwareInstallWindow })
$btnWindowsUpdate.Add_Click({ InstallWindowsUpdates })
$btnDriverInstall.Add_Click({ InstallDrivers })
$btnJoinDomain.Add_Click({ ShowJoinDomainWindow })

# Show the main window
$windowMain.ShowDialog() | Out-Null
