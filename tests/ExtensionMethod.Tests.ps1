throw "Under developpment"
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

