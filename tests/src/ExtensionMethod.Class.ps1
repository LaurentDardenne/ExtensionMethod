 #Extension classes
$source = @"
using System;
using System.Reflection;

  [Flags]
  public enum Flags
  {
      F1 = 1,
      F2 = 2
  }

  public enum MyColors
  {
      Red,
      Green,
      Blue,
      Black
  }

  public static class Helper
  {
    public static void WriteSignature(MethodBase mi)
    {
        string S=mi.ToString();
        Console.WriteLine(S);
    }
  }

  public static class BasicTest
  {

    public static int My(this string S){
        Helper.WriteSignature(MethodInfo.GetCurrentMethod());
        return 1;
    }
    public static int My(this string S, int end){
        Helper.WriteSignature(MethodInfo.GetCurrentMethod());
        return 2;
    }
    public static int My(this string S, string end){
        Helper.WriteSignature(MethodInfo.GetCurrentMethod());
        return 3;
    }
  }

  public static class Optionnal
  {
    public static int My(this string S){
        Helper.WriteSignature(MethodInfo.GetCurrentMethod());
        return 1;
    }
    public static int My(this string S, int end){
        Helper.WriteSignature(MethodInfo.GetCurrentMethod());
        return 2;
    }
    public static int My(this string S, string end){
        Helper.WriteSignature(MethodInfo.GetCurrentMethod());
        return 3;
    }

     //https://stackoverflow.com/questions/37894416/why-does-c-sharp-allow-ambiguous-function-calls-through-optional-arguments
     //
     //https://learn.microsoft.com/en-us/dotnet/csharp/programming-guide/classes-and-structs/named-and-optional-arguments?redirectedfrom=MSDN#overload-resolution
     // "If two candidates are judged to be equally good, preference goes to a candidate that does not have optional parameters for
     // which arguments were omitted in the call.
     // This is a consequence of a general preference in overload resolution for candidates that have fewer parameters."

    public static int My(this string S, int end, bool includeBoundary=true){
        Helper.WriteSignature(MethodInfo.GetCurrentMethod());
        return 4;
    }
   }

   public static class OutParam
   {
    public static int MethodWithOutParam( this string S, out string str2m, ref string str3m)
    {
        Helper.WriteSignature(MethodInfo.GetCurrentMethod());
        str2m="set by method";
        return 1;
    }

    public static int MethodWithOutParam( this string S ,out string str2m)
    {
        Helper.WriteSignature(MethodInfo.GetCurrentMethod());
        str2m="set by method";
        return 2;
    }

     //Change type of S parameter :
      //The in, ref, and out keywords are not considered part of the method signature for the purpose of overload resolution.
      //Therefore, methods cannot be overloaded if the only difference is that one method takes a ref or in argument and
      //the other takes an out argument.
    public static int MethodWithOutParam( this int S, ref string str2m)
    {
        Helper.WriteSignature(MethodInfo.GetCurrentMethod());
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

    public static MyColors FColors(this string S, MyColors color=MyColors.Red) {
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
   }

   public static class ParamsKeyWord
   {



    public static int ArrayOfParams(this string S, int i)
    {
        Helper.WriteSignature(MethodInfo.GetCurrentMethod());
        return 1;
    }

    // TODO documenter le cas  ?
    public static int ArrayOfParams(this string S, params object[] parameters)
    {
        Helper.WriteSignature(MethodInfo.GetCurrentMethod());
        return 2;
    }

    public static int ArrayOfParams(this string S, int i, int j)
    {
        Helper.WriteSignature(MethodInfo.GetCurrentMethod());
        return 3;
    }

    /*
    public static int ArrayOfParams(this string S, int i, int j, int k=10)
    {
        Helper.WriteSignature(MethodInfo.GetCurrentMethod());
        return 4;
    }
    */

     //Note : appel possible ArrayOfParams('S',1,2) parameters est un tableau vide
     // Déclare le cas {$_ -gt NbArgs }
     // todo ? Déclare le cas {$_ -gt NbArgs } et {$_ -eq NbArgs }
    //CS0111	Le type 'ParamsKeyWord' définit déjà un membre appelé 'ArrayOfParams' avec les mêmes types de paramètre	TestExtension
/*
    public static int ArrayOfParams(this string S, int i, int j, params object[] parameters)
    {
        Helper.WriteSignature(MethodInfo.GetCurrentMethod());
        return 5;
    }
*/

    public static int ArrayOfParams(this string S, int i, int j=5, params object[] parameters)
    {
        Helper.WriteSignature(MethodInfo.GetCurrentMethod());
        return 5;
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
"@
$Assembly=Add-Type -TypeDefinition $source -Passthru