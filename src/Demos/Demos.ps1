Import-Module ExtensionMethod

$Filepath=$env:Temp
$TypesFileName="System.Management.Automation.Language.TokenKind.Types.ps1xml"
$FileName=Join-path -Path $Filepath -ChildPath $TypesFileName
Write-Warning "Generate file '$FileName'"

$Types=[psobject].Assembly.ExportedTypes|Find-ExtensionMethod -ExcludeGeneric
$ExtensionMethodInfos=$Types|
      Get-ExtensionMethodInfo -ExcludeGeneric -ExcludeInterface|
      New-HashTable -key "Key" -Value "Value" -MakeArray

$ScriptMethods=$ExtensionMethodInfos.GetEnumerator() | New-ExtensionMethodType

 Types -PreContent '<?xml version="1.0" encoding="utf-8"?>' -Types {
   $ScriptMethods
  } > $FileName

 #Same result with this call :
 #  [psobject].Assembly.ExportedTypes|
 #   New-ExtendedTypeData -Path $TypesFileName -All -Force

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


return
# !!!! This example need a specific dll.

Set-Location $env:Temp
nuget install Z.ExtensionMethods

$AssemblyPath="$env:Temp\Z.ExtensionMethods.2.0.10\lib\net45\Z.ExtensionMethods.dll"

Add-Type -Path $AssemblyPath -Pass|
 New-ExtendedTypeData -Path c:\temp\All.ps1xml -All

Add-Type -Path $AssemblyPath -Pass|
 New-ExtendedTypeData -Path c:\temp\TestPs1Xml\All.ps1xml


