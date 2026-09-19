function New-GuideTranslation {
    <#
    .SYNOPSIS
    Start a translation with the existing safe scaffold operation and a work report.
    .DESCRIPTION
    Creates an empty body only when production explicitly disables the language.
    Existing translations are preserved. Refresh Prepare after creation; the
    returned work report is not a replacement for discovered inventory.
    .EXAMPLE
    New-GuideTranslation -WorkspaceRoot $PWD.Path -Policy $policy -GuideId guide-a -EditionId 2026 -Language fr -WhatIf
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory)][string]$WorkspaceRoot,[Parameter(Mandatory)][Collections.IDictionary]$Policy,
        [Parameter(Mandatory)][string]$GuideId,[Parameter(Mandatory)][string]$EditionId,
        [Parameter(Mandatory)][string]$Language)
    $argsForWork=@{WorkspaceRoot=$WorkspaceRoot;Policy=$Policy;GuideId=$GuideId;EditionId=$EditionId;Language=$Language}
    $work=Get-GuideTranslationWork @argsForWork
    if($work.Target){return [pscustomobject]@{Status='preserved';Work=$work;RefreshDiscoveryRequired=(-not $work.TargetDeclared)}}
    if(-not $work.CanCreateScaffold){throw "Cannot create this translation. $($work.Findings.Action -join ' ')"}
    $status='planned'
    if($PSCmdlet.ShouldProcess($work.TargetPath,'Create an empty translation scaffold')){
        $created=New-GuideTranslationScaffold @argsForWork -Confirm:$false
        $status=$created.Status
        $work=Get-GuideTranslationWork @argsForWork
    }
    [pscustomobject]@{Status=$status;Work=$work;RefreshDiscoveryRequired=($status -eq 'created')}
}
function Get-GuideTranslationOutline {
    param([string]$Body)
    # Review aid for ATX headings only; this is deliberately not a Markdown parser.
    $fence=$null
    foreach($line in ($Body -split '\r?\n')){
        if($line -match '^ {0,3}(`{3,}|~{3,})'){
            $token=$Matches[1]
            if(-not $fence){$fence=$token}
            elseif($token[0] -eq $fence[0] -and $token.Length -ge $fence.Length){$fence=$null}
            continue
        }
        if(-not $fence -and $line -match '^ {0,3}(#{1,6})(?:\s+|$)(.*)$'){
            [pscustomobject]@{Level=$Matches[1].Length;Text=$Matches[2]}
        }
    }
}
function Test-GuideTranslation {
    <#
    .SYNOPSIS
    Check a complete translation candidate without writing it.
    .DESCRIPTION
    Validates YAML metadata and a nonempty body. Only title, description and summary
    metadata may differ from the selected target. ATX heading outlines are review
    aids, not a full Markdown or translation-quality check. Run the site build for
    rendering, effective wrapper/i18n and publication checks.
    .EXAMPLE
    Test-GuideTranslation -WorkspaceRoot $PWD.Path -Policy $policy -GuideId guide-a -EditionId 2026 -Language fr -CandidateContent $candidate
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$WorkspaceRoot,[Parameter(Mandatory)][Collections.IDictionary]$Policy,
        [Parameter(Mandatory)][string]$GuideId,[Parameter(Mandatory)][string]$EditionId,
        [Parameter(Mandatory)][string]$Language,[Parameter(Mandatory)][string]$CandidateContent)
    $work=Get-GuideTranslationWork -WorkspaceRoot $WorkspaceRoot -Policy $Policy -GuideId $GuideId -EditionId $EditionId -Language $Language
    $findings=[Collections.Generic.List[object]]::new()
    function Add-Finding([string]$Code,[string]$Severity,[string]$Action){$findings.Add([pscustomobject]@{Code=$Code;Severity=$Severity;Action=$Action})}
    if(-not $work.Target){Add-Finding 'TARGET_MISSING' blocker 'Create a scaffold, then rerun Prepare.'}
    if(-not $work.TargetDeclared){Add-Finding 'REFRESH_DISCOVERY' blocker 'Rerun Prepare; the target is not in this inventory.'}
    if(-not $work.WriteAllowed){Add-Finding 'PROTECTED_RESOURCE' blocker 'The supplied policy protects the selected translation.'}
    $candidate=$null
    try{$candidate=ConvertFrom-GuideMarkdown -Content $CandidateContent}catch{Add-Finding 'INVALID_GUIDE_MARKDOWN' blocker $_.Exception.Message}
    $sourceOutline=@(Get-GuideTranslationOutline $work.Source.Body);$candidateOutline=@()
    if($candidate){
        if($candidate.Metadata.Contains('lang')){Add-Finding 'FRONT_MATTER_LANG' blocker 'Remove lang from Hugo front matter; PDF language is supplied separately.'}
        if([string]::IsNullOrWhiteSpace($candidate.Body)){Add-Finding 'TRANSLATION_BODY_EMPTY' blocker 'Supply the translated body.'}
        if($work.Target){
            $before=@{};$after=@{}
            foreach($key in $work.Target.Metadata.Keys){if($key -cnotin @('title','description','summary')){$before[$key]=$work.Target.Metadata[$key]}}
            foreach($key in $candidate.Metadata.Keys){
                if($key -cin @('title','description','summary')){
                    if($candidate.Metadata[$key] -isnot [string] -or [string]::IsNullOrWhiteSpace($candidate.Metadata[$key])){Add-Finding 'INVALID_TRANSLATED_METADATA' blocker "Supply nonempty text for $key."}
                }else{$after[$key]=$candidate.Metadata[$key]}
            }
            foreach($key in @('title','description','summary')){
                if($work.Target.Metadata.Contains($key) -and -not $candidate.Metadata.Contains($key)){Add-Finding 'TRANSLATED_METADATA_REMOVED' blocker "Preserve and translate the existing $key field."}
            }
            if(-not (Test-GuideValueEqual $before $after)){Add-Finding 'STRUCTURAL_METADATA_CHANGED' blocker 'Preserve all metadata except title, description and summary, including aliases, version, layout, fonts and custom fields.'}
        }
        $candidateOutline=@(Get-GuideTranslationOutline $candidate.Body)
        if((@($sourceOutline|ForEach-Object {$_.Level}) -join ',') -cne (@($candidateOutline|ForEach-Object {$_.Level}) -join ',')){Add-Finding 'HEADING_STRUCTURE_REVIEW' review 'ATX heading levels differ from the source. Review omissions and intentional restructuring; setext headings and embedded markup are not assessed.'}
        if($candidate.Body.Trim() -ceq $work.Source.Body.Trim()){Add-Finding 'SOURCE_BODY_UNCHANGED' review 'The candidate body matches the source. Confirm this is intentional; text similarity does not establish translation quality.'}
    }
    [pscustomobject]@{
        Outcome=if(@($findings|Where-Object Severity -EQ blocker).Count){'blocked'}else{'review-required'}
        Findings=@($findings);SourceSha256=$work.Source.Sha256
        TargetSha256=if($work.Target){$work.Target.Sha256}else{$null}
        SourceOutline=$sourceOutline;CandidateOutline=$candidateOutline
        TranslationQualityAssessed=$false;BuildRequired=$true
    }
}
function Set-GuideTranslation {
    <#
    .SYNOPSIS
    Apply a reviewed translation document against exact source and target hashes.
    .DESCRIPTION
    Preserves structural metadata; only the body and title/description/summary may
    change. Both current-source and target hashes are mandatory. Optional Git
    source comparison is returned as evidence, not stored in front matter and not
    interpreted as the revision previously translated. No language is enabled,
    PDF generated, or publication approved. Rerun Prepare and both target builds.
    .EXAMPLE
    Set-GuideTranslation -WorkspaceRoot $PWD.Path -Policy $policy -GuideId guide-a -EditionId 2026 -Language fr -CandidateContent $candidate -ExpectedSourceSha256 $work.Source.Sha256 -ExpectedSha256 $work.Target.Sha256 -WhatIf
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory)][string]$WorkspaceRoot,[Parameter(Mandatory)][Collections.IDictionary]$Policy,
        [Parameter(Mandatory)][string]$GuideId,[Parameter(Mandatory)][string]$EditionId,
        [Parameter(Mandatory)][string]$Language,[Parameter(Mandatory)][string]$CandidateContent,
        [Parameter(Mandatory)][ValidatePattern('^[a-fA-F0-9]{64}$')][string]$ExpectedSha256,
        [Parameter(Mandatory)][ValidatePattern('^[a-fA-F0-9]{64}$')][string]$ExpectedSourceSha256,
        [ValidateNotNullOrEmpty()][string]$SourceRevision,[string]$SourcePathAtRevision)
    $selection=@{WorkspaceRoot=$WorkspaceRoot;Policy=$Policy;GuideId=$GuideId;EditionId=$EditionId;Language=$Language}
    $history=@{}
    if($SourceRevision){$history.SourceRevision=$SourceRevision}
    if($SourcePathAtRevision){$history.SourcePathAtRevision=$SourcePathAtRevision}
    $work=Get-GuideTranslationWork @selection @history
    if($work.Source.Sha256 -ine $ExpectedSourceSha256){throw 'Translation source changed since review. Compare the new source and revise the candidate.'}
    if(-not $work.Target -or $work.Target.Sha256 -ine $ExpectedSha256){throw 'Translation target changed since review or is missing. Reconcile the candidate with the current target.'}
    $check=Test-GuideTranslation @selection -CandidateContent $CandidateContent
    if($check.Outcome -eq 'blocked'){throw "Translation candidate blocked: $($check.Findings.Action -join ' ')"}
    if($check.SourceSha256 -ine $ExpectedSourceSha256 -or $check.TargetSha256 -ine $ExpectedSha256){throw 'Translation inputs changed during review; candidate not applied.'}
    $bytes=[Text.UTF8Encoding]::new($false,$true).GetBytes($CandidateContent)
    $digest=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes)).ToLowerInvariant()
    $status='unchanged'
    if($digest -ine $ExpectedSha256){
        $status='planned'
        if($PSCmdlet.ShouldProcess($work.TargetPath,'Apply reviewed translation body and editorial metadata')){
            Write-GuideReviewedFile -WorkspaceRoot $WorkspaceRoot -Policy $Policy -RelativePath $work.TargetPath -CandidateBytes $bytes -ExpectedSha256 $ExpectedSha256 -SourcePath $work.Source.Path -ExpectedSourceSha256 $ExpectedSourceSha256
            $status='updated'
        }
    }
    [pscustomobject]@{
        Status=$status;GuideId=$GuideId;EditionId=$EditionId;Language=$Language;Path=$work.TargetPath
        SourcePath=$work.Source.Path;SourceSha256=$ExpectedSourceSha256.ToLowerInvariant()
        PreviousSha256=$ExpectedSha256.ToLowerInvariant();CandidateSha256=$digest
        Comparison=$work.Comparison;Findings=$check.Findings
        TranslationQualityAssessed=$false;VerificationRequired=$true
    }
}
