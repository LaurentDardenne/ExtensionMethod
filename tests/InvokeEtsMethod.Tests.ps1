
Import-Module '..\Release\Extensionmethod\\ExtensionMethod.psd1'

<#
 #redirect stdOut

$Writer = [System.IO.StreamWriter]::new("$temp\Pester.txt")
$Writer.AutoFlush = $true
$OriginalOut = [System.Console]::Out
try
{
    [System.Console]::SetOut($Writer)
    $a=[BasicTest]::my('tt')
}
finally
{
    [System.Console]::SetOut($OriginalOut)
    $Writer.Close()
}
#>

$EtsFileName="$Env:Temp\ExtensionMethodClass.ps1xml"
Push-Location ".\src"
 $Assembly=.\ExtensionMethod.Class.ps1
Pop-Location

$Assembly|New-ExtendedTypeData -Path $EtsFileName -All -Force
Update-TypeData -PrependPath $EtsFileName

Describe 'Invoke ETS method provided by [BasicTest]' {

  it 'Invoke My()' {
    'String'.My()|Should -be 1
  }

  it 'Invoke My(int)' {
    'String'.My(10)|Should -be 2
  }

  it 'Invoke My(String)' {
    'String'.My('test')|Should -be 3
  }

}

