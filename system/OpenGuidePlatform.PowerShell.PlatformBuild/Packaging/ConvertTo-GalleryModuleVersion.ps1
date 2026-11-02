function ConvertTo-GalleryModuleVersion {
    param([Parameter(Mandatory)][string]$Version)
    $parsed=$null
    if($Version -cnotmatch '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(?:-[A-Za-z0-9.-]+)?$' -or -not [System.Management.Automation.SemanticVersion]::TryParse($Version,[ref]$parsed)) { throw 'Module packaging requires a canonical OGP semantic version without build metadata.' }
    $numeric="$($parsed.Major).$($parsed.Minor).$($parsed.Patch)"
    $label=$null
    if($parsed.PreReleaseLabel){
        # Gallery supports a single SemVer 1 label. Encode SemVer 2 identifiers
        # into an alphabetic label whose lexical order preserves their order:
        # numeric < text; numeric digit length before value; text ASCII hex.
        # A zero terminator sorts before every encoded text character (2d-7a).
        # Unary numeric length supports rollover without an arbitrary limit.
        $tokens=foreach($part in $parsed.PreReleaseLabel.Split('.')){
            if($part -cmatch '^0[0-9]+$'){throw 'Numeric prerelease identifiers must not have leading zeros.'}
            if($part -cmatch '^[0-9]+$'){'1'+('1'*$part.Length)+'0'+$part+'0'}
            else{'2'+[Convert]::ToHexString([Text.Encoding]::ASCII.GetBytes($part)).ToLowerInvariant()+'0'}
        }
        $label='pre'+($tokens -join '')
    }
    [pscustomobject]@{ModuleVersion=$numeric;Prerelease=$label;GalleryVersion=$numeric+$(if($label){'-'+$label});ReleaseVersion=$Version}
}
