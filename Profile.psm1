$moduleName = "Profile"


$profileModulesArrayString = "PROFILE_MODULES_ARRAY"

function Add-Path {
  <#
    .SYNOPSIS
      Adds a Directory to the Current Path
    .DESCRIPTION
      Add a directory to the current path.  This is useful for 
      temporary changes to the path or, when run from your 
      profile, for adjusting the path within your powershell 
      prompt.
    .EXAMPLE
      Add-Path -Directory "C:\Program Files\Notepad++"
    .PARAMETER Directory
      The name of the directory to add to the current path.
  #>

  [CmdletBinding()]
  param (
    [Parameter(
      Mandatory=$True,
      ValueFromPipeline=$True,
      ValueFromPipelineByPropertyName=$True,
      HelpMessage='What directory would you like to add?')]
    [Alias('dir')]
    [string[]]$Directory
  )

  PROCESS {
    $Path = Get-EnvironmentVariable("PATH").ToLower().Split(";")
    $Directory = $Directory.ToLower()

    foreach ($dir in $Directory) {
      if ($Path -contains $dir) {
        Write-Verbose "$dir is already present in PATH"
      } else {
        if (-not (Test-Path $dir)) {
          Write-Verbose "$dir does not exist in the filesystem"
        } else {
          $Path += $dir
        }
      }
    }

    $pathStr = [String]::Join(';', $Path)
    Set-EnvironmentVariable "PATH" $pathStr -Global
  }
}

function Set-EnvironmentVariable {
    param(
        [Parameter(
            Mandatory=$True,
            ValueFromPipeline=$True,
            ValueFromPipelineByPropertyName=$True,
            HelpMessage='What variable would you like to add?')]
        [string]$Name,
        [Parameter(
            Mandatory=$True,
            ValueFromPipeline=$True,
            ValueFromPipelineByPropertyName=$True,
            HelpMessage='What value would you like to add?')]
        [string]$Val,
        
        [Parameter(
            ValueFromPipeline=$True,
            ValueFromPipelineByPropertyName=$True,
            HelpMessage='Add to the global environment?')]
        [switch]$Global
    )
    [System.Environment]::SetEnvironmentVariable($Name,$Val,"Process")
    [System.Environment]::SetEnvironmentVariable($Name,$Val,"User")
    if ($Global)
    {
        [System.Environment]::SetEnvironmentVariable($Name,$Val,"Machine")
    }
}

function Get-EnvironmentVariable {
    param(
        [Parameter(
            Mandatory=$True,
            ValueFromPipeline=$True,
            ValueFromPipelineByPropertyName=$True,
            HelpMessage='What variable would you like to add?')]
        [string]$Name,
        
        [Parameter(
            ValueFromPipeline=$True,
            ValueFromPipelineByPropertyName=$True,
            HelpMessage='Add to the global environment?')]
        [switch]$Global
    )
    $val = [System.Environment]::GetEnvironmentVariable($Name,"Process")
    if ($val -eq $null )
    {
        $val = [System.Environment]::GetEnvironmentVariable($Name,"User")
        if ($val -eq $null )
        {
            $val = [System.Environment]::GetEnvironmentVariable($Name,"Machine")
        } 
    } 
    return $val
}

function Remove-EnvironmentVariable {
    param(
        [Parameter(
            Mandatory=$True,
            ValueFromPipeline=$True,
            ValueFromPipelineByPropertyName=$True,
            HelpMessage='What variable would you like to add?')]
        [string]$Name,
        [Parameter(
            ValueFromPipeline=$True,
            ValueFromPipelineByPropertyName=$True,
            HelpMessage='Add to the global environment?')]
        [switch]$Global
    )
    [System.Environment]::SetEnvironmentVariable($Name,$null,"Process")
    [System.Environment]::SetEnvironmentVariable($Name,$null,"User")
    if ($Global)
    {
        [System.Environment]::SetEnvironmentVariable($Name,$null,"Machine")
    }
}


function Import-ProfileModules {
    $MyModuleArrayString = Get-EnvironmentVariable $profileModulesArrayString
    if ($MyModuleArrayString -ne $null)
    {
        $MyModules = $MyModuleArrayString.Split(";")
        foreach ($mod in $MyModules){
            Import-Module $mod -Force -Global
        }
    }
}

function Register-ProfileModule {
[CmdletBinding()]
param(
    [Parameter(
      Mandatory=$True,
      ValueFromPipeline=$True,
      ValueFromPipelineByPropertyName=$True,
      HelpMessage='What module would you like to add?')]
    [string]$File
)
    
    $myfile = $File.ToLower()
    if (Test-Path $myfile){
        Import-Module $myfile -Force -Global

        $MyModuleArrayString = Get-EnvironmentVariable $profileModulesArrayString
        if ($MyModuleArrayString -eq $null)
        {
            $MyModuleArrayString = $myfile
        } 
        else 
        {
            [System.Collections.ArrayList]$MyModules = $MyModuleArrayString.Split(";")
            if (-Not $MyModules.Contains("$myfile")){
                $MyModules.Add($myfile)
                $MyModuleArrayString = [System.String]::Join(";",$MyModules)
            }
        }
        
        Set-EnvironmentVariable $profileModulesArrayString $MyModuleArrayString 
    }
}

function Unregister-ProfileModule {
    [CmdletBinding()]
    param(
        [Parameter(
          Mandatory=$True,
          ValueFromPipeline=$True,
          ValueFromPipelineByPropertyName=$True,
          HelpMessage='What module would you like to remove?')]
        [string]$File
    )
    
    $myfile = $File.ToLower()
    $MyModuleArrayString = Get-EnvironmentVariable($profileModulesArrayString)
    if ($MyModuleArrayString -ne $null)
    {
        [System.Collections.ArrayList]$MyModules = $MyModuleArrayString.Split(";")
        if (-Not $MyModules.Contains("$myfile")){
            $MyModules.Remove("$myfile")
            $MyModuleArrayString = [System.String]::Join(";",$MyModules)
        }
    }
    
    if ($MyModuleArrayString -eq "")
    {
        $MyModuleArrayString = $null
    }
    Set-EnvironmentVariable $profileModulesArrayString $MyModuleArrayString 

    Get-Module | ? {$_.path.ToLower() -eq "$myfile"} | Remove-Module
}

