<#
.SYNOPSIS

Creates Active Directory Student Accounts from a SFTP sourced Open Roster Compliant Students CSV

.DESCRIPTION

Creates Active Directory Student Accounts from a SFTP sourced Open Roster Compliant Students CSV

.EXAMPLE

OpenRosterSFTPSync.ps1

.Example

SettingsEditor.ps1

.NOTES

Use SettingsEditor.ps1 to configure.

.LINK

https://fikesmedia.com
#>

#
# Download File from SFTP to specified location.
function DownloadStudentCSV() {
    
    param (
        $SFTPServer, 
        $SFTPPort,
        $SFTPUsername, 
        $SFTPPassword, 
        $SFTPLocation, 
        $LocalLocation 
    )

    # Load WinSCP .NET assembly
    $WinSCP = "WinSCPnet.dll"
    Add-Type -Path $WinSCP

    # Set up session options
    $sessionOptions = New-Object WinSCP.SessionOptions -Property @{
        Protocol = [WinSCP.Protocol]::Sftp
        HostName = $SFTPServer
        UserName = $SFTPUsername
        Password = $SFTPPassword
        PortNumber = $SFTPPort
        GiveUpSecurityAndAcceptAnySshHostKey = $true
    }

    $sessionOptions.AddRawSettings("FSProtocol", "2")

    $session = New-Object WinSCP.Session

    try
    {
        # Connect
        $session.Open($sessionOptions)

        # Transfer files
        $session.GetFiles($SFTPLocation, $LocalLocation).Check()
    }
    finally
    {
        $session.Dispose()
        
    }
}
# END Download File from SFTP to specified location. 

#
# Email Report 
function EmailReport() {
    param(
        $SMTPServer,
        $SMTPPort,
        $SMTPSSL,
        $SMTPUsername,
        $SMTPPassword,
        $SMTPDestination,
        $SMTPSubject,
        $SMTPBody,
        $SMTPAttachments
    )

    # New Message Object
    $Message = new-object Net.Mail.MailMessage
    $Message.Sender =  $SMTPUsername
    $Message.From = $SMTPUsername
    $Message.To.add($SMTPDestination)
    $Message.SubjectEncoding = [system.Text.Encoding]::Unicode
    $Message.Subject = $SMTPSubject
    #$Message.BodyEncoding = [system.Text.Encoding]::Unicode
    $Message.IsBodyHtml = $true
    $Message.Body = $SMTPBody
    #Add Attachments
    if ($SMTPAttachments.count -gt 0 ) {
        foreach ($Attachment in $SMTPAttachments) {
            $Message.Attachments.Add($Attachment)
        }
    }

    # SMTP Settings
    $SMTP = new-object Net.Mail.SmtpClient($SMTPServer,$SMTPPort)
    $SMTP.EnableSsl = $SMTPSSL
    $SMTP.Credentials = New-Object System.Net.NetworkCredential($SMTPUsername,$SMTPPassword)
    try {
        $SMTP.Send($Message)
    } catch {
        Write-Host $_
    }   
}
# END Email Report 


#
# Create Report Template CSV
function CreateReport() {
    
    param(
        $LocalLocation
    )

    $CSVHeader = @(
        '"Status","DisplayName","Username","Email","StudentID","PasswordClear","Class","OU","Message"'
    )

    try {
        $CSVHeader | ForEach-Object { Add-Content -Path $LocalLocation -Value $_ } 
    } catch {
        Write-Host $_
    }

}
# END Create Report Template CSV


#
# Add Report Entry
function AddReportEntry() {

    param (
        $LocalLocation,
        $Status,
        $Username,
        $DisplayName,
        $Email,
        $StudentID,
        $PasswordClear,
        $Class,
        $OU,
        $Message
    )

       #$CSVContent = $Status+","+"$DisplayName"+","+$Username+","+$Email+","+$StudentID+","+$PasswordClear+","+$Class+","+$OU+","+$Message
       $CSVContent = "`""+$Status+"`",`""+"$DisplayName"+"`",`""+$Username+"`",`""+$Email+"`",`""+$StudentID+"`",`""+$PasswordClear+"`",`""+$Class+"`",`""+$OU+"`",`""+$Message+"`""

    try {
        Add-Content -Path $LocalLocation -Value $CSVContent
    } catch {
        Write-Host $_
    }
    
}
# END Add Report Entry


#
# Check if student already exist
function CheckExistingStudent(){
    param (
        $SAMUsername
    )
    # Check If User Exist
    $UserAlreadyExist = Get-ADUser -Filter "sAMAccountName -eq '$SAMUsername'" -Properties sAMAccountName | Measure-Object | Select-Object -ExpandProperty Count
    # Build Boolean response
    if ($UserAlreadyExist -eq 0) {
        return $false
    } else {
        return $true
    }
}


#
# Enable Student account from previously unenrolled and reset password.
function CheckPreviousUnenrolled(){
    param (
        $NewStudentAccount
    )

    # Get Existing Account for comparrison
    $ExistingStudent = Get-ADUser -Identity $NewStudentAccount.SAMUsername -Properties Givenname,Surname,EmployeeID,Enabled

    # If all details match, update account and enable
    If(($NewStudentAccount.SAMUsername -eq $ExistingStudent.SamAccountName) -and ($NewStudentAccount.FirstName -eq $ExistingStudent.GivenName) -and ($NewStudentAccount.LastName -eq $ExistingStudent.Surname) -and ($NewStudentAccount.EmployeeID -eq $ExistingStudent.EmployeeID) -and ($ExistingStudent.Enable -eq $false)) {
        if($Settings.EnableCreation -eq $true) {
            Try {
                Set-ADUser -Identity $NewStudentAccount.SAMUsername -Name $NewStudentAccount.DisplayName -DisplayName $NewStudentAccount.DisplayName -EmailAddress $NewStudentAccount.Email -AccountPassword $NewStudentAccount.PasswordSecure -OtherAttributes @{'pager'=$NewStudentAccount.Pager;'employeeid'=$NewStudentAccount.EmployeeID}
                Enable-ADAccount -Identity $NewStudentAccount.SAMUsername
                AddReportEntry -LocalLocation $ReportFile.toString() -Status "Enabled" -DisplayName $NewStudentAccount.DisplayName -UserName $NewStudentAccount.SAMUsername -Email $NewStudentAccount.Email -StudentID $NewStudentAccount.EmployeeID -PasswordClear $NewStudentAccount.PasswordClear -Class $NewStudentAccount.ClassOf -OU $NewStudentAccount.OU -Message "Previous Student"
                $ReportEnabledPrevious += 1
            } Catch {
                AddReportEntry -LocalLocation $ReportFile.toString() -Status "Error" -DisplayName $NewStudentAccount.DisplayName -UserName $NewStudentAccount.SAMUsername -Email $NewStudentAccount.Email -StudentID $NewStudentAccount.EmployeeID -PasswordClear $NewStudentAccount.PasswordClear -Class $NewStudentAccount.ClassOf -OU $NewStudentAccount.OU -Message "Error Enabling Previous Student"
                $global:ReportErrorsLogged += 1
            }
        } else {
            AddReportEntry -LocalLocation $ReportFile.toString() -Status "Audit Enabled" -DisplayName $NewStudentAccount.DisplayName -UserName $NewStudentAccount.SAMUsername -Email $NewStudentAccount.Email -StudentID $NewStudentAccount.EmployeeID -PasswordClear $NewStudentAccount.PasswordClear -Class $NewStudentAccount.ClassOf -OU $NewStudentAccount.OU -Message "Previous Student"
        }
    }
}

#
# Execution of Account Creation
function CreateNewStudentAccount() {  
    param (
        $NewStudentAccount
    )


    if($Settings.EnableCreation -eq $true) {
        Try {
            # Create user and enable
            New-ADUser -Path $NewStudentAccount.OU -SamAccountName $NewStudentAccount.SAMUsername -Name $NewStudentAccount.DisplayName -DisplayName $NewStudentAccount.DisplayName -GivenName $NewStudentAccount.FirstName -Surname $NewStudentAccount.LastName -EmailAddress $NewStudentAccount.Email -AccountPassword $NewStudentAccount.PasswordSecure -OtherAttributes @{'pager'=$NewStudentAccount.Pager;'employeeid'=$NewStudentAccount.EmployeeID} -ErrorAction Stop
            Set-AdUser -UserPrincipalName $NewStudentAccount.UserPrincipalName -Identity $NewStudentAccount.SAMUsername
            Enable-ADAccount -Identity $NewStudentAccount.SAMUsername
            # Add User to Students Group
            if (-not([string]::IsNullOrEmpty($Settings.DefaultGroup))) {
                Try {
                    Add-ADGroupMember -Identity $Settings.DefaultGroup -Members $NewStudentAccount.SAMUsername
                } Catch {
                    AddReportEntry -LocalLocation $ReportFile.toString() -Status "Error" -DisplayName $NewStudentAccount.DisplayName -UserName $NewStudentAccount.SAMUsername -Email $NewStudentAccount.Email -StudentID $NewStudentAccount.EmployeeID -PasswordClear $NewStudentAccount.PasswordClear -Class $NewStudentAccount.ClassOf -OU $NewStudentAccount.OU -Message "Could not assign group membership"    
                    $global:ReportErrorsLogged += 1
                }
            }
            # Create HomeDirectory if setting exist
            Try {
                if (-not([string]::IsNullOrEmpty($Settings.HomeDir))) {
                    if (Test-Path -Path $Settings.HomeDir) {
                        # Check for path and create if doesnt exist
                        $UserHomeDir = Join-Path -Path $Settings.HomeDir -ChildPath $NewStudentAccount.SAMUsername
                        if(-not(Test-Path $UserHomeDir -PathType Container)){
                            New-Item -Path $UserHomeDir -ItemType Directory
                        } else {
                            AddReportEntry -LocalLocation $ReportFile.toString() -Status "Error" -DisplayName $NewStudentAccount.DisplayName -UserName $NewStudentAccount.SAMUsername -Email $NewStudentAccount.Email -StudentID $NewStudentAccount.EmployeeID -PasswordClear $NewStudentAccount.PasswordClear -Class $NewStudentAccount.ClassOf -OU $NewStudentAccount.OU -Message "Home Directory Already Exist"
                        }
                        # Set Security for folder
                        # Create Group Strings
                        $UserPerm = $Settings.ADDomain.ToString() + "\" + $NewStudentAccount.SAMUsername.toString()
                        $AdminGroupPerm = $Settings.ADDomain.ToString() + "\Domain Admins"
                        # Set Owner
                        $FolderACL = Get-Acl -Path $UserHomeDir
                        $AccessRule = New-Object System.Security.Principal.NTAccount("Builtin", "Administrators")
                        $FolderACL.SetOwner($AccessRule)
                        $FolderACL | Set-Acl -Path $UserHomeDir
                        # Add User to Folder
                        $FolderACL = Get-Acl -Path $UserHomeDir
                        $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("$UserPerm","FullControl","ContainerInherit,ObjectInherit", "None", "Allow")
                        $FolderACL.SetAccessRule($AccessRule)
                        $FolderACL | Set-Acl -Path $UserHomeDir
                        # Add Domain Admin to Folder
                        $FolderACL = Get-Acl -Path $UserHomeDir
                        $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("$AdminGroupPerm","FullControl","ContainerInherit,ObjectInherit", "None", "Allow")
                        $FolderACL.SetAccessRule($AccessRule)
                        $FolderACL | Set-Acl -Path $UserHomeDir
                        # Remove Inheritance and any 
                        $FolderACL = Get-Acl -Path $UserHomeDir
                        $FolderACL.SetAccessRuleProtection($true,$false)
                        $FolderACL | Set-Acl -Path $UserHomeDir
                        # END CREATE HOME DIR
                        # Assign Home Directory
                        Set-ADUser -Identity $NewStudentAccount.SAMUsername -HomeDirectory $UserHomeDir -HomeDrive H
                    }
                }
            } Catch {
                AddReportEntry -LocalLocation $ReportFile.toString() -Status "Error" -DisplayName $NewStudentAccount.DisplayName -UserName $NewStudentAccount.ReportedUsername -Email $NewStudentAccount.Email -StudentID $NewStudentAccount.EmployeeID -PasswordClear $NewStudentAccount.PasswordClear -Class $NewStudentAccount.ClassOf -OU $NewStudentAccount.OU -Message "Failed to create home directory"
                $global:ReportErrorsLogged += 1
            }
            #Everything Completed successfully
            AddReportEntry -LocalLocation $ReportFile.toString() -Status "Complete" -DisplayName $NewStudentAccount.DisplayName -UserName $NewStudentAccount.ReportedUsername -Email $NewStudentAccount.Email -StudentID $NewStudentAccount.EmployeeID -PasswordClear $NewStudentAccount.PasswordClear -Class $NewStudentAccount.ClassOf -OU $NewStudentAccount.OU -Message ""
            $ReportCreatedAccounts += 1
        } Catch {
            # Output error to screen
            Write-Host $_
            # Log Error to Report
            AddReportEntry -LocalLocation $ReportFile.toString() -Status "Failure" -DisplayName $NewStudentAccount.DisplayName -UserName $NewStudentAccount.ReportedUsername -Email $NewStudentAccount.Email -StudentID $NewStudentAccount.EmployeeID -PasswordClear $NewStudentAccount.PasswordClear -Class $NewStudentAccount.ClassOf -OU $NewStudentAccount.OU -Message "Failure to create user"
            $ReportFailuresLogged += 1
        }
    } else {
        AddReportEntry -LocalLocation $ReportFile.toString() -Status "Audit Creation" -DisplayName $NewStudentAccount.DisplayName -UserName $NewStudentAccount.ReportedUsername -Email $NewStudentAccount.Email -StudentID $NewStudentAccount.EmployeeID -PasswordClear $NewStudentAccount.PasswordClear -Class $NewStudentAccount.ClassOf -OU $NewStudentAccount.OU -Message "Account not created. AUDIT MODE"
    }
}
# END Execution of Account Creation


#
# Disable Active Accounts Not Enrolled
function DisableUnEnrolled(){
    param(
        $EnrolledUsers
    )

    $ActiveUsers = @()
    # Get Active Users in each OU
    ForEach($OUPath in $OUList) {
        $Users = Get-ADUser -Filter * -SearchBase $OUpath | Where-Object { $_.Enabled -eq $True} | Select-Object -ExpandProperty SAMAccountName
        ForEach($User in $Users){
            $ActiveUsers += $User
        }
    }

    # If User not present in Enrolled Students add to disable list
    $DisableList = @()
    ForEach($User in $ActiveUsers){
        If(-not ($EnrolledUsers -contains $User)){
            # Add to Removal
            $DisableList += $User
        }
    }
    # Each User in Disable List
    ForEach($User in $DisableList){
        $ThisUser = Get-ADUser -Identity $User -Properties DisplayName,mail,Givenname,Surname,SamAccountName,EmployeeID,DistinguishedName
        
        If($Settings.EnableSuspension -eq $true) {
            Try {
                Disable-ADAccount -Identity $ThisUser.SAMAccountName
                AddReportEntry -LocalLocation $ReportFile.toString() -Status "Disabled" -DisplayName $ThisUser.DisplayName -UserName $ThisUser.SAMAccountName -Email $ThisUser.mail -StudentID "$ThisUser.EmployeeID" -PasswordClear "" -Class "" -OU $ThisUser.DistinguishedName -Message ""
                $ReportDisabledAccounts += 1
            } Catch {
                AddReportEntry -LocalLocation $ReportFile.toString() -Status "Error" -DisplayName $ThisUser.DisplayName -UserName $ThisUser.SAMAccountName -Email $ThisUser.mail -StudentID "$ThisUser.EmployeeID" -PasswordClear "" -Class "" -OU $ThisUser.DistinguishedName -Message "Error Disabling Account"
            }
        } Else {
            AddReportEntry -LocalLocation $ReportFile.toString() -Status "Audit Suspension" -DisplayName $ThisUser.DisplayName -UserName $ThisUser.SAMAccountName -Email $ThisUser.mail -StudentID $ThisUser.EmployeeID -PasswordClear "" -Class "" -OU $ThisUser.DistinguishedName -Message "Account exist but was not disabled."
        }
    }

}


<# Main Program #>

# Import Settings
try {
    $Settings = Import-Clixml -Path Settings.xml
} catch {
    Write-Host $_
}


# Create working variables from imported settings.
$StudentEmailDomain = $Settings.EMailDomain
$StudentADDomain = $Settings.ADDomain
$SAMUsernameFormat = $Settings.UsernameFormat
$EmailUsernameFormat = $Settings.EmailFormat
$PasswordFormat = $Settings.PasswordFormat
$SpecificDefaultPassword = $Settings.DefaultPassword
$OUModifier = $Settings.OUSearch
$HomeDirectoryLocation = $Settings.HomeDir

# Add AD Module 
Import-Module ActiveDirectory

# Create temporary file to facilitate the download
$StudentInfoFile = New-TemporaryFile | Rename-Item -NewName { $_ -replace 'tmp$', 'csv' } -PassThru 
Write-Host $StudentInfoFile

# Download file using specific settings
Try {
    Clear-Host
    Write-Host "Downloading from SFTP . . ."
    DownloadStudentCSV -SFTPServer $Settings.SFTPServer -SFTPPort $Settings.SFTPPort -SFTPUsername $Settings.SFTPUsername -SFTPPassword $Settings.SFTPPassword -SFTPLocation $Settings.SFTPFile -LocalLocation $StudentInfoFile.ToString() | Out-Null
} Catch {
    Write-Host $_
}

# Import Student CSV from download
Try {
    Write-Host "Importing data from file . . ."
    $StudentInfo = Import-Csv $StudentInfoFile
} Catch {
    Write-Host $_
}


#Generate Report for Email
$ReportFilename = $(Get-Date -Format yyyyMMdd) + "-" + $(Get-Random -Minimum 1000 -Maximum 9999) + "-StatusReport.csv"
$ReportFile = New-TemporaryFile | Rename-Item -NewName $ReportFilename -Force -PassThru 
CreateReport -LocalLocation $ReportFile

# Create Counters for Email
$ReportProcessedAccounts = 0
$global:ReportErrorsLogged = 0
$ReportFailuresLogged = 0
$ReportCreatedAccounts = 0
$ReportDisabledAccounts = 0
$ReportEnabledPrevious = 0

# Create Arrays for Suspension
$EnrolledUsers = @()

# Build OU array object from filter
$OUList = @()
$OUFilter = "*$OUModifier*"
Try {
    # Create OU Object using the Filter
    $GetOU =  Get-ADOrganizationalUnit -Filter "Name -like `"$OUFilter`""
    foreach ( $OU in $GetOU ) {
        $OUList += $OU.DistinguishedName
    }
    if ($OUList -eq 0) {
        Write-Host "No OU matching filter found."
        exit
    }
} Catch {
    Write-Host $_
}


# Check each row of import for existing account
Write-Host "Processing student information . . ."
ForEach($Student in $StudentInfo) { 

    #Append Count
    $ReportProcessedAccounts += 1

    # Add Text Functions for m
    $textInfo = (Get-Culture).TextInfo

    # Pull Text from CSV Row
    $FirstName = $textInfo.ToTitleCase($Student."FIRST_NAME".ToLower()) -replace "'"
    # Remove Second First Name
    if($FirstName.Contains(" ")) { $FirstName = $FirstName.Substring(0,$FirstName.LastIndexOf(' ')) }
    $MiddleName = $textInfo.ToTitleCase($Student."MIDDLE_NAME".ToLower()) -replace "'"
    $LastName = $textInfo.ToTitleCase($Student."LAST_NAME".ToLower()) -replace "'"
    # Remove Second Last Name
    if($LastName.Contains(" ")) { $LastName = $LastName.Substring(0,$LastName.LastIndexOf(' ')) }
    # Remove S from Student ID
    $StudentID = $Student."STUDENT_ID" -replace 'S'
    # Assign Grade
    $GRADE = $Student."GRADE"


    # Build Username using Settings
    # 1=F.L  2=L.F  3=FL  4=LF  5=F_L  6=L_F
    Switch($SAMUsernameFormat) {
        "1" { 
                $SAMUsername = $FirstName.ToLower() + '.' + $LastName.ToLower()
                if($SAMUsername.Length -gt 19) { $SAMUsername = $SAMUsername.Substring(0,20) }
            }
        "2" { 
                $SAMUsername = $LastName.ToLower() + '.' + $FirstName.ToLower()
                if($SAMUsername.Length -gt 19) { $SAMUsername = $SAMUsername.Substring(0,20) }
            }
        "3" {
                $SAMUsername = $FirstName.ToLower() + $LastName.ToLower()
                if($SAMUsername.Length -gt 19) { $SAMUsername = $SAMUsername.Substring(0,20) }
            }
        "4" {
                $SAMUsername = $LastName.ToLower() + $FirstName.ToLower()
                if($SAMUsername.Length -gt 19) { $SAMUsername = $SAMUsername.Substring(0,20) }
            }
        "5" {
                $SAMUsername = $FirstName.ToLower() + '_' + $LastName.ToLower()
                if($SAMUsername.Length -gt 19) { $SAMUsername = $SAMUsername.Substring(0,20) }
            }
        "6" {
                $SAMUsername = $LastName.ToLower() + '_' + $FirstName.ToLower()
                if($SAMUsername.Length -gt 19) { $SAMUsername = $SAMUsername.Substring(0,20) }
            }
        default {
                Write-Host "Please select a proper email format"
                exit
            }
    }

    # Build UserPrincipalName using Settings
    # 1=F.L  2=L.F  3=FL  4=LF  5=F_L  6=L_F
    Switch($SAMUsernameFormat) {
        "1" { 
                $UserPrincipalName = $FirstName.ToLower() + '.' + $LastName.ToLower()  + "@" + $StudentADDomain.ToString().ToLower() 
            }
        "2" { 
                $UserPrincipalName = $LastName.ToLower() + '.' + $FirstName.ToLower() + "@" + $StudentADDomain.ToString().ToLower()
            }
        "3" {
                $UserPrincipalName = $FirstName.ToLower() + $LastName.ToLower() + "@" + $StudentADDomain.ToString().ToLower()
            }
        "4" {
                $UserPrincipalName = $LastName.ToLower() + $FirstName.ToLower() + "@" + $StudentADDomain.ToString().ToLower()
            }
        "5" {
                $UserPrincipalName = $FirstName.ToLower() + '_' + $LastName.ToLower() + "@" + $StudentADDomain.ToString().ToLower()
            }
        "6" {
                $UserPrincipalName = $LastName.ToLower() + '_' + $FirstName.ToLower() + "@" + $StudentADDomain.ToString().ToLower()
            }
        default {
                Write-Host "Please select a proper email format"
                exit
            }
    }

    #Reported Username
    $ReportedUsername = $UserPrincipalName.Substring(0,$UserPrincipalName.LastIndexOf('@'))

    # Add to Enrolled Array
    $EnrolledUsers += $SAMUsername

    # Build graduation year from grade
    # Get Year and Month
    $CurrentYear = (Get-Date).Year
    $CurrentMonth = (Get-Date).Month
    # Correct Mid Semester Calculation
    if ( $CurrentMonth -gt 6) {
        $CurrentYear = $CurrentYear + 1
    }
    # Make Adjustments for Lettered Grades
    if ( $Grade -eq "KG" ) {
        $ClassOfYear = $CurrentYear + 12
    } elseif ( $Grade -eq "PK" ) {
        $ClassOfYear = $CurrentYear + 13
    } elseif ( $Grade -eq "EE" ) {
        $ClassOfYear = $CurrentYear + 14
    } else {
        $ClassOfYear = $CurrentYear + 12 - $Grade
    }
    # Convert correction to String
	$ClassOfYear = $ClassOfYear.ToString();

    # Other AD Fields
    # Display Name
    $DisplayName = $FirstName + " " + $LastName
    # Pager (Used for printing access)
    $Pager = $StudentID
    # EmployeeID (Used for Student ID field)
    $EmployeeID = $StudentID


    # Build Email using Settings
    # 1=F.L  2=L.F  3=FL  4=LF  5=F_L  6=L_F
    Switch($EmailUsernameFormat) {
        "1" { 
                $EmailAddress = $FirstName.ToLower() + '.' + $LastName.ToLower() + "@" + $StudentEmailDomain.ToString().ToLower()
            }
        "2" { 
                $EmailAddress = $LastName.ToLower() + '.' + $FirstName.ToLower() + "@" + $StudentEmailDomain.ToString().ToLower()
            }
        "3" {
                $EmailAddress = $FirstName.ToLower() + $LastName.ToLower() + "@" + $StudentEmailDomain.ToString().ToLower()
            }
        "4" {
                $EmailAddress = $LastName.ToLower() + $FirstName.ToLower() + "@" + $StudentEmailDomain.ToString().ToLower()
            }
        "5" {
                $EmailAddress = $FirstName.ToLower() + '_' + $LastName.ToLower() + "@" + $StudentEmailDomain.ToString().ToLower()
            }
        "6" {
                $EmailAddress = $LastName.ToLower() + '_' + $FirstName.ToLower() + "@" + $StudentEmailDomain.ToString().ToLower()
            }
        default {
                Write-Host "Please select a proper email format"
                exit
            }
    }


    # Build Password from settings
    # 1=ID#  2=FiLiID#  3=LiFiID#  4=Fi2(Proper)Li2(Proper)ID#  5=Li2(Proper)Fi2(Proper)ID#
    Switch($PasswordFormat) {
        "1" {
                $StudentPasswordClear = $StudentID
            }
        "2" {
                $StudentPasswordClear = $FirstName.Substring(0,1) + $LastName.Substring(0,1) + $StudentID
            }
        "3" {
                $StudentPasswordClear = $LastName.Substring(0,1) + $FirstName.Substring(0,1) + $StudentID
            }
        "4" {
                $StudentPasswordClear = $FirstName.Substring(0,2) + $LastName.Substring(0,2) + $StudentID
            }
        "5" {
                $StudentPasswordClear = $LastName.Substring(0,2) + $FirstName.Substring(0,2) + $StudentID
            }
        "6" {
                $StudentPasswordClear = $SpecificDefaultPassword
            }
        default {
                Write-Host "Please select a proper password format "
                exit
            }
    }
    # Create Secure String of Password
    $StudentPasswordSecure = ConvertTo-SecureString -String $StudentPasswordClear -AsPlainText -Force

    # Search in list of OU Graduation Year
    $OUSearchString = "*$ClassOfYear*"
    ForEach ($OU in $OUList) {       
        if($OU -like $OUSearchString){
            $UserOU = $OU
            break
        }
    }

    # Build HomeDirectory Location
    $HomeDirectory = $HomeDirectoryLocation+$SAMUsername

    <# Create New user Object #>
    $NewStudentAccount = New-Object -TypeName psobject
    $NewStudentAccount | Add-Member -NotePropertyName UserPrincipalName -NotePropertyValue $UserPrincipalName
    $NewStudentAccount | Add-Member -NotePropertyName SAMUsername -NotePropertyValue $SAMUsername
    $NewStudentAccount | Add-Member -NotePropertyName ReportedUsername -NotePropertyValue $ReportedUsername
    $NewStudentAccount | Add-Member -NotePropertyName FirstName -NotePropertyValue $FirstName
    $NewStudentAccount | Add-Member -NotePropertyName MiddleName -NotePropertyValue $MiddleName
    $NewStudentAccount | Add-Member -NotePropertyName LastName -NotePropertyValue $LastName
    $NewStudentAccount | Add-Member -NotePropertyName DisplayName -NotePropertyValue $DisplayName
    $NewStudentAccount | Add-Member -NotePropertyName EmployeeID -NotePropertyValue $EmployeeID
    $NewStudentAccount | Add-Member -NotePropertyName Pager -NotePropertyValue $Pager
    $NewStudentAccount | Add-Member -NotePropertyName Email -NotePropertyValue $EmailAddress
    $NewStudentAccount | Add-Member -NotePropertyName PasswordSecure -NotePropertyValue $StudentPasswordSecure
    $NewStudentAccount | Add-Member -NotePropertyName PasswordClear -NotePropertyValue $StudentPasswordClear
    $NewStudentAccount | Add-Member -NotePropertyName ClassOf -NotePropertyValue $ClassOfYear
    $NewStudentAccount | Add-Member -NotePropertyName OU -NotePropertyValue $UserOU
    $NewStudentAccount | Add-Member -NotePropertyName HomeDirectory -NotePropertyValue $HomeDirectory
    <# END Create New user Object #>

    # Check if user exist.
    if ((CheckExistingStudent -SAMUsername $SAMUsername) -eq $false) {
        CreateNewStudentAccount -NewStudentAccount $NewStudentAccount
    } else {
        CheckPreviousUnenrolled -NewStudentAccount $NewStudentAccount
    }

}

# Unenrolled Accounts
Write-Host "Processing unenrolled accounts . . ."
DisableUnEnrolled -EnrolledUsers $EnrolledUsers


# Finish up and Email Report
# Build Attachment Array
$AttachmentArray = @()
# Attach Report
$AttachmentArray += $ReportFile.toString()
# Email Body
# Mode Message
if ($Settings.EnableCreation -eq $false) {
    $StatusMessage = "Account creation is not enabled. Informational purposes only."
} elseif ($Settings.EnableCreation -eq $true) {
    $StatusMessage = "Please review the report for any errors."
}
$EmailBody =@"
<h2 style="color:#000">Open Roster AD Sync Results</h2>
<table style="color:#000">
<tr><td style="width:160px">Total Processed Students</td><td>$ReportProcessedAccounts</td></tr>
<tr><td colspan="2"></td></tr>
<tr><td colspan="2">$StatusMessage</td></tr>
</table>
"@



# If SMTP Enabled Send Message 
if($Settings.SMTPEnable -eq $true) {
    Write-Host "Sending email report . . ."
    EmailReport -SMTPServer $Settings.SMTPServer -SMTPUsername $Settings.SMTPUsername -SMTPPassword $Settings.SMTPPassword -SMTPPort $Settings.SMTPPort -SMTPSSL $true -SMTPSubject $Settings.SMTPSubject -SMTPDestination $Settings.SMTPDestination -SMTPBody $EmailBody -SMTPAttachments $AttachmentArray
}



# Remove Temp File
$CacheLocked = $true
While($CacheLocked) {
    Try {
        Write-Host "Cleaning up cache . . ."
        Remove-Item $StudentInfoFile -ErrorAction Stop
        $CacheLocked = $false
    } Catch {
        Write-Host "Cache locked, waiting for  . . ."
        Start-Sleep -Seconds 5
    }   
}

# CLI Status Report
$ReportCLI = New-Object -TypeName psobject
$ReportCLI | Add-Member -NotePropertyName "Processed Accounts" -NotePropertyValue $ReportProcessedAccounts
$ReportCLI | Add-Member -NotePropertyName "Created Accounts" -NotePropertyValue $ReportCreatedAccounts
$ReportCLI | Add-Member -NotePropertyName "Enabled Accounts" -NotePropertyValue $ReportEnabledPrevious
$ReportCLI | Add-Member -NotePropertyName "Disabled Accounts" -NotePropertyValue $ReportDisabledAccounts
$ReportCLI | Add-Member -NotePropertyName "Errors" -NotePropertyValue $global:ReportErrorsLogged
$ReportCLI | Add-Member -NotePropertyName "Failures" -NotePropertyValue $ReportFailuresLogged

# Output Report
Write-Host "`n`nOpen Roster AD Sync Results"
$ReportCLI 
Write-host $StatusMessage "`n`n"


# Move Report
if(Test-Path -Path $Settings.ReportDir) {
    $ReportFileNotMoved = $true
    Write-Host "Copying report to archive . . ."
    Copy-Item -Path $ReportFile -Destination $Settings.ReportDir -Force
    # Powershell sometimes will not unlock files till reboot . . . Thanks MSFT
    $GiveUpCounter = 0
    While($ReportFileNotMoved) {
        Try {
            Remove-Item -Path $ReportFile -ErrorAction Stop
            $ReportFileNotMoved = $false
        } Catch {
            Write-Host "File locked, waiting for reattempt . . ."
            $GiveUpCounter += 1
            if ($GiveUpCounter -gt 6){
                $ReportFileNotMoved = $false
            }
            Start-Sleep -Seconds 10
        }
    }
    Write-Host "Sync complete and report archived!"
} else {
    Write-Host "Sync Complete!"
}