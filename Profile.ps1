Clear-Host

Set-Location C:\
$Shell=$Host.UI.RawUI
$title = $Shell.WindowTitle + " V" + $PSVersionTable.PSVersion.Major
$Shell.WindowTitle = $title
$Profile_Path = Split-Path $profile
$Profile_Module = "$Profile_Path\Profile.psm1"



function prompt
{
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal] $identity

    $(if (test-path variable:/PSDebugContext) { '[DBG]: ' }

    elseif($principal.IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
    { Write-Host "[ADMIN]: " -NoNewline -ForegroundColor Green}

    else { '' }) + 'PS ' + $(Get-Location).ToString().Replace($HOME.ToString(),"~") + $(if ($nestedpromptlevel -ge 1) { '>>' }) + '> '
}



Write-Host "

PROFILE SOURCE can be found @ https://raw.githubusercontent.com/clintcparker/PowerShellScripts/master/Profile.ps1


Run `Get-Command -Module Profile` to see all profile functions.

All modules in $Profile_Path\Modules will be automatically loaded

"
 

if (-Not (Test-Path $Profile_Module))
{
    Invoke-WebRequest "https://raw.githubusercontent.com/clintcparker/PowerShellScripts/master/Profile.psm1" -OutFile $Profile_Module
}
Import-Module $Profile_Module -Force

Import-ProfileModules
