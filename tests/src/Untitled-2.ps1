$source = @"
using System;

  public static class BasicTest2
  {
    public static string Method2(this string S, int end)
    {
      return "(this string S, int end)";
    }

    public static string Method2(this string S, string end)
    {
      return "(this string S, string end)";
    }

    public static string Method2(this string S, params object[] parameters)
    {
      return "(this string S, params object[] parameters)";
    }    
  }
"@

Add-Type -TypeDefinition $source
#Connaitre la liste des méthodes ambigue, même nb de param avec au moin une méthode utilisant le mot clé 'params' dans sa signature 
# 1     : PS-dotnet résolvent le type
# -ge 1 : si  args[1] est un tableau, lever l'ambiguïté en spécifiant un tableau et pas une liste de paramètres

[Object[]]$Params=@('Test',1)
[BasicTest2]::ArrayOfParams.Invoke($Params)
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

