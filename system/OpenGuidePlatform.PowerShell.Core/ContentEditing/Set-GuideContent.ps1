function Set-GuideContent {
    <#
    .SYNOPSIS
    Apply a reviewed body correction to one existing guide document.
    .DESCRIPTION
    Requires exact discovered identifiers and the SHA-256 of the reviewed file.
    Preserves the original UTF-8 front matter bytes, including its delimiters and
    any BOM. Does not change metadata, other translations, configuration or PDFs.
    Rejects protected, missing or stale files and empty candidate bodies. Use the scaffold
    workflow for missing documents. Run the site build after applying a change;
    an updated result does not certify publication readiness or editorial quality.
    .EXAMPLE
    Set-GuideContent -WorkspaceRoot $PWD.Path -Policy $policy -GuideId my-guide -EditionId 2026 -Language en -ExpectedSha256 $document.Sha256 -CandidateBody $body -WhatIf
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string]$WorkspaceRoot,
        [Parameter(Mandatory)][Collections.IDictionary]$Policy,
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$GuideId,
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$EditionId,
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Language,
        [Parameter(Mandatory)][ValidatePattern('^[a-fA-F0-9]{64}$')][string]$ExpectedSha256,
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$CandidateBody
    )
    $selection=@(Get-GuideContent -WorkspaceRoot $WorkspaceRoot -Policy $Policy -GuideId $GuideId -EditionId $EditionId -Language $Language)
    if($selection.Count -ne 1){throw 'Select exactly one discovered guide document.'}
    $document=$selection[0]
    Assert-GuideWriteAllowed -Policy $Policy -RelativePath $document.Path
    if(-not $document.Exists){throw 'Guide document is missing. Use New-GuideTranslationScaffold for a new translation.'}
    if([string]::IsNullOrWhiteSpace($CandidateBody)){throw 'A guide correction must retain a nonempty body.'}
    $target=Resolve-GuideWorkspacePath $WorkspaceRoot $document.Path
    $original=[IO.File]::ReadAllBytes($target)
    $hash=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($original))
    if($hash -ine $ExpectedSha256){throw 'Guide file changed since review. Read the current document and review the correction again.'}
    $encoding=[Text.UTF8Encoding]::new($false,$true)
    $text=$encoding.GetString($original)
    $match=[regex]::Match($text,'\A\uFEFF?---\r?\n.*?\r?\n---(?:\r?\n|\z)',[Text.RegularExpressions.RegexOptions]::Singleline)
    if(-not $match.Success){throw 'Expected UTF-8 guide Markdown with YAML front matter.'}
    $prefix=$match.Value
    # A document whose closing delimiter ends at EOF needs a newline before its body.
    if(-not $prefix.EndsWith("`n")){throw 'The front matter closing delimiter needs a newline before editing the body.'}
    $bytes=$encoding.GetBytes($prefix+$CandidateBody)
    $digest=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes)).ToLowerInvariant()
    $status='unchanged'
    if($digest -ine $ExpectedSha256){
        $status='planned'
        if($PSCmdlet.ShouldProcess($target,'Apply reviewed guide body correction; preserve front matter')){
            $lockPath=$target+'.content-lock'
            $lock=[IO.File]::Open($lockPath,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
            $temporary=$target+'.candidate-'+[guid]::NewGuid().ToString('N')
            try{
                $stream=[IO.File]::Open($temporary,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
                try{$stream.Write($bytes,0,$bytes.Length)}finally{$stream.Dispose()}
                $checked=Resolve-GuideWorkspacePath $WorkspaceRoot $document.Path
                Assert-GuideWriteAllowed -Policy $Policy -RelativePath $document.Path
                if(-not [IO.File]::Exists($checked) -or (Get-FileHash -LiteralPath $checked -Algorithm SHA256).Hash -ine $ExpectedSha256){throw 'Guide file changed during preparation; correction not applied.'}
                [IO.File]::Replace($temporary,$checked,[System.Management.Automation.Language.NullString]::Value)
                $status='updated'
            }finally{
                try{if([IO.File]::Exists($temporary)){[IO.File]::Delete($temporary)}}finally{$lock.Dispose();[IO.File]::Delete($lockPath)}
            }
        }
    }
    [pscustomobject]@{
        Status=$status;GuideId=$GuideId;EditionId=$EditionId;Language=$Language
        Path=$document.Path;PreviousSha256=$ExpectedSha256.ToLowerInvariant();CandidateSha256=$digest
        VerificationRequired=$true
    }
}
