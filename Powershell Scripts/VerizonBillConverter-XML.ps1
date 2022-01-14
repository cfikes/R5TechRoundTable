[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

$Form1 = New-Object System.Windows.Forms.Form
$Form1.ClientSize = "480, 240"
$Form1.TopMost = $true
$Form1.text = "Verizon XML to CSV Converter"

$TextBox1 = New-Object System.Windows.Forms.TextBox
$TextBox1.Anchor = "Top,Bottom,Left,Right"
$TextBox1.Location = "12, 12"
$TextBox1.Multiline = $true
$TextBox1.ScrollBars = "Both"
$TextBox1.Size = "450, 210"
$TextBox1.AllowDrop = $true
$TextBox1.Text="Drag XML file here to convert.`r`n"
$TextBox1.add_DragEnter({FNprocess($_)})
$TextBox1.add_DragDrop({DropProcess($_)})

$Form1.Controls.Add($TextBox1)

$dropHandler = {
    
}


function FNprocess( $object ){
  foreach ($file in $object.Data.GetFileDropList()){
    $TextBox1.AllowDrop = $false
    $FileNameOutput = Split-Path $file -leaf
    $FileNameOutput = $FileNameOutput.Substring(0,$FileNameOutput.Length-4)
    $FilePathOutput = Split-Path -Path $file
    
    #$TextBox1.AppendText(Environment.NewLine)
    $TextBox1.AppendText("`r`nProcessing File:`r`n")
    $TextBox1.AppendText($file+[char]13+[char]10)
    #$TextBox1.AppendText($FileNameOutput+[char]13+[char]10)
  
    #AddedProcessing
    $Inputfile = $file

    $xml = (Get-Content $Inputfile)
    $xml = [xml](Get-Content $Inputfile)

    $lines = $xml.Breakdown_Total_Charges_Details.Voice_and_Data.Voice_and_Data_Charges.ChildNodes

    $OutputFile = $FileNameOutput+'.csv'

    Add-Content $OutputFile "Last Name,First Name,MTN,Monthly Access,Line Usage,Equpiment Charge, Surcharge, Line Total"

    foreach ($line in $lines) {
        if($line.Cost_Center -ne 'Subtotal') { 
            $name = $line.User_Name
            $fname,$lname = $name.split(' ')
            $mtn = $line.mtn
            $MonthlyAccess = $line.Monthly_Access_Charges
            $LineUsage = $line.Usage_Charges
            $EquipmentCharge = $line.Equipment_Charges
            $Surcharge = $line.VZW_Surcharges_and_Other_Charges_and_Credits
            $LineTotal = $line.Total_Charges

            Add-Content $OutputFile "$lname,$fname,$mtn,$MonthlyAccess,$LineUsage,$EquipmentCharge,$Surcharge,$LineTotal"
        
        }
    }

    $TextBox1.AppendText("`r`nOperation Complete`r`n"+$FileNameOutput+".csv Created.`r`n"+"`r`nENJOY!")

  }
}



[System.Windows.Forms.Application]::Run($Form1)