
Import-Module '..\Release\Extensionmethod\\ExtensionMethod.psd1'

<#
 #redirect stdOut

$Writer = [System.IO.StreamWriter]::new("$temp\Pester.txt")
$Writer.AutoFlush = $true
$OriginalOut = [System.Console]::Out
try
{
    [System.Console]::SetOut($Writer)
    $a=[BasicTest]::my('tt')
}
finally
{
    [System.Console]::SetOut($OriginalOut)
    $Writer.Close()
}
#>


<#
TODO
ajoute ces cas pour Params:
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

    //??
    public static string Method2(this string S, int end, object obj)
    {
      return "(this string S, int end, object obj)";
    }

TODO
vérifier si pour une méthode avec Params, $args peut contenir des tableaux et si la reconstruction de l'appel les considère tel quel.

#>
$EtsFileName="$Env:Temp\ExtensionMethodClass.ps1xml"
Push-Location ".\src"
 $Assembly=.\ExtensionMethod.Class.ps1
Pop-Location

$Assembly|New-ExtendedTypeData -Path $EtsFileName -All -Force
Update-TypeData -PrependPath $EtsFileName

Describe 'Invoke ETS method provided by [BasicTest]. No optional no params' {
  
  it "The method 'My' is provided by the [BasicTest] class" {  
    $o=Get-TypeData 'System.String'
    $o.Members.My.Script -match [regex]::Escape('[BasicTest]::My')|Should -be $true
  }

  it 'Invoke My()' {
    'String'.My()|Should -be 1
  }

  it 'Invoke My(int)' {
    'String'.My(10)|Should -be 2
  }

  it 'Invoke My(String)' {
    'String'.My('test')|Should -be 3
  }

}

Describe 'Invoke ETS method provided by [Optionnal]. With optional no params' {

  it "The method 'Other' is provided by the [Optional] class" {  
    $o=Get-TypeData 'System.String'
    $o.Members.Other.Script -match [regex]::Escape('[Optionnal]::Other')|Should -be $true
  }

  it 'Invoke Other()' {
    'String'.Other()|Should -be 1
  }

  it 'Invoke Other(int)' {
    # If two candidates are judged to be equally good, preference goes to a candidate that does not have optional parameters for
    # which arguments were omitted in the call.
    # This is a consequence of a general preference in overload resolution for candidates that have fewer parameters.

    'String'.Other(10)|Should -be 2
  }

  it 'Invoke Other(String)' {
    'String'.Other('test')|Should -be 3
  }

  it 'Invoke Other(int,bool)' {
    'String'.Other(10,$false)|Should -be 4
  }
}

Describe 'Invoke ETS method provided by [BasicTest2]. With optional no params' {

    it "The method 'Method1' is provided by the [BasicTest2] class" {  
      $o=Get-TypeData 'System.String'
      $o.Members.Method1.Script -match [regex]::Escape('[BasicTest2]::Method1')|Should -be $true
    }
  
    it 'Invoke Method1()' {
      'String'.Method1()|Should -be 1
    }
  
    it 'Invoke Method1(Bool)' {
      # If two candidates are judged to be equally good, preference goes to a candidate that does not have optional parameters for
      # which arguments were omitted in the call.
      # This is a consequence of a general preference in overload resolution for candidates that have fewer parameters.
  
      'String'.Method1($false)|Should -be 1
    }
  
    it 'Invoke Method1(Bool,int)' {
      'String'.Method1($False,10)|Should -be 2
    }
  
    it 'Invoke Method1(int,bool,string)' {
      #todo connaitre la valeur du paramètre 'Text' $null ou valeur par défaut du C#
      'String'.Method1($False,10,$null)|Should -be 3
    }

    it 'Invoke Method1(int,bool,string)' {
      'String'.Method1($False,10,'Test')|Should -be 3
    }    
  }

  Describe 'Invoke ETS method provided by [DefaultWithVariousType]. With optional no params' {

    it "The method 'Func1' is provided by the [DefaultWithVariousType] class" {  
      $o=Get-TypeData 'System.String'
      $o.Members.Func1.Script -match [regex]::Escape('[DefaultWithVariousType]::Func1')|Should -be $true
    }
  
    it 'Invoke Func1()' {
      'String'.Func1()|Should -be $true
    }

    it 'Invoke Func2()' {
      $flags=([Flags]::F1 -bor [Flags]::F2) -as [int]
      $result='String'.Func2()
      $result|Should -be $flags
    }

    it 'Invoke FColors()' {
      $result='String'.FColors()
      $result|Should -be 'Red'
    }

     #todo les trois cas semblent identique côté ETS
    it 'Invoke MethodPtr()' {
      $result='String'.MethodPtr()
      $result|Should -not -be $null
    }    

    it 'Invoke MethodPtr2()' {
      $result='String'.MethodPtr2()
      $result|Should -be $null
    }   

    it 'Invoke MethodPtr3()' {
      $result='String'.MethodPtr3()
      $result|Should -be 0
    }   
    
    it 'Invoke MethodDefault()' {
      $result='String'.MethodDefault('format')
      $result|Should -be 'C'
    }  

    it 'Invoke MethodPtr3()' {
      $result='String'.DefaultStr('format')
      $result|Should -be "Default value"
    }  
  }

  
  Describe 'Invoke ETS method provided by [OutParam]. With optional no params' {

    it "The method 'MethodWithOutParam' is provided by the [OutParam] class" {  
      $o=Get-TypeData 'System.String'
      $o.Members.MethodWithOutParam.Script -match [regex]::Escape('[OutParam]::MethodWithOutParam')|Should -be $true
    }  

    it 'Invoke MethodWithOutParam(out,ref)' {
      [ref]$outParam=$null
      [ref]$RefParam='Outer'

      $result='String'.MethodWithOutParam($outParam,$RefParam)
      $result|Should -be 1
      $outParam.Value|Should -be 'set by method'
      $RefParam.Value|Should -be 'Inner'
    }   

    it 'Invoke MethodWithOutParam(out)' {
      [ref]$outParam=$null

      $result='String'.MethodWithOutParam($outParam)
      $outParam.Value|Should -be 'set by method'
      $result|Should -be 2
    }     

    it 'Invoke MethodWithOutParam(ref)' {
      <#
      The in, ref, and out keywords are not considered part of the method signature for the purpose of overload resolution.
      Therefore, methods cannot be overloaded if the only difference is that one method takes a ref or in argument and
      the other takes an out argument.
      #>
      [ref]$RefParam='Outer'

      $I=123
      $result=$I.MethodWithOutParam($refParam)
      $RefParam.Value|Should -be 'Inner'
      $result|Should -be 3
    }      
}
Describe 'Invoke ETS method provided by [ParamsKeyWord]. With optional no params' {

  it "The method 'ConfusingSignature' is provided by the [ParamsKeyWord] class" {  
    $o=Get-TypeData 'System.String'
    $o.Members.ConfusingSignature.Script -match [regex]::Escape('[ParamsKeyWord]::ConfusingSignature')|Should -be $true
  }  
  #todo bug de génération si + signatures dont au moins une avec params on considère le cas ou il n'y a pas de valeur pour params
  it 'Invoke ConfusingSignature(int,int)' {
    $result='String'.ConfusingSignature(8,9)
    $result|Should -be 0
  }     

  it 'Invoke ArrayOfParams(int)' {
    $result='String'.ArrayOfParams(9)
    $result|Should -be 1
  }     

  it 'Invoke ArrayOfParams()' {
    $result='String'.ArrayOfParams()
    $result|Should -be 2
  }   

  it 'Invoke ArrayOfParams(@(1..4))' {
    $result='String'.ArrayOfParams(@(1..4))
    $result|Should -be 2
  }     

  it 'Invoke ArrayOfParams(1,@(2..4))' {
    $result='String'.ArrayOfParams(1,@(2..4))
    $result|Should -be 3
  }     

  it 'Invoke ArrayOfParams(int,int)' {
    $result='String'.ArrayOfParams(8,9)
    $result|Should -be 4
  }    
}

  <#
  //With optional and params
   //No optional and with params
   public static class ParamsKeyWord
   {

     //Note : appel possible ArrayOfParams('S',1,2) parameters est un tableau vide
     // Déclare le cas {$_ -gt NbArgs }
     // todo ? Déclare le cas {$_ -gt NbArgs } et {$_ -eq NbArgs }
     //CS0111	Le type 'ParamsKeyWord' définit déjà un membre appelé 'ArrayOfParams' avec les mêmes types de paramètre	TestExtension

    public static int ConfusingSignature(this string S, int i, int j, params object[] parameters)
    {
        Helper.WriteSignature(MethodInfo.GetCurrentMethod());
        return 0;
    }



    public static int ArrayOfParams(this string S, int i, int j, int k=10)
    {
        Helper.WriteSignature(MethodInfo.GetCurrentMethod());
        return 5;
    }


    public static int ArrayOfParams(this string S, int i, int j=5, params object[] parameters)
    {
        Helper.WriteSignature(MethodInfo.GetCurrentMethod());
        return 6;
    }
   }

   public static class DefaultKeyWord
   {
    //PS v5.1 bug : https://github.com/dotnet/corefx/issues/12338
    //PS Core ok.
    public static string Foo1(this string S, DateTime dt = new DateTime())
    {
        return string.Empty;
    }

    public static string Foo2(this string S, DateTime dt = default(DateTime))
    {
        return string.Empty;
    }

    public static string Foo3(this string S,int? x = null)
    {
      return string.Empty;
    }

    public static int Add(this string S, int a = 3, int b = 5 )
    {
     return a + b;
    }

    //D for Double
    public static double Add2(this string S, double a = 3.2D, double b = 5.235 )
    {
     return a + b;
    }

    //F for Float
    // 'float' is alias for 'Single'
    public static Single Add3(this string S, Single a = 123456789e4f, Single b =  1e12f )
    {
     return a + b;
    }

    //M for Decimal
    public static decimal Add4(this string S, decimal a = 3.2M, decimal b = 5.235M )
    {
     return a + b;
    }
  }

  #>