$source = @"
using System;

  public static class TestOptionalAndParams1
  {
    public static string ArrayOfParams(this string S, params object[] parameters)
    {
       Console.WriteLine("parameters :");
       Array.ForEach(parameters, Console.WriteLine);
       return "(this string S, params object[] parameters)";
    }
  }

  public static class TestOptionalAndParams2
  {
    
    public static string ArrayOfParams(this string S, int i)
    {
      Console.WriteLine(string.Format("i='{0}'",i)); 
      return "(this string S, int i)";
    }

    public static string ArrayOfParams(this string S, params object[] parameters)
    {
       Console.WriteLine("parameters :");
       Array.ForEach(parameters, Console.WriteLine);
       return "(this string S, params object[] parameters)";
    }
  }  

  public static class TestOptionalAndParams3
  {
    
    public static string ArrayOfParams(this string S, int i)
    {
      Console.WriteLine(string.Format("i='{0}'",i)); 
      return "(this string S, int i)";
    }
 
    public static string ArrayOfParams(this string S, int i, int j)
    {
      Console.WriteLine(string.Format("i='{0}'",i)); 
      Console.WriteLine(string.Format("j='{0}'",j)); 
      return "(this string S, int i, int j)";
    }

    public static string ArrayOfParams(this string S, params object[] parameters)
    {
       Console.WriteLine("parameters :");
       Array.ForEach(parameters, Console.WriteLine);
       return "(this string S, params object[] parameters)";
    }    
  }

  public static class TestOptionalAndParams4
  {
    public static string ArrayOfParams(this string S, int i, int j)
    {
      Console.WriteLine(string.Format("i='{0}'",i)); 
      Console.WriteLine(string.Format("j='{0}'",j)); 
      return "(this string S, int i, int j)";
    }

    public static string ArrayOfParams(this string S, params object[] parameters)
    {
       Console.WriteLine("parameters :");
       Array.ForEach(parameters, Console.WriteLine);
       return "(this string S, params object[] parameters)";
    }    
  }  
"@

$Assembly=Add-Type -TypeDefinition $source -PassThru
<#
$VerbosePreference='continue'
Import-Module  C:\Users\1801106\Documents\projets\ExtensionMethod\Release\Extensionmethod\ExtensionMethod.psd1
$Assembly|New-ExtendedTypeData -Path c:\temp\All2.ps1xml -All
Get-Content c:\temp\All2.ps1xml
Update-TypeData c:\temp\All2.ps1xml

$h=$Assembly|
      Find-ExtensionMethod -ExcludeGeneric|
      Get-ExtensionMethodInfo -ExcludeGeneric -ExcludeInterface|
      New-HashTable -key "Key" -Value "Value" -MakeArray
#>