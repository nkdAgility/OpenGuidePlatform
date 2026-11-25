#Requires -Version 7.4
function Invoke-NativeGo {
    param([string[]]$Arguments,[string]$Stage)
    $start=[Diagnostics.ProcessStartInfo]::new()
    $start.FileName=(Get-Command go -CommandType Application -ErrorAction Stop|Select-Object -First 1).Source
    $start.WorkingDirectory=$stage;$start.UseShellExecute=$false;$start.CreateNoWindow=$true
    $start.RedirectStandardOutput=$true;$start.RedirectStandardError=$true
    $start.Environment['GOWORK']='off';$start.Environment['GOFLAGS']=''
    foreach($argument in $Arguments){$start.ArgumentList.Add($argument)}
    $process=[Diagnostics.Process]::new();$process.StartInfo=$start
    try{
        $null=$process.Start();$stdout=$process.StandardOutput.ReadToEndAsync();$stderr=$process.StandardError.ReadToEndAsync()
        if(-not $process.WaitForExit(60000)){$process.Kill($true);throw 'Native Hugo update timed out.'}
        $raw=$stdout.GetAwaiter().GetResult();$diagnostics=$stderr.GetAwaiter().GetResult()
        if($process.ExitCode -ne 0){throw "Native Hugo update failed: $diagnostics $raw"}
        return $raw
    }finally{$process.Dispose()}
}

function New-GuideNativeHugoUpdatePlan {
[CmdletBinding()]
param([Parameter(Mandatory)][string]$WorkspaceRoot,[Parameter(Mandatory)][string]$SourcePath,[Parameter(Mandatory)]$NativeModule,[string]$PreviousVersion)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
Import-Module (Join-Path $PSScriptRoot '../OpenGuidePlatform.PowerShell.Core/OpenGuidePlatform.PowerShell.Core.psd1') -Force
Import-Module powershell-yaml -MinimumVersion 0.4.12 -ErrorAction Stop
$baseModule='github.com/nkdAgility/OpenGuidePlatform/system/OpenGuidePlatform.Hugo.Guides'
$legacy='github.com/nkdAgility/HugoGuides/module'
function Get-ModulePath([string]$Version){
    if($Version -cnotmatch '^v(?<major>[0-9]+)\.[0-9]+\.[0-9]+(?:-[A-Za-z0-9.-]+)?$'){throw 'Invalid native Hugo update version.'}
    if([int]$Matches.major -ge 2){"$baseModule/v$($Matches.major)"}else{$baseModule}
}
$canonical=Get-ModulePath $NativeModule.version
if($NativeModule.path -cne $canonical -or $NativeModule.sourceCommit -cnotmatch '^[a-f0-9]{40}$'){throw 'Invalid native Hugo update identity.'}
$previousPath=if($PreviousVersion){Get-ModulePath $PreviousVersion}else{$baseModule}
$knownPaths=@($legacy,$baseModule,$previousPath,$canonical)|Select-Object -Unique
$superseded=@($knownPaths|Where-Object {$_ -cne $canonical})
$pathPattern=($knownPaths|ForEach-Object {[regex]::Escape($_)}) -join '|'
$source=Resolve-GuideWorkspacePath $WorkspaceRoot $SourcePath
$stage=Resolve-GuideWorkspacePath $WorkspaceRoot ('.processing/native-module/'+[guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($stage)|Out-Null
$files=[ordered]@{};$expected=[ordered]@{}
function Read-Existing([string]$Relative){
    $path=Resolve-GuideWorkspacePath $WorkspaceRoot $Relative
    if(-not [IO.File]::Exists($path)){$expected[$Relative]=$null;return $null}
    $bytes=[IO.File]::ReadAllBytes($path)
    $expected[$Relative]=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes)).ToLowerInvariant()
    return ,$bytes
}
$modPath="$SourcePath/go.mod";$sumPath="$SourcePath/go.sum"
$modBytes=Read-Existing $modPath
if($null -eq $modBytes){throw 'The wrapper requires an existing go.mod before platform adoption.'}
[IO.File]::WriteAllBytes("$stage/go.mod",$modBytes)
$sumBytes=Read-Existing $sumPath
if($null -ne $sumBytes){[IO.File]::WriteAllBytes("$stage/go.sum",$sumBytes)}
$before=(Invoke-NativeGo -Stage $stage -Arguments @('mod','edit','-json'))|ConvertFrom-Json
if($PreviousVersion){
    $installed=@($before.Require|Where-Object Path -CEQ $previousPath)
    if($installed.Count -ne 1 -or $installed[0].Version -cne $PreviousVersion){throw 'The consumer native pin differs from its installation record; reconcile it before updating.'}
}
$removeRequirements=@($superseded|ForEach-Object {"-droprequire=$_"})
$removeReplacements=@($knownPaths|ForEach-Object {"-dropreplace=$_"})
if($before.PSObject.Properties['Replace'] -and $before.Replace){
    $removeReplacements+=@($before.Replace|Where-Object {$_.Old.Path -cin $knownPaths -and $_.Old.PSObject.Properties['Version']}|ForEach-Object {"-dropreplace=$($_.Old.Path)@$($_.Old.Version)"})
}
$null=Invoke-NativeGo -Stage $stage -Arguments (@('mod','edit')+$removeRequirements+$removeReplacements+@("-require=$canonical@$($NativeModule.version)"))
$download=(Invoke-NativeGo -Stage $stage -Arguments @('mod','download','-json',"$canonical@$($NativeModule.version)"))|ConvertFrom-Json
if(-not $download.PSObject.Properties['Origin'] -or $download.Origin.Hash -cne $NativeModule.sourceCommit -or $download.Path -cne $canonical -or $download.Version -cne $NativeModule.version){throw 'Downloaded native module does not match the coordinated release source/version.'}
$files[$modPath]=[IO.File]::ReadAllBytes("$stage/go.mod")
if([IO.File]::Exists("$stage/go.sum")){
    $lines=@([IO.File]::ReadAllLines("$stage/go.sum")|Where-Object {($_ -split ' ',2)[0] -cnotin $superseded})
    $files[$sumPath]=[Text.Encoding]::UTF8.GetBytes(($lines -join "`n")+"`n")
}else{throw 'Native module update did not produce checksum evidence.'}
$foundImport=$false
foreach($configuration in Get-ChildItem -LiteralPath $source -File|Where-Object {$_.Name -match '^hugo(?:\.[A-Za-z0-9_-]+)?\.ya?ml$'}){
    $relative=[IO.Path]::GetRelativePath([IO.Path]::GetFullPath($WorkspaceRoot),$configuration.FullName).Replace('\','/')
    $bytes=Read-Existing $relative
    $original=[Text.Encoding]::UTF8.GetString($bytes)
    $text=$original
    $data=ConvertFrom-Yaml $text
    if(-not $data.Contains('module') -or $data.module -isnot [Collections.IDictionary]){continue}
    $module=$data.module
    if($module.Contains('imports')){
        foreach($import in $module.imports){
            if($import.path -cin $knownPaths){
                $foundImport=$true
                if($import.path -cne $canonical){
                    $pattern='(?m)(^[ \t]*-[ \t]*path:[ \t]*["'']?)'+[regex]::Escape($import.path)+'(?=["'' \t\r\n#]|$)'
                    if(-not [regex]::IsMatch($text,$pattern)){throw "Reconcile the module import format in $relative before adoption."}
                    $text=[regex]::Replace($text,$pattern,('${1}'+$canonical))
                }
            }
        }
    }
    if($module.Contains('replacements') -and $null -ne $module.replacements){
        if($configuration.Name -in @('hugo.local.yaml','hugo.local.yml')){
            # Preserve local development destinations; migrate only the module identity.
            foreach($priorPath in $superseded){$text=$text.Replace("$priorPath ->","$canonical ->")}
            $text=[regex]::Replace($text,'(?m)(^[ \t]*-[ \t]*["'']?)(?:'+$pathPattern+')(?=[ \t]*->)',('${1}'+$canonical))
            if($text -cne $original){$files[$relative]=[Text.Encoding]::UTF8.GetBytes($text)}
            continue
        }
        $removed=0
        foreach($replacement in $module.replacements){
            if($replacement -cmatch ('^\s*(?:'+$pathPattern+')\s*->')){
                $pattern='(?m)^[ \t]*-[ \t]*["'']?'+[regex]::Escape($replacement)+'["'']?[ \t]*(?:#[^\r\n]*)?(?:\r?\n|$)'
                if([regex]::Matches($text,$pattern).Count -ne 1){throw "Reconcile the module replacement format in $relative before adoption."}
                $text=[regex]::Replace($text,$pattern,'');$removed++
            }
        }
        if($removed -and $removed -eq @($module.replacements).Count){
            $pattern='(?m)^[ \t]+replacements:[ \t]*(?:#[^\r\n]*)?\r?\n'
            if([regex]::Matches($text,$pattern).Count -ne 1){throw "Reconcile the replacements key in $relative before adoption."}
            $text=[regex]::Replace($text,$pattern,'')
        }
    }
    if($text -cne $original){$files[$relative]=[Text.Encoding]::UTF8.GetBytes($text)}
}
if(-not $foundImport){throw 'No native or historical HugoGuides import found in the wrapper YAML configuration.'}
# Returned bytes are a plan. Bootstrap preflights and writes them with all other
# coordinated files; this operation never changes tracked consumer files.
[pscustomobject]@{Files=$files;ExpectedHashes=$expected;Module=$NativeModule;Sum=$download.Sum;GoModSum=$download.GoModSum}
}
Export-ModuleMember -Function New-GuideNativeHugoUpdatePlan
