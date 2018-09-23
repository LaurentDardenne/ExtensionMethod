$ModuleVersion=(Import-ManifestData "$ExtensionMethodSrc\UncommonSense.PowerShell.TypeData\UncommonSense.PowerShell.TypeData.psd1").ModuleVersion

$Result=nuspec 'UncommonSense.PowerShell.TypeData' $ModuleVersion {
   properties @{
        Authors='Jan Hoek'
        Owners='Jan Hoek'
        Description=@'
PowerShell module to help build PowerShell type extension files.

If you're not familiar with the PowerShell type extension file format, please run Get-Help about_Types.ps1xml in your PowerShell console to find additional information.

In an attempt to simplify and shorten the syntax:

- all the cmdlets in the module have aliases (see below);
- most (if not all) cmdlet parameters are positional;
- each parent node has a script block parameter for easily adding child nodes.

'@
        title='UncommonSense.PowerShell.TypeData'
        summary='PowerShell module to help build type extension files.'
        copyright='Copyright (c) 2016'
        language='en-US'
        licenseUrl='https://www.gnu.org/licenses/gpl-3.0.en.html'
        projectUrl='https://github.com/jhoek/UncommonSense.PowerShell.TypeData'
        releaseNotes=''
        tags='type extended system ets extensions add-member update-typedata ps1xml'
   }

   files {
        file -src "$ExtensionMethodSrc\UncommonSense.PowerShell.TypeData\UncommonSense.PowerShell.TypeData.dll"
        file -src "$ExtensionMethodSrc\UncommonSense.PowerShell.TypeData\UncommonSense.PowerShell.TypeData.psd1"
        file -src "$ExtensionMethodSrc\UncommonSense.PowerShell.TypeData\UncommonSense.PowerShell.TypeData.Tests.ps1"
        file -src "$ExtensionMethodSrc\UncommonSense.PowerShell.TypeData\UncommonSense.PowerShell.TypeData.chm"
        file -src "$ExtensionMethodSrc\UncommonSense.PowerShell.TypeData\LICENSE.md"
        file -src "$ExtensionMethodSrc\UncommonSense.PowerShell.TypeData\README.md"
   }
}

$Result|
  Push-nupkg -Path $env:temp -Source 'https://www.myget.org/F/ottomatt/api/v2/package'

# $PSGalleryPublishUri = 'https://www.myget.org/F/ottomatt/api/v2/package'
# $PSGallerySourceUri = 'https://www.myget.org/F/ottomatt/api/v2'
# 
# Register-PSRepository -Name OttoMatt -SourceLocation $PSGallerySourceUri -PublishLocation $PSGalleryPublishUri #-InstallationPolicy Trusted
# Install-Module UncommonSense.PowerShell.TypeData # -Repository OttoMatt