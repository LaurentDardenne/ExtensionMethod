$source = @"
using System;

  public static class TestOptionalAndParams0
  {
    public static string ArrayOfParams(this string S)
    {
       return "(this string S)";
    }

    public static string ArrayOfParams(this string S, int i)
    {
      Console.WriteLine(string.Format("i='{0}'",i)); 
      return "(this string S, int i)";
    }
  }

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

    public static string ArrayOfParams(this string S, int i, params object[] parameters)
    {
       Console.WriteLine("parameters :");
       Array.ForEach(parameters, Console.WriteLine);
       return "(this string S, ini i, params object[] parameters)";
    }    
  }  

  public static class TestOptionalAndParams5
  {
    public static string ArrayOfParams(this string S, int i, int j)
    {
      Console.WriteLine(string.Format("i='{0}'",i)); 
      Console.WriteLine(string.Format("j='{0}'",j)); 
      return "(this string S, int i, int j)";
    }

    public static string ArrayOfParams(this string S, int i, params object[] parameters)
    {
       Console.WriteLine("parameters :");
       Array.ForEach(parameters, Console.WriteLine);
       return "(this string S, int i, params object[] parameters)";
    }    

    //Error for : public static string ArrayOfParams(this string S, int i, int j, object[] myparams)
    // Le type 'TestOptionalAndParams5' définit déjà  un membre appelé 'ArrayOfParams' avec les mêmes types de paramètres.

    //todo Collision ? 
    public static string ArrayOfParams(this string S, int i, int j, string[] myparams)
    {
      Console.WriteLine("myparams :");
      Array.ForEach(myparams, Console.WriteLine);
      return "(this string S, int i, int j, string[] myparams)";
   }  

    public static string ArrayOfParams(this string S, int i, int j, params object[] parameters)
    {
       Console.WriteLine("parameters :");
       Array.ForEach(parameters, Console.WriteLine);
       return "(this string S, int i, int j, params object[] parameters)";
    }  

     //todo doc 
     /*
      la signature ayant le plus de paramètre, et utilisant params, est la seule considérée dans le switch  {$_ -gt 4} 
     Pour différencier les deux méthodes on doit préciser un type tableau pour la méthode " ArrayOfParams(this string S, int i, int j, params object[] parameters) "
     Exemple :
      's'.ArrayOfParams(1,2,3)
      's'.ArrayOfParams(1,2,3,4)
       ETS call --> (this string S, int i, int j, int k, params object[] parameters)

       's'.ArrayOfParams(1,2,@(3))
       's'.ArrayOfParams(1,2,@(3,4))
      ETS call --> (this string S, int i, int j, params object[] parameters)
     */
    public static string ArrayOfParams(this string S, int i, int j, int k, params object[] parameters)
    {
       Console.WriteLine("parameters :");
       Array.ForEach(parameters, Console.WriteLine);
       return "(this string S, int i, int j, int k, params object[] parameters)";
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