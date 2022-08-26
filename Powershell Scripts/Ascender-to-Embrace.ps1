<#
.SYNOPSIS

Utility to convert Ascender SPED export into a compatible Embrace import. 

.DESCRIPTION

Utility to convert Ascender SPED export into a compatible Embrace import.

.EXAMPLE

./Ascender-to-Embrace.ps1 -ImportCSV "AscenderExport.csv" -ExportCSV "EmbraceStudentImport.csv"

.NOTES

The information contained in the export is not complete as of 08/26/2022 for Embrace and is missing information such as IEP dates and qualifiers. This information is not yet available for export from Ascender. 

.LINK

https://fikesmedia.com
#>


param(
    [Parameter(Position=0,mandatory=$True)]
	[string]$ImportCSV,
	[Parameter(Position=1,mandatory=$True)]
	[string]$ExportCSV = "EmbraceStudentImport.csv",
	[string]$WorkingFile = "WorkingFile.csv"
)

# Clean Up Previous
Remove-Item $ExportCSV -Force

# Import SPED Export Ascender
Import-CSV -Path $ImportCSV -Header "Student ID","State Student ID (SSN)","Student First Name","Student Middle Name","Student Last Name","Student Generation Code","Name Student Goes By","Student Address 1 (Physical)","Student Address 2 (Physical)","Student City (Physical)","Student State (Physical)","Student ZIP Code (Physical)","Student Phone Number","Student DOB","Student Medicaid ID","Student Ethnicity","Student Language","Student Home Campus","Student Home Campus Name","Transfer Campus Of Residence","Student Grade Level","Student Gender","Homeroom","Immigrant","G/T","CTE","Migrant","Title I","Economic Disadvantage","ESL/Bilingual","Parent 1 Relationship to Child","Parent 1 Last Name","Parent 1 Middle Name","Parent 1 First Name","Parent 1 Address 1","Parent 1 Address 2","Parent 1 City","Parent 1 State","Parent 1 ZIP Code","Parent 1 Phone Number","Parent 1 Work Phone Number","Parent 1 Phone (Cell or Other)","Parent 1 Occupation","Parent 1 Legal Custodian","Parent 2 Relationship to Child","Parent 2 Last Name","Parent 2 Middle Name","Parent 2 First Name","Parent 2 Address 1","Parent 2 Address 2","Parent 2 City","Parent 2 State","Parent 2 ZIP Code","Parent 2 Phone Number","Parent 2 Work Phone Number","Parent 2 Phone (Cell or Other)","Parent 2 Occupation","Parent 2 Legal Custodian","Emergency Contact Last Name","Emergency Contact Middle Name","Emergency Contact First Name","Emergency Contact Address 1","Emergency Contact Address 2","Emergency Contact City","Emergency Contact State","Emergency Contact ZIP Code","Emergency Contact Home Phone","Emergency Contact Work Phone","504","Status Description","Date W/D","Ethnicity","Race: American Indian or Alaskan Native","Race : Asian","Race: Black or African American","Race: White","Race: Native Hawaiian or Other Pacific Islander","Composite/Ethnicity Code Aggregate","Parent 1 Email","Parent 2 Email","Emergency Email","Student Address 1 (Mailing)","Student Address 2 (Mailing)","Student City (Mailing)","Student State (Mailing)","Student ZIP Code (Mailing)","Parent 1 Emergency Contact Indicator","Parent 2 Emergency Contact Indicator","Texas Unique Student ID","At Risk Indicator","LEP Indicator","LEP Parent Permission Description" |
  # Loop Rows Creating new structure
  ForEach-Object {
		$csvRow = New-Object -TypeName psobject
		# Res_District_Code
		$csvRow | Add-Member -NotePropertyName "Res_District_Code" -NotePropertyValue $($_."Student Home Campus".SubString(0,6))
		# **FirstName
		$csvRow | Add-Member -NotePropertyName "**FirstName" -NotePropertyValue $_."Student First Name"
		# MiddleName
		$csvRow | Add-Member -NotePropertyName "MiddleName" -NotePropertyValue $_."Student Middle Name"
		# **LastName
		$csvRow | Add-Member -NotePropertyName "**LastName" -NotePropertyValue $_."Student Last Name"
		# Student_District_ID
		$csvRow | Add-Member -NotePropertyName "Student_District_ID" -NotePropertyValue $_."Student ID"
		# **StateID(SIS #)
		$csvRow | Add-Member -NotePropertyName "**StateID(SIS #)" -NotePropertyValue $_."Texas Unique Student ID"
		# **DOB
		$csvRow | Add-Member -NotePropertyName "**DOB" -NotePropertyValue $_."Student DOB"
		# HasIEP 
		$csvRow | Add-Member -NotePropertyName "HasIEP" -NotePropertyValue ""
		# Has504
		switch($_."504") {
			"No" { $Has504 = "0" }
			"Yes" { $Has504 = "1" }
			Default { $Has504 = "" }
		}
		$csvRow | Add-Member -NotePropertyName "Has504" -NotePropertyValue $Has504
		# HasMTSS
		$csvRow | Add-Member -NotePropertyName "HasMTSS" -NotePropertyValue ""
		# Medicaid_Number
		$csvRow | Add-Member -NotePropertyName "Medicaid_Number" -NotePropertyValue ""
		# Last_Eval_Date
		$csvRow | Add-Member -NotePropertyName "Last_Eval_Date" -NotePropertyValue ""
		# Initial_Eval_Consent
		$csvRow | Add-Member -NotePropertyName "Initial_Eval_Consent" -NotePropertyValue ""
		# Reeval_Consent
		$csvRow | Add-Member -NotePropertyName "Reeval_Consent" -NotePropertyValue ""
		# Next_Annual_Review
		$csvRow | Add-Member -NotePropertyName "Next_Annual_Review" -NotePropertyValue ""
		# Primary_Elig
		$csvRow | Add-Member -NotePropertyName "Primary_Elig" -NotePropertyValue ""
		# Secondary_Elig
		$csvRow | Add-Member -NotePropertyName "Secondary_Elig" -NotePropertyValue ""
		# **Grade_Level
		Switch($_."Student Grade Level") {
			"EE" { $GRADELEVEL = "00" }
			"PK" { $GRADELEVEL = "14" }
			"KG" { $GRADELEVEL = "15" }
			"01" { $GRADELEVEL = "01" }
			"02" { $GRADELEVEL = "02" }
			"03" { $GRADELEVEL = "03" }
			"04" { $GRADELEVEL = "04" }
			"05" { $GRADELEVEL = "05" }
			"06" { $GRADELEVEL = "06" }
			"07" { $GRADELEVEL = "07" }
			"08" { $GRADELEVEL = "08" }
			"09" { $GRADELEVEL = "09" }
			"10" { $GRADELEVEL = "10" }
			"11" { $GRADELEVEL = "11" }
			"12" { $GRADELEVEL = "12" }
			Default { $GRADELEVEL = "" }		
		}
		$csvRow | Add-Member -NotePropertyName "**Grade_Level" -NotePropertyValue $GRADELEVEL
		# Case_Manager
		$csvRow | Add-Member -NotePropertyName "Case_Manager" -NotePropertyValue ""
		# HomeSchool
		$csvRow | Add-Member -NotePropertyName "HomeSchool" -NotePropertyValue ""
		# **ServingSchool
		$csvRow | Add-Member -NotePropertyName "**ServingSchool" -NotePropertyValue $_."Student Home Campus"
		#  Anticpated_HS_Grad
		$csvRow | Add-Member -NotePropertyName "Anticpated_HS_Grad" -NotePropertyValue ""
		# **Next_Grade
		$csvRow | Add-Member -NotePropertyName "**Next_Grade" -NotePropertyValue ""
		# Next_school
		$csvRow | Add-Member -NotePropertyName "Next_school" -NotePropertyValue ""
		# Gender
		$csvRow | Add-Member -NotePropertyName "Gender" -NotePropertyValue $_."Student Gender"
		# Race
		Switch($_."Composite/Ethnicity Code Aggregate") {
			"W" { $RACE = "16" }
			"B" { $RACE = "14" }
			"H" { $RACE = "11" }
			"M" { $RACE = "17" }
			Default { $RACE = "" }
		}
		$csvRow | Add-Member -NotePropertyName "Race" -NotePropertyValue $RACE
		# PrimaryLanguage
		Switch($_."Student Language") {
			"English" { $PRIMARYLANGUAGE = "000"}
			"Spanish" { $PRIMARYLANGUAGE = "001"}
			"Greek" { $PRIMARYLANGUAGE = "002"}
			"Italian" { $PRIMARYLANGUAGE = "003"}
			"Polish" { $PRIMARYLANGUAGE = "004"}
			"German" { $PRIMARYLANGUAGE = "005"}
			"Algonquin" { $PRIMARYLANGUAGE = "006"}
			"Serbian" { $PRIMARYLANGUAGE = "007"}
			"Korean" { $PRIMARYLANGUAGE = "008"}
			"Pilipino" { $PRIMARYLANGUAGE = "009"}
			"Arabic" { $PRIMARYLANGUAGE = "010"}
			"Japanese" { $PRIMARYLANGUAGE = "011"}
			"French" { $PRIMARYLANGUAGE = "012"}
			"Samoan" { $PRIMARYLANGUAGE = "013"}
			"Hindi" { $PRIMARYLANGUAGE = "014"}
			"Burmese" { $PRIMARYLANGUAGE = "015"}
			"Yiddish" { $PRIMARYLANGUAGE = "016"}
			"Lithuanian" { $PRIMARYLANGUAGE = "017"}
			"Ukrainian" { $PRIMARYLANGUAGE = "018"}
			"Hungarian" { $PRIMARYLANGUAGE = "019"}
			"Czech" { $PRIMARYLANGUAGE = "020"}
			"Cantonese" { $PRIMARYLANGUAGE = "021"}
			"Thai" { $PRIMARYLANGUAGE = "022"}
			"Portuguese" { $PRIMARYLANGUAGE = "023"}
			"Swedish" { $PRIMARYLANGUAGE = "024"}
			"Assyrian" { $PRIMARYLANGUAGE = "025"}
			"Armenian" { $PRIMARYLANGUAGE = "026"}
			"Romanian" { $PRIMARYLANGUAGE = "027"}
			"Dutch/Flemish" { $PRIMARYLANGUAGE = "028"}
			"Hebrew" { $PRIMARYLANGUAGE = "029"}
			"Mandarin" { $PRIMARYLANGUAGE = "030"}
			"Farsi" { $PRIMARYLANGUAGE = "031"}
			"Turkish" { $PRIMARYLANGUAGE = "032"}
			"Urdu" { $PRIMARYLANGUAGE = "033"}
			"Vietnamese" { $PRIMARYLANGUAGE = "034"}
			"Russian" { $PRIMARYLANGUAGE = "035"}
			"Cebuano" { $PRIMARYLANGUAGE = "036"}
			"Gujarati" { $PRIMARYLANGUAGE = "037"}
			"Latvian" { $PRIMARYLANGUAGE = "038"}
			"Sioux" { $PRIMARYLANGUAGE = "039"}
			"Norwegian" { $PRIMARYLANGUAGE = "040"}
			"Danish" { $PRIMARYLANGUAGE = "041"}
			"Albanian" { $PRIMARYLANGUAGE = "042"}
			"Comanche" { $PRIMARYLANGUAGE = "043"}
			"Finnish" { $PRIMARYLANGUAGE = "044"}
			"Slovak" { $PRIMARYLANGUAGE = "045"}
			"Swahili" { $PRIMARYLANGUAGE = "046"}
			"Taiwanese" { $PRIMARYLANGUAGE = "047"}
			"Creek" { $PRIMARYLANGUAGE = "048"}
			"Haitian" { $PRIMARYLANGUAGE = "049"}
			"Chippewa" { $PRIMARYLANGUAGE = "050"}
			"Gbaya" { $PRIMARYLANGUAGE = "051"}
			"Ewe" { $PRIMARYLANGUAGE = "052"}
			"Panjabi" { $PRIMARYLANGUAGE = "053"}
			"Bemba" { $PRIMARYLANGUAGE = "054"}
			"Bulgarian" { $PRIMARYLANGUAGE = "055"}
			"Apache" { $PRIMARYLANGUAGE = "056"}
			"Gaelic" { $PRIMARYLANGUAGE = "057"}
			"Macedonian" { $PRIMARYLANGUAGE = "058"}
			"Malay" { $PRIMARYLANGUAGE = "059"}
			"Malayalam" { $PRIMARYLANGUAGE = "060"}
			"Navajo" { $PRIMARYLANGUAGE = "061"}
			"Indonesian" { $PRIMARYLANGUAGE = "062"}
			"Kannada" { $PRIMARYLANGUAGE = "063"}
			"Estonian" { $PRIMARYLANGUAGE = "064"}
			"Chichewa" { $PRIMARYLANGUAGE = "065"}
			"Kashmiri" { $PRIMARYLANGUAGE = "066"}
			"Bengali" { $PRIMARYLANGUAGE = "067"}
			"Hmong" { $PRIMARYLANGUAGE = "068"}
			"Kanuri" { $PRIMARYLANGUAGE = "069"}
			"Icelandic" { $PRIMARYLANGUAGE = "070"}
			"Ga" { $PRIMARYLANGUAGE = "071"}
			"Menominee" { $PRIMARYLANGUAGE = "072"}
			"Cambodian" { $PRIMARYLANGUAGE = "073"}
			"Lao" { $PRIMARYLANGUAGE = "074"}
			"Shona" { $PRIMARYLANGUAGE = "075"}
			"Afrikaans" { $PRIMARYLANGUAGE = "076"}
			"Nepali" { $PRIMARYLANGUAGE = "077"}
			"Marathi" { $PRIMARYLANGUAGE = "078"}
			"Oneida" { $PRIMARYLANGUAGE = "079"}
			"Hausa" { $PRIMARYLANGUAGE = "080"}
			"Hemba" { $PRIMARYLANGUAGE = "081"}
			"Pima" { $PRIMARYLANGUAGE = "082"}
			"Isoko" { $PRIMARYLANGUAGE = "083"}
			"Pueblo" { $PRIMARYLANGUAGE = "084"}
			"Ibo/Igbo" { $PRIMARYLANGUAGE = "085"}
			"Telugu" { $PRIMARYLANGUAGE = "086"}
			"Choctaw" { $PRIMARYLANGUAGE = "087"}
			"Winnebago" { $PRIMARYLANGUAGE = "088"}
			"Kikamba" { $PRIMARYLANGUAGE = "089"}
			"Yoruba" { $PRIMARYLANGUAGE = "090"}
			"Maltese" { $PRIMARYLANGUAGE = "091"}
			"Luo" { $PRIMARYLANGUAGE = "092"}
			"Romany" { $PRIMARYLANGUAGE = "093"}
			"Tamil" { $PRIMARYLANGUAGE = "094"}
			"Hopi" { $PRIMARYLANGUAGE = "095"}
			"Slovenian" { $PRIMARYLANGUAGE = "096"}
			"Cherokee" { $PRIMARYLANGUAGE = "097"}
			"Crow" { $PRIMARYLANGUAGE = "098"}
			"Other" { $PRIMARYLANGUAGE = "099"}
			"Mandingo" { $PRIMARYLANGUAGE = "100"}
			"Mende" { $PRIMARYLANGUAGE = "101"}
			"Gaelic" { $PRIMARYLANGUAGE = "102"}
			"Akan" { $PRIMARYLANGUAGE = "103"}
			"Tuluau" { $PRIMARYLANGUAGE = "104"}
			"Amharic" { $PRIMARYLANGUAGE = "105"}
			"Oulof" { $PRIMARYLANGUAGE = "106"}
			"Balinese" { $PRIMARYLANGUAGE = "107"}
			"Chamorro" { $PRIMARYLANGUAGE = "108"}
			"Tigrinya" { $PRIMARYLANGUAGE = "109"}
			"Assamese" { $PRIMARYLANGUAGE = "110"}
			"Eskimo" { $PRIMARYLANGUAGE = "111"}
			"Bagheli" { $PRIMARYLANGUAGE = "112"}
			"Hakka" { $PRIMARYLANGUAGE = "113"}
			"Welsh" { $PRIMARYLANGUAGE = "114"}
			"Guyanese" { $PRIMARYLANGUAGE = "115"}
			"Bisaya" { $PRIMARYLANGUAGE = "116"}
			"Chechen" { $PRIMARYLANGUAGE = "117"}
			"Pampangan" { $PRIMARYLANGUAGE = "118"}
			"Konkani" { $PRIMARYLANGUAGE = "119"}
			"Krio" { $PRIMARYLANGUAGE = "120"}
			"Kurdish" { $PRIMARYLANGUAGE = "121"}
			"Lingala" { $PRIMARYLANGUAGE = "122"}
			"Luganda" { $PRIMARYLANGUAGE = "123"}
			"Luyia" { $PRIMARYLANGUAGE = "124"}
			"Lunda" { $PRIMARYLANGUAGE = "125"}
			"Yombe" { $PRIMARYLANGUAGE = "126"}
			"Okinawan" { $PRIMARYLANGUAGE = "127"}
			"Oriya" { $PRIMARYLANGUAGE = "128"}
			"Orri" { $PRIMARYLANGUAGE = "129"}
			"Ilocano" { $PRIMARYLANGUAGE = "130"}
			"Pashto" { $PRIMARYLANGUAGE = "131"}
			"Sikkimese" { $PRIMARYLANGUAGE = "132"}
			"Sindhi" { $PRIMARYLANGUAGE = "133"}
			"Sinhalese" { $PRIMARYLANGUAGE = "134"}
			"Sotho" { $PRIMARYLANGUAGE = "135"}
			"Kashi" { $PRIMARYLANGUAGE = "136"}
			"Tibetan" { $PRIMARYLANGUAGE = "137"}
			"Maori" { $PRIMARYLANGUAGE = "138"}
			"Kache" { $PRIMARYLANGUAGE = "139"}
			"Mina" { $PRIMARYLANGUAGE = "140"}
			"Mongolian" { $PRIMARYLANGUAGE = "141"}
			"Kpelle" { $PRIMARYLANGUAGE = "142"}
			"Ilonggo" { $PRIMARYLANGUAGE = "143"}
			"Efik" { $PRIMARYLANGUAGE = "144"}
			"Sourashtra" { $PRIMARYLANGUAGE = "145"}
			"Mien" { $PRIMARYLANGUAGE = "146"}
			"Chaochow" { $PRIMARYLANGUAGE = "147"}
			"Fukien" { $PRIMARYLANGUAGE = "148"}
			"Hainanese" { $PRIMARYLANGUAGE = "149"}
			"Shanghai" { $PRIMARYLANGUAGE = "150"}
			"Croatian" { $PRIMARYLANGUAGE = "151"}
			"Bosnian" { $PRIMARYLANGUAGE = "152"}
			"Albanian" { $PRIMARYLANGUAGE = "153"}
			"Tongan" { $PRIMARYLANGUAGE = "154"}
			"Uzbek" { $PRIMARYLANGUAGE = "155"}
			"Jamaican" { $PRIMARYLANGUAGE = "156"}
			"Dinlea" { $PRIMARYLANGUAGE = "157"}
			"Chaldean" { $PRIMARYLANGUAGE = "158"}
			"Kanjobal" { $PRIMARYLANGUAGE = "159"}
			"Palauan" { $PRIMARYLANGUAGE = "160"}
			"Hawaiian" { $PRIMARYLANGUAGE = "161"}
			"Maay" { $PRIMARYLANGUAGE = "162"}
			"Krahn" { $PRIMARYLANGUAGE = "163"}
			"Somali" { $PRIMARYLANGUAGE = "164"}
			"American" { $PRIMARYLANGUAGE = "165"}
			"Chin" { $PRIMARYLANGUAGE = "166"}
			"Karen" { $PRIMARYLANGUAGE = "167"}
			"Kirundi" { $PRIMARYLANGUAGE = "168"}
			"Chuj" { $PRIMARYLANGUAGE = "169"}
			"Ladino" { $PRIMARYLANGUAGE = "171"}
			"Tiv" { $PRIMARYLANGUAGE = "176"}
			"Tedim" { $PRIMARYLANGUAGE = "181"}
			"Senthang" { $PRIMARYLANGUAGE = "182"}
			"Runyankore" { $PRIMARYLANGUAGE = "184"}
			"Kunama" { $PRIMARYLANGUAGE = "188"}
			"Edo" { $PRIMARYLANGUAGE = "600"}
			"Twi" { $PRIMARYLANGUAGE = "601"}
			"Visayan" { $PRIMARYLANGUAGE = "602"}
			"Marshallese" { $PRIMARYLANGUAGE = "603"}
			"Bikol" { $PRIMARYLANGUAGE = "604"}
			"Yakama" { $PRIMARYLANGUAGE = "605"}
			"Sohaptian" { $PRIMARYLANGUAGE = "606"}
			"Georgian" { $PRIMARYLANGUAGE = "607"}
			"Kiribati" { $PRIMARYLANGUAGE = "608"}
			"Chinese" { $PRIMARYLANGUAGE = "609"}
			"Aguacageco" { $PRIMARYLANGUAGE = "610"}
			"Axerbaijani" { $PRIMARYLANGUAGE = "611"}
			"Byelorussian" { $PRIMARYLANGUAGE = "612"}
			"Dagbani" { $PRIMARYLANGUAGE = "613"}
			"Egyptian" { $PRIMARYLANGUAGE = "614"}
			"Fijian" { $PRIMARYLANGUAGE = "615"}
			"Ndebele" { $PRIMARYLANGUAGE = "616"}
			"Nuer" { $PRIMARYLANGUAGE = "617"}
			"Oromo" { $PRIMARYLANGUAGE = "618"}
			"Philippine" { $PRIMARYLANGUAGE = "619"}
			"Serbo" { $PRIMARYLANGUAGE = "620"}
			"Sidamic" { $PRIMARYLANGUAGE = "621"}
			"Siraiki" { $PRIMARYLANGUAGE = "622"}
			Default { $PRIMARYLANGUAGE = "" }
		}
		$csvRow | Add-Member -NotePropertyName "PrimaryLanguage" -NotePropertyValue $PRIMARYLANGUAGE		
		# Student_StreetAddress
		$csvRow | Add-Member -NotePropertyName "Student_StreetAddress" -NotePropertyValue $_."Student Address 1 (Physical)"
		# Student_City
		$csvRow | Add-Member -NotePropertyName "Student_City" -NotePropertyValue $_."Student City (Physical)"
		# Student_State
		$csvRow | Add-Member -NotePropertyName "Student_State" -NotePropertyValue $_."Student State (Physical)"
		# Student_Zip
		$csvRow | Add-Member -NotePropertyName "Student_Zip" -NotePropertyValue $_."Student ZIP Code (Physical)"
		# Student_Phone
		$csvRow | Add-Member -NotePropertyName "Student_Phone" -NotePropertyValue $_."Student Phone Number"
		# EmergencyContactName
		$csvRow | Add-Member -NotePropertyName "EmergencyContactName" -NotePropertyValue $_."Emergency Contact First Name"
		# EmergencyContactPhone
		$csvRow | Add-Member -NotePropertyName "EmergencyContactPhone" -NotePropertyValue $_."Emergency Contact Home Phone"
		# Parent_Name
		$PARENTNAME = $_."Parent 1 First Name" + " " + $_."Parent 1 Last Name"
		$csvRow | Add-Member -NotePropertyName "Parent_Name" -NotePropertyValue $PARENTNAME
		# Parent_Address
		$csvRow | Add-Member -NotePropertyName "Parent_Address" -NotePropertyValue $_."Parent 1 Address 1"
		# Parent_City
		$csvRow | Add-Member -NotePropertyName "Parent_City" -NotePropertyValue $_."Parent 1 City"
		# Parent_State
		$csvRow | Add-Member -NotePropertyName "Parent_State" -NotePropertyValue $_."Parent 1 State"
		# Parent_Zip
		$csvRow | Add-Member -NotePropertyName "Parent_Zip" -NotePropertyValue $_."Parent 1 ZIP Code"
		# Parent_Home_Phone
		$csvRow | Add-Member -NotePropertyName "Parent_Home_Phone" -NotePropertyValue $_."Parent 1 Phone Number"
		# Parent_Cell
		$csvRow | Add-Member -NotePropertyName "Parent_Cell" -NotePropertyValue $_."Parent 1 Phone (Cell or Other)"
		# Parent_Work_Phone
		$csvRow | Add-Member -NotePropertyName "Parent_Work_Phone" -NotePropertyValue $_."Parent 1 Work Phone Number"
		# Parent_Language
		$csvRow | Add-Member -NotePropertyName "Parent_Language" -NotePropertyValue ""
		# Parent_Email
		$csvRow | Add-Member -NotePropertyName "Parent_Email" -NotePropertyValue $_."Parent 1 Email"
		# Second_Parent_Name
		$PARENTNAME = $_."Parent 2 First Name" + " " + $_."Parent 2 Last Name"
		$csvRow | Add-Member -NotePropertyName "Second_Parent_Name" -NotePropertyValue $PARENTNAME
		# Second_Parent_Address
		$csvRow | Add-Member -NotePropertyName "Second_Parent_Address" -NotePropertyValue $_."Parent 2 Address 1"
		# Second_Parent_City
		$csvRow | Add-Member -NotePropertyName "Second_Parent_City" -NotePropertyValue $_."Parent 2 City"
		# Second_Parent_State
		$csvRow | Add-Member -NotePropertyName "Second_Parent_State" -NotePropertyValue $_."Parent 2 State"
		# Second_Parent_Zip
		$csvRow | Add-Member -NotePropertyName "Second_Parent_Zip" -NotePropertyValue $_."Parent 2 ZIP Code"
		# Second_Parent_Home_Phone
		$csvRow | Add-Member -NotePropertyName "Second_Parent_Home_Phone" -NotePropertyValue $_."Parent 2 Phone Number"
		# Second_Parent_Cell
		$csvRow | Add-Member -NotePropertyName "Second_Parent_Cell" -NotePropertyValue $_."Parent 2 Phone (Cell or Other)"
		# Second_Parent_Work_Phone
		$csvRow | Add-Member -NotePropertyName "Second_Parent_Work_Phone" -NotePropertyValue $_."Parent 2 Work Phone Number"
		# Second_Parent_Language
		$csvRow | Add-Member -NotePropertyName "Second_Parent_Language" -NotePropertyValue ""
		# Second_Parent_Email
		$csvRow | Add-Member -NotePropertyName "Second_Parent_Email" -NotePropertyValue $_."Parent 2 Email"
		# Inactivate
		$csvRow | Add-Member -NotePropertyName "Inactivate" -NotePropertyValue ""
		# IEP Referral
		$csvRow | Add-Member -NotePropertyName "IEP Referral" -NotePropertyValue ""
		# Cur_Sch_Yr
		$csvRow | Add-Member -NotePropertyName "Cur_Sch_Yr" -NotePropertyValue ""
		# Next_Sch_Yr
		$csvRow | Add-Member -NotePropertyName "Next_Sch_Yr" -NotePropertyValue ""
		# ELL
		$csvRow | Add-Member -NotePropertyName "ELL" -NotePropertyValue ""
		# HasISP
		$csvRow | Add-Member -NotePropertyName "HasISP" -NotePropertyValue ""
		# Medicaid_Consent_Status
		$csvRow | Add-Member -NotePropertyName "Medicaid_Consent_Status" -NotePropertyValue ""
		# Medicaid_Consent_Date
		$csvRow | Add-Member -NotePropertyName "Medicaid_Consent_Date" -NotePropertyValue ""
		# Initial_Eligibility_Determination_Date
		$csvRow | Add-Member -NotePropertyName "Initial_Eligibility_Determination_Date" -NotePropertyValue ""
		# 504_Referral
		$csvRow | Add-Member -NotePropertyName "504_Referral" -NotePropertyValue ""
		# 504_Last_Evaluation_Date
		$csvRow | Add-Member -NotePropertyName "504_Last_Evaluation_Date" -NotePropertyValue ""
		# 504_Initial_Evaluation_Consent_Date
		$csvRow | Add-Member -NotePropertyName "504_Initial_Evaluation_Consent_Date" -NotePropertyValue ""
		# 504_Initial_Eligibility_Determination_Date
		$csvRow | Add-Member -NotePropertyName "504_Initial_Eligibility_Determination_Date" -NotePropertyValue ""
		# 504_Reevaluation_Consent_Date
		$csvRow | Add-Member -NotePropertyName "504_Reevaluation_Consent_Date" -NotePropertyValue ""
		# 504_Next_Annual_Review_Date"
		$csvRow | Add-Member -NotePropertyName "504_Next_Annual_Review_Date" -NotePropertyValue ""
		# 504_Initial_Plan_Date
		$csvRow | Add-Member -NotePropertyName "504_Initial_Plan_Date" -NotePropertyValue ""
		# 504_Ineligible
		$csvRow | Add-Member -NotePropertyName "504_Ineligible" -NotePropertyValue ""
		# 504_Inelgible_Date
		$csvRow | Add-Member -NotePropertyName "504_Inelgible_Date" -NotePropertyValue ""
		# Hearing_Screening_Date
		$csvRow | Add-Member -NotePropertyName "Hearing_Screening_Date" -NotePropertyValue ""
		# Hearing_Screening_Pass
		$csvRow | Add-Member -NotePropertyName "Hearing_Screening_Pass" -NotePropertyValue ""
		# Hearing_Screening_Fail
		$csvRow | Add-Member -NotePropertyName "Hearing_Screening_Fail" -NotePropertyValue ""
		# Vision_Screening_Date
		$csvRow | Add-Member -NotePropertyName "Vision_Screening_Date" -NotePropertyValue ""
		# Vision_Screening_Pass
		$csvRow | Add-Member -NotePropertyName "Vision_Screening_Pass" -NotePropertyValue ""
		# Vision_Screening_Fail
		$csvRow | Add-Member -NotePropertyName "Vision_Screening_Fail" -NotePropertyValue ""
		# Hearing_Vision_Notes
		$csvRow | Add-Member -NotePropertyName "Hearing_Vision_Notes" -NotePropertyValue ""
		# Student_Address_Line_Two
		$csvRow | Add-Member -NotePropertyName "Student_Address_Line_Two" -NotePropertyValue $_."Student Address 2 (Physical)"
		# Parent_Address_Line_Two
		$csvRow | Add-Member -NotePropertyName "Parent_Address_Line_Two" -NotePropertyValue $_."Parent 1 Address 2"
		# Second_Parent_Address_Line_Two
		$csvRow | Add-Member -NotePropertyName "Second_Parent_Address_Line_Two" -NotePropertyValue $_."Parent 2 Address 2"
		# Ethnicity
		Switch($_."Ethnicity") {
			"1" { $ETHNICITY = "HL" }
			"0" { $ETHNICITY = "NHL" }
			Default { $ETHNICITY = "" }
		}
		$csvRow | Add-Member -NotePropertyName "Ethnicity" -NotePropertyValue $ETHNICITY
		# 504_Eligible
		$csvRow | Add-Member -NotePropertyName "504_Eligible" -NotePropertyValue ""
		# 504_Eligible_Date
		$csvRow | Add-Member -NotePropertyName "504_Eligible_Date" -NotePropertyValue ""
		# Medical_Alert
		$csvRow | Add-Member -NotePropertyName "Medical_Alert" -NotePropertyValue ""
		# Medical_Alert_Details
		$csvRow | Add-Member -NotePropertyName "Medical_Alert_Details" -NotePropertyValue ""
		# Next_Year_Home_School
		$csvRow | Add-Member -NotePropertyName "Next_Year_Home_School" -NotePropertyValue ""
		# Tertiary_Eligibility
		$csvRow | Add-Member -NotePropertyName "Tertiary_Eligibility" -NotePropertyValue ""
		# IEP_Evaluation_End_Date
		$csvRow | Add-Member -NotePropertyName "IEP_Evaluation_End_Date" -NotePropertyValue ""
		# IEP_Start_Date
		$csvRow | Add-Member -NotePropertyName "IEP_Start_Date" -NotePropertyValue ""
		# IEP_End_Date
		$csvRow | Add-Member -NotePropertyName "IEP_End_Date" -NotePropertyValue ""
		# Secondary_District_Code
		$csvRow | Add-Member -NotePropertyName "Secondary_District_Code" -NotePropertyValue ""
		# Student_Lives_With
		$csvRow | Add-Member -NotePropertyName "Student_Lives_With" -NotePropertyValue ""
		# Pre_Enrollment_Status
		$csvRow | Add-Member -NotePropertyName "Pre_Enrollment_Status" -NotePropertyValue ""
		# Gifted_Talented
		$csvRow | Add-Member -NotePropertyName "Gifted_Talented" -NotePropertyValue ""
		# Economic_Disadvantaged
		Switch($_."Economic Disadvantage") {
			"Yes" { $ED = "1" }
			"No" { $ED = "0" }
			Default { $ED = "" }
		}
		$csvRow | Add-Member -NotePropertyName "Economic_Disadvantaged" -NotePropertyValue $ED	
		# Migrant_Status
		Switch($_."Migrant") {
			"Yes" { $MIGRANT = "1" }
			"No" { $MIGRANT = "0" }
			Default { $MIGRANT = "" }
		}
		$csvRow | Add-Member -NotePropertyName "Migrant_Status" -NotePropertyValue $MIGRANT		
		# Parent_Preferred_Language
		$csvRow | Add-Member -NotePropertyName "Parent_Preferred_Language" -NotePropertyValue ""
		# Triennial_Reevaluation_Due_Date
		$csvRow | Add-Member -NotePropertyName "Triennial_Reevaluation_Due_Date" -NotePropertyValue ""
		
		# Output File
		$csvRow | Export-CSV -Path $WorkingFile -Append -NoTypeInformation
		
  }
  
# Remove Headers
Get-Content $WorkingFile | Select-Object -Skip 1 | Out-File $ExportCSV

# Remove Working File
Remove-Item $WorkingFile -Force