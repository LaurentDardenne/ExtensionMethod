#Compiles an extension method and dynamically adds a scriptmethod to the targeted type
Import-Module ExtensionMethod

Add-type -TypeDefinition @'
//https://csharp-extension.com/en/method/1002258/datetime-isfuture
using System;

public static partial class Extensions
{
    /// <summary>
    ///     A DateTime extension method that query if '@this' is in the future.
    /// </summary>
    /// <param name="this">The @this to act on.</param>
    /// <returns>true if the value is in the future, false if not.</returns>
    public static bool IsFuture(this DateTime @this)
    {
        return @this > DateTime.Now;
    }
}
'@

$Types=[Extensions].Assembly.ExportedTypes | Find-ExtensionMethod -ExcludeGeneric
$ExtensionMethodInfos=$Types |
      Get-ExtensionMethodInfo -ExcludeGeneric -ExcludeInterface |
      New-HashTable -key "Key" -Value "Value" -MakeArray

$ScriptMethods=$ExtensionMethodInfos.GetEnumerator() | New-ExtensionMethodType

$Date=[System.DateTime]::now.AddDays(+1)

$Parameters=@{
 TypeName=[System.DateTime].Name
 MemberType='ScriptMethod'
 MemberName=$ScriptMethods.Members[0].Name
 Value=[Scriptblock]::Create($ScriptMethods.Members[0].Script)
}
Update-TypeData @Parameters

$Date.IsFuture()
