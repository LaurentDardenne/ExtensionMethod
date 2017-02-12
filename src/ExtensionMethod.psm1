#ExtensionMethod.psm1

#Fonctions d'aide à la création de fichier ps1xml dédié aux
# méthodes d'extension contenues dans un fichier assembly dotnet.
#
#D'après une idée de Bart De Smet's :
# http://bartdesmet.net/blogs/bart/archive/2007/09/06/extension-methods-in-windows-powershell.aspx
#

#todo UncommonSense.PowerShell.TypeData
#todo
#v3 Update-Type
#   $List_String = new-object 'Collections.Generic.List[String]'
#   $List_Int = new-object 'Collections.Generic.List[Int]'
#
#   ,$List_String|gm -MemberType scriptmethod
#   ,$List_Int|gm -MemberType scriptmethod
#
#   $TypeFullname=$List_String.GetType().Fullname
#   Update-TypeData -TypeName $TypeFullname -MemberType ScriptMethod  -MemberName MyMethod -Value {
#    Param(
#      [Object[]] $ArgumentList
#    )
#     Write-host "MyMethod $ArgumentList"
#   }
#
#   ,$List_String|gm -MemberType scriptmethod
#   ,$List_Int|gm -MemberType scriptmethod
#
#   Ici seule la classe Collections.Generic.List[String] possédera la méthode nommée 'MyMethod'.


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
    $ExtensionMethodShortCut.GetEnumerator()| Foreach {
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
 param(
    [ValidateNotNull()]
    [Parameter(Position=0, Mandatory=$true,ValueFromPipeline = $true)]
   [System.Type] $Type,
   [switch] $ExcludeGeneric
 )
 #Recherche et renvoi les méthodes d'extension contenu par le type $Types.
  #
  #On ne traite que les méthodes statiques publiques des types qui sont scéllés, non-générique et non-imbriqués.
  # Spec C# 3.0 :
  #   Lorsque le premier paramètre d'une méthode inclut le modificateur this, la méthode est dite méthode d'extension.
  #   Les méthodes d'extension ne peuvent être déclarées que dans des classes statiques non génériques non imbriquées.
  #   Le premier paramètre d'une méthode d'extension ne peut pas comporter de modificateurs autres que this, et le type
  #   de paramètre ne peut être un type pointeur.
  #
  # $ExcludeGeneric :  Ne renvoi pas les méthodes d'extension des types génériques, car ces types nécessiteraient,
  #                    dans le fichier ps1xml, une déclaration pour chaque type utilisé lors du paramètrage de la classe :
  #                     MyClass<String>, MyClass<Int>, etc
  #
  # Add-Type -path "$Path\$AssemblyName.dll" -Pass|GetExtensionMethods -ExcludeGeneric

  process {
     #Filtre les types publics qui sont scéllés, non-générique et non-imbriqués.
     #Les classes statiques possédent les attributs abstract et Sealed, ce dernier est placé sur
     # le type lors de la compilation (il n'est pas déclaré dans le code source)
   $Type|
    where {$_.IsPublic -and $_.IsSealed -and $_.IsAbstract -and ($_.IsGenericType -eq $false) -and ($_.IsNested -eq $false)}|
    Foreach {
        #recherche uniquement les méthodes statique publiques
       $_.GetMethods(([System.Reflection.BindingFlags]"Static,Public"))|
         #Filtre les méthodes d'extension.
         # Note: en C# l'attribut ExtensionAttribute est défini par le compilateur.
        Where {$_.IsDefined([System.Runtime.CompilerServices.ExtensionAttribute], $false)}|
        Foreach {
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

function Test-ClassExtensionMethods([System.Type] $Type)
{ #Détermine si le type $Type contient des méthodes d'extension.
  #
  @($Type|
    where {$_.IsPublic -and $_.IsSealed -and $_.IsAbstract -and ($_.IsGenericType -eq $false) -and ($_.IsNested -eq $false)}|
    Foreach {
       $_.GetMethods(([System.Reflection.BindingFlags]"Static,Public"))|
        Where {$_.IsDefined([System.Runtime.CompilerServices.ExtensionAttribute], $false)}
    }).count -gt 0
}#Test-ClassExtensionMethods

function Get-ExtensionMethodInfo{
  Param (
     [ValidateNotNull()]
     [Parameter(Position=0, Mandatory=$true,ValueFromPipeline = $true)]
    [System.Reflection.MethodInfo] $MethodInfo,
    [switch] $ExcludeGeneric,
    [switch] $ExcludeInterface
  )

  #On renvoi, à partir d'informations d'une méthode d'extension, un objet DictionaryEntry dont :
  #       la clé est le type du premier paramètre, déclaré dans la signature de la méthode (le type peut être une type imbriqué),
  #       la valeur est une méthode d'extension rattachée à ce même type.
  #
  # $ExcludeGeneric :  Ne renvoi pas les méthodes d'extension dont le type du premier paramètre est un type générique,
  #                    car le nom de la méthode nécessiterait, dans le fichier ps1xml, une déclaration pour chaque type
  #                    utilisé lors du paramètrage de la méthode :
  #                      MyClass.MaMethod<DateTimefull strong name ...>, MyClass.MaMethod<Double full strong name ...>, etc
  #
  # $ExcludeInterface : Ne renvoi pas les méthodes d'extension dont le type du premier paramètre est un type interface.
  #                     PowerShell v2 ne sait pas 'extraire' une interface particulière à partir d'un objet.
  #                     De plus les objets de type IEnumerable sont transformés en System.Array par PowerShell...
 process {
     #Le premier paramètre de la méthode détermine le type sur lequel on déclare la méthode d'extension.
     #En C# c'est le rôle du mot clé 'this'.
     #Une méthode d'extension a au moins 1 paramètre.
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
#From http://blogs.msdn.com/b/powershell/archive/2007/11/27/new-hashtable.aspx
# Author:   laurent Dardenne (ajout $Value)
# Version:  0.2
# Author:   Jeffrey Snover
# Version:  0.1
#Requires -Version 1.0
param(
    $Key=$(Throw "USAGE: New-HashTable -Key <property>"),
    $Value,
    [Switch]$NoOverWrite,
    [Switch]$MakeArray
    )
  Begin
  {
      $hash = @{}
  }
  Process
  {
       #On définit la clé
      $Property = $_.$key

       #On définit la valeur de la clé à partir
       # du nom de propriété contenue dans $Value
      if ([String]::IsNullOrEmpty($Value))
      {  $Object=$_
      }else
      {  $Object=$_.$Value
      }

       #Pas d'écrasement de la clé si elle existe
      if ($NoOverWrite -And $hash.$Property)
      {  Write-Error "$Property already exists"
      }elseif ($MakeArray) #Il existe plusieurs occurences d'une même clé,
      {                    # on crée un tableau afin de mémoriser toutes les valeurs
         if (!$hash.$Property)
         {   $hash.$Property = new-object System.Collections.ArrayList
         }
         [void]$hash.$Property.Add($Object)
      }else
      {    #Il n'existe qu'une occurence d'une clé
           #On la remplace si elle existe.
         $hash.$Property = $Object
      }
  }
  End
  {
      $hash
  }
}#New-HashTable

function Format-TableExtensionMethod{
 #Affiche sur la console la liste des méthodes d'extension regroupées par type.
 #Wrapper spécialisé du cmdlet Format-Table.
 param(
    [ValidateNotNull()]
    [Parameter(Position=0, Mandatory=$true,ValueFromPipeline = $true)]
    [System.Collections.HashTable] $Hashtable
 )
#
#Hashtable : Hashtable contenant les méthodes d'extension.
$Hashtable.GetEnumerator()|
 Foreach {
   $InstanceType=$_.Key;$_.Value|
    Sort $_.ParameterCount|
    Add-Member NoteProperty InstanceType $InstanceType -pass
 }|
 Format-Table @{Label="Method";Expression={ $_.ToString()}} -GroupBy InstanceType
}#Format-TableExtensionMethod


Function New-ExtensionMethodTypeData{
#Renvoi un texte représentant une structure XML à insérer dans un fichier .ps1xml
 [CmdletBinding()]
 param(
    [ValidateNotNull()]
    [Parameter(Position=0, Mandatory=$true,ValueFromPipeline = $true)]
  [System.Collections.HashTable] $Datas,

  [switch] $Split
 )
#$Datas :
#         Hashtable contenant les méthodes d'extension d'une ou plusieurs classes,
#          on crée une seule définition de type pour toutes les classes.
#         DictionaryEntry contenant les méthodes d'extension d'une classe,
#          on crée une définition de type par classe.


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
Begin {
  $Header=@"
<?xml version="1.0" encoding="utf-8"?>
 <Types>
"@
    $_Body=@'
   <Type>
    <Name>$CurrentType</Name>
    <Members>
'@

  $CloseClass=@"
     </Members>
   </Type>
"@

  $Footer=@"
 </Types>
"@
}
 process {
  $isAllClasses=-not $PSBoundParameters.ContainsKey('Split')
   Write-Debug "isAllClasses : $isAllClasses"
  if ($isAllClasses)
  { $Classes=$Datas.GetEnumerator() }
  else
  { $Classes=$Datas }


  Write-Debug "Write `$Header"
  Write-Output $Header

   #Pour chaque type (classe/struct)
  $Classes|
   Foreach {
    $CurrentType=$_.Key
    $Body=$ExecutionContext.InvokeCommand.ExpandString($_Body)

    if ($isAllClasses) { Write-Debug "Write `$Body"; Write-Output $Body }
    $_.Value| Group Name |
      #Pour chaque groupe de méthodes du type courant
      #Utilise une Here-String imbriquées
    Foreach {
      #Peut provoquer des appels récursifs fatal, par exemple sur System.Object
     if ( $_.Name -eq 'ToString')
     {Write-Warning "Excluded method : $CurrentType.ToString"}
     else
     {
      Write-Debug "`tWrite ScriptMethod"
@"

      <ScriptMethod>
        <Name>$($_.Name)</Name>
        <Script>
$("`t"*6)switch (`$args.Count) {
           $(
             $_.group|
                #Pour faciliter le tri on ajoute un membre contenant le nombre de paramètre de la méthode.
              Add-member ScriptProperty ParameterCount -value {$this.GetParameters().Count} -Force -pass|
                #On ne crée qu'une seule ligne pour les méthodes surchargées utilisant un nombre identique de paramètres.
                #Exemple :
                #  public static SubStringFrom From(this string s, int start);
                #  public static SubStringFrom From(this string s, string start);
                #Dans ce cas leurs types est différent, ce qui ne pose pas de pb car PowerShell est non typé.
                #
              Sort ParameterCount -unique|
              foreach {
               $Count=$_.GetParameters().Count
                 #On soustrait 1 à $Count pour créer un décalage :
                 #    0 =$this                   -> $Objet.Method()
                 #    1=$this,$args[0]           -> $Objet.Method($Param1)
                 #    2=$this,$args[0],$args[1]  -> $Objet.Method($Param1,$Param2)
                 #
                 # Le décalage sur le nombre de paramètres est dû au fait que l'on doit prendre en charge
                 # le modificateur C# this, qui est égal à $this dans un script de méthode PowerShell, celui-ci
                 # n'est pas précisé lors de l'appel de la méthode PowerShell.
                 #
                 #On construit plusieurs lignes respectant la syntaxe d'appel d'une méthode d'extension( méthode statique) :
                 #  nb_argument  { [TypeName]::MethodName($this, 0..n arguments) }
@"
$("`t"*7)$($Count-1) { [$($_.Declaringtype)]::$($_.Name)(`$this$(
              "$(if ($Count -gt 1){1..($Count-1)|Foreach {",`$args[$($_-1)]"}})"))}`r`n`t
"@
              }
           )
            default { throw "La méthode $($_.Name) ne propose pas de signature contenant `$(`$args.Count) paramètres." }
          }
        </Script>
      </ScriptMethod>
"@
    } #else
  } #foreach  methods

  if ($isAllClasses) { Write-Debug "Write `$CloseClass"; Write-Output $CloseClass }
  }#foreach  Class

 if ($isAllClasses)
 { Write-Debug "Write `$Footer";Write-Output $Footer }
 else
 { Write-Debug "Write `$ALL";Write-Output @($Header;$Body;$CloseClass;$Footer) }
 } #process
} #New-ExtensionMethodTypeData


# Suppression des objets du module
Function OnRemoveExtensionMethodZip {
  $DebugLogger.PSDebug("Remove TypeAccelerators") #<%REMOVE%>
  $ExtensionMethodShortCut.GetEnumerator()|
   Foreach {
     Try {
       [void]$AcceleratorsType::Remove($_.Key)
     } Catch {
       write-Error -Exception $_.Exception
     }
   }
#<DEFINE %DEBUG%>
  Stop-Log4Net $Script:lg4n_ModuleName
#<UNDEF %DEBUG%>
}#OnRemoveExtensionMethodZip

$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = { OnRemoveExtensionMethodZip }


