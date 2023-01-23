$source = @"
using System;

    //In case of overload the compiler always calls the method declaring the most parameters
    //the method declaring a parameter of type params is called last and if there is no ambiguity
    //We assume a single overload with 'params' and that it is declared last
    //Mixing this type of declaration is possible but determining which method will be called is confusing.

    //En cas de surcharge le compilateur appel tjr la méthode déclarant le plus de paramètres
    //la méthode déclarant un paramètre de type params est appelé en dernier et s'il n'y a pas d'ambiguité
    //On suppose une seule surcharge avec 'params' et qu'elle est déclarée en dernier
    //Mixer ce type de déclaration est possible mais de déterminer quelle méthode sera appelée est confus.

  public static class TestOptionalAndParams
  {
    public static string ArrayOfParams(this string S, int i)
    {
      Console.WriteLine(string.Format("i='{0}'",i)); 
      return "(this string S, int i)";
    }

    public static string ArrayOfParams(this string S, int i, params object[] parameters)
    {
       Console.WriteLine(string.Format("i='{0}'",i));
       Console.WriteLine("parameters :");
       Array.ForEach(parameters, Console.WriteLine);
       return "(this string S, int i, params object[] parameters)";
    }

     // A method declaring an optional parameter AND a params is possible.
     //  public static string ArrayOfParams(this string S, int i, int j=10, params object[] parameters)
     // But with powershell throw System.IndexOutOfRangeException: https://github.com/PowerShell/PowerShell/issues/8182
     //
     // https://msdn.microsoft.com/en-us/library/ms182135.aspx
     // CA1026: Default parameters should not be used
     //https://docs.microsoft.com/en-us/visualstudio/code-quality/ca1026-default-parameters-should-not-be-used?view=vs-2017
    public static string ArrayOfParams(this string S, int i, int j=10, params object[] parameters)
    {
       Console.WriteLine(string.Format("i='{0}'",i));
       Console.WriteLine(string.Format("j='{0}'",j));
       Console.WriteLine("parameters :");
       Array.ForEach(parameters, Console.WriteLine);
       return "(this string S, int i, int j=10, params object[] parameters)";
    }
  }
"@

Add-Type -TypeDefinition $source

[TestOptionalAndParams].Assembly.ExportedTypes | New-ExtendedTypeData -Path c:\temp\All.ps1xml -All
Update-TypeData -PrependPath c:\temp\All.ps1xml

's'.ArrayOfParams(1,2)
# !!!!!!! Exception lors de l'appel de «ArrayOfParams» avec «2» argument(s): «L'index se trouve en dehors des limites du tableau.»

's'.ArrayOfParams(1,@(2))
#(this string S, int i, params object[] parameters)

's'.ArrayOfParams(1,5,@(2))
# The value of the second argument is an integer (5)
#(this string S, int i, int j=10, params object[] parameters)

's'.ArrayOfParams(1,@(2),1)
# The value of the second argument is an array,The Powershell runtime create an array of object
#(this string S, int i, params object[] parameters)

[Object[]]$Params=@('Test',1)
[TestOptionalAndParams]::ArrayOfParams.Invoke($Params)
#OK (this string S, int i)

[Object[]]$Params=@('Test',1,@('1'))
[TestOptionalAndParams]::ArrayOfParams.Invoke($Params)
#(this string S, int i, params object[] parameters)

[Object[]]$Params=@('Test',1,5,@(2))
[TestOptionalAndParams]::ArrayOfParams.Invoke($Params)
#(this string S, int i, int j=10, params object[] parameters)

#BUT
[Object[]]$Params=@('Test',1,'s',@(2))
[TestOptionalAndParams]::ArrayOfParams.Invoke($Params)
#(this string S, int i, params object[] parameters)

[Object[]]$Params=@('Test',1,2)
#[Object[]]$Params=@('Test',1,'Str') --> ok
#[Object[]]$Params=@('Test',1,$null)  --> ok
#[Object[]]$Params=@('Test',1,[Type]::Missing)  --> ok
[TestOptionalAndParams]::ArrayOfParams.Invoke($Params)
# !!!!!!! Exception

[Object[]]$Params=@('Test',1,$null,$null)
#[Object[]]$Params=@('Test',1,@())
[TestOptionalAndParams]::ArrayOfParams.Invoke($Params)
#(this string S, int i, params object[] parameters)

[Object[]]$Params=@('Test',1,1,$null)
[TestOptionalAndParams]::ArrayOfParams.Invoke($Params)
#(this string S, int i, int j=10, params object[] parameters)

[Object[]]$Params=@('Test',1,'1',$null)
[TestOptionalAndParams]::ArrayOfParams.Invoke($Params)
# !!!! Le type du second paramètre influence la sélection de la methode
#(this string S, int i, params object[] parameters)

[Object[]]$Params=@('Test',1,'1',3,4,5)
[TestOptionalAndParams]::ArrayOfParams.Invoke($Params)
#(this string S, int i, params object[] parameters)

[Object[]]$Params=@('Test',1,1,3,4,5)
[TestOptionalAndParams]::ArrayOfParams.Invoke($Params)
#(this string S, int i, params object[] parameters)

[Object[]]$Params=@('Test',1,1,3)
[TestOptionalAndParams]::ArrayOfParams.Invoke($Params)
#(this string S, int i, int j=10, params object[] parameters)

 [Object[]]$Params=@('Test',1,1,3,4)
[TestOptionalAndParams]::ArrayOfParams.Invoke($Params)
#(this string S, int i, params object[] parameters)
