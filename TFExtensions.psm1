$moduleName = "TF-Extensions"


$tfsUrlString = "TFS_URL"

function Initialize-Workspace {
    [CmdletBinding()]
  param (
        [Parameter(
      Mandatory=$True,
      ValueFromPipeline=$True,
      ValueFromPipelineByPropertyName=$True,
      HelpMessage='What tfs directory would you like to add?')]
      [Alias('TFS Directory')]
    [string]$TFS_Directory,
        [Parameter(
      Mandatory=$True,
      ValueFromPipeline=$True,
      ValueFromPipelineByPropertyName=$True,
      HelpMessage='Where will it be mapped to?')]
    [string]$Local_Directory,
        [Parameter(
      Mandatory=$True,
      ValueFromPipeline=$True,
      ValueFromPipelineByPropertyName=$True,
      HelpMessage='Workspace Name')]
    [string]$Workspace_Name
    )
        $newWS = New-Workspace -tfsUrl
        tf workfold /map $TFS_Directory $Local_Directory /workspace:$newWS
        tf get $Local_Directory /remap /recursive
}
function New-Workspace{
<#

.SYNOPSIS

Creates a new empty TFS workspace.



.DESCRIPTION

tf workspace /new /noprompt does not inherently work.

The New-Workspace a combination of tf commands behind the scenes. It first looks for an empty 
workspace to use as a template. If one is not found, it will create a new permanent template workspace,
and then use that to create the desired workspace.



.PARAMETER tfsUrl 

The URL of the TFS server. If this is not supplied, it will try to use $env:TFS_URL. 



.PARAMETER newWorkspaceName

The desired name of the new workspace. If that already exists, it will append _{n} for up to 100 tries.



.EXAMPLE

New-Workspace

.EXAMPLE

New-Workspace -newWorkspaceName:MY_NEW_WORKSPACE-dev

.EXAMPLE 

New-Workspace -tfsUrl:https://tfs.mycompany.com/tfs

.EXAMPLE 

New-Workspace -tfsUrl:https://tfs.mycompany.com/tfs -newWorkspaceName:MY_NEW_WORKSPACE-dev


.NOTES


#>

    param(
        [string]$tfsUrl,
        [string]$newWorkspaceName = "$env:COMPUTERNAME"
    )

    if($tfsUrl -eq "" -or $tfsUrl -eq $null){
        $tfsUrl = Get-EnvironmentVariable $tfsUrlString
    }

    function New-WorkspaceFromTemplate {
        param(
            [string]$newName,
            [string]$templateName
        )

        tf workspace /new /noprompt /template:$templateName $newName /collection:$tfsUrl
    }

    function Get-WorkspaceNames{
        [string[]]$wsNames = @()
        $workspaces = $(tf workspaces /format:detailed /collection:$tfsUrl | ? {$_ -match "Workspace"} | ? {$_ -notmatch "No workspace"} )
        foreach ($ws in $workspaces)
        {
            $wsName = $ws.Split(":")[1].Trim()
            #Write-Host $wsName
            $wsNames += $wsName
        }
        return $wsNames
    }

    function Create-TemplateWorkspace{
        $wsNames = Get-WorkspaceNames

        if($wsNames -eq $null){
            $defaultName = $env:COMPUTERNAME + "_template"
            tf workspace /new /noprompt $defaultName  /collection:"$tfsurl"
            tf workfold /unmap $/ /workspace:$defaultName /collection:"$tfsurl"
            return $defaultName
        }

        foreach ($wsName in $wsNames){
            $workingFolders = Get-WorkingFolders $wsName
            if($workingFolders.Count -eq 1){
                $donorWorkspace = $wsName
                break
            }
        }
        if ($donorWorkspace -eq ""){
            #no singly mapped workspaces
            $donorWorkspace = $wsNames[0]
        }
        $donorMappings = Get-WorkingFolders $donorWorkspace
        foreach ($mapping in $donorMappings){
            # $/mb/util : C:\IIS\wwwroot\util
            tf workfold /unmap $mapping.Replace($mapping.Split(":")[0]+": ","").Trim() /workspace:$donorWorkspace #/collection:$tfsUrl
        }
        #donor is now a template

        #create permanent template
        $templateName = $env:COMPUTERNAME + "_template"
        if ($wsNames -match $templateName){
            $templateName = $donorWorkspace + "_template"
        } 

        New-WorkspaceFromTemplate -newName:$templateName -templateName:$donorWorkspace
        #tf workspace /new /noprompt /template:$donorWorkspace $templateName /collection:$tfsUrl

        #restore mappings
        foreach ($mapping in $donorMappings){
            # $/mb/util : C:\IIS\wwwroot\util
            #tf workfold /map serverfolder localfolder
            #[/collection:TeamProjectCollectionUrl]
            #[/workspace:workspacename]
            #[/login:username,[password]]
            $serverFolder = $mapping.Split(":")[0].Trim();
            $localFolder = $mapping.Replace($serverFolder+": ","").Trim();
            tf workfold /map $serverFolder $localFolder /collection:$tfsUrl /workspace:$donorWorkspace
        }

        return $templateName
    }

    function Get-WorkingFolders {
        param(
            [string]$workspaceName
        )
        $workspace = tf workspaces $workspaceName /format:detailed /collection:$tfsUrl
        $workingFolders = $($workspace | ? {$_ -match ".*\$"})
        return $workingFolders
    }

    function Find-TemplateWorkspace{
        $templateName = ""
        foreach ($wsName in Get-WorkspaceNames){
            $workingFolders = Get-WorkingFolders $wsName
            if($workingFolders.Count -eq 0){
                $templateName = $wsName
                break
            }
        }
        return $templateName
    }


    function Get-TemplateWorkspace {
        $templateName = Find-TemplateWorkspace 
        if ($templateName -eq ""){
            $templateName = Create-TemplateWorkspace
        }
        return $templateName
    }


    $template = Get-TemplateWorkspace

    $usedWorkspaces = Get-WorkspaceNames

    if ($usedWorkspaces -contains $newWorkspaceName)
    {
        for($i=1; $i -le 100; $i++)
        {
            if ($usedWorkspaces -notcontains $($newWorkspaceName + "_$i"))
            {
                $newWorkspaceName = $($newWorkspaceName + "_$i")
                break
            }
        }
    }
    
    Write-Host "Creating new workspace $newWorkspaceName for $tfsUrl"

    New-WorkspaceFromTemplate -newName:$newWorkspaceName -templateName:$template
   
    Write-Host "Finished"

    return $newWorkspaceName
}


