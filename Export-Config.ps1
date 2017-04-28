# FSRM CryptoWall prevention configuration export script
# Matt Savicki


$ErrorActionPreference = "Continue"
if (!$PSScriptRoot) {$PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent -ErrorAction Continue}
Start-Transcript "$PSScriptRoot\FSRM-ExportLog.txt"
Get-Date
[string]$ConfigPath = "$PSScriptRoot\FSRM-Config"
[decimal]$NTver = (Get-WmiObject win32_operatingsystem).version.substring(0,3)


# Create folder to store config files if it does not exist
if (!(Test-Path $ConfigPath -PathType Container)) {New-Item $ConfigPath -ItemType Directory}

if ($NTver -ge 6.2)  # Server 2012+
    {
    # Export file group
    Get-FsrmFileGroup -Name "CryptoMalware-Prod" | Export-Clixml -Path "$ConfigPath\FileGroup-Prod.xml" -Force -Verbose
    Get-FsrmFileGroup -Name "CryptoMalware-Test" | Export-Clixml -Path "$ConfigPath\FileGroup-Test.xml" -Force -Verbose

    # Export file screen template
    Get-FsrmFileScreenTemplate -Name "CryptoMalware-Prod" | Export-Clixml -Path "$ConfigPath\FileScreenTemplate-Prod.xml" -Force -Verbose
    Get-FsrmFileScreenTemplate -Name "CryptoMalware-Test" | Export-Clixml -Path "$ConfigPath\FileScreenTemplate-Test.xml" -Force -Verbose
    }

# All OS
    # Export file group
    if (Test-Path "$ConfigPath\FileGroup2008-Prod.xml") {Remove-Item "$ConfigPath\FileGroup2008-Prod.xml" -Force}
    cmd.exe /c "filescrn.exe filegroup export /file:`"$ConfigPath\FileGroup2008-Prod.xml`" /filegroup:`"CryptoMalware-Prod`"" | Out-Host

    if (Test-Path "$ConfigPath\FileGroup2008-Test.xml") {Remove-Item "$ConfigPath\FileGroup2008-Test.xml" -Force}
    cmd.exe /c "filescrn.exe filegroup export /file:`"$ConfigPath\FileGroup2008-Test.xml`" /filegroup:`"CryptoMalware-Test`"" | Out-Host

    # Export file screen template
    if (Test-Path "$ConfigPath\FileScreenTemplate2008-Prod.xml") {Remove-Item "$ConfigPath\FileScreenTemplate2008-Prod.xml" -Force}
    cmd.exe /c "filescrn.exe template export /file:`"$ConfigPath\FileScreenTemplate2008-Prod.xml`" /template:`"CryptoMalware-Prod`"" | Out-Host

    if (Test-Path "$ConfigPath\FileScreenTemplate2008-Test.xml") {Remove-Item "$ConfigPath\FileScreenTemplate2008-Test.xml" -Force}
    cmd.exe /c "filescrn.exe template export /file:`"$ConfigPath\FileScreenTemplate2008-Test.xml`" /template:`"CryptoMalware-Test`"" | Out-Host
########


Get-Date
Stop-Transcript

