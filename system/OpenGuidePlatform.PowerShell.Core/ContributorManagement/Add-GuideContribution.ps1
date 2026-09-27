function Add-GuideContribution {
    <# .SYNOPSIS
    Append one reviewed translation-team record without changing existing bytes.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string]$WorkspaceRoot,
        [Parameter(Mandatory)][Collections.IDictionary]$Policy,
        [Parameter(Mandatory)][string]$GuideId,
        [Parameter(Mandatory)][string]$Language,
        [Parameter(Mandatory)][ValidatePattern('^[a-fA-F0-9]{64}$')][string]$ExpectedSha256,
        [Parameter(Mandatory)][string]$CandidateYaml
    )
    $selection=Resolve-GuideContributionsPath $WorkspaceRoot $Policy $GuideId $Language
    Assert-GuideWriteAllowed $Policy $selection.Relative
    if(-not [IO.File]::Exists($selection.Path)){throw 'Contributor file is missing; use New-GuideContributions.'}
    $originalBytes=[IO.File]::ReadAllBytes($selection.Path)
    if([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($originalBytes)) -ine $ExpectedSha256){throw 'Contributor file changed since review; read and review it again.'}
    $encoding=[Text.UTF8Encoding]::new($false,$true)
    $original=$encoding.GetString($originalBytes)
    if(-not $CandidateYaml.StartsWith($original,[StringComparison]::Ordinal)){throw 'Append must preserve every existing byte, including comments and order.'}
    Import-Module powershell-yaml -MinimumVersion 0.4.12 -ErrorAction Stop
    $before=ConvertFrom-Yaml $original.TrimStart([char]0xFEFF)
    $after=ConvertFrom-Yaml $CandidateYaml.TrimStart([char]0xFEFF)
    if($before -isnot [Collections.IList] -or $after -isnot [Collections.IList] -or $after.Count -ne ($before.Count+1)){throw 'Append exactly one contributor to the existing collection.'}
    for($i=0;$i -lt $before.Count;$i++){
        if(($before[$i]|ConvertTo-Json -Depth 100 -Compress) -cne ($after[$i]|ConvertTo-Json -Depth 100 -Compress)){throw 'Append must preserve every existing contributor.'}
    }
    $added=$after[-1]
    if($added -isnot [Collections.IDictionary] -or [string]::IsNullOrWhiteSpace($added.name) -or [string]$added.role -cnotin $script:GuideTranslationRoles){throw 'The appended record needs a name and an allowed translation role.'}
    $editions=@($Policy.guides|Where-Object id -CEQ $GuideId|ForEach-Object {$_.editions.id})
    $contributions=@($added.contributions|Where-Object {$null -ne $_})
    if(-not $contributions.Count -or @($contributions|Where-Object {[string]$_ -cnotin $editions}).Count){throw 'The appended record must reference existing guide editions in contributions.'}
    if($null -ne $added['localizedNames'] -and $added['localizedNames'] -isnot [Collections.IDictionary]){throw 'localizedNames must map language codes to names.'}
    $identity=if($added['githubUsername']){"github:$($added['githubUsername'])".ToLowerInvariant()}else{"name:$($added['name'])".ToLowerInvariant()}
    foreach($person in $before){
        $existingIdentity=if($person['githubUsername']){"github:$($person['githubUsername'])".ToLowerInvariant()}else{"name:$($person['name'])".ToLowerInvariant()}
        if($identity -ceq $existingIdentity){throw 'The appended contributor identity already exists; update that record instead.'}
    }
    if($PSCmdlet.ShouldProcess($selection.Path,'Append reviewed translation contributor')){
        $lockPath=$selection.Path+'.update-lock'
        $lock=[IO.File]::Open($lockPath,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
        $temporary=$selection.Path+'.candidate-'+[guid]::NewGuid().ToString('N')
        try {
            [IO.File]::WriteAllBytes($temporary,$encoding.GetBytes($CandidateYaml))
            $checked=Resolve-GuideWorkspacePath $WorkspaceRoot $selection.Relative
            Assert-GuideWriteAllowed $Policy $selection.Relative
            if((Get-FileHash -LiteralPath $checked).Hash -ine $ExpectedSha256){throw 'Contributor file changed during preparation; candidate not applied.'}
            [IO.File]::Replace($temporary,$checked,[System.Management.Automation.Language.NullString]::Value)
        } finally {
            try {if([IO.File]::Exists($temporary)){[IO.File]::Delete($temporary)}}
            finally {$lock.Dispose();[IO.File]::Delete($lockPath)}
        }
        [pscustomobject]@{Status='appended';Path=$selection.Relative;ContributorName=$added.name;PreviousSha256=$ExpectedSha256.ToLowerInvariant();Sha256=(Get-FileHash -LiteralPath $selection.Path).Hash.ToLowerInvariant()}
    }
}
