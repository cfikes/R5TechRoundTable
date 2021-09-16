<#
.SYNOPSIS

Edits settings for Open Roster SFTP AD Sync

.DESCRIPTION

Edits settings for Open Roster SFTP AD Sync

.Example

SettingsEditor.ps1

.NOTES

Creates a default database.

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

<# Functions #>
function RefreshForm(){
    # Setup Local Settings Window
    $MainWindow.FindName("ReportLocation").Text = $Settings.ReportDir
    $MainWindow.FindName("StudentDomain").Text = $Settings.ADDomain
    $MainWindow.FindName("StudentEmailDomain").Text = $Settings.EMailDomain
    $MainWindow.FindName("OUSearchString").Text = $Settings.OUSearch
    $MainWindow.FindName("UsernameFormat").SelectedIndex = $Settings.UsernameFormat - 1
    $MainWindow.FindName("EmailFormat").SelectedIndex = $Settings.EmailFormat - 1
    $MainWindow.FindName("PasswordFormat").SelectedIndex = $Settings.PasswordFormat - 1
    $MainWindow.FindName("DefaultPassword").Text = $Settings.DefaultPassword
    $MainWindow.FindName("DefaultGroup").Text = $Settings.DefaultGroup
    $MainWindow.FindName("HomeDir").Text = $Settings.HomeDir
    if ($Settings.EnableCreation -eq $true){
        $MainWindow.FindName("EnableCreation").IsChecked = $true
    } else {
        $MainWindow.FindName("EnableCreation").IsChecked = $false
    }
    
    if ($Settings.EnableSuspension -eq $true){
        $MainWindow.FindName("EnableSuspension").IsChecked = $true
    } else {
        $MainWindow.FindName("EnableSuspension").IsChecked = $false
    }

    #SFTP Settings
    $MainWindow.FindName("SFTPServer").Text = $Settings.SFTPServer
    $MainWindow.FindName("SFTPPort").Text = $Settings.SFTPPort
    $MainWindow.FindName("SFTPUsername").Text = $Settings.SFTPUsername
    $MainWindow.FindName("SFTPPassword").Text = $Settings.SFTPPassword
    $MainWindow.FindName("RemoteFile").Text = $Settings.SFTPFile

    #SMTP Settings
    $MainWindow.FindName("SMTPServer").Text = $Settings.SMTPServer
    $MainWindow.FindName("SMTPPort").Text = $Settings.SMTPPort
    $MainWindow.FindName("SMTPUsername").Text = $Settings.SMTPUsername
    $MainWindow.FindName("SMTPPassword").Text = $Settings.SMTPPassword
    $MainWindow.FindName("SMTPSubject").Text = $Settings.SMTPSubject
    $MainWindow.FindName("SMTPDestination").Text = $Settings.SMTPDestination

    if($Settings.SMTPSSLEnable -eq $true) {
        $MainWindow.FindName("SMTPSSLEnable").IsChecked = $true
    } else {
        $MainWindow.FindName("SMTPSSLEnable").IsChecked = $false
    }

    if($Settings.SMTPEnable -eq $true) {
        $MainWindow.FindName("SMTPEnable").IsChecked = $true
    } else {
        $MainWindow.FindName("SMTPEnable").IsChecked = $false
    }
}


function GenerateNewSettings(){
    $Settings = New-Object -TypeName psobject
    $Settings | Add-Member -NotePropertyName ReportDir -NotePropertyValue "C:\Reports\"
    $Settings | Add-Member -NotePropertyName ADDomain -NotePropertyValue "domain.local"
    $Settings | Add-Member -NotePropertyName EMailDomain -NotePropertyValue "domain.net"
    $Settings | Add-Member -NotePropertyName UsernameFormat -NotePropertyValue 6
    $Settings | Add-Member -NotePropertyName EmailFormat -NotePropertyValue 6
    $Settings | Add-Member -NotePropertyName OUSearch -NotePropertyValue "Class"
    $Settings | Add-Member -NotePropertyName PasswordFormat -NotePropertyValue 6
    $Settings | Add-Member -NotePropertyName DefaultPassword -NotePropertyValue "P@ssword"
    $Settings | Add-Member -NotePropertyName DefaultGroup -NotePropertyValue ""
    $Settings | Add-Member -NotePropertyName HomeDir -NotePropertyValue ""
    $Settings | Add-Member -NotePropertyName EnableCreation -NotePropertyValue true
    $Settings | Add-Member -NotePropertyName EnableSuspension -NotePropertyValue false
    $Settings | Add-Member -NotePropertyName SMTPServer -NotePropertyValue "smtp.gmail.com"
    $Settings | Add-Member -NotePropertyName SMTPSSLEnable -NotePropertyValue true
    $Settings | Add-Member -NotePropertyName SMTPPort -NotePropertyValue 587
    $Settings | Add-Member -NotePropertyName SMTPUsername -NotePropertyValue "account@domain.net"
    $Settings | Add-Member -NotePropertyName SMTPPassword -NotePropertyValue "P@ssword"
    $Settings | Add-Member -NotePropertyName SMTPSubject -NotePropertyValue "New User Accounts"
    $Settings | Add-Member -NotePropertyName SMTPDestination -NotePropertyValue "user@domain.net"
    $Settings | Add-Member -NotePropertyName SMTPEnable -NotePropertyValue true
    $Settings | Add-Member -NotePropertyName SFTPServer -NotePropertyValue "sftp://127.0.0.1"
    $Settings | Add-Member -NotePropertyName SFTPPort -NotePropertyValue 22
    $Settings | Add-Member -NotePropertyName SFTPUsername -NotePropertyValue "sftpuser"
    $Settings | Add-Member -NotePropertyName SFTPPassword -NotePropertyValue "sftppassword"
    $Settings | Add-Member -NotePropertyName SFTPFile -NotePropertyValue "students.csv"

    $Settings | Export-Clixml Settings.xml

    RefreshForm
}


function SaveSettings(){
    try {
        $Settings = New-Object -TypeName psobject
        
        $Settings | Add-Member -NotePropertyName ReportDir -NotePropertyValue $MainWindow.FindName("ReportLocation").Text
        $Settings | Add-Member -NotePropertyName ADDomain -NotePropertyValue $MainWindow.FindName("StudentDomain").Text
        $Settings | Add-Member -NotePropertyName EMailDomain -NotePropertyValue $MainWindow.FindName("StudentEmailDomain").Text
        $Settings | Add-Member -NotePropertyName UsernameFormat -NotePropertyValue $($MainWindow.FindName("UsernameFormat").SelectedIndex + 1)
        $Settings | Add-Member -NotePropertyName EmailFormat -NotePropertyValue $($MainWindow.FindName("EmailFormat").SelectedIndex + 1)
        $Settings | Add-Member -NotePropertyName OUSearch -NotePropertyValue $MainWindow.FindName("OUSearchString").Text
        $Settings | Add-Member -NotePropertyName PasswordFormat -NotePropertyValue $($MainWindow.FindName("PasswordFormat").SelectedIndex + 1)
        $Settings | Add-Member -NotePropertyName DefaultPassword -NotePropertyValue $MainWindow.FindName("DefaultPassword").Text
        $Settings | Add-Member -NotePropertyName DefaultGroup -NotePropertyValue $MainWindow.FindName("DefaultGroup").Text
        $Settings | Add-Member -NotePropertyName HomeDir -NotePropertyValue $MainWindow.FindName("HomeDir").Text

        if ($MainWindow.FindName("EnableCreation").IsChecked -eq $true){
            $Settings | Add-Member -NotePropertyName EnableCreation -NotePropertyValue true 
        } else {
            $Settings | Add-Member -NotePropertyName EnableCreation -NotePropertyValue false
        }
        
        if ($MainWindow.FindName("EnableSuspension").IsChecked -eq $true){
            $Settings | Add-Member -NotePropertyName EnableSuspension -NotePropertyValue true 
        } else {
            $Settings | Add-Member -NotePropertyName EnableSuspension -NotePropertyValue false
        }

        $Settings | Add-Member -NotePropertyName SMTPServer -NotePropertyValue $MainWindow.FindName("SMTPServer").Text
        
        if($MainWindow.FindName("SMTPSSLEnable").IsChecked -eq $true) {
            $Settings | Add-Member -NotePropertyName SMTPSSLEnable -NotePropertyValue true
        } else {
            $Settings | Add-Member -NotePropertyName SMTPSSLEnable -NotePropertyValue false
        }
        
        $Settings | Add-Member -NotePropertyName SMTPPort -NotePropertyValue $MainWindow.FindName("SMTPPort").Text
        $Settings | Add-Member -NotePropertyName SMTPUsername -NotePropertyValue $MainWindow.FindName("SMTPUsername").Text
        $Settings | Add-Member -NotePropertyName SMTPPassword -NotePropertyValue $MainWindow.FindName("SMTPPassword").Text
        $Settings | Add-Member -NotePropertyName SMTPSubject -NotePropertyValue $MainWindow.FindName("SMTPSubject").Text
        $Settings | Add-Member -NotePropertyName SMTPDestination -NotePropertyValue $MainWindow.FindName("SMTPDestination").Text

        if($MainWindow.FindName("SMTPEnable").IsChecked -eq $true) {
            $Settings | Add-Member -NotePropertyName SMTPEnable -NotePropertyValue true
        } else {
            $Settings | Add-Member -NotePropertyName SMTPEnable -NotePropertyValue false
        }
        
        $Settings | Add-Member -NotePropertyName SFTPServer -NotePropertyValue $MainWindow.FindName("SFTPServer").Text
        $Settings | Add-Member -NotePropertyName SFTPPort -NotePropertyValue $MainWindow.FindName("SFTPPort").Text
        $Settings | Add-Member -NotePropertyName SFTPUsername -NotePropertyValue $MainWindow.FindName("SFTPUsername").Text
        $Settings | Add-Member -NotePropertyName SFTPPassword -NotePropertyValue $MainWindow.FindName("SFTPPassword").Text
        $Settings | Add-Member -NotePropertyName SFTPFile -NotePropertyValue $MainWindow.FindName("RemoteFile").Text

        # Save XML File
        $Settings | Export-Clixml Settings.xml

        $MainWindow.FindName("StatusMessage").Text = "Settings Updated"

        # Refresh from XML
        RefreshForm
    }
    catch {
        $MainWindow.FindName("StatusMessage").Text = "Error Saving Settings !"

    }
    
}

function CheckInstallation(){

    $WinSCP = "WinSCPnet.dll"
    $InfoPanelText = "Installation Status Report`n`n"

    # Check WinSCP Installation
    if(Test-Path $WinSCP) {
        $InfoPanelText = $InfoPanelText + "WinSCP:`t`tPresent`n"        
    } else {
        $InfoPanelText = $InfoPanelText + "WinSCP:`t`tMissing. Please install from WinSCP.net`n"
    }
    
    # Check Report Directory
    if(Test-Path $Settings.ReportDir) {
        $InfoPanelText = $InfoPanelText + "Report Directory:`tPresent`n"
    } else {
        $InfoPanelText = $InfoPanelText + "Report Directory:`tReport Directory invalid.`n"
    }

    # Check for AD Module
    if (Get-Module -ListAvailable -Name ActiveDirectory) {
        $InfoPanelText = $InfoPanelText + "AD Module:`tPresent`n"
    } 
    else {
        $InfoPanelText = $InfoPanelText + "AD Module:`tMissing. Install Active Directory Powershell tools.`n"
    }

    $MainWindow.FindName("InstallationCheck").Text = $InfoPanelText

}

<# Initialisation #>

$MainWindow.Add_ContentRendered({
    <# Import Settings From XML #>
    try {
        $Settings = Import-Clixml -Path Settings.xml
        RefreshForm
        CheckInstallation
    } catch {
        GenerateNewSettings
    }

})

<# Window Interaction #>
$MainWindow.FindName("SaveButton").add_click({
    SaveSettings
    $Settings = Import-Clixml -Path Settings.xml
    RefreshForm
    CheckInstallation
})

# Show MainWindow
$MainWindow.ShowDialog() | Out-Null