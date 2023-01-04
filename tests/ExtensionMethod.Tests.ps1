﻿Return
"Under developpment"

si la classe n'existe pas la compiler 
extraire les méthodes compter le nombre
charger le fichier généré
appeler la méthode tester le résultat afin 
  de connaitre la résolution de méthode selon le type de param

BUG :
New-ExtendedTypeData -Path c:\temp\TestPs1Xml\All.ps1xml -Type 'MyType.Parser' -All
New-HashTable : The input object cannot be bound to any parameters for the command either because the command does not
take pipeline input or the input and its properties do not match any of the parameters that take pipeline input.



---------
 #redirect stdOut

$Writer = [System.IO.StreamWriter]::new("$HOME\DemoLog.txt")
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
----

Add-type -TypeDefinition @'
//https://csharp-extension.com/en/method/1002258/datetime-isfuture
using System;

public static partial class Extensions
{
   
    public static string Method1(this string S, bool includeBoundary=true)
    {
      Console.WriteLine('1');
      return "1";
    }
                                                                            
    public static string Method2(this string S, int end)
    {
      Console.WriteLine('2');
      return "2";
    }

    public static string Method2(this string S, params object[] parameters)
    {
      Console.WriteLine('3');
      return "3";
    }
    public static string Foo1(this string S, DateTime dt=default(DateTime))
    {
        return string.Empty;
    }    
}

public static partial class ExtensionTo
{
   
  public static string To(this string S)
  {
    return "1";
  }

  public static string To(this string S, int end)
  {
    return "2";
  }

  public static string To(this string S, string end)
  {
    return "3";
  }

  public static string To(this string S, string end, bool includeBoundary=true)
  {
    return "4";
  }
}
'@
ipmo $env:USERPROFILE\Documents\projets\ExtensionMethod\Release\Extensionmethod\ExtensionMethod.psd1  
[Extensions].Assembly.ExportedTypes | New-ExtendedTypeData -Path 'c:\temp\test.ps1xml' -All -Force
update-TypeData 'c:\temp\test.ps1xml'
type 'c:\temp\test.ps1xml'

$Types=[Extensions].Assembly.ExportedTypes | Find-ExtensionMethod -ExcludeGeneric
$ExtensionMethodInfos=$Types |
      Get-ExtensionMethodInfo -ExcludeGeneric -ExcludeInterface |
      New-HashTable -key "Key" -Value "Value" -MakeArray

$ScriptMethods=$ExtensionMethodInfos.GetEnumerator() | New-ExtensionMethodType

$Parameters=@{
  TypeName=[System.String].Name
  MemberType='ScriptMethod'
  MemberName=$ScriptMethods.Members[1].Name
  Value=[Scriptblock]::Create($ScriptMethods.Members[0].Script)
 }
 Update-TypeData @Parameters

# $Date.IsFuture()


-----------

Describe 'Test-ClassExtensionMethod' {
    It 'Without extension method' {
        $result=Test-ClassExtensionMethod -Type System.Management.Automation.Language.TokenFlags
        $result | Should Be $false
    }

    It 'With extension method' {
        $result=Test-ClassExtensionMethod -Type System.Management.Automation.Language.TokenTraits
        $result | Should Be $true
    }
}

Describe 'Find-ExtensionMethod' {

      It 'Without -ExcludeGeneric' {
       [psobject].Assembly.ExportedTypes|Find-ExtensionMethod -ExcludeGeneric|%  {$_.ToString()}

        #System.Management.Automation.Language.TokenFlags GetTraits(System.Management.Automation.Language.TokenKind)
        #Boolean HasTrait(System.Management.Automation.Language.TokenKind, System.Management.Automation.Language.TokenFlags)
        #System.String Text(System.Management.Automation.Language.TokenKind)
        $true | Should Be $true #todo
    }

    It 'With -ExcludeGeneric' {
        [psobject].Assembly.ExportedTypes|Find-ExtensionMethod -ExcludeGeneric|%  {$_.ToString()}

        #System.Management.Automation.Language.TokenFlags GetTraits(System.Management.Automation.Language.TokenKind)
        #Boolean HasTrait(System.Management.Automation.Language.TokenKind, System.Management.Automation.Language.TokenFlags)
        #System.String Text(System.Management.Automation.Language.TokenKind)
        $true | Should Be $true #todo
    }
}


 Describe 'New-ExtensionMethodType' {

      It 'Without -ExcludeGeneric' {

        $true | Should Be $true #todo
      }
 }

Describe 'Get-ExtensionMethodInfo' {

      It 'Without -ExcludeGeneric' {

        $true | Should Be $true #todo
      }
      It 'Without -ExcludeInterface' {

        $true | Should Be $true #todo
      }
 }

Describe 'New-ExtendedTypeData' {

      It 'With -All' {

        $true | Should Be $true #todo
      }
      It 'With -Force' {

        $true | Should Be $true #todo
      }
 }

