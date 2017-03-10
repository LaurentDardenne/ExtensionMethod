#ExtensionMethod.psm1

#Fonctions d'aide à la création de fichier ps1xml dédié aux
# méthodes d'extension contenues dans un fichier assembly dotnet.
#
#From an idea of Bart De Smet's :
# http://bartdesmet.net/blogs/bart/archive/2007/09/06/extension-methods-in-windows-powershell.aspx
#
#doc: https://msdn.microsoft.com/en-us/library/dd878306(v=vs.85).aspx


#<DEFINE %DEBUG%>
$Script:lg4n_ModuleName=$MyInvocation.MyCommand.ScriptBlock.Module.Name

  #This code create the following variables : $script:DebugLogger, $script:InfoLogger, $script:DefaultLogFile
$InitializeLogging=[scriptblock]::Create("${function:Initialize-Log4NetModule}")
$Params=@{
  RepositoryName = $Script:lg4n_ModuleName
  XmlConfigPath = "$psScriptRoot\ExtensionMethodLog4Posh.Config.xml"
  DefaultLogFilePath = "$psScriptRoot\Logs\${Script:lg4n_ModuleName}.log"
}
&$InitializeLogging @Params
#<UNDEF %DEBUG%>

 #Liste des raccourcis de type
 #ATTENTION ne pas utiliser dans la déclaration d'un type de paramètre d'une fonction
$ExtensionMethodShortCut=@{}

$AcceleratorsType= [PSObject].Assembly.GetType("System.Management.Automation.TypeAccelerators")

Try {
    $ExtensionMethodShortCut.GetEnumerator()| Foreach-Object {
   Try {
     $AcceleratorsType::Add($_.Key,$_.Value)
   } Catch [System.Management.Automation.MethodInvocationException]{
     Write-Error -Exception $_.Exception
   }
 }
} Catch [System.Management.Automation.RuntimeException] {
   Write-Error -Exception $_.Exception
}

function Find-ExtensionMethod{
  #Recherche et renvoi les méthodes d'extension contenu dans le type $Type.
  #On ne traite que les méthodes statiques publiques des types qui sont scéllés, non-générique et non-imbriqués.
  # Spec C# 3.0 :
  #   Lorsque le premier paramètre d'une méthode inclut le modificateur this, la méthode est dite méthode d'extension.
  #   Les méthodes d'extension ne peuvent être déclarées que dans des classes statiques non génériques non imbriquées.
  #   Le premier paramètre d'une méthode d'extension ne peut pas comporter de modificateurs autres que this, et le type
  #   de paramètre ne peut être un type pointeur.

 param(
    [ValidateNotNull()]
    [Parameter(Position=0, Mandatory=$true,ValueFromPipeline = $true)]
   [System.Type] $Type,

     #Ne renvoi pas les méthodes d'extension des types génériques, car ces types nécessiteraient,
     #dans le fichier ps1xml, une déclaration pour chaque type utilisé lors du paramètrage de la classe :
     #  Class<String>, MyClass<Int>, etc
     # Add-Type -path "$Path\$AssemblyName.dll" -Pass|GetExtensionMethods -ExcludeGeneric
   [switch] $ExcludeGeneric
 )

  process {
     #Filtre les types publics qui sont scéllés, non-générique et non-imbriqués.
     #Les classes statiques possédent les attributs abstract et Sealed, ce dernier est placé sur
     # le type lors de la compilation (il n'est pas déclaré dans le code source)
   $Type|
    Where-Object {$_.IsPublic -and $_.IsSealed -and $_.IsAbstract -and ($_.IsGenericType -eq $false) -and ($_.IsNested -eq $false)}|
    Foreach-Object {
        #recherche uniquement les méthodes statique publiques
       $_.GetMethods(([System.Reflection.BindingFlags]"Static,Public"))|
         #Filtre les méthodes d'extension.
         # Note: en C# l'attribut ExtensionAttribute est défini par le compilateur.
        Where-Object {$_.IsDefined([System.Runtime.CompilerServices.ExtensionAttribute], $false)}|
        Foreach-Object {
           #on renvoi toutes les méthodes
          if ($ExcludeGeneric -eq $False)
           {$_}
           #on renvoi toutes les méthodes sauf les méthodes génériques.
          elseif ($_.IsGenericMethod -eq $false)
           {$_}
       }
    }
  }
} #Find-ExtensionMethod

function Test-ClassExtensionMethod([System.Type] $Type)
{ #Détermine si le type $Type contient des méthodes d'extension.
  #
  @($Type|
    Where-Object {$_.IsPublic -and $_.IsSealed -and $_.IsAbstract -and ($_.IsGenericType -eq $false) -and ($_.IsNested -eq $false)}|
    Foreach-Object {
       $_.GetMethods(([System.Reflection.BindingFlags]"Static,Public"))|
        Where-Object {$_.IsDefined([System.Runtime.CompilerServices.ExtensionAttribute], $false)}
    }).count -gt 0
}#Test-ClassExtensionMethod

function Get-ExtensionMethodInfo{
  #Renvoi, à partir d'informations d'une méthode d'extension, un objet DictionaryEntry dont :
  #       la clé est le type du premier paramètre, déclaré dans la signature de la méthode (le type peut être une type imbriqué),
  #       la valeur est une méthode d'extension rattachée à ce même type.
  Param (
     [ValidateNotNull()]
     [Parameter(Position=0, Mandatory=$true,ValueFromPipeline = $true)]
    [System.Reflection.MethodInfo] $MethodInfo,

      #todo : redondant si Find-ExtensionMethod -ExcludeGeneric  ?

      # $ExcludeGeneric :  Ne renvoi pas les méthodes d'extension dont le type du premier paramètre est un type générique,
      #                    car le nom de la méthode nécessiterait, dans le fichier ps1xml, une déclaration pour chaque type
      #                    utilisé lors du paramètrage de la méthode :
      #                      MyClass.MaMethod<DateTimefull strong name ...>, MyClass.MaMethod<Double full strong name ...>, etc
    [switch] $ExcludeGeneric,

      # $ExcludeInterface : Ne renvoi pas les méthodes d'extension dont le type du premier paramètre est un type interface.
      #                     PowerShell ne sait pas 'extraire' une interface particulière à partir d'un objet.
      #                     De plus les objets de type IEnumerable sont transformés en System.Array par PowerShell...
    [switch] $ExcludeInterface
  )

 process {
     #Le premier paramètre de la méthode détermine le type sur lequel on déclare la méthode d'extension.
     #En C# c'est le rôle du mot clé 'this'.
     #Une méthode d'extension a au moins 1 paramètre qui est le type auquel associer la méthode.
    $Parameter=($MethodInfo.GetParameters())[0]
    if (!($Parameter.ParameterType.IsInterface -and $ExcludeInterface))
    {
       #Si -ExcludeGeneric est précisé on ne traite pas les types génériques
       #
       #ContainsGenericParameters :
       # renvoie true si l'objet Type est lui-même un paramètre de type générique ou a des paramètres
       # de type pour lesquels les types spécifiques n'ont pas été fournis; sinon, false.
      if (!( $ExcludeGeneric -and
           ($Parameter.ParameterType.IsGenericType -or
            $Parameter.ParameterType.ContainsGenericParameters
           )
         ))
      {
         #Pas d'exclusion demandée ou le type n'est pas générique.
         #On renvoi une paire clé/valeur avec le type du premier paramètre et l'objet méthode
        new-object System.Collections.DictionaryEntry(
                                         #la clé est le nom du type du premier paramètre de l'objet méthode
                                       ($Parameter.ParameterType.ToString()),
                                         #la valeur est l'objet méthode
                                        $_
                                      )
      } #if ExcludeGeneric
    } #if ExcludeInterface
 }#process
} #Get-ExtensionMethodInfo

Function New-HashTable {
   [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions","",
                                                      Justification="New-HashTable do not change the system state.")]
#From http://blogs.msdn.com/b/powershell/archive/2007/11/27/new-hashtable.aspx
#        :   Laurent Dardenne (ajout $Value)
# Version:  0.2
# Author:   Jeffrey Snover
# Version:  0.1
param(
     [Parameter(Mandatory=$true)]
    $Key,
    $Value,
    [Switch]$NoOverWrite,
    [Switch]$MakeArray
    )
  Begin
  { $hash = @{} }
  Process
  {
       #On définit la clé
      $Property = $_.$key

       #On définit la valeur de la clé à partir
       # du nom de propriété contenue dans $Value
      if ([String]::IsNullOrEmpty($Value))
      { $Object=$_ }
      else
      { $Object=$_.$Value }

       #Pas d'écrasement de la clé si elle existe
      if ($NoOverWrite -And $hash.$Property)
      {  Write-Error "$Property already exists" }
      elseif ($MakeArray)
      {
         #Il existe plusieurs occurences d'une même clé,
         # on crée un tableau afin de mémoriser toutes les valeurs
         if (!$hash.$Property)
         { $hash.$Property = new-object System.Collections.ArrayList }
         [void]$hash.$Property.Add($Object)
      }
      else
      {    #Il n'existe qu'une occurence d'une clé
           #On la remplace si elle existe.
         $hash.$Property = $Object
      }
  }
  End
  { $hash }
}#New-HashTable

function Format-TableExtensionMethod{
 #Affiche sur la console, à partir d'une hashtable, la liste des méthodes d'extension regroupées par type.
 #Wrapper spécialisé du cmdlet Format-Table.
 param(
    [ValidateNotNull()]
    [Parameter(Position=0, Mandatory=$true,ValueFromPipeline = $true)]
     #Contient des méthodes d'extension reroupées par nom de type.
    [System.Collections.HashTable] $Hashtable
 )

$Hashtable.GetEnumerator()|
 Foreach-Object {
   $InstanceType=$_.Key;$_.Value|
    Sort-Object $_.ParameterCount|
    Add-Member NoteProperty InstanceType $InstanceType -pass
 }|
 Format-Table @{Label="Method";Expression={ $_.ToString()}} -GroupBy InstanceType
}#Format-TableExtensionMethod


Function New-ExtensionMethodType{
 [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions","",
                                                    Justification="New-ExtensionMethodType do not change the system state.")]

#Renvoi un ou des objets contenant la définition d'un type ETS déclarant ou ou plusieus membre de type ScriptMethod
 [CmdletBinding()]
 [OutputType([UncommonSense.PowerShell.TypeData.Type])]
 param(
    [ValidateNotNull()]
    [Parameter(Position=0, Mandatory=$true,ValueFromPipeline = $true)]
   # DictionaryEntry contenant les méthodes d'extension d'une classe,
 [System.Collections.DictionaryEntry] $Entry
 )

#Pour chaque type, on crée autant de balise <ScriptMethod> que de méthodes recensées.
#Comme chaque méthode peut être surchargée,  on doit considérer le type de la surcharge,
# par le nombre de paramètres et par leurs types :
#
#  1- public static string To(this SubStringFrom subStringFrom)
#  2- public static string To(this SubStringFrom subStringFrom, int end)
#  3- public static string To(this SubStringFrom subStringFrom, string end)
#  4- public static string To(this SubStringFrom subStringFrom, string end, bool includeBoundary)
#
#On teste le nombre de paramètres pour générer la balise script qui contient le code PowerShell :
#         <Script>
# 						switch ($args.Count) {
#            			0 { [Developpez.Dotnet.StringExtensions]::To($this)}
# 	 							1 { [Developpez.Dotnet.StringExtensions]::To($this,$args[0])}
# 	 							2 { [Developpez.Dotnet.StringExtensions]::To($this,$args[0] ,$args[1])}
# 	          default { throw "La méthode To ne propose pas de signature contenant $($args.Count) paramètres." }
#           }
#         </Script>
#
# Dans cet exemple, pour $args.Count = 1 (on ne compte pas $this) on ne doit générer qu'une seule ligne,
#on laisse le shell invoquer la méthode.
#Si le nombre de paramètres correspond, mais pas leurs type alors le shell déclenchera une exception.

 process {
    $TypeName=$Entry.Key
    $Methods=$Entry.Value
    Write-Verbose "Type '$TypeName'"
    New-Type -Name $TypeName -Members {

    $Methods| Group-Object Name |
      #Pour chaque groupe de méthodes du type courant
      #Utilise une Here-String imbriquées
    Foreach-Object {
      Write-Verbose "`tMethod '$($_.Name)'"
        #ToString() peut provoquer des appels récursifs fatal, par exemple sur System.Object
      if ( $_.Name -eq 'ToString')
      { Write-Warning "Excluded method : $TypeName.ToString()" }
      else
      {
        #begin switch
        $Script=New-Object System.Text.StringBuilder " switch (`$args.Count) {`r`n"
        $_.group|
            #Pour faciliter le tri on ajoute un membre contenant le nombre de paramètre de la méthode.
         Add-member ScriptProperty ParameterCount -value {$this.GetParameters().Count} -Force -PassThru|
            #On ne crée qu'une seule ligne pour les méthodes surchargées utilisant un nombre identique de paramètres.
            #Exemple :
            #  public static SubStringFrom From(this string s, int start);
            #  public static SubStringFrom From(this string s, string start);
            #Dans ce cas leurs types est différent, ce qui ne pose pas de pb car PowerShell est non typé.
            #note : pas de gestion nécessaire pour  Ref et Out -> Compiler Error CS1101
         Sort-Object ParameterCount -unique|
         Foreach-Object {
            $Count=$_.ParameterCount
                #On soustrait 1 à $Count pour créer un décalage :
                #    0=$this                    -> $Objet.Method()
                #    1=$this,$args[0]           -> $Objet.Method($Param1)
                #    2=$this,$args[0],$args[1]  -> $Objet.Method($Param1,$Param2)
                #
                # Le décalage sur le nombre de paramètres est dû au fait que l'on doit prendre en charge
                # le modificateur C# this, qui est égal à $this dans un script de méthode PowerShell, celui-ci
                # n'est pas précisé lors de l'appel de la méthode PowerShell.
                #
                #On construit plusieurs lignes respectant la syntaxe d'appel d'une méthode d'extension( méthode statique) :
                #  nb_argument  { [TypeName]::MethodName($this, 0..n arguments) }
            #current case
            $Script.Append( ("`t`t {0} {{ [{1}]::{2}(`$this" -F ($Count-1), $_.Declaringtype,$_.Name)) >$null
            if ($Count -gt 1)
            {
                $ofs=''
                $arguments=1..($Count-1)|Foreach-Object { ",`$args[$($_-1)]" }
                $Script.Append("$arguments") >$null
            }
            #close method call
            $Script.Append(") }`r`n") >$null
         }#foreach
         #default
         $Script.Append( ("`t`t default {{ throw `"No overload for '{0}' takes the specified number of parameters.`" }}" -F $_.Name) ) >$null
         #end switch
         $Script.Append("`r`n }") >$null

         Write-Debug "`tWrite ScriptMethod '$($_.Name)'"
         Write-debug "`tscript: $Script"
         New-ScriptMethod -Name $_.Name -Script $Script
      } #else
     } #foreach $Methods
    } #New-Type
 } #process
} #New-ExtensionMethodType

function New-ExtendedTypeData {
  #Create an extension file (ETS) containing wrappers of extension methods
 [CmdletBinding(DefaultParameterSetName="Path",SupportsShouldProcess = $true)]
 param(
    #Type to analyze
    [ValidateNotNull()]
    [Parameter(Position=0, Mandatory=$true,ValueFromPipeline = $true)]
   [System.Type] $Type,

    #Full path of the ps1xml file.
    #if all is specified, one file is created for each type, the path is:
    # DirectoryName + TypeName + .ps1xml
    #if type name contains '[].ps1xml', by example "System.Byte[].ps1xml", the name becomes "System.Byte.Array.ps1xml"
    [parameter(Mandatory=$True, ParameterSetName="Path")]
    [ValidateNotNullOrEmpty()]
   [string]$Path,

     #Full literal path of the ps1xml file
     [parameter(Mandatory=$True, ParameterSetName="LiteralPath")]
     [ValidateNotNullOrEmpty()]
   [string]$LiteralPath,

    #All extendend member are in the same file, otherwise one file is created for each type
   [Switch] $All,

    #Overwrite existent file, otherwise the operation is canceled.
   [Switch] $Force
 )
  begin {
    $isLiteral = $PsCmdlet.ParameterSetName -eq 'LiteralPath'

    $fileConflictConfirmNoToAll = $false
    $fileConflictConfirmYesToAll = $false

    function WriteDatas{
       [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidShouldContinueWithoutForce","",
                                                          Justification="WriteDatas create files.The caller declare ShouldProcess.")]
      param (
        [string] $FileName,
        [string] $Datas,
        [switch] $isLiteral
      )

       #Update-TypeData do not manage [] or `[`] for the name of the file : Byte[].ps1xml
       # but c:\Temp\test[1]\Byte.Array.ps1xml is possible for the directory of the file
      $FileName=$FileName -Replace '\[\].ps1xml$','.Array.ps1xml'
      if ($isLiteral)
      { $isExist=$ExecutionContext.InvokeProvider.Item.Exists(([Management.Automation.WildcardPattern]::Escape($FileName)),$false,$false) }
      else
      { $isExist=$ExecutionContext.InvokeProvider.Item.Exists($FileName,$false,$false)  }

      if ($PSCmdlet.ShouldProcess( "Create the ETS file '$FileName'",
                                   "Create the ETS file '$FileName'?",
                                   "Export extension methods" ))
      { #todo messages localization
        if (-Not $isExist -or $Force -or $PSCmdlet.ShouldContinue('OverwriteFile',
                                                                  "Existing file '$FileName'",
                                                                  [ref]$fileConflictConfirmYesToAll,
                                                                  [ref]$fileConflictConfirmNoToAll))
       {
          #Only one confirmation
         if ($isLiteral)
         { Set-Content -Value $Datas -LiteralPath $FileName -Encoding UTF8 -Confirm:$false}
         else
         { Set-Content -Value $Datas -Path $FileName -Encoding UTF8 -Confirm:$false}
       }
      }#ShouldProcess
    }#WriteDatas
  }#begin

  End {
    if ($PSCmdlet.MyInvocation.ExpectingInput)
    { $Types=$input }
    else
    { $Types=$Type }

    if ($isLiteral)
    { $FileInfo=[System.IO.FileInfo]$LiteralPath }
    else
    { $FileInfo=[System.IO.FileInfo]$Path }

    $Result=$Types|
      Find-ExtensionMethod -ExcludeGeneric|
      Get-ExtensionMethodInfo -ExcludeGeneric -ExcludeInterface|
      New-HashTable -key "Key" -Value "Value" -MakeArray

    if ($All)
    {
      $ScriptMethods=$Result.GetEnumerator() | New-ExtensionMethodType
      $EtsDatas=New-TypeData -PreContent '<?xml version="1.0" encoding="utf-8"?>' -Types {
         $ScriptMethods
       }
      WriteDatas -FileName $FileInfo -Datas $EtsDatas -isLiteral:$isLiteral
    }
    else
    {
      $Result.GetEnumerator() |
       Foreach-Object {
          #possible : System.Object[].ps1xml
          $LiteralPath ="{0}\{1}.ps1xml" -F $FileInfo.DirectoryName,$_.Key
          $ScriptMethod=New-ExtensionMethodType -Entry $_
          Write-Verbose "Create '$FileName'"
          $EtsDatas= New-TypeData -PreContent '<?xml version="1.0" encoding="utf-8"?>' -Types {
             $ScriptMethod
           }
          WriteDatas -FileName $LiteralPath -Datas $EtsDatas -isLiteral
       }#foreach
    }#else
 }#end
}#New-ExtendedTypeData

# Suppression des objets du module
Function OnRemoveExtensionMethod {
  $DebugLogger.PSDebug("Remove TypeAccelerators") #<%REMOVE%>
  $ExtensionMethodShortCut.GetEnumerator()|
   Foreach-Object {
     Try {
       [void]$AcceleratorsType::Remove($_.Key)
     } Catch {
       write-Error -Exception $_.Exception
     }
   }
#<DEFINE %DEBUG%>
  Stop-Log4Net $Script:lg4n_ModuleName
#<UNDEF %DEBUG%>
}#OnRemoveExtensionMethod

$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = { OnRemoveExtensionMethod }


