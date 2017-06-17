# ExtensionMethod
Creation of ps1xml file dedicated to the extension methods contained in an assembly.
From an idea of [Bart De Smet's](http://bartdesmet.net/blogs/bart/archive/2007/09/06/extension-methods-in-windows-powershell.aspx)

To install this module :
```Powershell
$PSGalleryPublishUri = 'https://www.myget.org/F/ottomatt/api/v2/package'
$PSGallerySourceUri = 'https://www.myget.org/F/ottomatt/api/v2'

Register-PSRepository -Name OttoMatt -SourceLocation $PSGallerySourceUri -PublishLocation $PSGalleryPublishUri #-InstallationPolicy Trusted
Install-Module ExtensionMethod -Repository OttoMatt
```

This code return all types containing extension methods :
```Powershell
 [psobject].Assembly.ExportedTypes|Find-ExtensionMethod -ExcludeGeneric|%  {$_.ToString()}

#System.Management.Automation.Language.TokenFlags GetTraits(System.Management.Automation.Language.TokenKind)
#Boolean HasTrait(System.Management.Automation.Language.TokenKind, System.Management.Automation.Language.TokenFlags)
#System.String Text(System.Management.Automation.Language.TokenKind)
```
By default Powershell can not use them, but with [ETS](https://msdn.microsoft.com/en-us/library/dd878306(v=vs.85).aspx) it is possible to make extension methods available.

The goal is to adapt each method  :
```xml
<?xml version="1.0" encoding="utf-8"?>
<Types>
  <Type>
    <Name>System.Management.Automation.Language.TokenKind</Name>
    <Members>
      <ScriptMethod>
         <Name>HasTrait</Name>
       <Script>
         switch ($args.Count) {
            1 { [System.Management.Automation.Language.TokenTraits]::HasTrait($this,$args[0])}

            default { throw "No overload for 'HasTrait' takes the specified number of parameters ($($args.Count))." }
         }</Script>
      </ScriptMethod>
      <ScriptMethod>
        <Name>GetTrait</Name>
             ...
```
Thus it is possible to write :
```Powershell
$code.Ast.EndBlock.BlockKind.HasTrait('MemberName')
```
The **New-ExtendedTypeData** function create one or many files from the extension methods contained in an assembly
```Powershell
Add-Type -Path $AssemblyPath -Pass|
 New-ExtendedTypeData -Path c:\temp\TestPs1Xml\All.ps1xml -All

WARNING: Excluded method : System.Boolean.ToString()
WARNING: Excluded method : System.Object.ToString()
WARNING: Excluded method : System.Char.ToString()
```
**NOTE**:
The ToString() method can be generate recursiv call, they are excluded.
The generic methods and those returning a type Interface are excluded.

The _-All_ parameter group all definitions to a single file :
```Powershell
dir  -Path c:\temp\TestPs1Xml

    Directory: C:\temp\TestPs1Xml

Mode                LastWriteTime         Length Name
----                -------------         ------ ----
-a----       16/02/2017     12:57         269651 All.ps1xml
```
The absence of the _-All_ parameter creates a file by type, the filename is the name of the corresponding type :
```Powershell
Add-Type -Path $AssemblyPath -Pass|
 New-ExtendedTypeData -Path c:\temp\TestPs1Xml\All.ps1xml

dir  -Path c:\temp\TestPs1Xml|more

    Directory: C:\temp\TestPs1Xml

Mode                LastWriteTime         Length Name
----                -------------         ------ ----
-a----       16/02/2017     12:57         269651 All.ps1xml
-a----       16/02/2017     13:07           5636 System.Array.ps1xml
-a----       16/02/2017     13:07           1098 System.Boolean.ps1xml
-a----       16/02/2017     13:07           1122 System.Byte.ps1xml
-a----       16/02/2017     13:07           4404 System.Byte.Array.ps1xml
-a----       16/02/2017     13:07           8636 System.Char.ps1xml
-a----       16/02/2017     13:07            509 System.Collections.Specialized.NameValueCollection.ps1xml
-a----       16/02/2017     13:07            864 System.Data.Common.DbCommand.ps1xml
-a----       16/02/2017     13:07           3736 System.Data.Common.DbConnection.ps1xml
...
```

To install this module :
```Powershell
$PSGalleryPublishUri = 'https://www.myget.org/F/ottomatt/api/v2/package'
$PSGallerySourceUri = 'https://www.myget.org/F/ottomatt/api/v2'

Register-PSRepository -Name OttoMatt -SourceLocation $PSGallerySourceUri -PublishLocation $PSGalleryPublishUri #-InstallationPolicy Trusted
Install-Module ExtensionMethod -Repository OttoMatt
```
This package install an unofficial version of the [UncommonSense.PowerShell.TypeData](https://github.com/jhoek/UncommonSense.PowerShell.TypeData) module.