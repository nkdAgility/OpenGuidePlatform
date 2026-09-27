function ConvertFrom-GuideTranslationJson {
    param([Parameter(Mandatory)][string]$Content)
    # ConvertFrom-Json in PowerShell 7.4 coerces ISO strings to DateTime.
    # Preserve the JSON types used by the text-only translation contract.
    function ReadJsonValue([System.Text.Json.JsonElement]$element) {
        switch ($element.ValueKind.ToString()) {
            'Object' {
                $value=[Collections.Specialized.OrderedDictionary]::new([StringComparer]::Ordinal)
                foreach($property in $element.EnumerateObject()){$value.Add($property.Name,(ReadJsonValue $property.Value))}
                return $value
            }
            'Array' {
                $value=@(foreach($item in $element.EnumerateArray()){ReadJsonValue $item})
                return ,$value
            }
            'String' { return $element.GetString() }
            'Number' { return (ConvertFrom-Json $element.GetRawText() -NoEnumerate) }
            'True' { return $true }
            'False' { return $false }
            'Null' { return $null }
            default { throw 'Unsupported JSON value.' }
        }
    }
    $document=[System.Text.Json.JsonDocument]::Parse($Content)
    try { return ,(ReadJsonValue $document.RootElement) }
    finally { $document.Dispose() }
}
function Get-GuideSiteTranslationWork {
    <# .SYNOPSIS
    Discover site-language work before selecting individual guide translations.
    .DESCRIPTION
    Read-only local work inventory, not effective readiness or editorial approval.
    JSON text fields require explicit reviewed JSON pointers; no prose is guessed.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$WorkspaceRoot,
        [Parameter(Mandatory)][Collections.IDictionary]$Policy,
        [Parameter(Mandatory)][ValidatePattern('^[A-Za-z]{2,8}(?:-[A-Za-z0-9]{1,8})*$')][string]$Language
    )
    Import-Module powershell-yaml -MinimumVersion 0.4.12 -ErrorAction Stop
    $wrapper=$Policy.wrapper.sourcePath.TrimEnd('/')
    $configPath="$wrapper/hugo.yaml";$productionPath="$wrapper/hugo.production.yaml"
    $config=ConvertFrom-Yaml ([IO.File]::ReadAllText((Resolve-GuideWorkspacePath $WorkspaceRoot $configPath)))
    $production=ConvertFrom-Yaml ([IO.File]::ReadAllText((Resolve-GuideWorkspacePath $WorkspaceRoot $productionPath)))
    function ConfigValue($name,$fallback){$key=@($config.Keys|Where-Object { $_ -ieq $name });if($key.Count){$config[$key[0]]}else{$fallback}}
    $sourceLanguage=[string](ConfigValue 'defaultContentLanguage' 'en')
    if($Language -ieq $sourceLanguage){throw 'Select a target language different from the site source language.'}
    $disabled=$production.Contains('languages') -and $production.languages.Contains($Language) -and $production.languages[$Language]['disabled'] -eq $true
    $declared=$config.Contains('languages') -and $config.languages.Contains($Language)
    function FileHash($relative){$file=Resolve-GuideWorkspacePath $WorkspaceRoot $relative;if([IO.File]::Exists($file)){(Get-FileHash -LiteralPath $file).Hash.ToLowerInvariant()}}
    function WorkItem($kind,$source,$target,$operation){
        $sourceHash=FileHash $source;$targetHash=FileHash $target
        [pscustomobject]@{Kind=$kind;SourcePath=$source;TargetPath=$target;SourceSha256=$sourceHash;TargetSha256=$targetHash;State=if($targetHash){'existing-review-required'}else{'missing'};WriteAllowed=(Test-GuideWritePolicy $Policy $target).Allowed;SupportedOperation=$operation}
    }
    $contentRelative="$wrapper/$(ConfigValue 'contentDir' 'content')"
    $content=Resolve-GuideWorkspacePath $WorkspaceRoot $contentRelative
    $wrappers=@(
        foreach($extension in @('yaml','yml')){if(Test-Path -LiteralPath (Resolve-GuideWorkspacePath $WorkspaceRoot "$wrapper/i18n/$sourceLanguage.$extension")){WorkItem 'catalogue' "$wrapper/i18n/$sourceLanguage.$extension" "$wrapper/i18n/$Language.$extension" 'Set-GuideWrapperTranslation'}}
        if(Test-Path -LiteralPath $content){foreach($file in Get-ChildItem -LiteralPath $content -Filter '*.md' -File -Recurse){
            $relative=[IO.Path]::GetRelativePath($WorkspaceRoot,$file.FullName).Replace('\','/')
            $inEdition=$false;foreach($guide in $Policy.guides){foreach($edition in $guide.editions){if($relative.StartsWith("$($guide.contentRoot)/$($edition.path)/",[StringComparison]::OrdinalIgnoreCase)){$inEdition=$true}}}
            if($inEdition){continue}
            # Hugo default-language source files are unsuffixed or explicitly source-suffixed.
            if($file.BaseName -match '\.([A-Za-z]{2,8}(?:-[A-Za-z0-9]{1,8})*)$'){
                if($Matches[1] -ine $sourceLanguage){continue};$stem=$relative.Substring(0,$relative.Length-$sourceLanguage.Length-4)
            }else{$stem=$relative.Substring(0,$relative.Length-3)}
            WorkItem 'markdown' $relative "$stem.$Language.md" 'Set-GuideWrapperTranslation'
        }}
        $dataRelative="$wrapper/$(ConfigValue 'dataDir' 'data')"
        $data=Resolve-GuideWorkspacePath $WorkspaceRoot $dataRelative
        if(Test-Path -LiteralPath $data){foreach($file in Get-ChildItem -LiteralPath $data -Filter "$sourceLanguage.json" -File -Recurse){
            $relative=[IO.Path]::GetRelativePath($WorkspaceRoot,$file.FullName).Replace('\','/')
            WorkItem 'json-text-selection-required' $relative ($relative.Substring(0,$relative.Length-$sourceLanguage.Length-5)+"$Language.json") 'Set-GuideWrapperTranslation -JsonTextPaths'
        }}
    )
    function SameJsonShape($source,$target){
        if($source -is [Collections.IDictionary]){
            if($target -isnot [Collections.IDictionary] -or $source.Count -ne $target.Count){return $false}
            foreach($key in $source.Keys){if(-not $target.Contains($key) -or -not (SameJsonShape $source[$key] $target[$key])){return $false}}
        }elseif($source -is [Collections.IList]){
            if($target -isnot [Collections.IList] -or $source.Count -ne $target.Count){return $false}
            for($i=0;$i -lt $source.Count;$i++){if(-not (SameJsonShape $source[$i] $target[$i])){return $false}}
        }else{
            function JsonScalarKind($value){if($null -eq $value){'null'}elseif($value -is [string]){'string'}elseif($value -is [bool]){'boolean'}elseif($value -is [ValueType]){'number'}else{'unsupported'}}
            if((JsonScalarKind $source) -ne (JsonScalarKind $target)){return $false}
        }
        return $true
    }
    foreach($item in $wrappers){
        if($item.Kind -eq 'json-text-selection-required'){
            try {
                $sourceJson=ConvertFrom-GuideTranslationJson ([IO.File]::ReadAllText((Resolve-GuideWorkspacePath $WorkspaceRoot $item.SourcePath)))
                if($item.TargetSha256){
                    $targetJson=ConvertFrom-GuideTranslationJson ([IO.File]::ReadAllText((Resolve-GuideWorkspacePath $WorkspaceRoot $item.TargetPath)))
                    if(-not (SameJsonShape $sourceJson $targetJson)){$item.State='unsupported-json-schema-reconciliation';$item.SupportedOperation=$null}
                }
            }catch{$item.State='unsupported-invalid-json';$item.SupportedOperation=$null}
        }
        if($item.Kind -eq 'catalogue'){
            $existing=@(foreach($ext in @('yaml','yml')){$candidate="$wrapper/i18n/$Language.$ext";if(FileHash $candidate){$candidate}})
            if($existing.Count -eq 1){$item.TargetPath=$existing[0];$item.TargetSha256=FileHash $existing[0];$item.State='existing-review-required';$item.WriteAllowed=(Test-GuideWritePolicy $Policy $item.TargetPath).Allowed}
            elseif($existing.Count -gt 1){$item.State='ambiguous-target-catalogue';$item.SupportedOperation=$null}
        }
        if(($item.Kind -eq 'markdown' -and -not $item.TargetPath.StartsWith("$wrapper/content/")) -or ($item.Kind -eq 'json-text-selection-required' -and -not $item.TargetPath.StartsWith("$wrapper/data/"))){$item.SupportedOperation=$null;$item.State='unsupported-custom-directory'}
    }
    $sourceCatalogues=@($wrappers|Where-Object Kind -EQ catalogue)
    if($sourceCatalogues.Count -gt 1){foreach($item in $sourceCatalogues){$item.State='ambiguous-source-catalogue';$item.SupportedOperation=$null}}
    foreach($group in @($wrappers|Group-Object TargetPath|Where-Object Count -gt 1)){foreach($item in $group.Group){$item.State='ambiguous-source';$item.SupportedOperation=$null}}
    $guides=@(foreach($guide in $Policy.guides){foreach($edition in $guide.editions){
        $target="$($guide.contentRoot)/$($edition.path)/index.$Language.md";$path=Resolve-GuideWorkspacePath $WorkspaceRoot $target
        $translation=@($edition.translations|Where-Object language -CEQ $Language)
        $intent=if($translation.Count){$translation[0].intent}else{$null}
        $state=if([IO.File]::Exists($path)){if([string]::IsNullOrWhiteSpace((Read-GuideDocument $path).Body)){'empty-stub'}else{'populated'}}else{'missing'}
        $excluded=$intent -eq 'excluded' -or @($Policy.publication.permanentExclusions|Where-Object {($_.subject -eq 'guide' -and $_.id -eq $guide.id) -or ($_.subject -eq 'edition' -and $_.id -eq "$($guide.id)/$($edition.id)")}).Count -gt 0
        $allowed=(Test-GuideWritePolicy $Policy $target).Allowed
        [pscustomobject]@{GuideId=$guide.id;EditionId=$edition.id;SourceLanguage=$edition.sourceLanguage;SourceLanguageSelected=($Language -ieq $edition.sourceLanguage);SourcePath="$($guide.contentRoot)/$($edition.path)/index.md";SourceSha256=(FileHash "$($guide.contentRoot)/$($edition.path)/index.md");TargetPath=$target;TargetSha256=(FileHash $target);State=$state;Intent=$intent;Excluded=$excluded;WriteAllowed=$allowed;Downloads=@($translation|ForEach-Object {$_.downloads});CanCreateScaffold=($state -eq 'missing' -and $Language -ine $edition.sourceLanguage -and $allowed -and $disabled -and -not $excluded -and $intent -notin @('pdf-only','fallback'))}
    }})
    [pscustomobject]@{
        SiteId=$Policy.siteId;Language=$Language;SourceLanguage=$sourceLanguage
        Configuration=[pscustomobject]@{MainPath=$configPath;MainSha256=(FileHash $configPath);LanguageDeclared=$declared;ProductionPath=$productionPath;ProductionSha256=(FileHash $productionPath);ProductionExplicitlyDisabled=$disabled}
        Wrappers=$wrappers;Guides=$guides
        Findings=@(
            if(-not $disabled){[pscustomobject]@{Code='PRODUCTION_EXCLUSION_REQUIRED';Severity='blocker';Action='Declare the target language disabled in production before creating files.'}}
            if(-not $declared){[pscustomobject]@{Code='SITE_LANGUAGE_CONFIGURATION_REQUIRED';Severity='work';Action='Review and add the selected language to the main site configuration.'}}
            foreach($item in $wrappers|Where-Object {-not $_.SupportedOperation}){[pscustomobject]@{Code='WRAPPER_SCOPE_UNSUPPORTED';Severity='blocker';Action="Resolve $($item.State): $($item.TargetPath) before claiming site scaffolding complete."}}
            [pscustomobject]@{Code='CUSTOM_SCOPE_REVIEW_REQUIRED';Severity='review';Action='Inspect custom mounts, non-JSON data and template-embedded copy; local discovery is not proof of complete effective coverage.'}
            [pscustomobject]@{Code='JSON_TEXT_SELECTION_REQUIRED';Severity='review';Action='Review JSON string pointers explicitly; machine-valued strings are not inferred.'}
            [pscustomobject]@{Code='EFFECTIVE_READINESS_REQUIRED';Severity='review';Action='Refresh Prepare and validate preview and production after changes; preserve existing bodies and PDF-only/fallback states and select body translation separately.'}
        )
        TranslationQualityAssessed=$false;PublicationVerified=$false
    }
}
