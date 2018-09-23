2018-02-28    Version 1.4.0
    Add
      Management of 'Params', 'optional' and 'byRef' parameters.
      Edit the method signature as comment
           # mymethod([string] $S, [ref] [string] $Str2)
           # mymethod([string] $S, [myColors] $color='Red')
           # Func2([string] $S, [Flags] $f='F1, F2')
           # MethodPtr([string] $S, [System.IntPtr] $arg=$null OR new OR default)

    Change
       UncommonSense.PowerShell.TypeData Module v1.2.1.40
       Refactoring 'Get-ParameterComment', 'New-ExtensionMethodType'

    Breacking change
     New-ExtendedTypeData : Rename the parameter '$Data' to '$TypeData'


2017-12-29    Version 1.3.3

  Change UncommonSense.PowerShell.TypeData Module v1.2.1.0
          Integrated aliases into cmdlet code
          Remove the file : UncommonSense.PowerShell.TypeData.psm1

2017-06-04    Version 1.3.2

    Change  New-ExtensionMethodType
             Adding method signature as comment
               version 1.3.1 :
                  1 { [Nager.Date.Extensions.DateTimeExtension]::IsWeekend($this,$args[0]) }
               now :
                   # IsWeekend([System.DateTime] $dateTime, [Nager.Date.CountryCode] $countryCode)
		              1 { [Nager.Date.Extensions.DateTimeExtension]::IsWeekend($this,$args[0]) }

2017-04-06    Version 1.3.0

  Add  UncommonSense.PowerShell.TypeData Module v1.1
  Fix New-Hastable


2017-02-12    Version 1.2.0

  Refactoring New-ExtensionMethodTypeData function with UncommonSense.PowerShell.TypeData Module


2014-01-29   Version 1.1.0
 Add Split feature on New-ExtensionMethodTypeData function


2010-07-31    Version 1.0.0
Original version
