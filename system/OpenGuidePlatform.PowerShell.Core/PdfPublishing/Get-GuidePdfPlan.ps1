function Get-GuidePdfPlan {
    <#
    Plans one generated PDF. The recipe comes only from committed configuration:
    platform defaults, then <site>/pdf, <site>/pdf/<guide> and
    <site>/pdf/<guide>/<edition> (see Resolve-GuidePdfRecipe). Cover credits come
    from data/contributions and labels from the site i18n catalogues.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$WorkspaceRoot,[Parameter(Mandatory)][System.Collections.IDictionary]$Policy,[Parameter(Mandatory)][string]$GuideId,[Parameter(Mandatory)][string]$EditionId,[Parameter(Mandatory)][string]$Language,[Parameter(Mandatory)][string]$DownloadPath)
    $selection=Get-GuideSelection $Policy $GuideId $EditionId
    $translations=@($selection.Edition.translations|Where-Object { $_.language -eq $Language })
    if ($translations.Count -ne 1) { throw 'Select one declared translation.' }
    $downloads=@($translations[0].downloads|Where-Object { $_.path -ceq $DownloadPath })
    if ($downloads.Count -ne 1 -or $downloads[0].handling -ne 'generated') { throw 'Only an explicitly generated download may be generated; supplied and protected PDFs are preserved.' }
    $relative="$($selection.RelativePath)/$DownloadPath"
    Assert-GuideWriteAllowed $Policy $relative
    $output=Resolve-GuideWorkspacePath $WorkspaceRoot $relative
    if ([IO.Path]::GetExtension($output) -ne '.pdf') { throw 'PDF output must use the .pdf extension.' }
    $filename=if($Language -eq $selection.Edition.sourceLanguage){'index.md'}else{"index.$Language.md"}
    $inputPath=Resolve-GuideWorkspacePath $WorkspaceRoot "$($selection.RelativePath)/$filename"
    $document=Read-GuideDocument $inputPath
    if ([string]::IsNullOrWhiteSpace($document.Body)) { throw 'An empty translation has no PDF body to generate.' }
    $retired=@(@($script:GuidePdfFontKeys)+@('dir')|Where-Object { $document.Metadata.Contains($_) })
    if ($retired.Count) { throw "PDF settings in front matter are no longer read ($($retired -join ', ')). Move them to $($Policy.wrapper.sourcePath)/pdf/pdf.yaml or pdf.<lang>.yaml." }
    $resolvedLanguage=Get-GuideLanguage $filename $selection.Edition.sourceLanguage

    $recipe=Resolve-GuidePdfRecipe $WorkspaceRoot $Policy $selection $resolvedLanguage $DownloadPath
    $settings=$recipe.Settings
    $cover=if($settings.cover -is [Collections.IDictionary]){$settings.cover}else{@{}}
    $credits=Get-GuideCredits -WorkspaceRoot $WorkspaceRoot -Policy $Policy -GuideId $GuideId -EditionId $EditionId -Language $resolvedLanguage -ContributorRoles @($cover.contributorRoles) -TranslatorRoles @($cover.translatorRoles)
    $labels=Get-GuidePdfLabels $WorkspaceRoot $Policy $resolvedLanguage $selection.Edition.sourceLanguage
    $direction='ltr'
    if ($Policy.wrapper.Contains('languageDirections') -and $Policy.wrapper.languageDirections -is [Collections.IDictionary]) {
        foreach($key in $Policy.wrapper.languageDirections.Keys){ if($key -ieq $resolvedLanguage){ $direction=[string]$Policy.wrapper.languageDirections[$key] } }
    }

    $title=[string]$document.Metadata['title']
    $metadata=[ordered]@{title=$title;'title-meta'=$title;edition=[string]$EditionId;guide=$GuideId;lang=$resolvedLanguage}
    # Pandoc's LaTeX template loads bidi whenever dir is set, so only pass it for RTL.
    if ($direction -eq 'rtl') { $metadata.dir='rtl' }
    if ($document.Metadata['short_title']) { $metadata.short_title=[string]$document.Metadata['short_title'] }
    $date=$document.Metadata['date']
    if ($date -is [datetime]) { $metadata.date=$date.ToString('yyyy-MM-dd',[Globalization.CultureInfo]::InvariantCulture) }
    elseif ($date) { $metadata.date=([string]$date -replace 'T.*$','') }
    $metadata.authors=@($credits.Authors);$metadata.contributors=@($credits.Contributors);$metadata.translators=@($credits.Translators)
    $metadata.'author-meta'=(@($credits.Authors|ForEach-Object {$_.name}) -join ', ')
    $metadata.labels=$labels.Labels
    foreach($key in @('watermark','licence')){ if(-not [string]::IsNullOrWhiteSpace([string]$settings[$key])){ $metadata[$key]=[string]$settings[$key] } }
    if (-not [string]::IsNullOrWhiteSpace([string]$cover.tagline)) { $metadata.tagline=[string]$cover.tagline }
    $resources=@($recipe.Files|Where-Object Relative|ForEach-Object Relative)
    if ($document.Metadata['forked_from'] -match '^(?<guide>.+)/(?<edition>[^/]+)$') {
        $sourceGuide=@($Policy.guides|Where-Object { $_.id -ieq $Matches['guide'] })
        $sourceEditionId=$Matches['edition']
        if ($sourceGuide.Count -eq 1) {
            $sourceEdition=@($sourceGuide[0].editions|Where-Object { [string]$_.id -ceq $sourceEditionId })
            if ($sourceEdition.Count -eq 1) {
                $base="$($sourceGuide[0].contentRoot)/$($sourceEdition[0].path)"
                foreach($name in @("index.$resolvedLanguage.md",'index.md')){
                    $candidate=Resolve-GuideWorkspacePath $WorkspaceRoot "$base/$name"
                    if([IO.File]::Exists($candidate)){ $metadata.based_on=[string](Read-GuideDocument $candidate).Metadata['title'];$resources+="$base/$name";break }
                }
            }
        }
    }
    $leaf=($GuideId -split '/')[-1]
    foreach($logoName in @("$leaf-logo.png","$($leaf.ToLowerInvariant())-logo.png")|Select-Object -Unique){
        $logoRelative="$($selection.Guide.contentRoot)/images/$logoName"
        $logo=Resolve-GuideWorkspacePath $WorkspaceRoot $logoRelative
        if([IO.File]::Exists($logo)){ $metadata.logo=ConvertTo-GuideLatexPath $logo;$resources+=$logoRelative;break }
    }

    if ($direction -eq 'rtl') {
        foreach($key in @('title','short_title','tagline','based_on','licence','watermark')){ if($metadata.Contains($key)){ $metadata[$key]=Format-GuidePdfText $metadata[$key] $true } }
        foreach($key in @('edition','date')){ if($metadata.Contains($key)){ $metadata[$key]=Format-GuidePdfText $metadata[$key] $true -Numeric } }
        # babel's default XeTeX bidi mode loses colour changes in right-to-left text; bidi-r keeps them.
        $metadata.babeloptions=@('bidi=bidi-r','provide=*')
        foreach($key in @($metadata.labels.Keys)){ $metadata.labels[$key]=Format-GuidePdfText $metadata.labels[$key] $true }
        foreach($credit in @($metadata.authors)+@($metadata.contributors)+@($metadata.translators)){ $credit.name=Format-GuidePdfText $credit.name $true }
    }

    $arguments=@($inputPath,'--pdf-engine=xelatex','--pdf-engine-opt=-interaction=nonstopmode','--metadata',"lang=$resolvedLanguage",'--metadata','keywords=','--metadata','title=','--metadata','author=')
    if ($direction -eq 'rtl') { $arguments+=@('--metadata','dir=rtl') }
    foreach($key in @($script:GuidePdfFontKeys)+@('papersize','geometry','fontsize')){
        if(-not [string]::IsNullOrWhiteSpace([string]$settings[$key])){ $arguments+=@('-V',"$key=$($settings[$key])") }
    }
    if ($settings.toc -eq $true) { $arguments+=@('--toc',"--toc-depth=$(if($settings.tocDepth){[int]$settings.tocDepth}else{2})") } else { $arguments+=@('--metadata','toc=false') }
    $resourcePath=@([IO.Path]::GetDirectoryName($inputPath))+@($recipe.ResourcePaths)
    $arguments+=@('--resource-path',($resourcePath -join [IO.Path]::PathSeparator))
    foreach($filter in $recipe.Filters){ $arguments+=@('--lua-filter',$filter.Lua) }

    # Template parts are rendered with the metadata before the main run; filter
    # headers are raw LaTeX. Parts not listed in settings.parts are skipped.
    $parts=@(if($settings.Contains('parts')){$settings.parts}else{$script:GuidePdfParts})
    $includes=[Collections.Generic.List[object]]::new()
    $rtlSupport=Join-Path (Get-GuidePdfPlatformRoot) 'rtl.tex'
    if($direction -eq 'rtl'){ $includes.Add([pscustomobject]@{Part='rtl';Placement='header';Path=$rtlSupport;Template=$false}) }
    foreach($part in @('style','page-header','page-footer')){ if($recipe.Templates.Contains($part)){ $includes.Add([pscustomobject]@{Part=$part;Placement='header';Path=$recipe.Templates[$part];Template=$true}) } }
    foreach($filter in $recipe.Filters|Where-Object Header){ $includes.Add([pscustomobject]@{Part="filter:$($filter.Name)";Placement='header';Path=$filter.Header;Template=$false}) }
    foreach($part in $parts){
        if($part -eq 'body' -or -not $recipe.Templates.Contains($part)){continue}
        $placement=if(@($parts).IndexOf($part) -lt @($parts).IndexOf('body')){'before'}else{'after'}
        $includes.Add([pscustomobject]@{Part=$part;Placement=$placement;Path=$recipe.Templates[$part];Template=$true})
    }
    $bodyStart=Join-Path (Get-GuidePdfPlatformRoot) 'body-start.tex'
    if(@($includes|Where-Object Placement -eq 'before').Count){
        $lastBefore=[Array]::FindLastIndex($includes.ToArray(),[Predicate[object]]{param($item) $item.Placement -eq 'before'})
        $includes.Insert($lastBefore+1,[pscustomobject]@{Part='body-start';Placement='before';Path=$bodyStart;Template=$false})
    }

    $fonts=[ordered]@{}
    foreach($key in $script:GuidePdfFontKeys){ if(-not [string]::IsNullOrWhiteSpace([string]$settings[$key])){ $fonts[$key]=[string]$settings[$key] } }
    # Each required font with the settings file that chose it and, when recorded, where to get it.
    $sources=if($settings['fontSources'] -is [Collections.IDictionary]){$settings['fontSources']}else{@{}}
    $fontRequirements=@(foreach($key in $fonts.Keys){
        $source=$null; foreach($name in $sources.Keys){ if($name -ieq $fonts[$key]){ $source=[string]$sources[$name] } }
        [pscustomobject]@{Key=$key;Font=$fonts[$key];SetBy=$(if($recipe.FontOrigins.ContainsKey($key)){$recipe.FontOrigins[$key]}else{'platform/pdf.yaml'});Source=$source}
    })
    $workspaceFiles=@(@("$($selection.RelativePath)/$filename")+$resources+@($credits.Files)+@($labels.Files)|Select-Object -Unique)
    $fingerprints=@(foreach($path in $workspaceFiles){
        $full=Resolve-GuideWorkspacePath $WorkspaceRoot $path
        [pscustomobject]@{Path=$path;Sha256=(Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash.ToLowerInvariant()}
    })
    $platformFiles=@(@($recipe.Files|Where-Object Level -eq 'platform'|ForEach-Object Path)+@((Join-Path (Get-GuidePdfPlatformRoot) 'labels.yaml'),$bodyStart,$rtlSupport))
    $platformEvidence=@($platformFiles|Sort-Object -Unique|ForEach-Object { "$([IO.Path]::GetRelativePath((Get-GuidePdfPlatformRoot),$_).Replace('\','/'))=$((Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash)" }) -join "`n"
    $metadataJson=$metadata|ConvertTo-Json -Depth 20 -Compress
    [pscustomobject]@{
        WorkspaceRoot=[IO.Path]::GetFullPath($WorkspaceRoot);Guide=$GuideId;Edition=$EditionId;Language=$resolvedLanguage;Input=$inputPath;Output=$output;RelativeOutput=$relative
        Arguments=$arguments;Includes=@($includes.ToArray());Metadata=$metadata;Settings=$settings;Fonts=$fonts;FontRequirements=$fontRequirements;Recipe=@($recipe.Files|Select-Object Level,Kind,@{n='Path';e={if($_.Relative){$_.Relative}else{"platform/$([IO.Path]::GetRelativePath((Get-GuidePdfPlatformRoot),$_.Path).Replace('\','/'))"}}})
        Fingerprints=$fingerprints
        MetadataSha256=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($metadataJson))).ToLowerInvariant()
        PlatformSha256=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($platformEvidence))).ToLowerInvariant()
        ConfigurationSha256=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes(($Policy | ConvertTo-Json -Depth 40 -Compress)))).ToLowerInvariant()
    }
}
function Get-GuidePdfToolchain {
    [CmdletBinding()]
    param()
    foreach($name in @('pandoc','xelatex','fc-list')) {
        $command=Get-Command $name -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
        if($null -eq $command) { [pscustomobject]@{Tool=$name;Available=$false;Version=$null};continue }
        $version=@(& $command.Source --version 2>&1)
        [pscustomobject]@{Tool=$name;Available=($LASTEXITCODE -eq 0);ExecutableSha256=(Get-FileHash -LiteralPath $command.Source -Algorithm SHA256).Hash.ToLowerInvariant();Version=if($version.Count){[string]$version[0]}else{$null}}
    }
}
function New-GuidePdf {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory)][string]$WorkspaceRoot,[Parameter(Mandatory)][System.Collections.IDictionary]$Policy,[Parameter(Mandatory)][string]$GuideId,[Parameter(Mandatory)][string]$EditionId,[Parameter(Mandatory)][string]$Language,[Parameter(Mandatory)][string]$DownloadPath,[ValidatePattern('^[a-fA-F0-9]{64}$')][string]$ExpectedOutputSha256,[ValidatePattern('^[a-fA-F0-9]{64}$')][string]$EnvironmentSha256)
    $plan=Get-GuidePdfPlan -WorkspaceRoot $WorkspaceRoot -Policy $Policy -GuideId $GuideId -EditionId $EditionId -Language $Language -DownloadPath $DownloadPath
    $replacing=[IO.File]::Exists($plan.Output)
    if ($replacing -and -not $ExpectedOutputSha256) { throw 'PDF already exists; supply its reviewed ExpectedOutputSha256 to replace it.' }
    if ($ExpectedOutputSha256 -and (-not $replacing -or (Get-FileHash -LiteralPath $plan.Output).Hash -ne $ExpectedOutputSha256)) { throw 'PDF changed since review or is missing.' }
    $toolchain=@(Get-GuidePdfToolchain)
    if (@($toolchain | Where-Object { $_.Tool -in @('pandoc','xelatex') -and -not $_.Available }).Count) { throw 'PDF generation requires Pandoc and XeLaTeX. Other Core commands do not.' }
    if(@($plan.FontRequirements).Count){
        $missing=@(Get-GuidePdfMissingFonts $plan.FontRequirements)
        if($missing.Count){ throw (Format-GuidePdfMissingFonts $missing "$($plan.RelativeOutput)") }
    }
    if ($PSCmdlet.ShouldProcess($plan.Output,'Generate a guide PDF with explicit language metadata')) {
        [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($plan.Output))|Out-Null
        $lockPath=$plan.Output+'.pdf-lock'
        $lock=[IO.File]::Open($lockPath,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
        $tempDirectory=$plan.Output+'.staging-'+[guid]::NewGuid().ToString('N')
        $temporary=Join-Path $tempDirectory 'guide.pdf'
        try {
            [IO.Directory]::CreateDirectory($tempDirectory)|Out-Null
            Import-Module powershell-yaml -MinimumVersion 0.4.12 -ErrorAction Stop
            $metadataPath=Join-Path $tempDirectory 'metadata.yaml'
            [IO.File]::WriteAllText($metadataPath,(ConvertTo-Yaml -Data $plan.Metadata),[Text.UTF8Encoding]::new($false))
            $empty=Join-Path $tempDirectory 'empty.md'
            [IO.File]::WriteAllText($empty,'')
            $arguments=@($plan.Arguments)+@('--metadata-file',$metadataPath)
            $index=0
            foreach($include in $plan.Includes){
                $path=$include.Path
                if($include.Template){
                    # Render the part as a Pandoc template so it can use the cover metadata.
                    $path=Join-Path $tempDirectory ("{0:D2}-{1}.tex" -f $index++,($include.Part -replace '[^A-Za-z0-9-]','-'))
                    $renderExit=Invoke-GuidePandoc -Arguments @($empty,'--from','markdown','--to','latex','--template',$include.Path,'--metadata-file',$metadataPath,'-o',$path)
                    if($renderExit -ne 0){throw "Pandoc failed with exit code $renderExit while rendering the $($include.Part) template."}
                }
                $option=switch($include.Placement){'header'{'--include-in-header'}'before'{'--include-before-body'}'after'{'--include-after-body'}}
                $arguments+=@($option,$path)
            }
            $arguments+=@('-o',$temporary)
            $nativeExit=Invoke-GuidePandoc -Arguments $arguments
            if($nativeExit -ne 0){throw "Pandoc failed with exit code $nativeExit."}
            if(-not [IO.File]::Exists($temporary)){throw 'Pandoc did not create a PDF.'}
            $stream=[IO.File]::OpenRead($temporary)
            try{$magic=[byte[]]::new(5);$count=$stream.Read($magic,0,5)}finally{$stream.Dispose()}
            if($count -ne 5 -or [Text.Encoding]::ASCII.GetString($magic) -ne '%PDF-'){throw 'Generated output is not a PDF.'}
            $checked=Resolve-GuideWorkspacePath $WorkspaceRoot $plan.RelativeOutput
            Assert-GuideWriteAllowed $Policy $plan.RelativeOutput
            [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($checked))|Out-Null
            foreach ($fingerprint in $plan.Fingerprints) {
                $inputFile=Resolve-GuideWorkspacePath $WorkspaceRoot $fingerprint.Path
                if ((Get-FileHash -LiteralPath $inputFile).Hash -ne $fingerprint.Sha256) { throw 'PDF input changed during generation; output not published.' }
            }
            if ($replacing) {
                if (-not [IO.File]::Exists($checked) -or (Get-FileHash -LiteralPath $checked).Hash -ne $ExpectedOutputSha256) { throw 'PDF changed during generation; output not published.' }
                [IO.File]::Replace($temporary,$checked,[System.Management.Automation.Language.NullString]::Value)
            } else { [IO.File]::Move($temporary,$checked) }
            [pscustomobject]@{schemaVersion=1;Guide=$GuideId;Edition=$EditionId;EnvironmentSha256=$EnvironmentSha256;Status=if($replacing){'replaced'}else{'created'};Path=$plan.RelativeOutput;Language=$plan.Language;Sha256=(Get-FileHash $checked -Algorithm SHA256).Hash.ToLowerInvariant();Inputs=$plan.Fingerprints;ConfigurationSha256=$plan.ConfigurationSha256;Fonts=$plan.Fonts;Toolchain=$toolchain;VisualReviewRequired=$true;CacheKey=if($EnvironmentSha256){Get-GuidePdfCacheKey $plan $toolchain $EnvironmentSha256}else{$null}}
        } finally {
            try {
                # Delete only this operation's validated sibling staging directory.
                $stageRelative=[IO.Path]::GetRelativePath([IO.Path]::GetFullPath($WorkspaceRoot),$tempDirectory).Replace('\','/')
                $stage=Resolve-GuideWorkspacePath $WorkspaceRoot $stageRelative
                if ([IO.Directory]::Exists($stage)) { [IO.Directory]::Delete($stage,$true) }
            } finally { $lock.Dispose();[IO.File]::Delete($lockPath) }
        }
    }
}

function Get-GuideInstalledFontFamilies {
    # Font families visible to XeTeX's fontconfig. $null when fc-list is unavailable.
    $command=Get-Command fc-list -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if($null -eq $command){ return $null }
    $families=@(& $command.Source --format '%{family}\n')
    if($LASTEXITCODE -ne 0){ throw 'Font enumeration with fc-list failed.' }
    ,@($families | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ } | Sort-Object -Unique)
}

function Get-GuidePdfMissingFonts {
    param([object[]]$Requirements)
    $installed=Get-GuideInstalledFontFamilies
    if($null -eq $installed){ throw 'Checking fonts needs fc-list, which ships with the TeX distribution (MiKTeX or TeX Live). Install it and run again.' }
    @($Requirements|Where-Object { $installed -inotcontains $_.Font })
}

function Format-GuidePdfMissingFonts {
    param([object[]]$Missing,[string]$Subject)
    $lines=foreach($group in $Missing|Group-Object Font){
        $first=$group.Group[0]
        $uses=(@($group.Group|ForEach-Object Key|Select-Object -Unique) -join ', ')
        $where=if($first.Source){"Get it from $($first.Source)"}else{"No source is recorded; add it under fontSources in $($first.SetBy)"}
        "  - $($group.Name) ($uses, set in $($first.SetBy)). $where"
    }
    "Missing fonts for $($Subject):
$($lines -join "
")
Install them and run again. Fonts are never installed or substituted automatically."
}

function Test-GuidePdfFonts {
    <#
    Reports every font the site's generated PDFs need and whether it is installed,
    with the settings file that chose it and where to get it.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$WorkspaceRoot,[Parameter(Mandatory)][System.Collections.IDictionary]$Policy)
    $installed=Get-GuideInstalledFontFamilies
    foreach($guide in $Policy.guides){ foreach($edition in $guide.editions){ foreach($translation in $edition.translations){
        foreach($download in @($translation.downloads|Where-Object { $_.handling -eq 'generated' })){
            try{ $plan=Get-GuidePdfPlan -WorkspaceRoot $WorkspaceRoot -Policy $Policy -GuideId $guide.id -EditionId $edition.id -Language $translation.language -DownloadPath $download.path }
            catch{ [pscustomobject]@{Pdf="$($guide.contentRoot)/$($edition.path)/$($download.path)";Language=$translation.language;Key=$null;Font=$null;SetBy=$null;Source=$null;Installed=$null;Problem=$_.Exception.Message}; continue }
            foreach($requirement in $plan.FontRequirements){
                [pscustomobject]@{Pdf=$plan.RelativeOutput;Language=$plan.Language;Key=$requirement.Key;Font=$requirement.Font;SetBy=$requirement.SetBy;Source=$requirement.Source;Installed=$(if($null -eq $installed){$null}else{$installed -icontains $requirement.Font});Problem=$null}
            }
        }
    }}}
}

function Invoke-GuidePandoc {
    param([string[]]$Arguments)
    & pandoc @Arguments | Out-Host
    return $LASTEXITCODE
}
