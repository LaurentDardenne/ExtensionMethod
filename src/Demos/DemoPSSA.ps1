#Extract extension methods from a DLL
Import-Module PSScriptAnalyzer
$Filepath=$env:Temp
$TypesFileName="PSSA.Types.ps1xml"
$FileName=Join-path -Path $Filepath -ChildPath $TypesFileName
Write-Warning "Generate file '$FileName'"
$Assembly=[System.AppDomain]::CurrentDomain.GetAssemblies()|Where-Object {$_.location -match '\.ScriptAnalyzer\.dll$'}
$Assembly.ExportedTypes | New-ExtendedTypeData -Path $FileName -All -Force
