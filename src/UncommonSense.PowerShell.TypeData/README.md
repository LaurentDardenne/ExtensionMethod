# UncommonSense.PowerShell.TypeData
*PowerShell module to help build PowerShell type extension files*
* https://github.com/jhoek/UncommonSense.PowerShell.TypeData *

## Installation
1. Build the project 
1. From the build output folder (depends on your build configuration; typically `bin/Debug` or  `bin/Release`), copy the following items to a folder called `UncommonSense.PowerShell.TypeData` anywhere in your PowerShell module path. To find your module path, type `$env:PSModulePath -split ';'` in a PowerShell console.
  - UncommonSense.PowerShell.TypeData.dll
  - UncommonSense.PowerShell.TypeData.psd1
  - UncommonSense.PowerShell.TypeData.psm1
  
  Alternatively, you could leave the files where they are, and call `Import-Module {Full/Path/To/UncommonSense.PowerShell.TypeData.psd1}`
  
## Usage
If you're not familiar with the PowerShell type extension file format, please run `Get-Help about_Types.ps1xml` in your PowerShell console to find additional information.

In an attempt to simplify and shorten the syntax:
- all the cmdlets in the module have aliases (see below);
- most (if not all) cmdlet parameters are positional;
- each parent node has a script block parameter for easily adding child nodes.

### Aliases
The following aliases are defined automatically.

```powershell
Set-Alias -Name Types -Value New-TypeData
Set-Alias -Name _Type -Value New-Type
Set-Alias -Name AliasProperty -Value New-AliasProperty
Set-Alias -Name CodeMethod -Value New-CodeMethod
Set-Alias -Name CodeProperty -Value New-CodeProperty
Set-Alias -name CodeReference -Value New-CodeReference
Set-Alias -Name MemberSet -Value New-MemberSet
Set-Alias -Name NoteProperty -Value New-NoteProperty
Set-Alias -Name PropertySet -Value New-PropertySet
Set-Alias -Name ScriptMethod -Value New-ScriptMethod
Set-Alias -Name ScriptProperty -Value New-ScriptProperty
```

> Note: The alias for `New-Type` is `_Type` instead of `Type`, because PowerShell installs `Type` at a higher scope level as an alias for `Get-Content`.

A possible usage scenario might look like this (using the cmdlet aliases and leaving out parameter names as much as possible):

```powershell
Types {
    _Type Foo {
        NoteProperty Baz Bar
        ScriptProperty Qux 'Get-Quux'
        MemberSet Quux {
            NoteProperty Quuux Boink
        }
    }
}
```

The resulting XML looks like this:

```xml
<Types>
  <Type>
    <Name>Foo</Name>
    <Members>
      <NoteProperty>
        <Name>Baz</Name>
        <Value>Bar</Value>
      </NoteProperty>
      <ScriptProperty>
        <Name>Qux</Name>
        <GetScriptBlock>Get-Quux</GetScriptBlock>
      </ScriptProperty>
      <MemberSet>
        <Name>Quux</Name>
        <Members>
            <NoteProperty>
                <Name>Quuux</Name>
                <Value>Boink</Value>
            </NoteProperty>
        <Members />
      </MemberSet>
    </Members>
  </Type>
</Types>
```

You could then use redirection, `Out-File` or `Set-Content` to send the XML to type extension file, which can be loaded into your PowerShell session using `Update-TypeData`, or can be made part of your own PowerShell module.
