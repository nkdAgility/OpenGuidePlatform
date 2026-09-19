function Get-GuideContent {
    <#
    .SYNOPSIS
    List discovered guide documents or inspect an exact selection.
    .DESCRIPTION
    Uses the same policy-shaped inventory as other Core commands. Load Prepare's
    discovered-site.json with Import-GuidePolicy. Filters are exact, case-sensitive
    identifiers, not wildcard patterns. Missing documents remain visible.
    Returned hashes identify current file bytes, not publication readiness.
    .EXAMPLE
    Get-GuideContent -WorkspaceRoot $PWD.Path -Policy $policy |
        Format-Table GuideId, EditionId, Language, State, WriteAllowed, Path
    .EXAMPLE
    Get-GuideContent -WorkspaceRoot $PWD.Path -Policy $policy -GuideId my-guide -EditionId 2026 -Language en
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$WorkspaceRoot,
        [Parameter(Mandatory)][Collections.IDictionary]$Policy,
        [ValidateNotNullOrEmpty()][string]$GuideId,
        [ValidateNotNullOrEmpty()][string]$EditionId,
        [ValidateNotNullOrEmpty()][string]$Language
    )
    $inventory=Get-GuideInventory -WorkspaceRoot $WorkspaceRoot -Policy $Policy
    $results=@(foreach($guide in $inventory.Guides){
        if($GuideId -and $guide.Id -cne $GuideId){continue}
        foreach($edition in $guide.Editions){
            if($EditionId -and $edition.Id -cne $EditionId){continue}
            foreach($translation in $edition.Translations){
                if($Language -and $translation.Language -cne $Language){continue}
                $path=Resolve-GuideWorkspacePath $WorkspaceRoot $translation.Source
                $exists=[IO.File]::Exists($path)
                $decision=Test-GuideWritePolicy -Policy $Policy -RelativePath $translation.Source
                $digest=$null;$body=$null
                if($exists){
                    # The body and review hash must describe the same byte snapshot.
                    $bytes=[IO.File]::ReadAllBytes($path)
                    $text=[Text.UTF8Encoding]::new($false,$true).GetString($bytes)
                    $match=[regex]::Match($text,'\A\uFEFF?---\r?\n.*?\r?\n---(?:\r?\n|\z)(?<body>.*)\z',[Text.RegularExpressions.RegexOptions]::Singleline)
                    if(-not $match.Success){throw "Expected UTF-8 guide Markdown with YAML front matter: $($translation.Source)"}
                    $digest=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes)).ToLowerInvariant()
                    $body=$match.Groups['body'].Value
                }
                [pscustomobject]@{
                    GuideId=$guide.Id;EditionId=$edition.Id;Language=$translation.Language
                    SourceLanguage=$edition.SourceLanguage;Path=$translation.Source
                    Exists=$exists;State=$translation.State;Intent=$translation.Intent
                    WriteAllowed=$decision.Allowed;WriteReason=$decision.Reason
                    Sha256=$digest;Body=$body
                    Downloads=$translation.Downloads
                }
            }
        }
    })
    if(-not $results.Count -and ($GuideId -or $EditionId -or $Language)){
        throw 'No discovered guide content matches those exact identifiers. Run Get-GuideContent without filters to list available selections.'
    }
    $results
}
