$source = @"
using System;

  public static class DuplicateMethodName1
  {
    public static string Method1(this string S)
    {
      return "(this string S)";
    }

    public static string Method1(this int end,string S)
    {
      return "(this int end,string S)";
    }

    public static string Method1(this string S, int end)
    {
      return "(this string S, int end)";
    }

    public static string Method1(this string S, bool includeBoundary=true)
    {
        return "Method1 (this string S, bool includeBoundary=true)";
    }

    public static string Method1(this string S, bool includeBoundary=true,int Boundary=10)
    {
        return "Method1 (this string S, bool includeBoundary=true,int Boundary=10)";
    }

    public static string Method1(this string S, double Sum, int Boundary=10)
    {
      return "(this string S, double Sum, int Boundary=10)";
    }

    public static string Method1(this string S, object Obj, int Boundary)
    {
        return "Method1 (this string S, object Obj, int Boundary)";
    }

    public static string Method1(this string S, int Boundary, object Obj)
    {
        return "Method1 (this string S, int Boundary, object Obj)";
    }


    public static string Method1(this string S, bool includeBoundary=true,int Boundary=10,string text="test")
    {
        return "Method1 (this string S, bool includeBoundary=true,int Boundary=10,string text='test')";
    }
  }

  public static class DuplicateMethodName2
  {
    public static string Method1(this int end,string S)
    {
      return "(this int end,string S)";
    }

    public static string Method1(this string S, int end)
    {
      return "(this string S, int end)";
    }

    public static string Method1(this string S, bool includeBoundary=true)
    {
        return "Method1 (this string S, bool includeBoundary=true)";
    }

    public static string Method1(this string S, bool includeBoundary=true,int Boundary=10)
    {
        return "Method1 (this string S, bool includeBoundary=true,int Boundary=10)";
    }

    public static string Method1(this string S, bool includeBoundary=true,int Boundary=10,string text="test")
    {
        return "Method1 (this string S, bool includeBoundary=true,int Boundary=10,string text='test')";
    }
  }  
"@

$Assembly=Add-Type -TypeDefinition $source  -PassThru
# $VerbosePreference='continue'
# #ipmo G:\ps\ExtensionMethod\Release\Extensionmethod\ExtensionMethod.psd1
# ipmo  C:\Users\1801106\Documents\projets\ExtensionMethod\Release\Extensionmethod\ExtensionMethod.psd1
# $O=$Assembly|New-ExtendedTypeData -Path c:\temp\All.ps1xml -All

<#
M(p)
 -> Colision !!!
    Pour PS et/ou C#
M(p,params)
M(p,Object)

#>