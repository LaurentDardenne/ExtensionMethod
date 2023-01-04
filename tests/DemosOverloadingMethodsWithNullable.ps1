Import-Module ExtensionMethod


function Get-VariableType {
  #If a PSVariable is $null, it is impossible to get his type.
  #One must read the _convertTypes member of ArgumentTypeConverterAttribute class.
  #Origin : http://poshcode.com/998
 param([string]$Name)
  Write-Debug ("Call : {0}" -F $MyInvocation.InvocationName)
  get-variable $name | select -expand attributes | ? {
      $_.gettype().name -eq "ArgumentTypeConverterAttribute" } | ForEach-Object {
      $_.gettype().invokemember("_convertTypes", "NonPublic,Instance,GetField", $null, $_, @())
  }
  Write-Debug ("End : {0}" -F $MyInvocation.InvocationName)
}

Add-type -TypeDefinition @'
using System;

public static class IntExtensions
{
    public static int AddOne(this int? number)
    {
        Console.WriteLine("Nullable version of Addone");
        //return (number ?? 0).AddOne();
        return number.Value +1;
    }

    //If we comment the following method, then the method with nullable type is handled, a variable of type [Int] will also select it.
    //If the following method is uncommented, it (with type [Int]) is always called,
    //either because of C#'s overloading mechanism or an implicit Powershell conversion.
    //
    //To force the call a cast is necessary:
    // [IntExtensions]::Addone([System.Nullable[int]]10)
    //
    //But this doesn't work:
    // [System.Nullable[int]]$i=10
    // [IntExtensions]::Addone($i)

    //Si on commente la méthode suivante, alors la méthode avec le type nullable est gérée, une variable de type [Int] la sélectionnera également.
    //Si on décommente la méthode suivante c'est elle (avec le type [Int]) qui est toujours appelée,
    //soit à cause du mécanisme de surcharge de C# soit par une conversion implicite de Powershell.
    //
    //Pour forcer l'appel un cast est nécessaire :
    //  [IntExtensions]::Addone([System.Nullable[int]]10)
    //
    //Mais ceci ne fonctionne pas :
    // [System.Nullable[int]]$i=10
    // [IntExtensions]::Addone($i)
/*
  public static int AddOne(this int number)
    {
        Console.WriteLine("Version Int");
        return number + 1;
    }
*/
}
'@
 #we exclude generic methods
$Types=[IntExtensions].Assembly.ExportedTypes | Find-ExtensionMethod -ExcludeGeneric

 #Le type nullable est générique on inclus les paramètres de type génerique
 #The nullable type is generic, including generic type parameters
$ExtensionMethodInfos=$Types |
      Get-ExtensionMethodInfo -ExcludeInterface |
      New-HashTable -key "Key" -Value "Value" -MakeArray

$ScriptMethods=$ExtensionMethodInfos.GetEnumerator() | New-ExtensionMethodType

$Parameters=@{
    #In expressions, Powershell will always use the underlying type of a nullable type
    TypeName=[System.Int32].Name
    #TypeName=(Get-VariableType 'I').ToString() // https://github.com/PowerShell/PowerShell/issues/7665#issuecomment-417390150
    MemberType='ScriptMethod'
    MemberName=$ScriptMethods.Members[0].Name
    Value=[Scriptblock]::Create($ScriptMethods.Members[0].Script)
   }
Update-TypeData @Parameters


[System.Nullable[System.Int32]]$I=$null
$I=10
#$I is a nullable, but PS call the [INT] type
#In ETS we use the AddOne() method with the Nullable signature but we declare it on the type [INT]...
$I.AddOne()
$I=$null
(Get-VariableType 'I').ToString()
"$(Get-VariableType 'I')"


[System.Int32]$K=10
$K.Addone()
