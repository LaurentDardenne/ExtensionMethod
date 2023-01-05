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

  public static class BasicTest
  {
    public static string ArrayOfParams(this string S, int i)
    {
        return "(this string S, int i)";
    }

    public static string ArrayOfParams(this string S, int i, params object[] parameters)
    {
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
        return "(this string S, int i, int j=10, params object[] parameters)";
    }    
  }
"@

Add-Type -TypeDefinition $source

[Object[]]$Params=@('Test',1)
[BasicTest]::ArrayOfParams.Invoke($Params)
#OK (this string S, int i)

[Object[]]$Params=@('Test',1,@('1'))
[BasicTest]::ArrayOfParams.Invoke($Params)
(this string S, int i, params object[] parameters)

[Object[]]$Params=@('Test',1,5,@(2))
[BasicTest]::ArrayOfParams.Invoke($Params)
#(this string S, int i, int j=10, params object[] parameters)

#BUT
[Object[]]$Params=@('Test',1,'s',@(2))
[BasicTest]::ArrayOfParams.Invoke($Params)
#(this string S, int i, params object[] parameters)

[Object[]]$Params=@('Test',1,2)
#[Object[]]$Params=@('Test',1,'Str')
#[Object[]]$Params=@('Test',1,$null)
[BasicTest]::ArrayOfParams.Invoke($Params)
# !!!!!!! Exception 

[Object[]]$Params=@('Test',1,$null,$null)
#[Object[]]$Params=@('Test',1,@())
[BasicTest]::ArrayOfParams.Invoke($Params)
#(this string S, int i, params object[] parameters)

[Object[]]$Params=@('Test',1,1,$null)
[BasicTest]::ArrayOfParams.Invoke($Params)
#(this string S, int i, int j=10, params object[] parameters)

