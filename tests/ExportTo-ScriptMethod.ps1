Function New-ScriptFileName {
 [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions","",
                                                    Justification="New-ScriptFileName do not change the system state, it create only a file name.")]
  <#
  .SYNOPSIS
    Create a new file name from a type data file (.ps1Xmlml).
    The name of the new file is equal to the "$TargertDirectory\$($File.Basename).ps1"
  .DESCRIPTION
    Long description
  .EXAMPLE
    PS C:\> $NewFile=ConvertTo-ScriptFileName -File $File -TargetDirectory $TargetDirectory 
    Explanation of what the example does todo
  .INPUTS
    [string]
  .OUTPUTS
    [string]
  .NOTES
    General notes
  #>
  param(
    # Specifies a path to one or more .ps1xml type data file.
     [Parameter(Mandatory=$true,
                Position=0,
                ValueFromPipeline=$true,
                HelpMessage="Path to one or more .ps1Xml type data file.")]
     [Alias("PSPath")]
     [ValidateNotNullOrEmpty()]
    [string] $File,

     # The destination directory for news files. The default value is : $env:temp
      [Parameter(Mandatory=$true)]
     [ValidateNotNullOrEmpty()]
    [string] $TargetDirectory
  
  )
  process {
       #todo control PSPath, relatif, litteral->'F[0]', etc...
    $ScriptFile=[System.IO.FileInfo]::New($File)
    Write-output ("{0}\{1}{2}" -F $TargetDirectory,$ScriptFile.BaseName,'.ps1')
  }
}
 
Function Export-ScriptMethod {
  <#
  .SYNOPSIS
    Extract scriptblocks of a ScriptMethod from a type data file (.ps1Xml) and create a new file.
    The name of the new file is equal to the "$TargertDirectory\$($File.Basename).ps1"
    This file can be used with Invoke-ScriptAnalyzer.
  .DESCRIPTION
    Long description
  .EXAMPLE
    PS C:\> <example usage> todo
    Explanation of what the example does
  .INPUTS
    [string]
  .OUTPUTS
    [string]
  .NOTES
    General notes
  #>
  param(
    # Specifies a path to one or more .ps1xml type data file.
     [Parameter(Mandatory=$true,
                Position=0,
                ValueFromPipeline=$true,
                HelpMessage="Path to one or more .ps1Xml type data file.")]
     [Alias("PSPath")]
     [ValidateNotNullOrEmpty()]
    [string] $File,

     # The destination directory for news files. The default value is : $env:temp
     [ValidateNotNullOrEmpty()]
    [string] $TargetDirectory=$env:TEMP
  
  )
  process {
    Write-Debug "Read '$File'"
    [Xml]$Xml=Get-Content $File
    #On suppose le fichier xml comme étant un fichier de type Powershell (ETS) valide
    [int]$Count=0
    
    $NewFile=New-ScriptFileName -File $File -TargetDirectory $TargetDirectory
    
    $Script=New-Object System.Text.StringBuilder "# $File`r`n"
    foreach ($Type in $Xml.Types.Type)
    { 
      foreach ($ScriptMethod in $Type.Members.ScriptMethod)
      { 
          Write-Debug "Extract ScriptMethod : '$($Type.Name).$($ScriptMethod.Name)' "
          $Script.AppendLine("# $($Type.Name)") >$null
          $Script.Append("Function Name$Count") >$null
          $Script.AppendLine(".$($ScriptMethod.Name) {") >$null
          $Script.AppendLine($ScriptMethod.Script+"`r`n}") >$null  
          $count++
      }
    }
    Write-Debug "Write '$NewFile'"
    Set-Content -Value $Script.ToString() -Path $NewFile -Encoding UTF8
    Write-output $NewFile
 }
}
