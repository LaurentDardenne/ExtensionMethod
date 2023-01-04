 #Run before 'Requirements.ps1'
$source = @"
using System;
using System.Reflection;

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
    public static void WriteSignature(MethodBase mi) 
     { 
        string S=mi.ToString();
        Console.WriteLine(S); 
     } 

    public static int My(this string S){
        WriteSignature(MethodInfo.GetCurrentMethod());
        return 1; 
    }
    public static int My(this string S, int end){
        WriteSignature(MethodInfo.GetCurrentMethod());
        return 2; 
    }
    public static int My(this string S, string end){
        WriteSignature(MethodInfo.GetCurrentMethod());
        return 3; 
    }
  }
  
  public static class Optionnal
  {
    public static int My(this string S){
        WriteSignature(MethodInfo.GetCurrentMethod());
        return 1; 
    }
    public static int My(this string S, int end){
        WriteSignature(MethodInfo.GetCurrentMethod());
        return 2; 
    }
    public static int My(this string S, string end){
        WriteSignature(MethodInfo.GetCurrentMethod());
        return 3; 
    }

     //https://stackoverflow.com/questions/37894416/why-does-c-sharp-allow-ambiguous-function-calls-through-optional-arguments
     //
     //https://learn.microsoft.com/en-us/dotnet/csharp/programming-guide/classes-and-structs/named-and-optional-arguments?redirectedfrom=MSDN#overload-resolution
     // "If two candidates are judged to be equally good, preference goes to a candidate that does not have optional parameters for
     // which arguments were omitted in the call.
     // This is a consequence of a general preference in overload resolution for candidates that have fewer parameters."

    public static string My(this string S, int end, bool includeBoundary=true){
        WriteSignature(MethodInfo.GetCurrentMethod());
        return 4; 
    }
   }

   public static class OutParam
   {
    public static int MethodWithOutParam( this string S, out string str2m, ref string str3m)
    {
        WriteSignature(MethodInfo.GetCurrentMethod());
        return 1; 
    }

    public static int MethodWithOutParam( this string S ,out string str2m)
    {
        WriteSignature(MethodInfo.GetCurrentMethod());
        return 2; 
    }

    public static int MethodWithOutParam( this string S, ref string str2m)
    {
        WriteSignature(MethodInfo.GetCurrentMethod());
        return 3; 
    }
   }

   public static class DefaultWithVariousType
   {   
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
      //Mixer ce type de déclaration est possible mais de déterminer quelle méthode sera appelée est confus.
      
      //In case of overload the compiler always calls the method declaring the most parameters
      //the method declaring a parameter of type params is called last and if there is no ambiguity
      //We assume a single overload with 'params' and that it is declared last
      //Mixing this type of declaration is possible but determining which method will be called is confusing.
      
      //
      // A method declaring an optional parameter AND a params is possible
      //  public static string ArrayOfParams(this string S, int i, int j=10, params object[] parameters)
      // But with powershell throw System.IndexOutOfRangeException: https://github.com/PowerShell/PowerShell/issues/8182
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

     //Note : appel possible ArrayOfParams('S',1,2) parameters est un tableau vide
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

    //PS v5.1 bug : https://github.com/dotnet/corefx/issues/12338
    //PS Core ok.
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