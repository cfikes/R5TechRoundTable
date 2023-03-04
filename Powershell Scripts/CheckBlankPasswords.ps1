function Test-ADCrential {
    [CmdletBinding()]
    param(
        [pscredential]$Credential
    )
     
    try {
        Add-Type -AssemblyName System.DirectoryServices.AccountManagement
        if(!$Credential) {
            $Credential = Get-Credential -EA Stop
        }
        if($Credential.username.split("\").count -ne 2) {
            return "Invalid"
            #throw "You haven't entered credentials in DOMAIN\USERNAME format. Given value : $($Credential.Username)"
        }
     
        $DomainName = $Credential.username.Split("\")[0]
        $UserName = $Credential.username.Split("\")[1]
        $Password = $Credential.GetNetworkCredential().Password
     
        $PC = New-Object System.DirectoryServices.AccountManagement.PrincipalContext([System.DirectoryServices.AccountManagement.ContextType]::Domain, $DomainName)
        if($PC.ValidateCredentials($UserName,$Password)) {
            return "Valid"
        } else {
            return "Invalid"
        }
    } catch {
        return "Invalid"
    }
}

# Storing the Findings
$UserListArray = @()

# Get all your AD Users
$AllUsers = Get-ADUser

# Loop through them all
foreach($User in $AllUsers){
    try {
        # Structure Data for Check
        $DomainName = Get-ADDomain | Select-Object -ExpandProperty NetBiosName
        $Username = $DomainName+"\"+$User.SamAccountName
        #
        # Checking Your Blank Password Here
        #
        $Password = ""

        [System.Security.SecureString]$SecPwd = ConvertTo-SecureString -String $Password -AsPlainText -Force 
        $Credential = New-Object -typename System.Management.Automation.PSCredential -argumentlist @($Username,$SecPwd)

        # Get Credential State
        try {
            $credentialState = Test-ADCrential $Credential
        }
        catch {
            $credentialState = "Error"
        }

        # Use Credential State
        if($credentialState -eq "Invalid"){
            $ThisUser = New-Object -TypeName PSObject -Property @{Username = $Username}
            $UserListArray += $ThisUser
        } elseif ($credentialState -eq "Valid") {
            # Valid, Do Something Else
        } elseif ($credentialState -eq "Error") {
            # Error, Do Something Else
        }
    }
    catch {
        # Error Do Something Else
    }
}

# Export the findings Change your Path
$UserListArray | Export-Csv -Path "C:\Findings.csv"