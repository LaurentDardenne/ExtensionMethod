#ExtensionMethod.psm1
#Help functions for the creation of ps1xml file dedicated to
# extension methods contained in an assembly file dotnet.
#

#From an idea of Bart De Smet's :
# http://bartdesmet.net/blogs/bart/archive/2007/09/06/extension-methods-in-windows-powershell.aspx
#


function Find-ExtensionMethod{
 #Find and return the extension methods contained in the type $Type.
 #Only process public static methods of types that are sealed, non-generic, and non-nested.
  # C# 3.0 specifications :
   # When the first parameter of a method includes the 'this' modifier, the method is called an extension method.
   # Extension methods can only be declared in non-generic, non-nested static classes.
   # The first parameter of an extension method cannot have modifiers other than this, and the type
   # of parameter cannot be a pointer type.
 [System.Diagnostics.CodeAnalysis.SuppressMessage('PSReviewUnusedParameter', '')]
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

function Test-ClassExtensionMethod{
  #Determines if the $Type type contains extension methods.
  param ([System.Type] $Type)

  @($Type|
    Where-Object {$_.IsPublic -and $_.IsSealed -and $_.IsAbstract -and ($_.IsGenericType -eq $false) -and ($_.IsNested -eq $false)}|
    Foreach-Object {
       $_.GetMethods(([System.Reflection.BindingFlags]"Static,Public"))|
        Where-Object {$_.IsDefined([System.Runtime.CompilerServices.ExtensionAttribute], $false)}
    }).count -gt 0
}

function AddMembers{
 #Add to a MethodInfo the following members : ParameterCount,CountOptional,isContainsParams
 #  ParameterCount   = Number of parameter
 #  CountOptional    = Number of optional parameter
 #  isContainsParams = $true when a parameter is 'params'
  param($CurrentMethod)

  #We modify the properties of a Runtimetype object which remains loaded in memory,
  #during a second call on the same type the members already exist.
 $Result=$CurrentMethod.PSObject.Properties.Match('ParameterCount')
 if ($Result.Count -eq 0)
 {
  $CountOptional=$Count=0
  $isContainsParams=$false
  foreach ($CurrentParameter in $CurrentMethod.GetParameters())
  {
    $Count++
    if ($isContainsParams -eq $false)
    {
      #todo see https://github.com/PowerShell/PowerShell/blob/4f57804f468c5ad47001708014d8989eac3043bc/src/System.Management.Automation/engine/CoreAdapter.cs#L2203
      $isContainsParams=$CurrentParameter.GetCustomAttributes([System.ParamArrayAttribute],$false).Count -gt 0
    }
    if ($CurrentParameter.isOptional)
    { $CountOptional++ }
  }
  Add-Member -inputobject $CurrentMethod -membertype NoteProperty -name ParameterCount -value $Count -passthru|
    Add-Member -membertype NoteProperty -name CountOptional -value $CountOptional -passthru|
    Add-Member -membertype NoteProperty -name isContainsParams -value $isContainsParams
 }
 else
 { Write-Debug "The additionnals members already exist on the method '$($CurrentMethod.Name)'" }

 Write-Output $CurrentMethod
}#AddMembers

function Get-ExtensionMethodInfo{
  #Returns, from information from an extension method, a DictionaryEntry object with:
  # the key is the type of the first parameter, declared in the method signature (the type can be a nested type),
  # the value is an extension method attached to that same type.
  Param (
     [ValidateNotNull()]
     [Parameter(Position=0, Mandatory=$true,ValueFromPipeline = $true)]
    [System.Reflection.MethodInfo] $MethodInfo,

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
       #We define the key
      $Property = $InputObject.$key

       #We define the value of the key from
       # the property name contained in $Value
      if ([String]::IsNullOrEmpty($Value))
      { $Object=$InputObject }
      else
      { $Object=$InputObject.$Value }

       #No overwriting of the key if it exists
      if ($NoOverWrite -And $hash.$Property)
      {  Write-Error "$Property already exists" }
      elseif ($MakeArray)
      {
          #There are several occurrences of the same key,
          # we create an array in order to memorize all the values
         if (!$hash.$Property)
         { $hash.$Property = New-Object System.Collections.ArrayList }
         [void]$hash.$Property.Add($Object)
      }
      else
      {
          #There is only one occurrence of a key
          #We replace it if it exists.
         $hash.$Property = $Object
      }
  }
  End
  { $hash }
}

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
    $InstanceType=$_.Key;
    $_.Value|
      Sort-Object $_.ParameterCount|
      Add-Member NoteProperty InstanceType $InstanceType -pass
  }|
  Format-Table @{Label="Method";Expression={ $_.ToString()}} -GroupBy InstanceType
}
}

Function Get-ParameterComment {
 param( $Method )
  $MethodSignature= foreach($Parameter in $Method.GetParameters()) {

    $ParameterName=$Parameter.Name
    Write-Debug "$ParameterName"
    if ($Parameter.ParameterType.IsByRef)
    {
      Write-Debug " byRef, out parameter"
      #[ref] powershell is for 'out' and 'ref' C# parameter modifier
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
             #Todo ? else isArray Or IEnumerable
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
    #Contains all methods created
    #ETS type name, method name, declaring type, parameter number (case of the associated Switch() in the XML node)
    #$h=@{};$h.'System.String'=@{};$h.'System.String'.'My'=@{};$h.'System.String'.'MyMethod'.'ExtensionClassType'.SwitchParameterCount=$true
    $MethodsCreated=@{}

   function AddAllParameters{
     param($Count)
    if ($Count -eq 0)
    { return }
    if ($Count -eq 1)
    { $LowerBound=1}
    else 
    { $LowerBound= $Count-1}

    Write-Debug "AddAllParameters '$count'"
    foreach ($Number in 1..$LowerBound)
    {
      Write-output ",`$args[$($Number-1)]"
    }
   }

  function AddSwitchClauseForMethodWithParams{
    param($ScriptBuilder,$MaxSignatureWithParamsKeyWord,$MaxSignatureWithoutParams)

    Write-Debug ("AddSwitchClauseForMethodWithParams without {0} with {1}" -f $MaxSignatureWithoutParams.ParameterCount,$MaxSignatureWithParamsKeyWord.ParameterCount)
    if ($null -ne $MaxSignatureWithParamsKeyWord)
    {
        #Add last signature with Params
      $Max=[Math]::Max($MaxSignatureWithoutParams.ParameterCount,$MaxSignatureWithParamsKeyWord.ParameterCount)
      Write-Debug "Max='$Max'"

      $ScriptBuilder.Append( ("`t`t`t $(Get-ParameterComment -Method $MaxSignatureWithParamsKeyWord)")) >$null
      $arguments=AddAllParameters -Count ($Max-1)

      #todo 1) pour : ArrayOfParams(this string S, params object[] parameters)
      #todo un seul parametre de type params alors  {$_ -ge 1} { 
      #todo  [Object[]]$Params=@($this , @($args[0..($args.count-1)]))
      #
      #todo si une seule méthode, pour une même signature, ET si elle contient 'params' alors -gt 0 ($Max-1) et sans le  switch  "1 : {}"
      #todo  on a 0..n combinaisons

      #Todo 2) pour ArrayOfParams([string] $S, [System.Object[]] $parameters)
      #todo  si pour une même signature on a deux méthodes dont une avec  'params' on crée le swtich 1 et {$_ -gt 1}
      #todo {$_ -gt 1} { [Object[]]$Params=@($this,@($args[0..($args.count-1)]))
    <#
      # ArrayOfParams([string] $S, [int] $i)
			 # ArrayOfParams([string] $S, [System.Object[]] $parameters)
		 1  { [TestOptionalAndParams2]::ArrayOfParams($this,$args[0]) ; Break }

        # ArrayOfParams([string] $S, [System.Object[]] $parameters)
     {$_ -gt 1} { [Object[]]$Params=@($this,@($args[0..($args.count-1)]))
    #>
<#
todo scénario de construction -> on doit ajouter des cas dans le switch selon la déclaration de méthode

    public static string Method2(this string S, int end)
    public static string Method2(this string S, params object[] parameters)
    # Todo ici on doit ajouter une signature qui n'existe pas dans la liste des méthodes
           method1(1 arg)
           method1(1 arg, 2 et >)

    public static string To(this string S, double end, bool includeBoundary){

    public static string Method2(this string S, int end, params object[] parameters){
     todo ici le switch du premier dépend du nb de param des méthodes suivantes
#>


      $ScriptBuilder.AppendLine(("`t`t {{`$_ -gt {1}}} {{ [Object[]]`$Params=@(`$this {0},@(`$args[{2}..(`$args.count-1)]))" -f "$Arguments",($Max-1),($Max-2)) ) >$null
      $ScriptBuilder.AppendLine(('                  [{0}]::{1}.Invoke($Params)' -f $MaxSignatureWithParamsKeyWord.Declaringtype,$MethodName) ) >$null
      $ScriptBuilder.AppendLine('                   Break') >$null
      $ScriptBuilder.AppendLine('                }') >$null
    }
  # See :     https://stackoverflow.com/questions/6484651/calling-a-function-using-reflection-that-has-a-params-parameter-methodbase
  #           https://stackoverflow.com/questions/35404295/invoking-generic-method-with-params-parameter-through-reflection
  }
}#begin

# For each type, we create as many <ScriptMethod> tags as methods listed.
# As each method can be overloaded, we must consider the type of the overload,
# by the number of parameters and by their types:
#
#  1- public static string To(this SubStringFrom subStringFrom)
#  2- public static string To(this SubStringFrom subStringFrom, int end)
#  3- public static string To(this SubStringFrom subStringFrom, string end)
#  4- public static string To(this SubStringFrom subStringFrom, string end, bool includeBoundary)
#
# We test the number of parameters to generate the script tag that contains the PowerShell code:
#         <Script>
# 						switch ($args.Count) {
#            			0 { [Developpez.Dotnet.StringExtensions]::To($this)}
# 	 							1 { [Developpez.Dotnet.StringExtensions]::To($this,$args[0])}
# 	 							2 { [Developpez.Dotnet.StringExtensions]::To($this,$args[0] ,$args[1])}
# 	          default { throw "The 'To' method does not provide a signature containing $($args.Count) parameters." }
#           }
#         </Script>
#
# In this example, for $args.Count = 1 (we don't count $this) we must generate only one line,
# let the shell invoke the method.
# If the number of parameters match, but their type does not then the shell will raise an exception.

 process {
   $TypeName=$Entry.Key
   $MethodsInfo=$Entry.Value
   Write-Verbose "Type '$TypeName'"
   
   $MethodsCreated.Add($TypeName,@{})

   New-Type -Name $TypeName -Members {
     #todo groupe par nom de méthode et puis par type si plusieurs entrées alors :
     #todo Write-Warning "The creation of the element for the method '$MethodName' is duplicated for more types."

     #Pour chaque type on a un groupe contenant toutes ses méthodes de même nom.
    foreach ($GroupMethod in $MethodsInfo| Group-Object DeclaringType,Name)
    {
      $MethodName=$GroupMethod.Group[0].Name
      Write-Verbose "`tMethod '$MethodName'"
      if ( $MethodName -eq 'ToString')
      {
         #ToString () can cause fatal recursive calls, for example on System.Object
        Write-Warning "Excluded method : $TypeName.ToString()"
      }
      else
      {
        if (-not $MethodsCreated.$TypeName.ContainsKey($MethodName) )
        { $MethodsCreated.$TypeName.Add($MethodName,@{}) }

        $Script=New-Object System.Text.StringBuilder " switch (`$args.Count) {`r`n"

          #Only one line is created for overloaded methods using the same number of parameters.
          #Example :
          #  public static SubStringFrom From(this string s, int start);
          #  public static SubStringFrom From(this string s, string start);
          #In this case their types are different, which is not a problem because PowerShell is untyped.
          #note: The parameter modifier 'ref' cannot be used with 'this' -> Compiler Error CS1101

          #Une méthode ayant un ou plusieurs paramètres optionels nécessite d'ajouter des pseudo signatures.
          #MethodsByParameterCount: hashtable permettant de rechercher les cas à ajouter dans le switch.
        $MethodsByParameterCount=$GroupMethod.Group|Group-Object ParameterCount -AsHashTable
        Write-Verbose "`tNumber of method signature to generate : '$($MethodsByParameterCount.Keys.Count)'"
        
        
        
        $SortedTemp=$GroupMethod.Group|Sort-Object -Property ParameterCount -Descending
         #Renvoi la méthode ayant le plus de paramètre pour celles déclarant un paramètre 'params'
        $MaxSignatureWithParams=$SortedTemp|Where-Object isContainsParams |Select-Object -first 1
         #Renvoi la méthode ayant le plus de paramètre pour celles ne déclarant pas de paramètre 'params'
        $MaxSignatureWithoutParams=$SortedTemp|Where-Object {-not $_.isContainsParams} |Select-Object -first 1
        Remove-Variable 'SortedTemp'

        Foreach ($Method in $MethodsByParameterCount.GetEnumerator()|Sort-Object ParameterCount)
        {
            Write-Verbose "`tSignature '$($Method.Value[0].ToString())'"
            # Le groupe de methodes, ayant le même nombre de paramètre, contient-il une méthode avec au moins un paramètre optionel ?
            #todo si optionnal et isContainsParams ?
            $isGroupMethodContainsOptionnalParameter= $null -ne ($GroupMethod.Group|Where-Object {$_.CountOptional -ge 1} |Select-Object -first 1) 
            Write-Debug "`t Contains optionnal parameter ? $isGroupMethodContainsOptionnalParameter"

            if ($null -ne $MaxSignatureWithParams)
            {
               Write-Verbose "`tMethod '$($Method[0].Name)' contains params statement"
                #The method declaring Params is added last, we do not duplicate his statement
               $CurrentSignatureWithParams=$Method|Where-Object isContainsParams |Select-Object -first 1
               if (($null -ne $CurrentSignatureWithParams) -and $CurrentSignatureWithParams.Equals($MaxSignatureWithParams))
               { continue }
            }
            [int]$ParameterCount=$Method.Key

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

             #Gets the class that declares this member.
            $DeclaringType=$Method.Value[0].Declaringtype

            if ( -not $MethodsCreated.$TypeName.$MethodName.ContainsKey($DeclaringType) )
            { $MethodsCreated.$TypeName.$MethodName.Add($DeclaringType,@{}) }

            if ( -not $MethodsCreated.$TypeName.$MethodName.$DeclaringType.ContainsKey($ParameterCount) )
            { $MethodsCreated.$TypeName.$MethodName.$DeclaringType.$ParameterCount=$true }
          

             #Add all method signatures with the same number of parameters
            foreach ( $MethodToComment in $Method.Value)
            { $Script.Append( ("`t`t`t $(Get-ParameterComment -Method $MethodToComment)")) >$null }
            
            Write-Verbose $("Add Switch case '{0}' for the type '{1}'" -F ($ParameterCount-1), $DeclaringType)
            $Script.Append( ("`t`t {0} {{ [{1}]::{2}(`$this" -F ($ParameterCount-1), $DeclaringType,$MethodName)) >$null
            if ($ParameterCount -gt 1)
            {
                $ofs=''
                $arguments= AddAllParameters -Count $ParameterCount
                $Script.Append("$arguments") >$null
            }
             #close method call
            $Script.Append(") ; Break }`r`n`r`n") >$null

             #Si au moins 1 optionel ajouter s'il n'en existe pas déjà une, une signature avec Parameter.count-1
            if ($isGroupMethodContainsOptionnalParameter)
            {
                #On ajoute un cas de switch pour chaque paramètre optionnel qu'une méthode déclare.
                #Pour la déclaration de methode suivante  : public static string M(this string S, bool includeBoundary=true)
                # le system de réflection ne renvoie qu'une seule signature, mais deux appels sont possibles : M("Test") et M("Test",$true)
                #On doit donc générer les signatures manquantes, ici M("Test")

                #Recherche dans les méthodes de même nom, ayant le nombre de paramètre identique,
                # celle ayant le plus grand nombre de paramètres optionels
               $Max=[Linq.Enumerable]::Max([Int[]]$Method.Value.CountOptional)
               Write-Debug "Max count optional '$Max'"
    
               0..$Max|
                ForEach-Object {
                    $CurrentCase=$_
                    $SwitchCase=$ParameterCount-$CurrentCase

                     #Si la signature n'existe pas dans les signatures d'origine et qu'elle n'existe pas déjà dans celles manquanted déjà créées
                     # alors on complète les cas du switch pour les signatures ayant un ou plusieurs paramètres optionnels.
                    if ( ($MethodsByParameterCount.ContainsKey($SwitchCase) -eq $false) -and ($MethodsCreated.$TypeName.$MethodName.$DeclaringType.ContainsKey($SwitchCase) -eq $false) )
                    {
                      Write-verbose " Add missing switch case '$($SwitchCase-1)'"
                      $MethodsCreated.$TypeName.$MethodName.$DeclaringType.$SwitchCase=$true 

                      $Script.Append( ("`t`t {0} {{ [{1}]::{2}(`$this" -F ($SwitchCase-1), $Declaringtype,$MethodName)) > $null

                      if ($ParameterCount -gt 1)
                      {
                          $ofs=''
                          $arguments= AddAllParameters -Count ($ParameterCount-1-$CurrentCase)
                          Write-Debug "arguments '$arguments'"
                          $Script.Append("$arguments") >$null
                      }
                      #close method call
                      $Script.Append(") ; Break }`r`n`r`n") >$null
        
                    }
                }
            }
        }
        Write-Debug "call addswitch"
        AddSwitchClauseForMethodWithParams -ScriptBuilder $Script -MaxSignatureWithParamsKeyWord $MaxSignatureWithParams -MaxSignatureWithoutParams $MaxSignatureWithoutParams

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

function New-ExtendedTypeData {
  [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseProcessBlockForPipelineCommand', '')]
  [System.Diagnostics.CodeAnalysis.SuppressMessage('PSReviewUnusedParameter', '')]
  #Create an extension file (ETS) containing wrappers of extension methods
 [CmdletBinding(DefaultParameterSetName="Path",SupportsShouldProcess = $true)]
 param(
    #Type to analyze.
    # If type is of type string then Powershell attempts a conversion,
    # square brackets are not accepted in the type name. Use 'MyType' instead of [MyType].
    [ValidateNotNull()]
    [Parameter(Position=0, Mandatory=$true,ValueFromPipeline = $true)]
   [System.Type] $Type,

    #Full path of the ps1xml file.
    #if all is specified, one file is created for each type, the path is:
    # DirectoryName + TypeName + .ps1xml
    #
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
      {
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
    {
       Write-Debug 'New-ExtendedTypeDat : Data received from pipeline input'
       #In the end block, the $input variable enumerates the collection of all input to the function.
      $Types=$input
    }
    else
    {
      Write-Debug 'New-ExtendedTypeDat : Data received from parameter $Type'
      $Types=$Type
    }

    if ($isLiteral)
    { $FileInfo=[System.IO.FileInfo]$LiteralPath }
    else
    { $FileInfo=[System.IO.FileInfo]$Path }

    $Result=$Types|
      Find-ExtensionMethod -ExcludeGeneric|
      Get-ExtensionMethodInfo -ExcludeGeneric -ExcludeInterface|
      New-HashTable -key "Key" -Value "Value" -MakeArray
       #Get-ExtensionMethodInfo return a key/value pair.
       # Key=the type of the first parameter
       # Value=the method object

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
      If ( ($FileInfo.Attributes.HasFlag([System.IO.FileAttributes]::Directory)) -and $FileInfo.Exist)
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
      else
      { throw "The path must be an existing directory name : '$FileInfo'."}
    }
 }
}



