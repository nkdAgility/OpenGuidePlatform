$script:GuideContributorRoles=@('creator','contributor','reviewer','involved')
$script:GuideTranslationRoles=@('translator','reviewer')
$script:GuideRetiredFrontMatterKeys=@('author','translators','mainfont','sansfont','monofont','dir')

function Get-GuideContributionFiles {
    # Maps site/data/contributions/<guide>[.<lang>].(yml|yaml) to declared guides.
    param([string]$WorkspaceRoot,[Collections.IDictionary]$Policy)
    $relativeDirectory="$($Policy.wrapper.sourcePath)/data/contributions"
    $directory=Resolve-GuideWorkspacePath $WorkspaceRoot $relativeDirectory
    if(-not [IO.Directory]::Exists($directory)){return @()}
    # Script blocks, not ForEach-Object <key>: key access on hashtables honours -WhatIf.
    $guideIds=@(foreach($guide in $Policy.guides){$guide.id})
    foreach($file in [IO.Directory]::GetFiles($directory)|Sort-Object){
        $name=[IO.Path]::GetFileName($file)
        if($name -notmatch '^(?<base>.+)\.(?<extension>ya?ml)$'){continue}
        $base=$Matches['base'];$extension=$Matches['extension']
        $guideId=$null;$language=$null
        foreach($id in $guideIds|Sort-Object Length -Descending){
            if($base -ieq $id){$guideId=$id;break}
            if($base.StartsWith("$id.",[StringComparison]::OrdinalIgnoreCase)){
                $suffix=$base.Substring($id.Length+1)
                if($suffix -match '^[A-Za-z]{2,8}(?:-[A-Za-z0-9]{1,8})*$'){$guideId=$id;$language=$suffix;break}
            }
        }
        [pscustomobject]@{Relative="$relativeDirectory/$name";Path=$file;Base=$base;Extension=$extension;GuideId=$guideId;Language=$language}
    }
}

function Read-GuideContributionFile {
    param([string]$Path)
    Import-Module powershell-yaml -MinimumVersion 0.4.12 -ErrorAction Stop
    $text=[IO.File]::ReadAllText($Path).TrimStart([char]0xFEFF)
    # Callers wrap the result in @(); records are emitted one by one.
    if([string]::IsNullOrWhiteSpace(($text -split "`n"|Where-Object {$_ -notmatch '^\s*#'}) -join '')){return}
    $records=ConvertFrom-Yaml $text -ErrorAction Stop
    if($records -isnot [Collections.IList]){throw 'Expected a YAML list of contributor records.'}
    foreach($record in $records){$record}
}

function Get-GuideContributorRecords {
    param([string]$WorkspaceRoot,[Collections.IDictionary]$Policy,[string]$GuideId,[string]$Language)
    $matches=@(Get-GuideContributionFiles $WorkspaceRoot $Policy|Where-Object {$_.GuideId -ceq $GuideId -and "$($_.Language)" -ieq "$Language"})
    if($matches.Count -gt 1){throw "Ambiguous contributor files for $GuideId$(if($Language){".$Language"}): both .yml and .yaml exist."}
    if(-not $matches.Count){return [pscustomobject]@{File=$null;Records=@()}}
    [pscustomobject]@{File=$matches[0];Records=@(Read-GuideContributionFile $matches[0].Path)}
}

function ConvertTo-GuideCredit {
    param([Collections.IDictionary]$Record,[string]$Language)
    $name=[string]$Record['name']
    $localized=$Record['localizedNames']
    if($Language -and $localized -is [Collections.IDictionary]){
        foreach($key in $localized.Keys){if($key -ieq $Language -and -not [string]::IsNullOrWhiteSpace([string]$localized[$key])){$name=[string]$localized[$key]}}
    }
    $url=if($Record['url']){[string]$Record['url']}elseif($Record['githubUsername']){"https://github.com/$($Record['githubUsername'])"}else{$null}
    $credit=[ordered]@{name=$name;role=[string]$Record['role']}
    if($url){$credit.url=$url}
    $credit
}

function Select-GuideCredits {
    param([object[]]$Records,[string]$EditionId,[string[]]$Roles,[string]$Language)
    # Order by weight; equal weights keep the data file's order, as the website does.
    $position=0
    $selected=@(foreach($record in $Records){
        $position++
        if($record -isnot [Collections.IDictionary]){continue}
        if([string]$record['role'] -notin $Roles){continue}
        if(@($record['contributions']|ForEach-Object {[string]$_}) -notcontains $EditionId){continue}
        [pscustomobject]@{Weight=$(if($null -ne $record['weight']){[double]$record['weight']}else{100});Position=$position;Record=$record}
    })
    @($selected|Sort-Object Weight,Position|ForEach-Object {ConvertTo-GuideCredit $_.Record $Language})
}

function Get-GuideCredits {
    <#
    Resolves the authors, contributors and translators of one guide edition in one
    language from site/data/contributions. Authors are records with role creator.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$WorkspaceRoot,[Parameter(Mandatory)][Collections.IDictionary]$Policy,
        [Parameter(Mandatory)][string]$GuideId,[Parameter(Mandatory)][string]$EditionId,[Parameter(Mandatory)][string]$Language,
        [string[]]$ContributorRoles=@('contributor','reviewer'),[string[]]$TranslatorRoles=@('translator'))
    $selection=Get-GuideSelection $Policy $GuideId $EditionId
    $base=Get-GuideContributorRecords $WorkspaceRoot $Policy $GuideId
    $files=@($base.File|Where-Object {$_}|ForEach-Object Relative)
    $translators=@()
    if($Language -ine $selection.Edition.sourceLanguage){
        $translation=Get-GuideContributorRecords $WorkspaceRoot $Policy $GuideId $Language
        $files+=@($translation.File|Where-Object {$_}|ForEach-Object Relative)
        $translators=@(Select-GuideCredits $translation.Records $EditionId $TranslatorRoles $Language)
    }
    [pscustomobject]@{
        Authors=@(Select-GuideCredits $base.Records $EditionId @('creator') $Language)
        Contributors=@(Select-GuideCredits $base.Records $EditionId $ContributorRoles $Language)
        Translators=$translators
        Files=$files
    }
}

function Get-GuideContributorFindings {
    # Source-convention checks for contributor data; returns finding records for Prepare.
    param([string]$WorkspaceRoot,[Collections.IDictionary]$Policy)
    $findings=[Collections.Generic.List[object]]::new()
    function Add($code,$subject,$message,$fix,$severity='blocker'){$findings.Add([pscustomobject]@{Code=$code;Severity=$severity;Subject=$subject;Message=$message;Remediation=$fix})}
    # Sites that do not keep contributor data are not asked for it.
    if(-not [IO.Directory]::Exists((Resolve-GuideWorkspacePath $WorkspaceRoot "$($Policy.wrapper.sourcePath)/data/contributions"))){return @()}
    $files=@(Get-GuideContributionFiles $WorkspaceRoot $Policy)
    foreach($group in $files|Group-Object {"$($_.GuideId)|$($_.Language)|$(if($_.GuideId){''}else{$_.Base})"}){
        if($group.Count -gt 1){Add CONTRIBUTOR_FILE_AMBIGUOUS $group.Group[0].Relative 'Both .yml and .yaml contributor files exist for the same guide and language.' 'Keep one file; new files use .yml.'}
    }
    $creatorEditions=@{}
    $translatorKeys=@{}
    foreach($file in $files){
        if(-not $file.GuideId){Add CONTRIBUTOR_FILE_UNKNOWN $file.Relative 'The contributor file does not match a declared guide.' 'Name contributor files <guide>.yml or <guide>.<lang>.yml using a declared guide identifier.';continue}
        $guide=@($Policy.guides|Where-Object id -CEQ $file.GuideId)[0]
        $editionIds=@($guide.editions|ForEach-Object {[string]$_.id})
        if($file.Language){
            $declared=@($guide.editions|ForEach-Object {$edition=$_;$_.translations|Where-Object {$_.language -ine $edition.sourceLanguage}|ForEach-Object {$_.language}})
            if($declared -inotcontains $file.Language){Add CONTRIBUTOR_FILE_UNKNOWN $file.Relative "No edition of $($file.GuideId) declares a $($file.Language) translation." 'Remove the file or add the translation it describes.';continue}
        }
        try{$records=@(Read-GuideContributionFile $file.Path)}catch{Add CONTRIBUTOR_RECORD_INVALID $file.Relative $_.Exception.Message 'Correct the YAML so the file is a list of contributor records.';continue}
        $roles=if($file.Language){$script:GuideTranslationRoles}else{$script:GuideContributorRoles}
        $seen=@{}
        for($index=0;$index -lt $records.Count;$index++){
            $record=$records[$index];$subject="$($file.Relative)#$($index+1)"
            if($record -isnot [Collections.IDictionary]){Add CONTRIBUTOR_RECORD_INVALID $subject 'Expected a contributor mapping.' 'Use name, role and contributions fields.';continue}
            if([string]::IsNullOrWhiteSpace([string]$record['name'])){Add CONTRIBUTOR_RECORD_INVALID $subject 'The record has no name.' 'Add the display name.'}else{$subject="$($file.Relative)#$($record['name'])"}
            if([string]$record['role'] -cnotin $roles){Add CONTRIBUTOR_RECORD_INVALID $subject "Role '$($record['role'])' is not allowed in this file." "Use one of: $($roles -join ', ')."}
            $editions=@($record['contributions']|Where-Object {$null -ne $_}|ForEach-Object {[string]$_})
            if(-not $editions.Count){Add CONTRIBUTOR_RECORD_INVALID $subject 'The record lists no editions in contributions.' 'List the edition identifiers this person contributed to.'}
            foreach($edition in $editions){if($edition -cnotin $editionIds){Add CONTRIBUTOR_EDITION_UNKNOWN $subject "Edition '$edition' is not an edition of $($file.GuideId)." 'Use an existing edition identifier.'}}
            if($null -ne $record['localizedNames'] -and $record['localizedNames'] -isnot [Collections.IDictionary]){Add CONTRIBUTOR_RECORD_INVALID $subject 'localizedNames must map language codes to names.' 'Use localizedNames: { fa: ... }.'}
            $identity=if($record['githubUsername']){"github:$($record['githubUsername'])".ToLowerInvariant()}else{"name:$($record['name'])".ToLowerInvariant()}
            if($seen.ContainsKey($identity)){Add CONTRIBUTOR_RECORD_INVALID $subject 'The same person appears more than once in this file.' 'Merge the records; list every edition in one contributions list.'}else{$seen[$identity]=$true}
            foreach($edition in $editions){
                if(-not $file.Language -and [string]$record['role'] -ceq 'creator'){$creatorEditions["$($file.GuideId)|$edition"]=$true}
                if($file.Language -and [string]$record['role'] -ceq 'translator'){$translatorKeys["$($file.GuideId)|$edition|$($file.Language.ToLowerInvariant())"]=$true}
            }
        }
    }
    foreach($guide in $Policy.guides){foreach($edition in $guide.editions){
        if(-not $creatorEditions.ContainsKey("$($guide.id)|$($edition.id)")){Add CREATORS_MISSING "$($guide.id)/$($edition.id)" 'No contributor record with role creator lists this edition.' "Add the authors to data/contributions/$($guide.id).yml with role: creator." warning}
        foreach($translation in $edition.translations){
            if($translation.language -ieq $edition.sourceLanguage -or $translation.intent -ne 'web'){continue}
            if(-not $translatorKeys.ContainsKey("$($guide.id)|$($edition.id)|$($translation.language.ToLowerInvariant())")){Add TRANSLATORS_MISSING "$($guide.id)/$($edition.id)/$($translation.language)" 'This translation has no translator record.' "Add the translators to data/contributions/$($guide.id).$($translation.language).yml with role: translator." warning}
        }
    }}
    @($findings.ToArray())
}
