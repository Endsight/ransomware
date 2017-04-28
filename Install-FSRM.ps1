
# File Server Resource Manager installation script
# Matt Savicki


param(
    [Parameter()]
    [switch]$Force
)


$ErrorActionPreference = "Continue"
if (!$PSScriptRoot) {$PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent -ErrorAction Continue}
Start-Transcript "$PSScriptRoot\Install-FSRM-Log.txt"
#Import-Module "$PSScriptRoot\ScriptLog.psm1"
Import-Module ServerManager

Get-Date
[decimal]$NTver = (Get-WmiObject win32_operatingsystem).version.substring(0,3)
$results = @()
[boolean]$restart = $false
[boolean]$success = $true

# Enumerate shares on the server, excluding administrative shares.
$shares = Get-WmiObject win32_share | where {$_.Name -ne "SYSVOL" -and $_.Name -ne "NETLOGON" -and $_.Name -ne "print$" -and $_.Type -eq 0}

# If -Force parameter specified or if file shares exist, install features.
if ($Force -or $shares)
    {
    # Check if FSRM Windows feature and dependent features are installed, and if not install them.
    ####################################################
    $FSFileServer = Get-WindowsFeature FS-FileServer
    if ($FSFileServer.Installed)
        {
        $FSFileServer
        if ($NTver -ge 6.2) {if ($FSFileServer.InstallState.tostring() -eq "InstallPending") {$restart = $true}}
        }
    else
        {
        $results += Add-WindowsFeature FS-FileServer -Verbose -LogPath "$PSScriptRoot\FS-FileServer-Log.txt"
        $results[-1]
        } 
    ####################################################
    $FSRM = Get-WindowsFeature FS-Resource-Manager
    if ($FSRM.Installed)
        {
        $FSRM
        if ($NTver -ge 6.2) {if ($FSRM.InstallState.tostring() -eq "InstallPending") {$restart = $true}}
        }
    else
        {
        $results += Add-WindowsFeature FS-Resource-Manager -Verbose -LogPath "$PSScriptRoot\FS-Resource-Manager-Log.txt"
        $results[-1]
        }
    ####################################################
    $FSRMRSAT = Get-WindowsFeature RSAT-FSRM-Mgmt
    if ($FSRMRSAT.Installed)
        {
        $FSRMRSAT
        if ($NTver -ge 6.2) {if ($FSRMRSAT.InstallState.tostring() -eq "InstallPending") {$restart = $true}}
        }
    else
        {
        $results += Add-WindowsFeature RSAT-FSRM-Mgmt -Verbose -LogPath "$PSScriptRoot\RSAT-FSRM-Mgmt-Log.txt"
        $results[-1]
        }
    ####################################################


    # Check the results of each feature install.  Notify of any failures or restart needed.

    foreach ($result in $results)
        {
        if ($result.FeatureResult.RestartNeeded -eq $true) {$restart = $true}
        if ($result.FeatureResult.Success -eq $false) {$success = $false}
        }
    $RebootPending = Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing" | where {$_.PSChildName -eq "RebootPending"}
    if ($RebootPending) {$restart = $true}

    if ($restart) {Write-Output "WARNING: A reboot is required to complete installaion of one or more features."}
    if (!$success) {Write-Output "ERROR: One or more feature installations returned errors.  Check the logs."}
    if ($success -and -not $restart) {Write-Output "SUCCESS: All features are installed."}
    }
else
    {Write-Output "ERROR: No file shares found and -Force switch not specified."}


Get-Date
Stop-Transcript

