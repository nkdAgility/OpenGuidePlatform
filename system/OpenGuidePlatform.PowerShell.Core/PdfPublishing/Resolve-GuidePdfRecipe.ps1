$script:GuidePdfFontKeys=@('mainfont','sansfont','monofont','CJKmainfont','CJKsansfont','CJKmonofont')
$script:GuidePdfSettingKeys=@('mainfont','sansfont','monofont','CJKmainfont','CJKsansfont','CJKmonofont','papersize','geometry','fontsize','toc','tocDepth','watermark','licence','parts','cover','fontSources','downloads')
$script:GuidePdfCoverKeys=@('tagline','contributorRoles','translatorRoles')
$script:GuidePdfParts=@('cover','licence','body','back')
$script:GuidePdfTemplates=[ordered]@{style='header';'page-header'='header';'page-footer'='header';cover='before';licence='before';back='after'}
$script:GuidePdfHandling=@('supplied','protected','generated')

function Get-GuidePdfPlatformRoot { Join-Path $script:CoreRoot 'PdfPublishing/templates' }

function Get-GuidePdfLevels {
    # Least to most specific. The platform level lives in the module, the others in <site>/pdf.
    param([string]$WorkspaceRoot,[Collections.IDictionary]$Policy,$Selection)
    $site="$($Policy.wrapper.sourcePath)/pdf"
    @(
        [pscustomobject]@{Name='platform';Relative=$null;Path=(Get-GuidePdfPlatformRoot)}
        [pscustomobject]@{Name='site';Relative=$site;Path=(Resolve-GuideWorkspacePath $WorkspaceRoot $site)}
        [pscustomobject]@{Name='guide';Relative="$site/$($Selection.Guide.id)";Path=(Resolve-GuideWorkspacePath $WorkspaceRoot "$site/$($Selection.Guide.id)")}
        [pscustomobject]@{Name='edition';Relative="$site/$($Selection.Guide.id)/$($Selection.Edition.path)";Path=(Resolve-GuideWorkspacePath $WorkspaceRoot "$site/$($Selection.Guide.id)/$($Selection.Edition.path)")}
    )
}

function Read-GuidePdfSettingsFile {
    param([string]$Path,[string]$Level,[string]$Display)
    Import-Module powershell-yaml -MinimumVersion 0.4.12 -ErrorAction Stop
    $settings=ConvertFrom-Yaml ([IO.File]::ReadAllText($Path).TrimStart([char]0xFEFF)) -ErrorAction Stop
    if($null -eq $settings){return @{}}
    if($settings -isnot [Collections.IDictionary]){throw "PDF settings must be a mapping: $Display"}
    foreach($problem in @(Test-GuidePdfSettings $settings $Level)){throw "${Display}: $problem"}
    $settings
}

function Test-GuidePdfSettings {
    # Returns problems as strings; an empty result means the settings are valid for that level.
    param([Collections.IDictionary]$Settings,[string]$Level)
    foreach($key in $Settings.Keys){
        if($key -cnotin $script:GuidePdfSettingKeys){"Unknown PDF setting '$key'."}
    }
    if($Settings.Contains('cover')){
        if($Settings.cover -isnot [Collections.IDictionary]){'cover must be a mapping.'}
        else{foreach($key in $Settings.cover.Keys){if($key -cnotin $script:GuidePdfCoverKeys){"Unknown cover setting '$key'."}}}
    }
    if($Settings.Contains('fontSources')){
        if($Settings.fontSources -isnot [Collections.IDictionary]){'fontSources must map font names to where to get them.'}
        else{foreach($font in $Settings.fontSources.Keys){if([string]::IsNullOrWhiteSpace([string]$Settings.fontSources[$font])){"fontSources for '$font' is empty."}}}
    }
    if($Settings.Contains('parts')){
        $parts=@($Settings.parts)
        foreach($part in $parts){if($part -cnotin $script:GuidePdfParts){"Unknown part '$part'. Use: $($script:GuidePdfParts -join ', ')."}}
        if($parts -cnotcontains 'body'){'parts must include body.'}
    }
    if($Settings.Contains('downloads')){
        if($Level -ne 'edition'){'downloads may only be declared in an edition folder.'}
        foreach($download in @($Settings.downloads)){
            if($download -isnot [Collections.IDictionary]){'Each download must be a mapping with a path.';continue}
            $path=[string]$download.path
            if($path -notmatch '^(?!/)(?!.*(?:^|/)\.\.(?:/|$))[^\\:]+\.pdf$'){"Download path '$path' must be a .pdf path inside the edition."}
            if($download.Contains('handling') -and [string]$download.handling -cnotin $script:GuidePdfHandling){"Download handling '$($download.handling)' must be one of: $($script:GuidePdfHandling -join ', ')."}
            foreach($key in $download.Keys){if($key -cnotin @('path','handling','papersize','geometry','fontsize','watermark')){"Unknown download setting '$key'."}}
        }
    }
}

function Get-GuidePdfDeclaredDownloads {
    <#
    Reads the downloads declared in <site>/pdf/<guide>/<edition>/pdf[.<lang>].yaml.
    Discovery uses these to mark PDFs generated or protected; everything else is supplied.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$SourceDirectory,[Parameter(Mandatory)][string]$GuideId,[Parameter(Mandatory)][string]$EditionPath)
    $directory=Join-Path (Join-Path (Join-Path $SourceDirectory 'pdf') $GuideId) $EditionPath
    if(-not [IO.Directory]::Exists($directory)){return}
    foreach($file in [IO.Directory]::GetFiles($directory,'pdf*.yaml')|Sort-Object){
        if([IO.Path]::GetFileName($file) -notmatch '^pdf(?:\.[A-Za-z]{2,8}(?:-[A-Za-z0-9]{1,8})*)?\.yaml$'){continue}
        $settings=Read-GuidePdfSettingsFile $file 'edition' "pdf/$GuideId/$EditionPath/$([IO.Path]::GetFileName($file))"
        foreach($download in @($settings.downloads|Where-Object {$_})){
            [pscustomobject]@{Path=[string]$download.path;Handling=$(if($download.Contains('handling')){[string]$download.handling}else{'supplied'})}
        }
    }
}

function Merge-GuidePdfSettings {
    param([Collections.IDictionary]$Target,[Collections.IDictionary]$Source)
    foreach($key in $Source.Keys){
        if($key -ceq 'downloads'){continue}
        if($key -cin @('cover','fontSources') -and $Target[$key] -is [Collections.IDictionary] -and $Source[$key] -is [Collections.IDictionary]){
            foreach($inner in $Source[$key].Keys){$Target[$key][$inner]=$Source[$key][$inner]}
        }elseif($Source[$key] -is [Collections.IDictionary]){
            $copy=[ordered]@{};foreach($inner in $Source[$key].Keys){$copy[$inner]=$Source[$key][$inner]};$Target[$key]=$copy
        }else{$Target[$key]=$Source[$key]}
    }
}

function Resolve-GuidePdfRecipe {
    <#
    Resolves settings, template parts, filters and resource folders for one PDF.
    Settings merge key by key (least to most specific, language file after the
    plain file at each level). Template parts and same-named filters are replaced
    by the most specific file.
    #>
    param([string]$WorkspaceRoot,[Collections.IDictionary]$Policy,$Selection,[string]$Language,[string]$DownloadPath)
    $levels=@(Get-GuidePdfLevels $WorkspaceRoot $Policy $Selection)
    $settings=[ordered]@{}
    $files=[Collections.Generic.List[object]]::new()
    function Use($level,$path,$kind){$files.Add([pscustomobject]@{Level=$level.Name;Kind=$kind;Path=$path;Relative=$(if($level.Relative){"$($level.Relative)/$([IO.Path]::GetRelativePath($level.Path,$path).Replace('\','/'))"}else{$null})})}
    $download=$null
    $origins=@{}
    foreach($level in $levels){
        foreach($name in @('pdf.yaml',"pdf.$Language.yaml")){
            $path=Join-Path $level.Path $name
            if(-not [IO.File]::Exists($path)){continue}
            $display=if($level.Relative){"$($level.Relative)/$name"}else{"platform/$name"}
            $values=Read-GuidePdfSettingsFile $path $level.Name $display
            Merge-GuidePdfSettings $settings $values
            foreach($key in $script:GuidePdfFontKeys){ if($values.Contains($key)){ $origins[$key]=$display } }
            if($level.Name -eq 'edition' -and $values.Contains('downloads')){
                $declared=@($values.downloads|Where-Object {[string]$_.path -ceq $DownloadPath})
                if($declared.Count){$download=$declared[-1]}
            }
            Use $level $path settings
        }
    }
    if($download){foreach($key in $download.Keys){if($key -cnotin @('path','handling')){$settings[$key]=$download[$key]}}}
    $templates=[ordered]@{}
    foreach($part in $script:GuidePdfTemplates.Keys){
        foreach($level in $levels[($levels.Count-1)..0]){
            $found=@("$part.$Language.tex","$part.tex"|ForEach-Object {Join-Path $level.Path $_}|Where-Object {[IO.File]::Exists($_)})
            if($found.Count){$templates[$part]=$found[0];Use $level $found[0] template;break}
        }
    }
    $filters=[ordered]@{}
    foreach($level in $levels){
        $directory=Join-Path $level.Path 'filters'
        if(-not [IO.Directory]::Exists($directory)){continue}
        foreach($lua in [IO.Directory]::GetFiles($directory,'*.lua')|Sort-Object){
            $name=[IO.Path]::GetFileNameWithoutExtension($lua)
            $header=[IO.Path]::ChangeExtension($lua,'.tex')
            $filters[$name]=[pscustomobject]@{Name=$name;Level=$level;Lua=$lua;Header=$(if([IO.File]::Exists($header)){$header}else{$null})}
        }
    }
    foreach($filter in $filters.Values){Use $filter.Level $filter.Lua filter;if($filter.Header){Use $filter.Level $filter.Header filter-header}}
    $resources=@($levels[($levels.Count-1)..0]|ForEach-Object {Join-Path $_.Path 'images'}|Where-Object {[IO.Directory]::Exists($_)})
    [pscustomobject]@{Settings=$settings;FontOrigins=$origins;Templates=$templates;Filters=@($filters.Values|Sort-Object Name);ResourcePaths=$resources;Files=@($files.ToArray());Download=$download}
}

function Get-GuidePdfLabels {
    # Platform English labels, then the site default language, then the PDF language.
    param([string]$WorkspaceRoot,[Collections.IDictionary]$Policy,[string]$Language,[string]$DefaultLanguage)
    Import-Module powershell-yaml -MinimumVersion 0.4.12 -ErrorAction Stop
    $values=[ordered]@{}
    $defaults=ConvertFrom-Yaml ([IO.File]::ReadAllText((Join-Path (Get-GuidePdfPlatformRoot) 'labels.yaml')))
    foreach($key in $defaults.Keys){$values[$key]=[string]$defaults[$key]}
    $used=@()
    foreach($catalogueLanguage in @($DefaultLanguage,$Language|Select-Object -Unique)){
        foreach($extension in @('yaml','yml')){
            $relative="$($Policy.wrapper.sourcePath)/i18n/$catalogueLanguage.$extension"
            $path=Resolve-GuideWorkspacePath $WorkspaceRoot $relative
            if(-not [IO.File]::Exists($path)){continue}
            $catalogue=ConvertFrom-Yaml ([IO.File]::ReadAllText($path).TrimStart([char]0xFEFF))
            $entries=@{}
            if($catalogue -is [Collections.IDictionary]){foreach($key in $catalogue.Keys){$entries[$key]=$catalogue[$key]}}
            elseif($catalogue -is [Collections.IList]){foreach($entry in $catalogue){if($entry -is [Collections.IDictionary] -and $entry.Contains('id')){$entries[[string]$entry.id]=$entry.translation}}}
            $applied=$false
            foreach($key in @($values.Keys)){
                if(-not $entries.ContainsKey($key)){continue}
                $value=$entries[$key]
                if($value -is [Collections.IDictionary]){$value=if($value.Contains('other')){$value.other}elseif($value.Contains('translation')){$value.translation}else{$null}}
                if(-not [string]::IsNullOrWhiteSpace([string]$value)){$values[$key]=[string]$value;$applied=$true}
            }
            if($applied){$used+=$relative}
            break
        }
    }
    $labels=[ordered]@{}
    foreach($key in $values.Keys){$labels[($key -replace '^pdf_','' -replace '_label$','')]=$values[$key]}
    [pscustomobject]@{Labels=$labels;Files=$used}
}

function Get-GuidePdfSettingFindings {
    # Source-convention checks for <site>/pdf settings and PDF labels; returns finding records for Prepare.
    param([string]$WorkspaceRoot,[Collections.IDictionary]$Policy)
    $relativeRoot="$($Policy.wrapper.sourcePath)/pdf"
    $root=Resolve-GuideWorkspacePath $WorkspaceRoot $relativeRoot
    if([IO.Directory]::Exists($root)){
        foreach($file in [IO.Directory]::GetFiles($root,'pdf*.y*ml',[IO.SearchOption]::AllDirectories)|Sort-Object){
            $inside=[IO.Path]::GetRelativePath($root,$file).Replace('\','/')
            $display="$relativeRoot/$inside"
            $name=[IO.Path]::GetFileName($file)
            if($name -notmatch '^pdf(?:\.[A-Za-z]{2,8}(?:-[A-Za-z0-9]{1,8})*)?\.yaml$'){
                [pscustomobject]@{Code='PDF_SETTINGS_INVALID';Severity='blocker';Subject=$display;Message='PDF settings files are named pdf.yaml or pdf.<lang>.yaml.';Remediation='Rename the file.'};continue
            }
            $folder=[IO.Path]::GetDirectoryName($inside).Replace('\','/')
            $level=if(-not $folder){'site'}
                elseif(@($Policy.guides|Where-Object {$_.id -ieq $folder}).Count){'guide'}
                elseif(@($Policy.guides|ForEach-Object {$guide=$_;$_.editions|Where-Object {"$($guide.id)/$($_.path)" -ieq $folder}}).Count){'edition'}
                else{$null}
            if(-not $level){[pscustomobject]@{Code='PDF_SETTINGS_INVALID';Severity='blocker';Subject=$display;Message="Folder '$folder' is not a guide or edition.";Remediation='Place settings in pdf/, pdf/<guide>/ or pdf/<guide>/<edition>/.'};continue}
            try{$null=Read-GuidePdfSettingsFile $file $level $display}
            catch{[pscustomobject]@{Code='PDF_SETTINGS_INVALID';Severity='blocker';Subject=$display;Message=$_.Exception.Message;Remediation='Correct the PDF settings; see the platform pdf.yaml for the supported keys.'}}
        }
    }
    # Labels: warn when a generated PDF's language has no translation for a PDF label.
    Import-Module powershell-yaml -MinimumVersion 0.4.12 -ErrorAction Stop
    $keys=@((ConvertFrom-Yaml ([IO.File]::ReadAllText((Join-Path (Get-GuidePdfPlatformRoot) 'labels.yaml')))).Keys)
    $languages=@($Policy.guides|ForEach-Object {$_.editions}|ForEach-Object {$edition=$_;$_.translations|Where-Object {$_.language -ine $edition.sourceLanguage -and @($_.downloads|Where-Object {$_.handling -eq 'generated'}).Count}|ForEach-Object {$_.language}}|Sort-Object -Unique)
    foreach($language in $languages){
        $present=@()
        foreach($extension in @('yaml','yml')){
            $path=Resolve-GuideWorkspacePath $WorkspaceRoot "$($Policy.wrapper.sourcePath)/i18n/$language.$extension"
            if(-not [IO.File]::Exists($path)){continue}
            try{$catalogue=ConvertFrom-Yaml ([IO.File]::ReadAllText($path).TrimStart([char]0xFEFF))}catch{break}
            $present=if($catalogue -is [Collections.IDictionary]){@($catalogue.Keys)}else{@($catalogue|Where-Object {$_ -is [Collections.IDictionary]}|ForEach-Object {$_['id']})}
            break
        }
        $missing=@($keys|Where-Object {$_ -notin $present}|Sort-Object)
        if($missing.Count){[pscustomobject]@{Code='PDF_LABEL_MISSING';Severity='warning';Subject="$($Policy.wrapper.sourcePath)/i18n/$language";Message="Generated PDFs in $language will use English for: $($missing -join ', ').";Remediation="Add translations for these ids to i18n/$language.yaml."}}
    }
}

function Format-GuidePdfText {
    # Metadata strings are read as Markdown. In a right-to-left document, text
    # without any RTL characters is wrapped in an LTR span so bidi keeps Latin
    # word order (Pandoc writes \LR{...}).
    param([string]$Text,[bool]$RightToLeft,[switch]$Numeric)
    # -Numeric also wraps letterless values such as editions and dates ("2025.7").
    if(-not $RightToLeft -or [string]::IsNullOrWhiteSpace($Text) -or $Text -match '[\u0590-\u08FF\uFB1D-\uFDFF\uFE70-\uFEFF]' -or ($Text -notmatch '\p{L}' -and -not $Numeric)){return $Text}
    # The trailing LEFT-TO-RIGHT MARK keeps closing punctuation with the Latin run.
    '['+($Text -replace '([\\\[\]])','\$1')+[char]0x200E+']{lang=en}'
}

function ConvertTo-GuideLatexPath {
    # Raw LaTeX inline so Pandoc does not escape the path in templates.
    param([string]$Path)
    '`'+([IO.Path]::GetFullPath($Path).Replace('\','/'))+'`{=latex}'
}
