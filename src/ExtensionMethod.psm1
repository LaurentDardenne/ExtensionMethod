#ExtensionMethod.psm1
#Help functions for the creation of ps1xml file dedicated to
# extension methods contained in an assembly file dotnet.
#

#From an idea of Bart De Smet's :
# http://bartdesmet.net/blogs/bart/archive/2007/09/06/extension-methods-in-windows-powershell.aspx
#

#<DEFINE %DEBUG%>
$Script:lg4n_ModuleName=[log4net.GlobalContext]::Properties["LogJobName"]=$MyInvocation.MyCommand.ScriptBlock.Module.Name
#todo add xml file
#todo build debug add directory
#[log4net.GlobalContext]::Properties["ApplicationLogPath"]="$PSScriptRoot\Logs"
#Initialize-Log4Net -RepositoryName $Script:lg4n_ModuleName -XmlConfigPath "$PSScriptRoot\Log4Net.Config.xml"

#<UNDEF %DEBUG%>


function Find-ExtensionMethod{
 #Find and return the extension methods contained in the type $Type.
 #Only process public static methods of types that are sealed, non-generic, and non-nested.
  # C# 3.0 specifications :
   # When the first parameter of a method includes the 'this' modifier, the method is called an extension method.
   # Extension methods can only be declared in non-generic, non-nested static classes.
   # The first parameter of an extension method cannot have modifiers other than this, and the type
   # of parameter cannot be a pointer type.
 param(
    [ValidateNotNull()]
    [Parameter(Position=0, Mandatory=$true,ValueFromPipeline = $true)]
   [System.Type] $Type,

     #Do not return extension methods of generic types, as these types would require,
     # in the ps1xml file, a declaration for each type used when setting up the class:
     #  Class<String>, MyClass<Int>, etc
     # Add-Type -path "$Path\$AssemblyName.dll" -Pass|GetExtensionMethods -ExcludeGeneric
   [switch] $ExcludeGeneric
 )

  process {
     #Filter public types that are sealed, non-generic, and non-nested.
     #Static classes have abstract and Sealed attributes, the latter is placed on
     # the type at compile time (it is not declared in the source code)
   $Type|
    Where-Object {$_.IsPublic -and $_.IsSealed -and $_.IsAbstract -and ($_.IsGenericType -eq $false) -and ($_.IsNested -eq $false)}|
    Foreach-Object {
        #search only public static methods
       $_.GetMethods(([System.Reflection.BindingFlags]"Static,Public"))|
         #Filter extension methods.
         # Note: in C# the ExtensionAttribute attribute is defined by the compiler.
        Where-Object {$_.IsDefined([System.Runtime.CompilerServices.ExtensionAttribute], $false)}|
        Foreach-Object {
           #Return all methods
          if ($ExcludeGeneric -eq $False)
           {$_}
           #Return all methods except generic methods.
          elseif ($_.IsGenericMethod -eq $false)
           {$_}
       }
    }
  }
}

function Test-ClassExtensionMethod([System.Type] $Type)
{ #Determines if the $Type type contains extension methods.
  #
  @($Type|
    Where-Object {$_.IsPublic -and $_.IsSealed -and $_.IsAbstract -and ($_.IsGenericType -eq $false) -and ($_.IsNested -eq $false)}|
    Foreach-Object {
       $_.GetMethods(([System.Reflection.BindingFlags]"Static,Public"))|
        Where-Object {$_.IsDefined([System.Runtime.CompilerServices.ExtensionAttribute], $false)}
    }).count -gt 0
}

function AddMembers{
 #Add to a MethodInfo the following members : ParameterCount,CountOptional,isContainsParams
 #  ParameterCount= Number of parameter
 #  CountOptional= Number of optional parameter
 #  isContainsParams= $true when a parameter is 'params'
  param($CurrentMethod)

 $CountOptional=$Count=0
 $isContainsParams=$false
 foreach ($CurrentParameter in $CurrentMethod.GetParameters())
 {
   $Count++
   if ($isContainsParams -eq $false)
   { $isContainsParams=$CurrentParameter.GetCustomAttributes([System.ParamArrayAttribute],$false).Count -gt 0 }
   if ($CurrentParameter.isOptional)
   { $CountOptional++ }
 }
 Add-member -inputobject $CurrentMethod -membertype NoteProperty -name ParameterCount -value $Count -passthru|
   Add-member -membertype NoteProperty -name CountOptional -value $CountOptional -passthru|
   Add-member -membertype NoteProperty -name isContainsParams -value $isContainsParams
 write-output $CurrentMethod
}#AddMembers

function Get-ExtensionMethodInfo{
  #Returns, from information from an extension method, a DictionaryEntry object with:
  # the key is the type of the first parameter, declared in the method signature (the type can be a nested type),
  # the value is an extension method attached to that same type.
  Param (
     [ValidateNotNull()]
     [Parameter(Position=0, Mandatory=$true,ValueFromPipeline = $true)]
    [System.Reflection.MethodInfo] $MethodInfo,

      #todo : redondant si Find-ExtensionMethod -ExcludeGeneric  ?

      # $ExcludeGeneric: Do not return extension methods whose first parameter type is a generic type,
      #                  because the method name would require, in the ps1xml file, a declaration for each type
      #                  used when setting up the method:
      #                   MyClass.MyMethod<DateTimefull strong name ...>, MyClass.MyMethod<Double full strong name ...>, etc
    [switch] $ExcludeGeneric,

      # $ExcludeInterface: Don't return extension methods whose first parameter type is an interface type.
      #                    PowerShell doesn't know how to 'extract' a particular interface from an object.
      #                    In addition, objects of type IEnumerable are transformed into System.Array by PowerShell...
    [switch] $ExcludeInterface
  )

 process {
     #The first parameter of the method determines the type on which we declare the extension method.
     #In C# this is the role of the 'this' keyword.
     #An extension method has at least 1 parameter which is the type to associate the method with.
    $Parameter=($MethodInfo.GetParameters())[0]
    if (!($Parameter.ParameterType.IsInterface -and $ExcludeInterface))
    {
       #If -ExcludeGeneric is specified, generic types are not processed
       #
       #ContainsGenericParameters:
       # returns true if the Type object is itself a generic type parameter or has parameters
       # of types for which specific types were not provided; otherwise, false.
      if (!( $ExcludeGeneric -and
           ($Parameter.ParameterType.IsGenericType -or
            $Parameter.ParameterType.ContainsGenericParameters
           )
         ))
      {
        $MethodInfo= AddMembers -CurrentMethod $_
         #No exclusion requested or the type is not generic.
         #We return a key/value pair with the type of the first parameter and the method object
        new-object System.Collections.DictionaryEntry(
                                         #The key is the type name of the first parameter of the method object
                                       ($Parameter.ParameterType.ToString()),
                                         #The value is the method object
                                        $MethodInfo
                                      )
      }
    }
 }
}

Function New-HashTable {
   [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions","",
                                                      Justification="New-HashTable do not change the system state.")]
#From http://blogs.msdn.com/b/powershell/archive/2007/11/27/new-hashtable.aspx
#        :   Laurent Dardenne (ajout $InputObject, Mandatory)
# Version:  0.3
#        :   Laurent Dardenne (ajout $Value)
# Version:  0.2
# Author:   Jeffrey Snover
# Version:  0.1
param(
     [Parameter(Position=0, Mandatory=$true,ValueFromPipeline = $true)]
    $InputObject,

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
      $Property = $InputObject.$key

       #On définit la valeur de la clé à partir
       # du nom de propriété contenue dans $Value
      if ([String]::IsNullOrEmpty($Value))
      { $Object=$InputObject }
      else
      { $Object=$InputObject.$Value } #todo test si la clé existe

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
 #Display on the console, from a hashtable, the list of extension methods grouped by type.
 #Specialized wrapper of the Format-Table cmdlet.
 param(
    [ValidateNotNull()]
    [Parameter(Position=0, Mandatory=$true,ValueFromPipeline = $true)]
     #Contains extension methods grouped by type name.
    [System.Collections.HashTable] $Hashtable
 )
process {
  $Hashtable.GetEnumerator()|
  Foreach-Object {
    $InstanceType=$_.Key;$_.Value|
      Sort-Object $_.ParameterCount|
      Add-Member NoteProperty InstanceType $InstanceType -pass
  }|
  Format-Table @{Label="Method";Expression={ $_.ToString()}} -GroupBy InstanceType
}
}

Function Get-ParameterComment {
# need dotNET 4.5 -> ps v4 and >
#todo vérifier si toutes les signatures d'une method surchargée sont précisées
 param( $Method )
  $MethodSignature= foreach($Parameter in $Method.GetParameters()) {

    $ParameterName=$Parameter.Name
    Write-Debug "$ParameterName"
    if ($Parameter.ParameterType.IsByRef)
    {
      Write-Debug " byRef"
      #[ref] powershell is for 'out' and 'ref' c# parameter modifier
      $ParameterStatement="[ref] [$($Parameter.ParameterType.GetElementType())]"
    }
    else
    {
      $ParameterStatement="[$($Parameter.ParameterType)]" #default
      if ($Parameter.IsOptional)
      {
        Write-Debug " optional"
        $ParameterType=$Parameter.ParameterType
        if ($Parameter.HasDefaultValue)
        {
           Write-Debug "  hasDefault"
           $isPtr=($ParameterType.FullName -eq 'System.IntPtr') -or ($ParameterType.FullName -eq 'System.UIntPtr')
           if ($null -eq $Parameter.DefaultValue)
           {
             $ParameterName +="=`$null"
             if ($isPtr)
             {$ParameterName +=" OR new OR default" } #impossible to determine one of the three cases ?
           }
           else
           {
             Write-Debug "   NotNull value"
             if (($Parameter.RawDefaultValue -is [string]) -or (($Parameter.RawDefaultValue -is [char]) ))
             {
               Write-Debug "     String or Char"
               $ParameterName +="='$($Parameter.RawDefaultValue)'"
             }
             elseif ($ParameterType.isEnum)
             {
               Write-Debug "     ENUM"
               $ParameterName +="='$([system.Enum]::Parse($Parameter.ParameterType,$Parameter.RawDefaultValue))'"
             }
             elseif ($Parameter.RawDefaultValue -is [boolean])
             {
               Write-Debug "     bool"
               $ParameterName +="=`$$($Parameter.RawDefaultValue)"
             }
             elseif (($ParameterType.isPrimitive -and (-not $isPtr)) -or ($Parameter.RawDefaultValue -is [Decimal]) -or ($Parameter.RawDefaultValue -is [Single]))
             {
               Write-Debug "     Numeric"
               $ParameterName +="=$($Parameter.DefaultValue.ToString([System.Globalization.CultureInfo]::InvariantCulture))"
             }
             #else TODO ? isArray Or IEnumerable
           }
        }#hasDefaultValue
        else
        {
          Write-Debug "     Default"
          $ParameterName +="=new OR default"
        }
      }#isOptionnal
    }
   '{0} ${1}' -f $ParameterStatement,$ParameterName
  }
 $ofs=', '
 return "# $($Method.Name)($MethodSignature)`r`n"
}

Function New-ExtensionMethodType{
 [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions","",
                                                    Justification="New-ExtensionMethodType do not change the system state.")]

#Returns one or more objects containing the definition of an ETS type declaring or or several members of type ScriptMethod
 [CmdletBinding()]
 [OutputType([UncommonSense.PowerShell.TypeData.Type])]
 param(
    [ValidateNotNull()]
    [Parameter(Position=0, Mandatory=$true,ValueFromPipeline = $true)]
   # DictionaryEntry containing extension methods of a class
 [System.Collections.DictionaryEntry] $Entry
 )
begin {
   function AddAllParameters{
     param($Count)
    foreach ($Number in 1..($Count-1))
    {
      Write-output ",`$args[$($Number-1)]"
    }
   }

  function AddSwitchClauseForMethodWithParams{
    param($ScriptBuilder,$MaxSignatureWithParamsKeyWord)

    if ($null -ne $MaxSignatureWithParamsKeyWord)
    {
        #Add last signature with Params
      $MaxSignatureWithoutParams=$SortedTemp|Where-Object {-not $_.isContainsParams} |Select-Object -first 1
      $Max=[Math]::Max($MaxSignatureWithoutParams.ParameterCount,$MaxSignatureWithParamsKeyWord.ParameterCount)

      $Script.Append( ("`t`t`t $(Get-ParameterComment -Method $MaxSignatureWithParamsKeyWord)")) >$null
      $arguments=AddAllParameters -Count ($Max-1)
      #todo params peut ne pas être renseigné dans l'appel, dans ce cas
      # on a {1} {{ [Object[]]`$Params=@(`$this {0})" -f "$Arguments",($Max-2))
      #Si le cas ($Max-2) Args.Count n'existe pas
      $Script.AppendLine(("`t`t {{`$_ -gt {1}}} {{ [Object[]]`$Params=@(`$this {0},@(`$args[{1}..`$args.count-1]))" -f "$Arguments",($Max-2)) ) >$null
      $Script.AppendLine(('                  [{0}]::{1}.Invoke($Params)' -f $MaxSignatureWithParamsKeyWord.Declaringtype,$MethodName) ) >$null
      $Script.AppendLine('                }') >$null
    }
  # (voirs les liens ) https://stackoverflow.com/questions/6484651/calling-a-function-using-reflection-that-has-a-params-parameter-methodbase
  #                    https://stackoverflow.com/questions/23660137/c-sharp-reflective-method-invocation-with-arbitrary-number-of-parameters?noredirect=1&lq=1
  #                    https://stackoverflow.com/questions/22235490/methodinfo-invoke-throws-exception-for-variable-number-of-arguments?noredirect=1&lq=1
  #                    https://stackoverflow.com/questions/16777547/invoke-a-method-using-reflection-with-the-params-keyword-without-arguments?noredirect=1&lq=1
  #
  #                    https://stackoverflow.com/questions/35404295/invoking-generic-method-with-params-parameter-through-reflection
  }
}#begin

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
   $MethodsInfo=$Entry.Value
   Write-Verbose "Type '$TypeName'"

   New-Type -Name $TypeName -Members {
    foreach ($GroupMethod in $MethodsInfo| Group-Object Name)
    {
      $MethodName=$GroupMethod.Name
      Write-Verbose "`tMethod '$MethodName'"
      if ( $MethodName -eq 'ToString')
      {
         #ToString () can cause fatal recursive calls, for example on System.Object
        Write-Warning "Excluded method : $TypeName.ToString()"
      }
      else
      {
        $Script=New-Object System.Text.StringBuilder " switch (`$args.Count) {`r`n"

         #Contains the section numbers of the switch associated with a method.
         #The section number is the number of parameters of each signature
        $SwitchSections= [System.Collections.Generic.HashSet[String]]::new()

          #Only one line is created for overloaded methods using the same number of parameters.
          #Example :
          #  public static SubStringFrom From(this string s, int start);
          #  public static SubStringFrom From(this string s, string start);
          #In this case their types are different, which is not a problem because PowerShell is untyped.
          #note: The parameter modifier 'ref' cannot be used with 'this' -> Compiler Error CS1101

        $GroupMethodSignatures=$GroupMethod.group |Group-Object ParameterCount
        $SortedTemp=$GroupMethod.group|Sort-Object parametercount -Descending
        $MaxSignatureWithParams=$SortedTemp|Where-Object isContainsParams |Select-Object -first 1

        foreach ($Method in $GroupMethodSignatures)
        {
            if ($null -ne $MaxSignatureWithParams)
            {
              #The method declaring Params is added last, we do not duplicate his statement
              $CurrentSignatureWithParams=$Method.Group|Where-Object isContainsParams |Select-Object -first 1
              if (($null -ne $CurrentSignatureWithParams) -and $CurrentSignatureWithParams.Equals($MaxSignatureWithParams))
              { continue }
            }
            [int]$ParameterCount=$Method.Name
            $SwitchSections.Add($ParameterCount)>$null
                #We subtract 1 from $ParameterCount to create an offset:
                #    0=$this                    -> $Objet.Method()                 -> [Type]::Method($this)
                #    1=$this,$args[0]           -> $Objet.Method($Param1)          -> [Type]::Method($this,$args[0])
                #    2=$this,$args[0],$args[1]  -> $Objet.Method($Param1,$Param2)  -> [Type]::Method($this,$args[0],$args[1])
                #

                # The lag on the number of parameters is due to the fact that one has to support
                # the C# modifier 'this', which is equal to $this in a PowerShell method script, this
                # is not specified when calling the PowerShell method.
                #
                #We build several lines respecting the call syntax of an extension method (static method):
                # nb_argument { [TypeName]::MethodName($this, 0..n arguments) }
                #
                #Note: If a parameter is ByRef, the caller declares it [ref] on the variable used and PS propagates it to the extension method

             #switch clause for ($ParameterCount-1) $Args
            foreach ( $MethodToComment in $Method.Group)
            {
               #Add all method signatures with the same number of parameters
               #todo :     s'il existe pas dans le groupe une méthode avec le même nombre de paramètre on ne l'ajoute pas celle avec params
               #           s'il n'existe pas une méthode avec param +1
              $Script.Append( ("`t`t`t $(Get-ParameterComment -Method $MethodToComment)")) >$null
            }
            $Script.Append( ("`t`t {0} {{ [{1}]::{2}(`$this" -F ($ParameterCount-1), $Method.group[0].Declaringtype,$MethodName)) >$null
            if ($ParameterCount -gt 1)
            {
                $ofs=''
                $arguments= AddAllParameters -Count $ParameterCount
                $Script.Append("$arguments") >$null
            }
            #close method call
            $Script.Append(") }`r`n`r`n") >$null
        }
         #todo PSSA ScriptBuilder not used
        AddSwitchClauseForMethodWithParams -ScriptBuilder $Script -MaxSignatureWithParamsKeyWord $MaxSignatureWithParams

         #Add default switch clause
        $Script.Appendline( ("`t`t default {{ throw `"No overload for '{0}' takes the specified number of parameters.`" }}" -F $MethodName) ) >$null

         #Add end of switch
        $Script.Appendline('   }') >$null

        Write-Debug "`tWrite ScriptMethod '$($MethodName)'"
        Write-debug "`tscript: $Script"
        New-ScriptMethod -Name $MethodName -Script $Script
      }
     }
   }
 }
}

<#
todo scénario de construction -> on doit ajouter des cas dans le switch selon la déclaration de méthode
 traite celles sans option ni params
 traite celles avec option ni params
 traite celles sans option et avec params
 traite celles avec option et avec params ->Error : PS ne gére pas le cas où l'optionnel est absent et params 'vide'


    public static string Method1(this string S, bool includeBoundary=true){  # ici on doit ajouter une signature qui n'existe pas dans la liste des méthodes
                                                                             method1(1 arg)

    pour 2 param :
     existe-t-il une signature de méthode ayant 1 paramètre ?
       oui suite
       non ajoute
     existe-t-il une signature de méthode ayant 2 paramètres ?
       oui suite
       non ajoute

    public static string Method2(this string S, int end)
    public static string Method2(this string S, params object[] parameters){  # ici on doit ajouter une signature qui n'existe pas dans la liste des méthodes
                                                                             method1(1 arg)
                                                                             method1(1 arg, 2 et >)
    public static string To(this string S, double end, bool includeBoundary){

    public static string Method2(this string S, int end, params object[] parameters){  # todo ici le switch du premier dépend du nb de param des méthodes suivantes

    public static string From(this string S){
    public static string From(this string S, bool includeBoundary=true){ #ici sans l'optionnel, le compilo appel -> From(this string S)
                                                                         #ici on n'ajoute pas de signature, car elle existe déjà dans la liste des méthodes

    public static string From(this string S){
    public static string From(this string S, int end){
    public static string From(this string S, bool includeBoundary=true){  #ici on n'ajoute pas la signature, car elle existe déjà
                                                                          #todo c'est le type qui détermine la méthode appeler ?

    public static string To(this string S){
    public static string To(this string S, bool includeBoundary=true){ #todo on doit ordonner le traitemnt des signatures
    public static string To(this string S, int end){
    public static string To(this string S, string end){
    public static string To(this string S, int end, bool includeBoundary=true){
    public static string To(this string S, double end, bool includeBoundary=true){
    public static string To(this string S, double end, bool includeBoundary=true, int count=2){


une seule ayant un param, on traite
  System.String To(System.String)

 $CountArgCreated.Add(1)

deux ayant 2 params, on ne crée qu'une seule entrée pour 2
  System.String To(System.String, Int32)
  System.String To(System.String, System.String)

 $CountArgCreated.Add(2)

une ayant 3 params dont un optionnel,on crée une seule entrée pour 3 params
      si (3         -        1) est déjà déclaré on passe if -not ($CountArgCreated.contains( (3-1) ) {create '2 {call [Class]::Method($this,$args[1],$args[2])}
      si (3         -        1) n'est déjà déclaré on crée une seule entrée pour 2 params

  $CountArgCreated.Add(3)
System.String To(System.String, Int32, Boolean) #optional

une ayant 4 params dont 2 optionnels, on crée une seule entrée pour 4 params
      si (4         -        2) est déjà déclaré on passe
      si (4         -        1) n'est déjà déclaré on crée une seule entrée pour 2 params
System.String To(System.String, Int32, Boolean,int) #optionals

$CountArgCreated.Add(4)




                pour les param optionnel On ajoute des signatures dans la hashtable ?

                $OptionnalParameter= $Method.GetParameters()|where isOptionnal ( ne peuvent être byref en même temps

                 2 param mais un optionnnel ( ils sont à la fin)
                switch ($args.Count) {
                  # Func1([string] $S, [bool] $isvalid=$True)
       --->   ajouter  (count-nBParamOption) NUMBER { [BasicTest]::Func1($this) }
                        (2-1) -> une ligne avec le premier seulement
                 1 { [BasicTest]::Func1($this,$args[0]) }

                 default { throw "No overload for 'Func1' takes the specified number of parameters." }
               }

               pour
                # Add([string] $S, [int] $a=3, [int] $b=5)
                (3-1) -> deux lignes: première avec this seulement
                                      seconde avec this +le premier
                2 { [BasicTest]::Add($this,$args[0],$args[1]) }
#>


#todo construction des blocs a revoir
#todo PSSA PSUseProcessBlockForPipelineCommand
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
        [string] $TypeData,
        [switch] $IsLiteral
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
         { Set-Content -Value $TypeData -LiteralPath $FileName -Encoding UTF8 -Confirm:$false}
         else
         { Set-Content -Value $TypeData -Path $FileName -Encoding UTF8 -Confirm:$false}
       }
      }
    }
  }

  End {
    Function Get-PrecontentString{
      $version =$MyInvocation.MyCommand.ScriptBlock.Module.Version
      $Comment="`r`n<!--Generated by https://github.com/LaurentDardenne/ExtensionMethod version $Version -->"
      Return $('<?xml version="1.0" encoding="utf-8"?>'+$Comment)
    }

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

    $PreContent=Get-PrecontentString
    if ($All)
    {
      $ScriptMethods=$Result.GetEnumerator() | New-ExtensionMethodType
      $EtsDatas=New-TypeData -PreContent $PreContent  -Types {
         $ScriptMethods
       }
      WriteDatas -FileName $FileInfo -TypeData $EtsDatas -isLiteral:$isLiteral
    }
    else
    {
      $Result.GetEnumerator() |
       Foreach-Object {
          #Possible : System.Object[].ps1xml
          $LiteralPath ="{0}\{1}.ps1xml" -F $FileInfo.DirectoryName,$_.Key
          $ScriptMethod=New-ExtensionMethodType -Entry $_
          Write-Verbose "Create '$FileName'"
          $EtsDatas= New-TypeData -PreContent $PreContent -Types {
             $ScriptMethod
           }
          WriteDatas -FileName $LiteralPath -TypeData $EtsDatas -isLiteral
       }
    }
 }
}

#<DEFINE %DEBUG%>
# Deleting Module Objects
Function OnRemoveExtensionMethod {
  Stop-Log4Net $Script:lg4n_ModuleName
}#OnRemoveExtensionMethod

$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = { OnRemoveExtensionMethod }
#<UNDEF %DEBUG%>


