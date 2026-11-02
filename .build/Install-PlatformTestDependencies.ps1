#Requires -Version 7.4
[CmdletBinding()]
param([string]$WorkspaceRoot=(Split-Path $PSScriptRoot -Parent),[ValidateSet('AllUsers','CurrentUser')][string]$DependencyScope='AllUsers')
Import-Module "$PSScriptRoot/../system/OpenGuidePlatform.PowerShell.PlatformBuild/OpenGuidePlatform.PowerShell.PlatformBuild.psm1"
Invoke-PlatformBuildOperation -DependencyScope $DependencyScope -Operation Install-PlatformTestDependencies -WorkspaceRoot $WorkspaceRoot
