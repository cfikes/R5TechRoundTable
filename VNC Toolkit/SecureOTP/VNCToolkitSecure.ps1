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

# Hide the console window
Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("Kernel32.dll")]
public static extern IntPtr GetConsoleWindow();

[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);'

[Console.Window]::ShowWindow([Console.Window]::GetConsoleWindow(), 0)


# Add Assemblies for XAML
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

# Import XAML Window
[xml]$XAML = Get-Content "MainWindowSecure.xaml"
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

# Generate Secure Password
Function Get-RandomPassword {
    #define parameters
    param([int]$PasswordLength = 8)
 
    #ASCII Character set for Password
    $CharacterSet = @{
            Uppercase   = (97..122) | Get-Random -Count 10 | % {[char]$_}
            Lowercase   = (65..90)  | Get-Random -Count 10 | % {[char]$_}
            Numeric     = (48..57)  | Get-Random -Count 10 | % {[char]$_}
            #SpecialChar = (33..47)+(58..64)+(91..96)+(123..126) | Get-Random -Count 10 | ForEach-Object {[char]$_}
    }
 
    #Frame Random Password from given character set
    $StringSet = $CharacterSet.Uppercase + $CharacterSet.Lowercase + $CharacterSet.Numeric #+ $CharacterSet.SpecialChar
 
    -join(Get-Random -Count $PasswordLength -InputObject $StringSet)
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
        Start-ThreadJob -Name "TEST" -ScriptBlock {
            $ThisComputer = $args[0]
            $OTPPassword = $args[1]
            # Deploy
            Start-Process Powershell.exe -ArgumentList "-file `"$(Get-Location)\Deploy-TightVNC.ps1`" -ComputerName $($ThisComputer) -VNCPassword $OTPPassword" -Verb RunAs -Wait
            # Connect
            Start-Process -FilePath "tvnviewer.exe" -ArgumentList "`"$ThisComputer`" -password=$OTPPassword -scale=auto" -Wait
            # Remove
            Start-Process Powershell.exe -ArgumentList "-file `"$(Get-Location)\Deploy-TightVNC.ps1`" -ComputerName $($ThisComputer) -Remove" -Verb RunAs 
        } -ArgumentList $ComputerListBox.SelectedItem,$(Get-RandomPassword -PasswordLength 8)
        
    }
})


# Show MainWindow
$MainWindow.ShowDialog() | Out-Null