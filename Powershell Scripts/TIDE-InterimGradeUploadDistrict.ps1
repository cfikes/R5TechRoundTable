<#
.SYNOPSIS

Create TIDE Interim Test Upload Files from Ascender Report

.DESCRIPTION

Create TIDE Interim Test Upload Files from Ascender Report. Acender STAR/TAKS Precoding Extract

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

$WorkingCSV = Import-Csv $WorkingFile -Header "TSDS ID","Enrolled District ID","Enrolled Campus ID","Testing District ID","Testing Campus ID","Last Name","First Name","Middle Name","Gender","Birthdate","Grade Level Code","PEIMS ID","Local Student ID","Hispanic Latino Code (ETH)","American Indian Alaska Native Code (I)","Asian Code (A)","Black African American Code (B)","Native Hawaiian Pacific Islander Code (P)","White Code (W)","Emergent Bilingual Indicator Code (EL)","Bilingual Program Type Code (B)","ESL Program Type Code (ESL)","Migrant Indicator Code (MS)","Years In U.S. Schools","Parental Denial Code","Unschooled Asylee/Refugee Code","Student with Interrupted Formal Education Code","High School Equivalency Program (HSEP)","Texas Migrant Interstate Program (TMIP)","New To Texas","Special Ed Indicator Code (SE)","Section 504 Indicator Code","Gifted Talented Indicator Code (G/T)","Economic Disadvantage Code (ED)","Title I Part A Indicator Code(TIA)","At-Risk Indicator Code (AR)","TELPAS Alternate","STAAR Alternate 2","STAAR Alternate 2 EOC Eligibility - Algebra I","STAAR Alternate 2 EOC Eligibility - Biology","STAAR Alternate 2 EOC Eligibility - English I","STAAR Alternate 2 EOC Eligibility - English II","STAAR Alternate 2 EOC Eligibility - U.S. History","STAAR 3-8 Above Grade - Mathematics","STAAR 3-8 Above Grade - RLA","STAAR 3-8 Above Grade - Science","STAAR 3-8 Above Grade - Social Studies","December EOC Eligibility - Algebra I","December EOC Eligibility - Biology","December EOC Eligibility - English I","December EOC Eligibility - English II","December EOC Eligibility - U.S. History","Spring EOC Eligibility - Algebra I","Spring EOC Eligibility - Biology","Spring EOC Eligibility - English I","Spring EOC Eligibility - English II","Spring EOC Eligibility - U.S. History","June EOC Eligibility - Algebra I","June EOC Eligibility - Biology","June EOC Eligibility - English I","June EOC Eligibility - English II","June EOC Eligibility - U.S. History","Field for Local Use 1","Field for Local Use 2","Field for Local Use 3","Field for Local Use 4","Action"

# Object for Holding
$InterimTests =@()

# Interim Definitions
$Test03 = @("Mathematics","RLA")
$Test04 = @("Mathematics","RLA")
$Test05 = @("Mathematics","RLA","Science")
$Test06 = @("Mathematics","RLA")
$Test07 = @("Mathematics","RLA")
$Test08 = @("Mathematics","RLA","Science","Social Studies")

# Cambium Test Definitions
$ALG1Test = "Algebra I"
$BIOTest = "Biology"
$ENG1Test = "English I"
$ENG2Test = "English II"
$USHTest = "U.S. History"


# Counter For Giggles
$RowCounter = 0
$TestCounter = 0
try {
    foreach ($Row in $WorkingCSV) {
    
        
        #
        # Third Grade
        #
        if($Row."Grade Level Code" -eq "03") {
            foreach($Test in $Test03){
                $InterimTest = New-Object -TypeName psobject
                $InterimTest | Add-Member -MemberType NoteProperty -Name "TSDS ID" -Value $Row."TSDS ID"
                $InterimTest | Add-Member -MemberType NoteProperty -Name "Field" -Value "Interim Grade Testing"
                $InterimTest | Add-Member -MemberType NoteProperty -Name "Subject" -Value $Test
                $InterimTest | Add-Member -MemberType NoteProperty -Name "Grade" -Value $Row."Grade Level Code"
                $InterimTests += $InterimTest
                # Count Tests
                $TestCounter += 1
            }
        }

        #
        # Fourth Grade
        #
        if($Row."Grade Level Code" -eq "04") {
            foreach($Test in $Test04){
                $InterimTest = New-Object -TypeName psobject
                $InterimTest | Add-Member -MemberType NoteProperty -Name "TSDS ID" -Value $Row."TSDS ID"
                $InterimTest | Add-Member -MemberType NoteProperty -Name "Field" -Value "Interim Grade Testing"
                $InterimTest | Add-Member -MemberType NoteProperty -Name "Subject" -Value $Test
                $InterimTest | Add-Member -MemberType NoteProperty -Name "Grade" -Value $Row."Grade Level Code"
                $InterimTests += $InterimTest
                # Count Tests
                $TestCounter += 1
            }

        }

        #
        # Fifth Grade
        #
        if($Row."Grade Level Code" -eq "05") {
            foreach($Test in $Test05){
                $InterimTest = New-Object -TypeName psobject
                $InterimTest | Add-Member -MemberType NoteProperty -Name "TSDS ID" -Value $Row."TSDS ID"
                $InterimTest | Add-Member -MemberType NoteProperty -Name "Field" -Value "Interim Grade Testing"
                $InterimTest | Add-Member -MemberType NoteProperty -Name "Subject" -Value $Test
                $InterimTest | Add-Member -MemberType NoteProperty -Name "Grade" -Value $Row."Grade Level Code"
                $InterimTests += $InterimTest
                # Count Tests
                $TestCounter += 1
            }

        }
        
        #
        # Sixth Grade
        #
        if($Row."Grade Level Code" -eq "06") {
            foreach($Test in $Test06){
                $InterimTest = New-Object -TypeName psobject
                $InterimTest | Add-Member -MemberType NoteProperty -Name "TSDS ID" -Value $Row."TSDS ID"
                $InterimTest | Add-Member -MemberType NoteProperty -Name "Field" -Value "Interim Grade Testing"
                $InterimTest | Add-Member -MemberType NoteProperty -Name "Subject" -Value $Test
                $InterimTest | Add-Member -MemberType NoteProperty -Name "Grade" -Value $Row."Grade Level Code"
                $InterimTests += $InterimTest
                # Count Tests
                $TestCounter += 1
            }

        }

        #
        # Seventh Grade
        #
        if($Row."Grade Level Code" -eq "07") {
            foreach($Test in $Test07){
                $InterimTest = New-Object -TypeName psobject
                $InterimTest | Add-Member -MemberType NoteProperty -Name "TSDS ID" -Value $Row."TSDS ID"
                $InterimTest | Add-Member -MemberType NoteProperty -Name "Field" -Value "Interim Grade Testing"
                $InterimTest | Add-Member -MemberType NoteProperty -Name "Subject" -Value $Test
                $InterimTest | Add-Member -MemberType NoteProperty -Name "Grade" -Value $Row."Grade Level Code"
                $InterimTests += $InterimTest
                # Count Tests
                $TestCounter += 1
            }

        }

        #
        # Eighth Grade
        #
        if($Row."Grade Level Code" -eq "08") {
            foreach($Test in $Test08){
                $InterimTest = New-Object -TypeName psobject
                $InterimTest | Add-Member -MemberType NoteProperty -Name "TSDS ID" -Value $Row."TSDS ID"
                $InterimTest | Add-Member -MemberType NoteProperty -Name "Field" -Value "Interim Grade Testing"
                $InterimTest | Add-Member -MemberType NoteProperty -Name "Subject" -Value $Test
                $InterimTest | Add-Member -MemberType NoteProperty -Name "Grade" -Value $Row."Grade Level Code"
                $InterimTests += $InterimTest
                # Count Tests
                $TestCounter += 1
            }
        }

        # 
        # High School Checks
        # 
        if($Row."Grade Level Code" -eq "09" -or $Row."Grade Level Code" -eq "10" -or $Row."Grade Level Code" -eq "11" -or $Row."Grade Level Code" -eq "12") {

            # 
            # Check for Algebra
            if($Row."December EOC Eligibility - Algebra I" -eq "Y" -or $Row."Spring EOC Eligibility - Algebra I" -eq "Y") {
                    $InterimTest = New-Object -TypeName psobject
                    $InterimTest | Add-Member -MemberType NoteProperty -Name "TSDS ID" -Value $Row."TSDS ID"
                    $InterimTest | Add-Member -MemberType NoteProperty -Name "Field" -Value "Interim Grade Testing"
                    $InterimTest | Add-Member -MemberType NoteProperty -Name "Subject" -Value $ALG1Test
                    $InterimTest | Add-Member -MemberType NoteProperty -Name "Grade" -Value "Yes"
                    $InterimTests += $InterimTest
                    # Count Tests
                    $TestCounter += 1
            }

            # 
            # Check for ENG 1
            if($Row."December EOC Eligibility - English I" -eq "Y" -or $Row."Spring EOC Eligibility - English I" -eq "Y") {
                    $InterimTest = New-Object -TypeName psobject
                    $InterimTest | Add-Member -MemberType NoteProperty -Name "TSDS ID" -Value $Row."TSDS ID"
                    $InterimTest | Add-Member -MemberType NoteProperty -Name "Field" -Value "Interim Grade Testing"
                    $InterimTest | Add-Member -MemberType NoteProperty -Name "Subject" -Value $ENG1Test
                    $InterimTest | Add-Member -MemberType NoteProperty -Name "Grade" -Value "Yes"
                    $InterimTests += $InterimTest
                    # Count Tests
                    $TestCounter += 1
            }

            # 
            # Check for ENG 2
            if($Row."December EOC Eligibility - English II" -eq "Y" -or $Row."Spring EOC Eligibility - English II" -eq "Y") {
                    $InterimTest = New-Object -TypeName psobject
                    $InterimTest | Add-Member -MemberType NoteProperty -Name "TSDS ID" -Value $Row."TSDS ID"
                    $InterimTest | Add-Member -MemberType NoteProperty -Name "Field" -Value "Interim Grade Testing"
                    $InterimTest | Add-Member -MemberType NoteProperty -Name "Subject" -Value $ENG2Test
                    $InterimTest | Add-Member -MemberType NoteProperty -Name "Grade" -Value "Yes"
                    $InterimTests += $InterimTest
                    # Count Tests
                    $TestCounter += 1
            }

            # 
            # Check for Biology
            if($Row."December EOC Eligibility - Biology" -eq "Y" -or $Row."Spring EOC Eligibility - Biology" -eq "Y") {
                    $InterimTest = New-Object -TypeName psobject
                    $InterimTest | Add-Member -MemberType NoteProperty -Name "TSDS ID" -Value $Row."TSDS ID"
                    $InterimTest | Add-Member -MemberType NoteProperty -Name "Field" -Value "Interim Grade Testing"
                    $InterimTest | Add-Member -MemberType NoteProperty -Name "Subject" -Value $BIOTest
                    $InterimTest | Add-Member -MemberType NoteProperty -Name "Grade" -Value "Yes"
                    $InterimTests += $InterimTest
                    # Count Tests
                    $TestCounter += 1
            }

            # 
            # Check for US History
            if($Row."December EOC Eligibility - U.S. History" -eq "Y" -or $Row."Spring EOC Eligibility - U.S. History" -eq "Y") {
                    $InterimTest = New-Object -TypeName psobject
                    $InterimTest | Add-Member -MemberType NoteProperty -Name "TSDS ID" -Value $Row."TSDS ID"
                    $InterimTest | Add-Member -MemberType NoteProperty -Name "Field" -Value "Interim Grade Testing"
                    $InterimTest | Add-Member -MemberType NoteProperty -Name "Subject" -Value $USHTest
                    $InterimTest | Add-Member -MemberType NoteProperty -Name "Grade" -Value "Yes"
                    $InterimTests += $InterimTest
                    # Count Tests
                    $TestCounter += 1
            }

        }
        
        $RowCounter += 1
    }

    # Write New File
    $InterimTests | Sort-Object -Property "TSDS ID" | Export-Csv -Path $OutputFile -NoTypeInformation

    # Write Results
    Write-Host "Processed $RowCounter records and created $TestCounter tests."
}
catch {
    Write-Warning -Message "Something went wrong \_(ツ)_/"
    Write-Warning $_
}