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

# Add Assemblies for XAML
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

# Import XAML Window
[xml]$XAML = Get-Content "MainWindow.xaml"
$XAML.Window.RemoveAttribute('x:Class')
$XAML.Window.RemoveAttribute('mc:Ignorable')
$XAMLReader = New-Object System.Xml.XmlNodeReader $XAML
$MainWindow = [Windows.Markup.XamlReader]::Load($XAMLReader)

# Create UI Elements
$XAML.SelectNodes("//*[@Name]") | ForEach-Object{Set-Variable -Name ($_.Name) -Value $MainWindow.FindName($_.Name)}

# Define ListBox
$ComputerListBox = $MainWindow.FindName("ComputerList")

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
        Start-Process -FilePath "tvnviewer.exe" -ArgumentList $ComputerListBox.SelectedItem
    }
})

$MainWindow.FindName("DeployBTN").add_click({
    if ([string]::IsNullOrEmpty($MainWindow.FindName("VNCPassword").Text) -or [string]::IsNullOrEmpty($ComputerListBox.SelectedItem) ) {
        [System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')
        [System.Windows.Forms.MessageBox]::Show('You must select a machine and set password before deployment.','ERROR')
    } else {
        Start-Process Powershell.exe -ArgumentList "-file `"$(Get-Location)\Deploy-TightVNC.ps1`" -ComputerName $($ComputerListBox.SelectedItem) -VNCPassword $($MainWindow.FindName("VNCPassword").Text)" -Verb RunAs 
    }
    
    
})

$MainWindow.FindName("UninstallBTN").add_click({
    if ([string]::IsNullOrEmpty($ComputerListBox.SelectedItem) ) {
        [System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')
        [System.Windows.Forms.MessageBox]::Show('You must select a machine before removal.','ERROR')
    } else {
        Start-Process Powershell.exe -ArgumentList "-file `"$(Get-Location)\Deploy-TightVNC.ps1`" -ComputerName $($ComputerListBox.SelectedItem) -Remove" -Verb RunAs 
    }
})

# Show MainWindow
$MainWindow.ShowDialog() | Out-Null