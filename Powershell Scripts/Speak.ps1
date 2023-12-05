param (
    [Parameter (Position=0,Mandatory = $True,ValueFromPipeline=$true)][string]$Sentence,
    [int]$Voice=0
)

function speak {

    [CmdletBinding()]
    param (	
    [string]$Sentence,
    [int]$Voice
    ) 
    
    
    $s=New-Object -ComObject SAPI.SpVoice
    $s.Voice = $s.GetVoices().Item($Voice)
    $s.Rate = -2
    $s.Speak($Sentence)    
}

if (($Voice -eq 0) -or ($Voice -eq 1))
{
    speak $Sentence -Voice $Voice
}
