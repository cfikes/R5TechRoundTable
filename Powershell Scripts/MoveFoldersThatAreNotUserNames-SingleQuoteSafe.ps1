#Set These For Source and Destination
$SourceDirectory = "C:\Source\Directory\"
$DestinationDirectory = "C:\Destination\Directory\"
#Output CSV
$OutputCSV = "C:\Report.csv"
#Output Errors
$ErrorLog = "C:\Errors.txt"
#Change to $false if you dont want to see the output of each user/foldername
$SeeOutputText = $true
#Change this $true to run the script and not test
$Enable = $false
$Counter=0
if(-Not $Enable ) { Write-Host "Script is in TEST MODE AND WILL NOT EFFECT ANY FILES OR FOLDERS" }
if((Test-Path -Path $SourceDirectory -PathType Container) -And (Test-Path -Path $DestinationDirectory -PathType Container)) {
    #The Source Actually Exist
    foreach($_ in (Get-ChildItem $SourceDirectory)) {
        $FullPath = $_.FullName
        if($_.PSIsContainer) {
            $ThisUser = $_.name
            $ThisUserSQSafe = $ThisUser.Replace("'","''")
            $CheckUsername = Get-ADUser -Filter "sAMAccountName -eq '$ThisUserSQSafe'" -Properties sAMAccountName | Measure-Object | Select-Object -ExpandProperty Count
            if( $CheckUsername -eq 0 ) {
                #Folder is not a valid AD user
                if($SeeOutputText) { 
                    Write-Host "$ThisUser is Not an AD User"
                }
                if($Enable) { 
                    Move-Item -Path $FullPath -Destination $DestinationDirectory
                    #Log Errors 
                    if (!$?) {
                        if(-Not (Test-Path -Path $ErrorLog -PathType Leaf)) { New-Item $ErrorLog -ItemType "file" }
                        "Error on $($file.name)" | Out-File $ErrorLog -append
                    } else {
                        #Create CSV if it doesnt Exist
                        if(-Not (Test-Path -Path $ErrorLog -PathType Leaf)) {
                            Add-Content -Path $OutputCSV -Value 'Username,Source,Destination'
                        }
                        #Add Content to CSV
                        Add-Content -Path $OutputCSV -Value "$ThisUser,$FullPath,$DestinationDirectory$ThisUser"
                    }
                } else { 
                    Move-Item -Path $_.FullName -Destination $DestinationDirectory -WhatIf
                    $Counter++
                }
            } else {
               #Folder is a valid AD user
               if($SeeOutputText) { Write-Host "$ThisUser is a valid AD user account" }
            }
        }
    }
    Write-Host $Counter
} else {
    Write-Host "You have to specify a valid location before it begins"
}