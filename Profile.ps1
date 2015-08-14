Clear-Host

Set-Location C:\
$Shell=$Host.UI.RawUI
$title = $Shell.WindowTitle
$Shell.WindowTitle = $title
$Profile_Path = Split-Path $profile
$Profile_Module = "$Profile_Path\Profile.psm1"

Write-Host "

PROFILE SOURCE can be found @ https://raw.githubusercontent.com/clintcparker/PowerShellScripts/master/Profile.ps1


Run `Get-Command -Module Profile` to see all profile functions.

"


if (-Not (Test-Path $Profile_Module))
{
    Invoke-WebRequest "https://raw.githubusercontent.com/clintcparker/PowerShellScripts/master/Profile.psm1" -OutFile $Profile_Module
}
Import-Module $Profile_Module -Force
