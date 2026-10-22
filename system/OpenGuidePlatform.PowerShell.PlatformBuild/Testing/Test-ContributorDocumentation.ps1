#Requires -Version 7.4
[CmdletBinding()]
param([Parameter(Mandatory)][string]$PackageRoot)
$ErrorActionPreference = 'Stop'
$packagePath = [IO.Path]::GetFullPath($PackageRoot)
$guide = Join-Path $PackageRoot 'system/OpenGuidePlatform.Agents.Integration/contributor-guide'
$pages = @('README','system','setup','files','translation','first-translation','review-wording','status','add-language','translate-guide','update-translation','content','credits-pdfs','validation','troubleshooting')
foreach ($page in $pages) {
    $path = Join-Path $guide "$page.md"
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Contributor documentation missing: $page.md" }
    $text = [IO.File]::ReadAllText($path)
    # Code examples describe syntax, not navigation links.
    $prose = [regex]::Replace($text, '(?ms)^```.*?^```\r?$', '')
    $prose = [regex]::Replace($prose, '`[^`\r\n]+`', '')
    foreach ($match in [regex]::Matches($prose, '\[[^\]]*\]\(([^)]+)\)')) {
        $link = $match.Groups[1].Value
        if ($link -match '^[a-z]+:') { continue }
        $parts = $link.Split('#', 2)
        $target = if ($parts[0]) { [IO.Path]::GetFullPath((Join-Path $guide $parts[0])) } else { $path }
        $relativeTarget = [IO.Path]::GetRelativePath($packagePath, $target).Replace('\', '/')
        if ([IO.Path]::IsPathRooted($relativeTarget) -or $relativeTarget -match '^\.\.(?:/|$)') {
            throw "Contributor link escapes package in ${page}: $link"
        }
        if (-not (Test-Path -LiteralPath $target -PathType Leaf)) { throw "Broken contributor link in ${page}: $link" }
        if ($parts.Count -eq 2 -and $parts[1]) {
            $headings = [regex]::Matches([IO.File]::ReadAllText($target), '(?m)^#{1,6} (.+)\r?$')
            $anchors = @($headings | ForEach-Object { ($_.Groups[1].Value.Trim().ToLowerInvariant() -replace '[^\p{L}\p{N}_ -]', '') -replace ' ', '-' })
            if ($parts[1] -cnotin $anchors) { throw "Broken contributor anchor in ${page}: $link" }
        }
    }
}
foreach ($name in @('ownership','candidate','translation','publication')) {
    $path = Join-Path $guide "diagrams/$name.svg"
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Contributor diagram missing: $name" }
    [xml]$svg = [IO.File]::ReadAllText($path)
    if ($svg.DocumentElement.LocalName -ne 'svg' -or -not $svg.svg.viewBox -or -not $svg.svg.title.InnerText -or -not $svg.svg.desc.InnerText -or $svg.svg.role -ne 'img' -or $svg.svg.'aria-labelledby' -ne 'title description') {
        throw "Contributor diagram lacks accessible structure: $name"
    }
    if ($svg.SelectNodes('//*[local-name()="script" or local-name()="foreignObject"]').Count -gt 0) { throw "Contributor diagram contains active content: $name" }
}
"Validated contributor pages, local links, heading anchors and SVG structure in $PackageRoot"
