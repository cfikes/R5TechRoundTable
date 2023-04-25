<#
.SYNOPSIS

TightVNC Sever Deployment Tool PS5 Helper

.DESCRIPTION

.Not Used By Itself

.EXAMPLE

.Not Used By Itself

.NOTES

.Not Used By Itself

.LINK

https://fikesmedia.com
#>

param(
    [string]$ThisComputer,
    [string]$OTPPassword
)

# Hide the console window
Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("Kernel32.dll")]
public static extern IntPtr GetConsoleWindow();

[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);'

[Console.Window]::ShowWindow([Console.Window]::GetConsoleWindow(), 0)

# Deploy
Start-Process Powershell.exe -ArgumentList "-file `"$(Get-Location)\Deploy-TightVNC.ps1`" -ComputerName $($ThisComputer) -VNCPassword $OTPPassword" -Verb RunAs -Wait
# Connect
Start-Process -FilePath "tvnviewer.exe" -ArgumentList "`"$ThisComputer`" -password=$OTPPassword -scale=auto" -Wait
# Remove
Start-Process Powershell.exe -ArgumentList "-file `"$(Get-Location)\Deploy-TightVNC.ps1`" -ComputerName $($ThisComputer) -Remove" -Verb RunAs 