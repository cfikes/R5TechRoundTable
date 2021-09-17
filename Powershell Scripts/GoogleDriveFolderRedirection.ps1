<#
.SYNOPSIS

HACK to use Google Drive Storage as Folder Redirection.

.DESCRIPTION

HACK to use Google Drive Storage as Folder Redirection. Kinda Chicken Egg, need account signed to Google Drive before it works . . . Has a mode for login and logoff

.EXAMPLE

GoogleDriveFolderRedirection.ps1 -Mode Login

.Example

GoogleDriveFolderRedirection.ps1 -Mode Logout

.NOTES

Use -Mode to specify Login or Logout

.LINK

#>

Param ([string] $Mode)
      
if($Mode -eq "Login") {
    if (Test-Path "G:\My Drive") {
        #Check for already renamed Local Documents folder
        if (-Not (Test-Path $env:USERPROFILE\DocumentsLocal)) {
            Rename-Item -Path $env:USERPROFILE\Documents -NewName $env:USERPROFILE\DocumentsLocal
        }
        #Check if DocumentsLocal Exist and not already mapped Documents
        if ((Test-Path $env:USERPROFILE\DocumentsLocal) -and (-Not (Test-Path $env:USERPROFILE\Documents)) ){
            #Create Redirection Folder if not exist
            if (-Not (Test-Path 'G:\My Drive\FolderRedirection')) {
                New-Item -ItemType directory 'G:\My Drive\FolderRedirection'
            }
            #Create Junction
            New-Item -ItemType junction -path $env:USERPROFILE\Documents -Value 'G:\My Drive\FolderRedirection'
        }
    }
} elseif( $Mode -eq "Logout") {
    if((Test-Path 'G:\My Drive\FolderRedirection') -and (Test-Path $env:USERPROFILE\Documents\FolderRedirection)) {
            Remove-Item $env:USERPROFILE\Documents
            Rename-Item -Path $env:USERPROFILE\DocumentsLocal -NewName $env:USERPROFILE\Documents
    }
} else {
    Write-Host "You Must Specify a Mode Login or Logout"
}

