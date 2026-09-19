function Invoke-GuideGitRead {
    param([string]$WorkspaceRoot,[string[]]$Arguments,[int[]]$AllowedExitCodes=@(0))
    $start=[Diagnostics.ProcessStartInfo]::new('git')
    $start.UseShellExecute=$false;$start.CreateNoWindow=$true
    $start.RedirectStandardOutput=$true;$start.RedirectStandardError=$true
    foreach($argument in @('--no-pager','-C',$WorkspaceRoot)+$Arguments){$start.ArgumentList.Add($argument)}
    $process=[Diagnostics.Process]::Start($start)
    $buffer=[IO.MemoryStream]::new()
    try{
        $errors=$process.StandardError.ReadToEndAsync()
        $process.StandardOutput.BaseStream.CopyTo($buffer)
        $process.WaitForExit()
        $detail=$errors.GetAwaiter().GetResult()
        if($process.ExitCode -notin $AllowedExitCodes){throw "Cannot read source comparison from Git. Check the revision and source path. $detail"}
        return ,$buffer.ToArray()
    }finally{$buffer.Dispose();$process.Dispose()}
}
function Get-GuideSourceComparison {
    param([string]$WorkspaceRoot,[string]$SourceRevision,[string]$SourcePathAtRevision,$CurrentSource)
    $encoding=[Text.UTF8Encoding]::new($false,$true)
    $gitRoot=$encoding.GetString((Invoke-GuideGitRead $WorkspaceRoot @('rev-parse','--show-toplevel'))).Trim()
    if([IO.Path]::GetFullPath($gitRoot).TrimEnd('/','\') -ne [IO.Path]::GetFullPath($WorkspaceRoot).TrimEnd('/','\')){throw 'Source comparison requires WorkspaceRoot to be the Git repository root.'}
    $commit=$encoding.GetString((Invoke-GuideGitRead $WorkspaceRoot @('rev-parse','--verify','--end-of-options',"$SourceRevision^{commit}"))).Trim()
    if($commit -notmatch '^[a-f0-9]{40,64}$'){throw 'Git did not resolve one source commit.'}
    $historicalPath=if($SourcePathAtRevision){$SourcePathAtRevision}else{$CurrentSource.Path}
    $null=Resolve-GuideWorkspacePath $WorkspaceRoot $historicalPath
    $bytes=Invoke-GuideGitRead $WorkspaceRoot @('cat-file','blob',"${commit}:$historicalPath")
    $baseline=ConvertFrom-GuideMarkdown -Content $encoding.GetString($bytes)
    $baselineHash=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes)).ToLowerInvariant()
    $temporary=Join-Path ([IO.Path]::GetTempPath()) ('ogp-comparison-'+[guid]::NewGuid().ToString('N'))
    [IO.Directory]::CreateDirectory($temporary)|Out-Null
    $before=Join-Path $temporary 'source-before.md';$after=Join-Path $temporary 'source-current.md'
    try{
        [IO.File]::WriteAllBytes($before,$bytes)
        [IO.File]::WriteAllText($after,$CurrentSource.Content,$encoding)
        $diff=$encoding.GetString((Invoke-GuideGitRead $WorkspaceRoot @('diff','--no-index','--no-ext-diff','--no-textconv','--no-color','--',$before,$after) @(0,1)))
    }finally{
        foreach($file in @($before,$after)){if([IO.File]::Exists($file)){[IO.File]::Delete($file)}}
        [IO.Directory]::Delete($temporary)
    }
    [pscustomobject]@{
        Commit=$commit;Path=$historicalPath;Sha256=$baselineHash;Content=$baseline.Content;Body=$baseline.Body
        CurrentSha256=$CurrentSource.Sha256;Changed=($baselineHash -cne $CurrentSource.Sha256);Diff=$diff
        Meaning='User-selected source comparison; not evidence of the revision previously translated.'
    }
}
function Get-GuideTranslationWork {
    <#
    .SYNOPSIS
    Inspect source, translation, optional Git comparison, and remaining publishing work.
    .DESCRIPTION
    Selects an actual guide and edition from Prepare's discovered inventory. An
    absent target is a proposed scaffold path, not a new inventory declaration.
    SourceRevision is an explicit Git comparison baseline, never inferred from
    the translation. Current source and target hashes include uncommitted edits.
    Wrapper observations are local diagnostics; Prepare and builds supply effective
    readiness. No translation-quality or publication approval is inferred.
    .EXAMPLE
    Get-GuideTranslationWork -WorkspaceRoot $PWD.Path -Policy $policy -GuideId guide-a -EditionId 2026 -Language fr
    .EXAMPLE
    Get-GuideTranslationWork -WorkspaceRoot $PWD.Path -Policy $policy -GuideId guide-a -EditionId 2026 -Language fr -SourceRevision HEAD~1
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$WorkspaceRoot,
        [Parameter(Mandatory)][Collections.IDictionary]$Policy,
        [Parameter(Mandatory)][string]$GuideId,[Parameter(Mandatory)][string]$EditionId,
        [Parameter(Mandatory)][ValidatePattern('^[A-Za-z]{2,8}(?:-[A-Za-z0-9]{1,8})*$')][string]$Language,
        [ValidateNotNullOrEmpty()][string]$SourceRevision,[string]$SourcePathAtRevision
    )
    if($SourcePathAtRevision -and -not $SourceRevision){throw 'SourcePathAtRevision requires an explicit SourceRevision.'}
    $selection=Get-GuideSelection $Policy $GuideId $EditionId
    if($Language -ieq $selection.Edition.sourceLanguage){throw 'Select a target language different from the source language. Use Set-GuideContent for source corrections in this edition.'}
    $source=Read-GuideSnapshot $WorkspaceRoot "$($selection.RelativePath)/index.md"
    if([string]::IsNullOrWhiteSpace($source.Body)){throw 'The selected source guide has no body to translate.'}
    $targetPath="$($selection.RelativePath)/index.$Language.md"
    $targetFile=Resolve-GuideWorkspacePath $WorkspaceRoot $targetPath
    $target=if([IO.File]::Exists($targetFile)){Read-GuideSnapshot $WorkspaceRoot $targetPath}else{$null}
    $declared=@($selection.Edition.translations|Where-Object language -CEQ $Language)
    if($declared.Count -gt 1){throw 'Target language is ambiguous in the supplied inventory.'}
    $write=Test-GuideWritePolicy -Policy $Policy -RelativePath $targetPath
    $productionPath=Resolve-GuideWorkspacePath $WorkspaceRoot "$($Policy.wrapper.sourcePath)/hugo.production.yaml"
    $disabled=$false
    if([IO.File]::Exists($productionPath)){
        $production=ConvertFrom-Yaml ([IO.File]::ReadAllText($productionPath))
        $disabled=$production -is [Collections.IDictionary] -and $production.Contains('languages') -and
            $production.languages -is [Collections.IDictionary] -and $production.languages.Contains($Language) -and
            $production.languages[$Language] -is [Collections.IDictionary] -and $production.languages[$Language]['disabled'] -eq $true
    }
    $comparison=if($SourceRevision){Get-GuideSourceComparison $WorkspaceRoot $SourceRevision $SourcePathAtRevision $source}else{$null}
    $findings=@(
        if(-not $write.Allowed){[pscustomobject]@{Code='PROTECTED_RESOURCE';Action=$write.Reason}}
        if(-not $target -and -not $disabled){[pscustomobject]@{Code='SCAFFOLD_CONFIGURATION_REQUIRED';Action="Declare $Language disabled in hugo.production.yaml before scaffolding. Review main/preview language configuration separately."}}
        if($target -and -not $declared.Count){[pscustomobject]@{Code='REFRESH_DISCOVERY';Action='Rerun Prepare to discover the existing target before applying content.'}}
        [pscustomobject]@{Code='EDITORIAL_REVIEW_REQUIRED';Action='Review translated body, title, description and summary against the source, including terminology, links, shortcodes and code examples.'}
        [pscustomobject]@{Code='EFFECTIVE_READINESS_REQUIRED';Action='Rerun Prepare and full preview/production builds after the complete change; review wrapper, routes, i18n and download findings.'}
        if($declared.Count -and @($declared[0].downloads).Count){[pscustomobject]@{Code='DOWNLOAD_REVIEW_REQUIRED';Action='Review declared downloads. Generate only permitted generated PDFs and retain their receipts; preserve supplied/protected PDFs.'}}
    )
    [pscustomobject]@{
        GuideId=$GuideId;EditionId=$EditionId;Language=$Language;SourceLanguage=$selection.Edition.sourceLanguage
        Source=$source;Target=$target;TargetPath=$targetPath;TargetDeclared=($declared.Count -eq 1)
        TargetIntent=if($declared.Count){$declared[0].intent}else{$null}
        Downloads=if($declared.Count){@($declared[0].downloads)}else{@()}
        CanCreateScaffold=(-not $target -and $disabled -and $write.Allowed)
        WriteAllowed=$write.Allowed;ProductionExplicitlyDisabled=$disabled
        Comparison=$comparison;Wrapper=(Get-GuideWrapperStatus -WorkspaceRoot $WorkspaceRoot -Policy $Policy -Languages @($Language))
        Findings=$findings;TranslationQualityAssessed=$false;PublicationVerified=$false
    }
}
