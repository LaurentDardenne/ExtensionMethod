if(! (Test-Path variable:ExtensionMethodVcs))
{ throw "The project configuration is required, see the 'ExtensionMethod_ProjectProfile.ps1' script." }

$ModuleVersion=(Import-ManifestData "$ExtensionMethodVcs\src\ExtensionMethod.psd1").ModuleVersion

$Result=nuspec 'ExtensionMethod' $ModuleVersion {
   properties @{
        Authors='Dardenne Laurent'
        Owners='Dardenne Laurent'
        Description=@'
Creation of ps1xml file dedicated to the extension methods contained in an assembly
'@
        title='ExtensionMethod module'
        summary='Creation of ps1xml file dedicated to the extension methods contained in an assembly.'
        copyright='Copyleft'
        language='fr-FR'
        licenseUrl='https://creativecommons.org/licenses/by-nc-sa/4.0/'
        projectUrl='https://github.com/LaurentDardenne/ExtensionMethod'
        #iconUrl='https://github.com/LaurentDardenne/Template/blob/master/icon/ExtensionMethod.png'
        releaseNotes="$(Get-Content "$ExtensionMethodVcs\CHANGELOG.md" -raw)"
        tags='Template Conditionnal Directive Regex'
   }

   dependencies {
        dependency Log4Posh 2.0.1
        dependency UncommonSense.PowerShell.TypeData 1.0.2
   }

   files {
        file -src "$ExtensionMethodVcs\src\ExtensionMethod.psd1"
        file -src "$ExtensionMethodVcs\src\ExtensionMethod.psm1"
        file -src "$ExtensionMethodVcs\src\ExtensionMethod.Resources.psd1"
        file -src "$ExtensionMethodVcs\src\ExtensionMethodLog4Posh.Config.xml"
        #file -src "$ExtensionMethodVcs\README.md"
        file -src "$ExtensionMethodVcs\src\Demos\Demos.ps1" -target "Demos\"
   }
}

$Result|
  Push-nupkg -Path $ExtensionMethodDelivery -Source 'https://www.myget.org/F/ottomatt/api/v2/package'

