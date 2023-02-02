$source = @"
using System;

  [Flags]
  public enum Flags
  {
      F1 = 1,
      F2 = 2
  }
    public enum myColors
    {
        Red,
        Green,
        Blue,
        Black
    }

  public static class BasicTest
  {
    public static string My(this string S){
     return "My(this string S)";
    }
    public static string My(this string S, int end){
     return "My(this string S, int end)";
    }
    public static string My(this string S, string end){
     return "My(this string S, string end)";
    }

     //https://stackoverflow.com/questions/37894416/why-does-c-sharp-allow-ambiguous-function-calls-through-optional-arguments
     //
     //https://learn.microsoft.com/en-us/dotnet/csharp/programming-guide/classes-and-structs/named-and-optional-arguments?redirectedfrom=MSDN#overload-resolution
     // "If two candidates are judged to be equally good, preference goes to a candidate that does not have optional parameters for
     // which arguments were omitted in the call.
     // This is a consequence of a general preference in overload resolution for candidates that have fewer parameters."

    public static string My(this string S, int end, bool includeBoundary=true){
    return "My(this string S, int end, bool includeBoundary=true)";
   }

    public static string My2(this string S){
     return "My2(this string S)";
    }

    public static string My2(this string S, int end, bool includeBoundary=true){
    return "My2(this string S, int end, bool includeBoundary=true)";
   }

    public static int mymethod (
       this string S, out string str2m, ref string str3m)
    {
       str2m = "in mymethod"+S+str3m;
       return 1;
    }

    public static int mymethod2 (
       this string S ,out string str2m)
    {
       str2m = "in mymethod"+S;
       return 2;
    }

    public static int mymethod3 (
       this string S, ref string str2m)
    {
       str2m = "in mymethod"+S;
       return 3;
    }

    public static bool Func1(this string S, bool isvalid = true) {
     return isvalid;
    }

    public static Flags Func2(this string S, Flags f = (Flags.F1 | Flags.F2)) {
     return f;
    }

    public static myColors FColors(this string S, myColors color=myColors.Red) {
     return color;
    }

    public static int MethodPtr(this string S, IntPtr arg = new IntPtr()) {
     return 0;
   }

    public static int MethodPtr2(this string S, IntPtr? ptr = null) {
     return 0;
   }

   public static int MethodPtr3(this string S, IntPtr arg =  default(IntPtr)) {
     return 0;
   }
    public static string MethodDefault(this string S, string format, char mychar = 'C')
    {
        return string.Empty;
    }

    public static string DefaultStr(this string S, string format, string nullString = "Default value")
    {
        return string.Empty;
    }

      //En cas de surcharge le compilateur appel tjr la méthode déclarant le plus de paramètres
      //la méthode déclarant un paramètre de type params est appelé en dernier et s'il n'y a pas d'ambiguité
      //On suppose une seule surcharge avec 'params' et qu'elle est déclarée en dernier
      //Mixer ce type de déclaration est possible mais de déterminer quelle méthode sera appelée est confus
      //
      // une méthode déclarant un parametre optionelle ET un params est possible
      //  public static string ArrayOfParams(this string S, int i, int j=10, params object[] parameters)
      // mais déclenche sous PS System.IndexOutOfRangeException
      // https://msdn.microsoft.com/en-us/library/ms182135.aspx
      // CA1026: Default parameters should not be used
      //https://docs.microsoft.com/en-us/visualstudio/code-quality/ca1026-default-parameters-should-not-be-used?view=vs-2017
    public static string ArrayOfParams(this string S, int i)
    {
        return "(this string S, int i)";
    }
 //   public static string ArrayOfParams(this string S, params object[] parameters)
 //   {
 //       return "(this string S, params object[] parameters)";
 //   }

    public static string ArrayOfParams(this string S, int i, int j)
    {
        return "(this string S, int i, int j)";
    }

    public static string ArrayOfParams(this string S, int i, int j, int k=10)
    {
        return "(this string S, int i, int j, int k=10)";
    }

     //Note : appel possible ArrayOfParams('S', 1,2) parameters est un tableau vide
     // Déclare le cas {$_ -gt NbArgs }
    public static string ArrayOfParams(this string S, int i, int j, params object[] parameters)
    {
        return "(this string S, int i, int j, params object[] parameters)";
    }


    public static string ArrayOfParams2(this string S, int i)
    {
        return "(this string S, int i)";
    }
    // Déclare le cas {$_ -gt NbArgs } et {$_ -eq NbArgs }
    public static string ArrayOfParams2(this string S, int i, int j, params object[] parameters)
    {
        return "(this string S, int i, int j, params object[] parameters)";
    }


    // Déclare le cas {$_ -gt NbArgs } et {$_ -eq NbArgs }
    public static string ArrayOfParams3(this string S, int i, int j, params object[] parameters)
    {
        return "(this string S, int i, int j, params object[] parameters)";
    }

    // TODO documenter le cas  ?
    public static string ArrayOfParams4(this string S,params object[] parameters)
    {
        return "(this string S,params object[] parameters)";
    }

    //bug : https://github.com/dotnet/corefx/issues/12338
    //public static string Foo1(this string S, DateTime dt = new DateTime())
    //{
    //    return string.Empty;
    //}

    //public static string Foo2(this string S, DateTime dt = default(DateTime))
    //{
    //    return string.Empty;
    //}

    public static string Foo3(this string S,int? x = null)
    {
      return string.Empty;
    }

    public static int Add(this string S, int a = 3, int b = 5 ){
     return a + b;
    }

    //D for Double
    public static double Add2(this string S, double a = 3.2D, double b = 5.235 ){
     return a + b;
    }

    //F for Float
    // 'float' is alias for 'Single'
    public static Single Add3(this string S, Single a = 123456789e4f, Single b =  1e12f ){
     return a + b;
    }

    //M for Decimal
    public static decimal Add4(this string S, decimal a = 3.2M, decimal b = 5.235M ){
     return a + b;
    }
  }
"@

$Assembly=Add-Type -TypeDefinition $source -Passthru

Set-Location G:\PS\ExtensionMethod\src
Import-Module .\ExtensionMethod.psd1
$Assembly| New-ExtendedTypeData -Path c:\temp\TestExtension.ps1xml  -All

$source = @"
using System;
  public static class BasicTest
  {
    public static string ArrayOfParams(this string S, int i)
    {
        return "(this string S, int i)";
    }

    //Note : appel possible ArrayOfParams('S', 1,2) parameters est un tableau vide
    public static string ArrayOfParams(this string S, int i, int j, params object[] parameters)
    {
        return "(this string S, int i, int j, params object[] parameters)";
    }
  }
"@

$Assembly=Add-Type -TypeDefinition $source -Passthru

$Result=$Assembly|
      Find-ExtensionMethod -ExcludeGeneric|
      Get-ExtensionMethodInfo -ExcludeGeneric -ExcludeInterface|
      New-HashTable -key "Key" -Value "Value" -MakeArray
$GroupMethod=$Result.'System.String'| Group-Object Name
$MethodSignatures=foreach ($CurrentMethod in $GroupMethod.group)
{
    #On ne crée qu'une seule ligne pour les méthodes surchargées utilisant un nombre identique de paramètres.
    #Exemple :
    #  public static SubStringFrom From(this string s, int start);
    #  public static SubStringFrom From(this string s, string start);
    #Dans ce cas leurs types est différent, ce qui ne pose pas de pb car PowerShell est non typé.
    #note : pas de gestion nécessaire pour Ref et Out sur 'this' -> Compiler Error CS1101

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
     #Pour faciliter le tri on ajoute un membre contenant le nombre de paramètre de la méthode.
  Add-member -inputobject $CurrentMethod -membertype NoteProperty -name ParameterCount -value $Count -passthru|
   Add-member -membertype NoteProperty -name CountOptional -value $CountOptional -passthru|
   Add-member -membertype NoteProperty -name isContainsParams -value $isContainsParams
 write-output $CurrentMethod
}

$GroupMethodSignatures=$MethodSignatures |Group-Object ParameterCount
$SortedTemp=$MethodSignatures|Sort-Object parametercount -Descending


# BUG ----> https://github.com/PowerShell/PowerShell/issues/8182
$source = @"
using System;
  public static class BasicTest
  {
    public static string ArrayOfParams(this string S, int i)
    {
        return "(this string S, int i)";
    }

    //Note : appel possible ArrayOfParams('S', 1,2) parameters est un tableau vide
    public static string ArrayOfParams(this string S, int i, int j=10, params object[] parameters)
    {
        return "(this string S, int i, int j=10, params object[] parameters)";
    }
    public static string Test()
    {
        string S="Test";
        return S.ArrayOfParams(1,5);
    }
  }
"@

$Assembly=Add-Type -TypeDefinition $source -Passthru
$m=$Assembly.GetMethods()|Where name -eq 'ArrayOfParams'
[Object[]]$Params=@('Test',1)
[BasicTest]::ArrayOfParams.Invoke($Params)

[Object[]]$Params=@('Test',1,@(2))
[BasicTest]::ArrayOfParams.Invoke($Params)
#Cannot find an overload for "ArrayOfParams" and the argument count: "3".

[Object[]]$Params=@('Test',1,5)
[BasicTest]::ArrayOfParams.Invoke($Params)
# $error[0].exception.Innerexception|select *

[Object[]]$Params=@('Test',1,5,@(2))
[BasicTest]::ArrayOfParams.Invoke($Params)

[BasicTest]::Test()



$source = @"
using System;
  public static class BasicTest
  {
    public static string ArrayOfParams(this string S, int i, int j, int k=10)
    {
        return "(this string S, int i, int j, int k=10)";
    }

     //Note : appel possible ArrayOfParams('S', 1,2) parameters est un tableau vide
     // Déclare le cas {$_ -gt NbArgs }
    public static string ArrayOfParams(this string S, int i, int j, params object[] parameters)
    {
        return "(this string S, int i, int j, params object[] parameters)";
    }
  }
"@

$Assembly=Add-Type -TypeDefinition $source -Passthru

$m=Import-Module PSScriptAnalyzer -PassThru
$Path="$($m.ModuleBase)\Microsoft.Windows.PowerShell.ScriptAnalyzer.dll"
$Assembly=Get-Assemblies|Where-Object  Location -eq $path

Set-Location G:\PS\ExtensionMethod\src
Import-Module .\ExtensionMethod.psd1
$Assembly.GetExportedTypes()| New-ExtendedTypeData -Path c:\temp\ScriptAnalyzer.ps1xml  -All