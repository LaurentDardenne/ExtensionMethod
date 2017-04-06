throw "Under developpment"


BUG :
New-ExtendedTypeData -Path c:\temp\TestPs1Xml\All.ps1xml -Type [MyType.Parser] -All
New-ExtendedTypeData : Cannot process argument transformation on parameter 'Type'. Cannot convert the
"[GetAdminExt.Parser]" value of type "System.String" to type "System.Type".

BUG :
New-ExtendedTypeData -Path c:\temp\TestPs1Xml\All.ps1xml -Type 'MyType.Parser' -All
New-HashTable : The input object cannot be bound to any parameters for the command either because the command does not
take pipeline input or the input and its properties do not match any of the parameters that take pipeline input.


vérifier si ceci correspond au code c# :
 ***
  <?xml version="1.0" encoding="utf-8"?>
  <Types>
    <Type>
      <Name>System.String</Name>    ici c'est le type du paramètre qui porte la méthode
      <Members>
        <ScriptMethod>
          <Name>Parse</Name>
          <Script> switch ($args.Count) {
                   0 { [GetAdminExt.Parser]::Parse($this) }
                   default { throw "No overload for 'Parse' takes the specified number of parameters." }
   }</Script>
        </ScriptMethod>
      </Members>
    </Type>
  </Types>
***

------------- use case 
Add-Type -TypeDefinition @'
using System;
using System.Collections;
namespace GetAdmin
{
    public class Net
    {
        #region Paramaters 
 
        public string Interface { get; set; }
        public System.Net.IPAddress IPAddress { get; set; }
        public string Netmask { get; set; } 
 
        #endregion Parameters
 
        #region Constructors
        public Net()
        {
            Interface = null;
            IPAddress = new System.Net.IPAddress((long)16777343);
            Netmask = null;
        }
        public Net(
            string name,
            System.Net.IPAddress ipaddress,
            string netmask
        )
        {
            Interface = name;
            IPAddress = ipaddress;
            Netmask = netmask;
        }
        #endregion Constructors
    }
    public class Server
    {
        #region Paramaters 
 
        public string    Name    { get; set; }
        public ArrayList Network { get; set; } 
 
        #endregion Parameters
 
        #region Constructors
        public Server()
        {
            Name    = null;
            Network = new ArrayList();
        }
        public Server(
            string name,
            ArrayList network
        )
        {
            Name    = name;
            Network = network;
        }
        #endregion Constructors
    }
}

namespace GetAdminExt
{
  public static class Parser {
     
    public static GetAdmin.Net Parse(this string value) {        
      if (string.IsNullOrEmpty(value))
       throw new InvalidCastException("Value is null or empty, conversion impossible.");
      try
      {
          GetAdmin.Net result = new GetAdmin.Net();
          string[] Fields = value.Split(new char[1] { ',' });

          result.Interface  = Fields[0];
          result.IPAddress  = System.Net.IPAddress.Parse(Fields[1]);
          result.Netmask    = Fields[2];
          return result;
      }
      catch (Exception e)
      {
        throw new InvalidCastException("Conversion impossible",e);
      }
   }
 }
}
'@ -passthru|
 New-ExtendedTypeData -Path c:\temp\TestPs1Xml\All.ps1xml -All

 ----------------

[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '', Scope='*', Target='SuppressImportModule')]
$SuppressImportModule = $true
. $PSScriptRoot\Shared.ps1

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

