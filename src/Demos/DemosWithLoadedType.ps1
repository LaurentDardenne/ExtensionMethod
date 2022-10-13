#Creates a ps1xml file containing scriptmethods associated with a type loaded in memory
Import-Module ExtensionMethod

$Filepath=$env:Temp
$TypesFileName="System.Management.Automation.Language.TokenKind.Types.ps1xml"
$FileName=Join-path -Path $Filepath -ChildPath $TypesFileName
Write-Warning "Generate file '$FileName'"

 #Generic METHODS are excluded
$Types=[psobject].Assembly.ExportedTypes|Find-ExtensionMethod -ExcludeGeneric

 #We exclude methods with generic PARAMETERS
$ExtensionMethodInfos=$Types|
      Get-ExtensionMethodInfo -ExcludeGeneric -ExcludeInterface|
      New-HashTable -key "Key" -Value "Value" -MakeArray

$ExtensionMethodInfos|Format-TableExtensionMethod

$ScriptMethods=$ExtensionMethodInfos.GetEnumerator() | New-ExtensionMethodType

#Use 'UncommonSense.PowerShell.TypeData' command
New-TypeData -PreContent '<?xml version="1.0" encoding="utf-8"?>' -Types {
  $ScriptMethods
} > $FileName

 #Same result with this call :
 #  [psobject].Assembly.ExportedTypes|
 #   New-ExtendedTypeData -Path $FileName -All -Force

 Update-TypeData -PrependPath $FileName
 Write-Warning "Load TypeData"

 $Code={
 function FunctionOne($Serveur)
 {
   Write-Warning "Test"
 }
}

$code.Ast.EndBlock.BlockKind|Get-Member -MemberType scriptMethod
 #HasTrait is a extension method, $TypesFileName contains its wrapper
$code.Ast.EndBlock.BlockKind.HasTrait('MemberName')
