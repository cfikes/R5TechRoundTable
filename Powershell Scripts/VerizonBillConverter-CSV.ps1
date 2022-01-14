[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

$Form1 = New-Object System.Windows.Forms.Form
$Form1.ClientSize = "480, 240"
$Form1.TopMost = $true
$Form1.text = "Verizon CSV to Sorted CSV Converter"

$TextBox1 = New-Object System.Windows.Forms.TextBox
$TextBox1.Anchor = "Top,Bottom,Left,Right"
$TextBox1.Location = "12, 12"
$TextBox1.Multiline = $true
$TextBox1.ScrollBars = "Both"
$TextBox1.Size = "450, 210"
$TextBox1.AllowDrop = $true
$TextBox1.Text="Drag CSV file here to convert.`r`n"
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
    
    #$TextBox1.AppendText(Environment.NewLine)
    $TextBox1.AppendText("`r`nProcessing File:`r`n")
    $TextBox1.AppendText($file+[char]13+[char]10)
    #$TextBox1.AppendText($FileNameOutput+[char]13+[char]10)
  
    $OutputFile = $FileNameOutput+'-Sorted.csv'

    
$lines = Get-Content -Path $file | Select-Object -Skip 8 

$lines = Import-Csv $file -Header "CostCenter","Number/User","AccountCharges","MonthlyAccessCharges","UsageCharges","EquipmentCharges","VZWSurcharges","Taxes","ThirdPartyCharges","Total"
$LineLength = 0 
$CSVLength = foreach($line in $lines) {
    $LineLength += 1 
}



$BilledLines =@()


$Counter=0
foreach ($line in $lines) {
    # SKip Verizons Incorrect Formatting
    if($Counter -gt 4 -and $Counter -lt ($LineLength - 2)) {

        $MTNUserArray =  $line.'Number/User'.Split("/")
        $MTN = $MTNUserArray[0].Trim()
        $MTNNameArray = $MTNUserArray[1].trim().Split(" ")
        $LastName = $MTNNameArray[1].Trim()
        $FirstName = $MTNNameArray[0].Trim()

        if ($MTN -ne $null) {
            $BilledLine = New-Object -TypeName psobject
            $BilledLine | Add-Member -MemberType NoteProperty -Name "MTN" -Value $MTN
            $BilledLine | Add-Member -MemberType NoteProperty -Name "LastName" -Value $LastName
            $BilledLine | Add-Member -MemberType NoteProperty -Name "FirstName" -Value $FirstName
            $BilledLine | Add-Member -MemberType NoteProperty -Name "AccountCharges" -Value $line.AccountCharges
            $BilledLine | Add-Member -MemberType NoteProperty -Name "MonthlyAccessCharges" -Value $line.MonthlyAccessCharges
            $BilledLine | Add-Member -MemberType NoteProperty -Name "UsageCharges" -Value $line.UsageCharges
            $BilledLine | Add-Member -MemberType NoteProperty -Name "EquipmentCharges" -Value $line.EquipmentCharges
            $BilledLine | Add-Member -MemberType NoteProperty -Name "VZWSurcharges" -Value $line.VZWSurcharges
            $BilledLine | Add-Member -MemberType NoteProperty -Name "Taxes" -Value $line.Taxes
            $BilledLine | Add-Member -MemberType NoteProperty -Name "ThirdPartyCharges" -Value $line.ThirdPartyCharges
            $BilledLine | Add-Member -MemberType NoteProperty -Name "Total" -Value $line.Total
            

        }

        $BilledLines += $BilledLine

    }
    $Counter += 1
}
    $BilledLines | Sort-Object -Property LastName | Export-Csv -Path $OutputFile -NoTypeInformation

    $TextBox1.AppendText("`r`nOperation Complete`r`n"+$FileNameOutput+"-Sorted.csv Created.`r`n"+"`r`nENJOY!")

  }
}



[System.Windows.Forms.Application]::Run($Form1)