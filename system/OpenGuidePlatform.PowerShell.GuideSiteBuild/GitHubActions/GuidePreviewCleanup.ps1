# Select only an obsolete, numeric, same-repository PR preview. Never accept an
# arbitrary environment name from manual workflow input.
function Resolve-GuidePreviewCleanup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ValidatePattern('^[A-Za-z0-9_-]+/[A-Za-z0-9_.-]+$')][string]$Repository,
        [Parameter(Mandatory)][ValidatePattern('^[1-9][0-9]*$')][string]$PullRequest
    )
    if(-not $env:GH_TOKEN){throw 'Preview cleanup validation requires GH_TOKEN.'}
    $pr=Invoke-RestMethod -Uri "https://api.github.com/repos/$Repository/pulls/$PullRequest" -Headers @{
        Authorization="Bearer $env:GH_TOKEN";Accept='application/vnd.github+json'
    } -ErrorAction Stop
    if($pr.state -cne 'closed' -or [string]$pr.number -cne $PullRequest -or
        $pr.base.repo.full_name -ine $Repository -or $pr.head.repo.full_name -ine $Repository){
        throw 'Cleanup requires the exact closed same-repository pull request. No environment was removed.'
    }
    return $PullRequest
}
