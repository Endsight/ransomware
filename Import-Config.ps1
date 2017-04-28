# FSRM CryptoWall prevention configuration import script
# Matt Savicki


param(
    [Parameter()]
    [switch]$Force
)


$ErrorActionPreference = "Continue"
if (!$PSScriptRoot) {$PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent -ErrorAction Continue}
Start-Transcript ("$PSScriptRoot" + "\" + $env:COMPUTERNAME + "_FSRM-ImportLog.txt")
Get-Date
[string]$ConfigPath = "$PSScriptRoot\FSRM-Config"
[decimal]$NTver = (Get-WmiObject win32_operatingsystem).version.substring(0,3)


if ($NTver -ge 6.2)  # Server 2012+
    {
    # Enumerate shares on the server, excluding administrative shares.
    $shares = Get-SmbShare -Special $false -ErrorAction SilentlyContinue | where {$_.Name -ne "SYSVOL" -and $_.Name -ne "NETLOGON" -and $_.Name -ne "print$" -and $_.ShareType -eq "FileSystemDirectory"}

    # Continue if -Force parameter specified or if file shares exist.
    if ($Force -or $shares)
        {
        # Set FSRM global settings
        Set-FsrmSetting -ReportFileScreenAuditEnable

        # Clear existing configuration
        Get-FsrmFileScreen | Remove-FsrmFileScreen -Confirm:$false
        Get-FsrmFileScreenTemplate | Remove-FsrmFileScreenTemplate -Confirm:$false
        Get-FsrmFileGroup | Remove-FsrmFileGroup -Confirm:$false

        # Import prod file group
        $FileGroup = Import-Clixml -Path "$ConfigPath\FileGroup-Prod.xml"
        New-FsrmFileGroup -Name $FileGroup.Name -IncludePattern $FileGroup.IncludePattern

        # Import test file group
        $TestFileGroup = Import-Clixml -Path "$ConfigPath\FileGroup-Test.xml"
        New-FsrmFileGroup -Name $TestFileGroup.Name -IncludePattern $TestFileGroup.IncludePattern

        # Import prod file screen template
        $FileScreenTemplate = Import-Clixml -Path "$ConfigPath\FileScreenTemplate-Prod.xml"
        New-FsrmFileScreenTemplate -Name $FileScreenTemplate.Name -Active:$FileScreenTemplate.Active -IncludeGroup $FileScreenTemplate.IncludeGroup -Notification $FileScreenTemplate.Notification
        
        # Import test file screen template
        $TestFileScreenTemplate = Import-Clixml -Path "$ConfigPath\FileScreenTemplate-Test.xml"
        New-FsrmFileScreenTemplate -Name $TestFileScreenTemplate.Name -Active:$TestFileScreenTemplate.Active -IncludeGroup $TestFileScreenTemplate.IncludeGroup -Notification $TestFileScreenTemplate.Notification

        # On the root of each share create file screens based on the production template and test template.
        foreach ($share in $shares)
            {
            New-FsrmFileScreen -Path $share.Path -Template $FileScreenTemplate.Name
            # Test file screen is created on the parent directory of the share root, because FSRM only allows for one file screen per directory.
            [string]$ParentPath = Split-Path $share.Path -Parent
            if (!(Get-FsrmFileScreen -Path $ParentPath -ErrorAction SilentlyContinue)) {New-FsrmFileScreen -Path $ParentPath -Template $TestFileScreenTemplate.Name}
            }
        }
    else {Write-Output "ERROR: No file shares found and -Force switch not specified."}
    }

elseif ($NTver -le 6.1)  # Server 2008R2-
    {
    # Enumerate shares on the server, excluding administrative shares.
    $shares = Get-WmiObject win32_share | where {$_.Name -ne "SYSVOL" -and $_.Name -ne "NETLOGON" -and $_.Name -ne "print$" -and $_.Type -eq 0}
    
    # Continue if -Force parameter specified or if file shares exist.
    if ($Force -or $shares)
        {
        # Set FSRM global settings
        cmd.exe /c "filescrn.exe admin options /ScreenAudit:Enabled" | Out-Host

        # Clear existing configuration
        # File screens:
        $ScreenList = filescrn.exe screen list
        [string]$Regex = "^File Screen Path:\s+(\S+.*?)\s*$"
        $ScreenList -match $Regex -replace $Regex,'$1' | foreach {cmd.exe /c "filescrn.exe screen delete /path:`"$_`" /quiet"}
        # File screen templates:
        $TemplateList = filescrn.exe template list
        [string]$Regex = "^Template:\s+(\S+.*?)\s*$"
        $TemplateList -match $Regex -replace $Regex,'$1' | foreach {cmd.exe /c "filescrn.exe template delete /template:`"$_`" /quiet"}
        # File groups:
        $FilegroupList = filescrn.exe filegroup list
        [string]$Regex = "^File Group Name:\s+(\S+.*?)\s*$"
        $FilegroupList -match $Regex -replace $Regex,'$1' | foreach {cmd.exe /c "filescrn.exe filegroup delete /filegroup:`"$_`" /quiet"}

        # Import prod file group
        cmd.exe /c "filescrn.exe filegroup import /file:`"$ConfigPath\FileGroup2008-Prod.xml`" /overwrite" | Out-Host

        # Import test file group
        cmd.exe /c "filescrn.exe filegroup import /file:`"$ConfigPath\FileGroup2008-Test.xml`" /overwrite" | Out-Host

        # Import prod file screen template
        cmd.exe /c "filescrn.exe template import /file:`"$ConfigPath\FileScreenTemplate2008-Prod.xml`" /overwrite" | Out-Host

        # Import test file screen template
        cmd.exe /c "filescrn.exe template import /file:`"$ConfigPath\FileScreenTemplate2008-Test.xml`" /overwrite" | Out-Host

        # On the root of each share create file screens based on the production template and test template.
        foreach ($share in $shares)
            {
            [string]$SharePath = $share.Path
            Write-Output "Processing:"
            Write-Output $share.Path
            cmd.exe /c "filescrn.exe screen add /path:`"$SharePath`" /SourceTemplate:`"CryptoMalware-Prod`" /overwrite" | Out-Host
            # Test file screen is created on the parent directory of the share root, because FSRM only allows for one file screen per directory.
            [string]$ParentPath = Split-Path $share.Path -Parent
            Write-Output "Processing:"
            Write-Output $ParentPath
            $GetParentFileScreen = filescrn.exe screen list /path:"$ParentPath"
            if (!($GetParentFileScreen -match "^File Screen Path:\s+\S+.*$"))
                {cmd.exe /c "filescrn.exe screen add /path:`"$ParentPath`" /SourceTemplate:`"CryptoMalware-Test`" /overwrite" | Out-Host}
            }
        }
    else {Write-Output "ERROR: No file shares found and -Force switch not specified."}
    }


Get-Date
Stop-Transcript

