<#
.SYNOPSIS

Create TIDE Interim Test Upload Files from Ascender Report

.DESCRIPTION

Create TIDE Interim Test Upload Files from Ascender Report. Acender Custom Report Export Fields "Grade", "TX Unique Stu ID", "Active"

.EXAMPLE

./Tide-InterimGradeUploadELJH.ps1 -WorkingFile "UCReport_xxx.csv" -OutputFile "InterimTests.csv"

.NOTES

Only Processes Elementary and Junior High Records.

.LINK

https://fikesmedia.com
#>

param(
    [Parameter(Position=0,mandatory=$true)]
    [string] $WorkingFile,
    [Parameter(Position=1,mandatory=$true)]
    [string] $OutputFile
)

$WorkingCSV = Import-Csv $WorkingFile -Header "Grade","TX Unique Stu ID","Active"

# Object for Holding
$InterimTests =@()

# Interim Definitions
$Test03 = @("Mathematics","RLA")
$Test04 = @("Mathematics","RLA")
$Test05 = @("Mathematics","RLA","Science")
$Test06 = @("Mathematics","RLA")
$Test07 = @("Mathematics","RLA")
$Test08 = @("Mathematics","RLA","Science","Social Studies")

# Counter For Giggles
$RowCounter = 0
$TestCounter = 0
try {
    foreach ($Row in $WorkingCSV) {
        if($Row.Active -eq "1") {
            
            #
            # Third Grade
            #
            if($Row.Grade -eq "03") {
                foreach($Test in $Test03){
                    $InterimTest = New-Object -TypeName psobject
                    $InterimTest | Add-Member -MemberType NoteProperty -Name "TSDS ID" -Value $Row."TX Unique Stu ID"
                    $InterimTest | Add-Member -MemberType NoteProperty -Name "Field" -Value "Interim Grade Testing"
                    $InterimTest | Add-Member -MemberType NoteProperty -Name "Subject" -Value $Test
                    $InterimTest | Add-Member -MemberType NoteProperty -Name "Grade" -Value $Row."Grade"
                    $InterimTests += $InterimTest
                    # Count Tests
                    $TestCounter += 1
                }
            }

            #
            # Fourth Grade
            #
            if($Row.Grade -eq "04") {
                foreach($Test in $Test04){
                    $InterimTest = New-Object -TypeName psobject
                    $InterimTest | Add-Member -MemberType NoteProperty -Name "TSDS ID" -Value $Row."TX Unique Stu ID"
                    $InterimTest | Add-Member -MemberType NoteProperty -Name "Field" -Value "Interim Grade Testing"
                    $InterimTest | Add-Member -MemberType NoteProperty -Name "Subject" -Value $Test
                    $InterimTest | Add-Member -MemberType NoteProperty -Name "Grade" -Value $Row."Grade"
                    $InterimTests += $InterimTest
                    # Count Tests
                    $TestCounter += 1
                }

            }

            #
            # Fifth Grade
            #
            if($Row.Grade -eq "05") {
                foreach($Test in $Test05){
                    $InterimTest = New-Object -TypeName psobject
                    $InterimTest | Add-Member -MemberType NoteProperty -Name "TSDS ID" -Value $Row."TX Unique Stu ID"
                    $InterimTest | Add-Member -MemberType NoteProperty -Name "Field" -Value "Interim Grade Testing"
                    $InterimTest | Add-Member -MemberType NoteProperty -Name "Subject" -Value $Test
                    $InterimTest | Add-Member -MemberType NoteProperty -Name "Grade" -Value $Row."Grade"
                    $InterimTests += $InterimTest
                    # Count Tests
                    $TestCounter += 1
                }

            }
            
            #
            # Sixth Grade
            #
            if($Row.Grade -eq "06") {
                foreach($Test in $Test06){
                    $InterimTest = New-Object -TypeName psobject
                    $InterimTest | Add-Member -MemberType NoteProperty -Name "TSDS ID" -Value $Row."TX Unique Stu ID"
                    $InterimTest | Add-Member -MemberType NoteProperty -Name "Field" -Value "Interim Grade Testing"
                    $InterimTest | Add-Member -MemberType NoteProperty -Name "Subject" -Value $Test
                    $InterimTest | Add-Member -MemberType NoteProperty -Name "Grade" -Value $Row."Grade"
                    $InterimTests += $InterimTest
                    # Count Tests
                    $TestCounter += 1
                }

            }

            #
            # Seventh Grade
            #
            if($Row.Grade -eq "07") {
                foreach($Test in $Test07){
                    $InterimTest = New-Object -TypeName psobject
                    $InterimTest | Add-Member -MemberType NoteProperty -Name "TSDS ID" -Value $Row."TX Unique Stu ID"
                    $InterimTest | Add-Member -MemberType NoteProperty -Name "Field" -Value "Interim Grade Testing"
                    $InterimTest | Add-Member -MemberType NoteProperty -Name "Subject" -Value $Test
                    $InterimTest | Add-Member -MemberType NoteProperty -Name "Grade" -Value $Row."Grade"
                    $InterimTests += $InterimTest
                    # Count Tests
                    $TestCounter += 1
                }

            }

            #
            # Eighth Grade
            #
            if($Row.Grade -eq "08") {
                foreach($Test in $Test08){
                    $InterimTest = New-Object -TypeName psobject
                    $InterimTest | Add-Member -MemberType NoteProperty -Name "TSDS ID" -Value $Row."TX Unique Stu ID"
                    $InterimTest | Add-Member -MemberType NoteProperty -Name "Field" -Value "Interim Grade Testing"
                    $InterimTest | Add-Member -MemberType NoteProperty -Name "Subject" -Value $Test
                    $InterimTest | Add-Member -MemberType NoteProperty -Name "Grade" -Value $Row."Grade"
                    $InterimTests += $InterimTest
                    # Count Tests
                    $TestCounter += 1
                }
            }
        } # End Active Check
        $RowCounter += 1
    }

    # Write New File
    $InterimTests | Sort-Object -Property "TSDS ID" | Export-Csv -Path $OutputFile -NoTypeInformation

    # Write Results
    Write-Host "Processed $RowCounter records and created $TestCounter tests."
}
catch {
    Write-Warning -Message "Something went wrong \_(ツ)_/"
}