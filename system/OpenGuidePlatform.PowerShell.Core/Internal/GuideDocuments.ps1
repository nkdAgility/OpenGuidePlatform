function ConvertFrom-GuideMarkdown {
    param([Parameter(Mandatory)][string]$Content)
    $match=[regex]::Match($Content,'\A\uFEFF?---\r?\n(?<yaml>.*?)\r?\n---(?:\r?\n|\z)(?<body>.*)\z',[Text.RegularExpressions.RegexOptions]::Singleline)
    if(-not $match.Success){throw 'Expected UTF-8 guide Markdown with YAML front matter.'}
    Import-Module powershell-yaml -MinimumVersion 0.4.12 -ErrorAction Stop
    $metadata=ConvertFrom-Yaml $match.Groups['yaml'].Value -ErrorAction Stop
    if($metadata -isnot [Collections.IDictionary]){throw 'Expected mapping front matter.'}
    [pscustomobject]@{Content=$Content;Metadata=$metadata;Body=$match.Groups['body'].Value}
}
function Read-GuideSnapshot {
    param([string]$WorkspaceRoot,[string]$RelativePath)
    $path=Resolve-GuideWorkspacePath $WorkspaceRoot $RelativePath
    $bytes=[IO.File]::ReadAllBytes($path)
    $document=ConvertFrom-GuideMarkdown -Content ([Text.UTF8Encoding]::new($false,$true).GetString($bytes))
    [pscustomobject]@{
        Path=$RelativePath;Content=$document.Content;Metadata=$document.Metadata;Body=$document.Body
        Sha256=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes)).ToLowerInvariant()
    }
}
function Assert-GuideDocumentOperation {
    param([Collections.IDictionary]$Policy,[string]$GuideId,[string]$EditionId,[string]$Language,
        [ValidateSet('Source','Translation')][string]$Operation,[string]$RelativePath,
        [string]$SourcePath,[string]$ExpectedSourceSha256)
    $selection=Get-GuideSelection $Policy $GuideId $EditionId
    $source="$($selection.RelativePath)/index.md"
    if($Operation -eq 'Source'){
        if($Language -cne $selection.Edition.sourceLanguage){throw 'Wrong command for a translation. Use Set-GuideTranslation with this guide, edition, language and reviewed source and target hashes.'}
        if($RelativePath -cne $source -or $SourcePath -or $ExpectedSourceSha256){throw 'Source correction must target the selected edition source only. Use Set-GuideContent with its source language.'}
    }elseif($Operation -eq 'Translation'){
        if($Language -ieq $selection.Edition.sourceLanguage){throw 'Wrong command for source content. Use Set-GuideContent with this edition source language and reviewed target hash.'}
        $translations=@($selection.Edition.translations|Where-Object language -CEQ $Language)
        if($translations.Count -ne 1){throw 'Translation is not uniquely declared for this guide and edition. Use New-GuideTranslation for a missing target, then rerun Prepare.'}
        if($RelativePath -cne "$($selection.RelativePath)/index.$Language.md" -or $SourcePath -cne $source){throw 'Translation target and source must belong to the selected guide and edition. Use Set-GuideTranslation with that exact selection.'}
        if($ExpectedSourceSha256 -notmatch '^[a-fA-F0-9]{64}$'){throw 'Set-GuideTranslation requires the reviewed source hash as well as the target hash.'}
    }else{throw 'A source or translation operation is required; use the corresponding public command.'}
}
function Write-GuideReviewedFile {
    param([string]$WorkspaceRoot,[Collections.IDictionary]$Policy,[string]$RelativePath,
        [byte[]]$CandidateBytes,[string]$ExpectedSha256,[string]$SourcePath,[string]$ExpectedSourceSha256,
        [Parameter(Mandatory)][ValidateSet('Source','Translation')][string]$Operation,
        [Parameter(Mandatory)][string]$GuideId,[Parameter(Mandatory)][string]$EditionId,[Parameter(Mandatory)][string]$Language)
    function Confirm-Inputs {
        Assert-GuideDocumentOperation -Policy $Policy -GuideId $GuideId -EditionId $EditionId -Language $Language -Operation $Operation -RelativePath $RelativePath -SourcePath $SourcePath -ExpectedSourceSha256 $ExpectedSourceSha256
        $checked=Resolve-GuideWorkspacePath $WorkspaceRoot $RelativePath
        Assert-GuideWriteAllowed -Policy $Policy -RelativePath $RelativePath
        if(-not [IO.File]::Exists($checked) -or (Get-FileHash -LiteralPath $checked -Algorithm SHA256).Hash -ine $ExpectedSha256){throw 'Guide file changed during preparation; correction not applied.'}
        if($SourcePath){
            $source=Resolve-GuideWorkspacePath $WorkspaceRoot $SourcePath
            if(-not [IO.File]::Exists($source) -or (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -ine $ExpectedSourceSha256){throw 'Translation source changed during preparation; candidate not applied.'}
        }
        $checked
    }
    $target=Confirm-Inputs
    $lockPath=$target+'.content-lock'
    $lock=[IO.File]::Open($lockPath,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
    $temporary=$target+'.candidate-'+[guid]::NewGuid().ToString('N')
    try{
        $stream=[IO.File]::Open($temporary,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
        try{$stream.Write($CandidateBytes,0,$CandidateBytes.Length)}finally{$stream.Dispose()}
        $checked=Confirm-Inputs
        [IO.File]::Replace($temporary,$checked,[System.Management.Automation.Language.NullString]::Value)
    }finally{
        try{if([IO.File]::Exists($temporary)){[IO.File]::Delete($temporary)}}finally{$lock.Dispose();[IO.File]::Delete($lockPath)}
    }
}
function Test-GuideValueEqual {
    param($Left,$Right)
    if($null -eq $Left -or $null -eq $Right){return $null -eq $Left -and $null -eq $Right}
    if($Left -is [Collections.IDictionary]){
        if($Right -isnot [Collections.IDictionary] -or $Left.Count -ne $Right.Count){return $false}
        foreach($key in $Left.Keys){if(-not $Right.Contains($key) -or -not (Test-GuideValueEqual $Left[$key] $Right[$key])){return $false}}
        return $true
    }
    if($Left -is [Collections.IList]){
        if($Right -isnot [Collections.IList] -or $Left.Count -ne $Right.Count){return $false}
        for($index=0;$index -lt $Left.Count;$index++){if(-not (Test-GuideValueEqual $Left[$index] $Right[$index])){return $false}}
        return $true
    }
    return $Left.GetType() -eq $Right.GetType() -and $Left -ceq $Right
}

