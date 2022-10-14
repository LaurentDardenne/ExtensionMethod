Import-Module ExtensionMethod

Add-type -TypeDefinition @'
using System;

public static class IntExtensions
{
    public static int AddOne(this int? number)
    {
        return (number ?? 0).AddOne();
    }

    public static int AddOne(this int number)
    {
        return number + 1;
    }
}
'@
$Types=[IntExtensions].Assembly.ExportedTypes | Find-ExtensionMethod -ExcludeGeneric
$ExtensionMethodInfos=$Types |
      Get-ExtensionMethodInfo  -ExcludeInterface |
      New-HashTable -key "Key" -Value "Value" -MakeArray

$ScriptMethods=$ExtensionMethodInfos.GetEnumerator() | New-ExtensionMethodType
