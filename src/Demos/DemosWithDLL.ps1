#Loads a dll from which we extract all its extension methods.
# !!!! This example need a specific dll.

Set-Location $env:Temp
mkdir 'TestPs1Xml'

nuget install Z.ExtensionMethods

$AssemblyPath="$env:Temp\Z.ExtensionMethods.2.1.1\lib\net45\Z.ExtensionMethods.dll"

#One file for all types
Add-Type -Path $AssemblyPath -Pass|
 New-ExtendedTypeData -Path c:\temp\All.ps1xml -All

#One file per type
Add-Type -Path $AssemblyPath -Pass|
 New-ExtendedTypeData -Path 'C:\temp\TestPs1Xml\'


