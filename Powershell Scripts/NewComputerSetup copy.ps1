# Load required assemblies
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore

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

# XAML Definition as a PowerShell multi-line string
$xaml = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="New Machine Setup" Height="350" Width="450"
    WindowStartupLocation="CenterScreen">
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Margin" Value="10"/>
            <Setter Property="Padding" Value="5"/>
            <Setter Property="Background" Value="#FF1E90FF"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="BorderBrush" Value="#FF1E90FF"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Effect">
                <Setter.Value>
                    <DropShadowEffect Color="Black" Direction="320" ShadowDepth="3" Opacity="0.5"/>
                </Setter.Value>
            </Setter>
        </Style>
        <Style TargetType="CheckBox">
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="FontWeight" Value="Medium"/>
            <Setter Property="Margin" Value="5"/>
        </Style>
        <Style TargetType="TextBox">
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="Margin" Value="10"/>
            <Setter Property="Height" Value="30"/>
        </Style>
        <Style TargetType="Label">
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="Margin" Value="5"/>
        </Style>
    </Window.Resources>
    <StackPanel>
        <Label Content="Select Software to Install:" FontWeight="Bold"/>
        <ScrollViewer Height="150">
            <StackPanel x:Name="softwarePanel">
            </StackPanel>
        </ScrollViewer>
        <Button x:Name="btnInstallSoftware" Content="Install Software"/>
        <Button x:Name="btnJoinDomain" Content="Join Domain"/>
    </StackPanel>
</Window>
"@

# Convert the XAML string to WPF objects
$reader = New-Object System.Xml.XmlNodeReader ([System.Xml.XmlDocument]($xaml))
$window = [System.Windows.Markup.XamlReader]::Load($reader)

# Map the controls
$softwarePanel = $window.FindName("softwarePanel")
$btnInstallSoftware = $window.FindName("btnInstallSoftware")
$btnJoinDomain = $window.FindName("btnJoinDomain")

# Dynamically create checkboxes based on the software list
foreach ($software in $softwareList) {
    $checkBox = New-Object System.Windows.Controls.CheckBox
    $checkBox.Content = $software.Name
    $checkBox.Tag = $software.Id
    $softwarePanel.Children.Add($checkBox)
}

# Event for installing software
$btnInstallSoftware.Add_Click({
    $softwarePanel.Children | Where-Object { $_.IsChecked } | ForEach-Object {
        Start-Process "winget" -ArgumentList "install --id $($_.Tag) -e" -NoNewWindow -Wait
    }
})

# Event for opening the domain join dialog
$btnJoinDomain.Add_Click({
    # Define another window for domain joining details
    $domainXaml = @"
    <Window
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Join Domain" Height="480" Width="400"
        WindowStartupLocation="CenterScreen" ResizeMode="CanMinimize"
        WindowStyle="SingleBorderWindow">
        <Window.Resources>
            <Style TargetType="TextBox">
                <Setter Property="Margin" Value="10"/>
                <Setter Property="FontSize" Value="14"/>
                <Setter Property="Height" Value="30"/>
                <Setter Property="VerticalContentAlignment" Value="Center"/>
            </Style>
            <Style TargetType="PasswordBox">
                <Setter Property="Margin" Value="10"/>
                <Setter Property="FontSize" Value="14"/>
                <Setter Property="Height" Value="30"/>
                <Setter Property="VerticalContentAlignment" Value="Center"/>
            </Style>
            <Style TargetType="Button">
            <Setter Property="Margin" Value="10"/>
            <Setter Property="Padding" Value="5"/>
            <Setter Property="Background" Value="#FF1E90FF"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="BorderBrush" Value="#FF1E90FF"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Effect">
                <Setter.Value>
                    <DropShadowEffect Color="Black" Direction="320" ShadowDepth="3" Opacity="0.5"/>
                </Setter.Value>
            </Setter>
        </Style>
            <Style TargetType="Label">
                <Setter Property="Margin" Value="10,10,10,0"/>
                <Setter Property="FontSize" Value="14"/>
                <Setter Property="VerticalAlignment" Value="Center"/>
            </Style>
        </Window.Resources>
        <StackPanel>
            <Label Content="Domain Name:"/>
            <TextBox x:Name="txtDomain"/>
            <Label Content="Computer Name:"/>
            <TextBox x:Name="txtComputerName"/>
            <Label Content="Username:"/>
            <TextBox x:Name="txtUsername"/>
            <Label Content="Password:"/>
            <PasswordBox x:Name="txtPassword"/>
            <Button x:Name="okJoinDomain" Content="Join Domain" />
        </StackPanel>
    </Window>
"@

    $reader = New-Object System.Xml.XmlNodeReader ([System.Xml.XmlDocument]($domainXaml))
    $domainWindow = [System.Windows.Markup.XamlReader]::Load($reader)
    $btnJoin = $domainWindow.FindName("okJoinDomain")

    $btnJoin.Add_Click({
        $domain = $domainWindow.FindName("txtDomain").Text
        $computerName = $domainWindow.FindName("txtComputerName").Text
        $username = $domainWindow.FindName("txtUsername").Text
        $password = $domainWindow.FindName("txtPassword").SecurePassword
        $cred = New-Object System.Management.Automation.PSCredential ($username, $password)
        Add-Computer -DomainName $domain -NewName $computerName -Credential $cred -Restart
        $domainWindow.Close()
    })

    $domainWindow.ShowDialog() | Out-Null
})

# Show the main window
$window.ShowDialog() | Out-Null
