Set-StrictMode -Version Latest
$script:ContributorRoot = $PSScriptRoot

function New-OGPContext {
    param([string]$WorkspaceRoot,[string]$PlatformPath)
    $ErrorActionPreference = 'Stop'
    # Discovery writes disposable evidence even when the requested site mutation
    # is a preview. Do not let inherited WhatIf suppress restoration metadata.
    $WhatIfPreference = $false
    $ConfirmPreference = 'None'
    $root = [IO.Path]::GetFullPath($WorkspaceRoot)
    if (-not $PlatformPath -and -not (Test-Path -LiteralPath "$root/.OpenGuidePlatform/installation.json")) {
        throw 'Open PowerShell in your local guide-site folder. This folder needs an OGP installation; ask the site maintainer to install it first.'
    }
    $resolver = Join-Path $script:ContributorRoot 'Runtime/Resolve-OpenGuidePlatform.ps1'
    if (-not (Test-Path -LiteralPath $resolver)) {
        $resolver = Join-Path $script:ContributorRoot '../OpenGuidePlatform.PowerShell.GuideSiteAdoption/Resolve-OpenGuidePlatform.ps1'
    }
    $runtime = if ($PlatformPath) { & $resolver -WorkspaceRoot $root -PlatformSource Path -PlatformPath $PlatformPath 6>$null } else { & $resolver -WorkspaceRoot $root -UseInstalled 6>$null }
    $identity = Get-Content -LiteralPath "$runtime/platform.json" -Raw | ConvertFrom-Json
    $build = Import-Module "$runtime/system/OpenGuidePlatform.PowerShell.GuideSiteBuild/OpenGuidePlatform.PowerShell.GuideSiteBuild.psm1" -Force -PassThru -Scope Local
    $output = '.processing/contributor/' + [guid]::NewGuid().ToString('N')
    $prepareError = $null
    try {
        $diagnostics=& $build { param($r,$o) Invoke-GuideSiteBuild -WorkspaceRoot $r -Stage Prepare -Target preview -OutputPath $o } $root $output 6>&1 | Out-String
        Write-Verbose $diagnostics
    }
    catch { $prepareError = $_.Exception.Message }
    $core = Import-Module "$runtime/system/OpenGuidePlatform.PowerShell.Core/OpenGuidePlatform.PowerShell.Core.psd1" -Force -PassThru -Scope Local
    $policyPath = "$root/$output/discovered-site.json"
    if (-not (Test-Path -LiteralPath $policyPath)) { throw "Site discovery is unavailable. Ask the maintainer to resolve Prepare: $prepareError. Reports: $root/$output" }
    $policy = & $core { param($p) Import-GuidePolicy -Path $p } $policyPath
    if ($prepareError) { Write-Warning "Prepare has unresolved findings: $prepareError. Discovery supports repairs; this is not a readiness pass." }
    Write-Host "Site OGP $($identity.version). Prepare evidence: $root/$output"
    @{ WorkspaceRoot=$root; Runtime=$runtime; Identity=$identity; Core=$core; Build=$build; Policy=$policy; OutputPath=$output; PrepareError=$prepareError }
}

function Invoke-OGPCore {
    param($Context,[string]$Command,[hashtable]$Arguments)
    & $Context.Core {
        param($name,$values)
        $command = Get-Command -Name $name -CommandType Function -ErrorAction SilentlyContinue
        if (-not $command -or $command.Module.Path -cne $ExecutionContext.SessionState.Module.Path) {
            throw "The site's selected OGP release does not support $name. Ask the maintainer for a coordinated OGP update; installing newer contributor commands does not upgrade the site."
        }
        & $command @values
    } $Command $Arguments
}

function Get-OGPSelection {
    param($Context,[hashtable]$Selection)
    $values = @{WorkspaceRoot=$Context.WorkspaceRoot;Policy=$Context.Policy}
    foreach ($key in $Selection.Keys) { $values[$key]=$Selection[$key] }
    $values
}

function Get-OGPTranslationStatus {
    <# .SYNOPSIS
    Show website-language work and guide-body work separately.
    .EXAMPLE
    Get-OGPTranslationStatus -Language kn
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Language,[string]$WorkspaceRoot=$PWD.Path,[string]$PlatformPath)
    $context=New-OGPContext $WorkspaceRoot $PlatformPath
    $work=Invoke-OGPCore $context Get-GuideSiteTranslationWork (Get-OGPSelection $context @{Language=$Language})
    # Present task choices, not the Core writer's policy/hash contract. Draft
    # commands retain that technical evidence internally for their safe saves.
    [pscustomobject]@{
        SiteId=$work.SiteId;Language=$work.Language;SourceLanguage=$work.SourceLanguage
        Configuration=$work.Configuration|Select-Object MainPath,LanguageDeclared,ProductionPath,ProductionExplicitlyDisabled
        Wrappers=@($work.Wrappers|Select-Object Kind,SourcePath,TargetPath,State,SupportedOperation,WriteAllowed)
        Guides=@($work.Guides|Select-Object GuideId,EditionId,SourceLanguage,SourcePath,TargetPath,State,Intent,Excluded,WriteAllowed,Downloads,CanCreateScaffold)
        Findings=$work.Findings;PrepareReport=Join-Path $context.WorkspaceRoot "$($context.OutputPath)/prepare/assessment.md"
        TranslationQualityAssessed=$false;PublicationVerified=$false
    }
}

function New-OGPTranslation {
    <# .SYNOPSIS
    Create one eligible empty guide translation after preparing the site language.
    .EXAMPLE
    New-OGPTranslation -GuideId guide-a -EditionId 2026 -Language kn -WhatIf
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory)][string]$GuideId,[Parameter(Mandatory)][string]$EditionId,[Parameter(Mandatory)][string]$Language,[string]$WorkspaceRoot=$PWD.Path,[string]$PlatformPath)
    $context=New-OGPContext $WorkspaceRoot $PlatformPath
    $values=Get-OGPSelection $context @{GuideId=$GuideId;EditionId=$EditionId;Language=$Language}
    $site=Invoke-OGPCore $context Get-GuideSiteTranslationWork (Get-OGPSelection $context @{Language=$Language})
    $eligible=@($site.Guides|Where-Object { $_.GuideId -ceq $GuideId -and $_.EditionId -ceq $EditionId })
    if ($eligible.Count -ne 1 -or -not $eligible[0].CanCreateScaffold) { throw 'This edition is not eligible for an empty scaffold. Preserve existing, protected, PDF-only, fallback and excluded content; inspect Get-OGPTranslationStatus.' }
    if (-not $site.Configuration.LanguageDeclared -or @($site.Wrappers|Where-Object { $_.State -eq 'missing' -or -not $_.SupportedOperation }).Count) { throw 'Complete the main website-language settings and supported website text files before creating empty guide pages. Inspect Get-OGPTranslationStatus; unsupported files need maintainer help.' }
    if ($PSCmdlet.ShouldProcess("$GuideId/$EditionId/$Language",'Create an empty guide translation')) { Invoke-OGPCore $context New-GuideTranslation $values }
}

function Write-OGPDraft {
    param($Context,[hashtable]$Receipt,[string]$Content,[string]$Extension,$Comparison)
    $directory="$($Context.WorkspaceRoot)/$($Context.OutputPath)/draft"
    [IO.Directory]::CreateDirectory($directory) | Out-Null
    $candidate="$directory/candidate$Extension"
    $Receipt.schemaVersion=1
    $Receipt.workspace=$Context.WorkspaceRoot
    $Receipt.version=$Context.Identity.version
    $Receipt.sourceCommit=$Context.Identity.sourceCommit
    [IO.File]::WriteAllText($candidate,$Content,[Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText("$candidate.ogp.json",($Receipt|ConvertTo-Json -Depth 20))
    if ($Comparison) {
        [IO.File]::WriteAllText("$directory/source-changes.diff",$Comparison.Diff)
        [IO.File]::WriteAllText("$directory/source-baseline.md",$Comparison.Content)
    }
    [pscustomobject]@{Path=$candidate;SourcePath=$(if($Receipt.source){Join-Path $Context.WorkspaceRoot $Receipt.source}elseif($Receipt.targetHash){Join-Path $Context.WorkspaceRoot $Receipt.target});SourceDifferencePath=$(if($Comparison){"$directory/source-changes.diff"});SourceBaselinePath=$(if($Comparison){"$directory/source-baseline.md"});ComparisonCommit=$(if($Comparison){$Comparison.Commit});Next='Open this file and SourcePath in your editor, review the wording, save the draft, then run Save-OGPDraft -Path with this path and -Reviewed. No site content has been changed.'}
}

function New-OGPTranslationDraft {
    <# .SYNOPSIS
    Create an editable copy of an existing translation and retain its reviewed inputs.
    .EXAMPLE
    New-OGPTranslationDraft -GuideId guide-a -EditionId 2026 -Language kn
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$GuideId,[Parameter(Mandatory)][string]$EditionId,[Parameter(Mandatory)][string]$Language,[string]$SourceRevision,[string]$SourcePathAtRevision,[string]$WorkspaceRoot=$PWD.Path,[string]$PlatformPath)
    $context=New-OGPContext $WorkspaceRoot $PlatformPath
    $selection=@{GuideId=$GuideId;EditionId=$EditionId;Language=$Language}
    if ($SourcePathAtRevision -and -not $SourceRevision) { throw 'Choose an explicit source comparison revision before supplying its historical path.' }
    if ($SourceRevision) { $selection.SourceRevision=$SourceRevision }
    if ($SourcePathAtRevision) { $selection.SourcePathAtRevision=$SourcePathAtRevision }
    $work=Invoke-OGPCore $context Get-GuideTranslationWork (Get-OGPSelection $context $selection)
    if (-not $work.Target) { throw 'No translation page exists. Complete the site-language work, then use New-OGPTranslation for this selected edition.' }
    if ($work.Comparison) { $selection.SourceRevision=$work.Comparison.Commit;$selection.SourcePathAtRevision=$work.Comparison.Path }
    Write-OGPDraft $context @{kind='translation';selection=$selection;target=$work.TargetPath;targetHash=$work.Target.Sha256;source=$work.Source.Path;sourceHash=$work.Source.Sha256} $work.Target.Content '.md' $work.Comparison
}

function New-OGPWrapperDraft {
    <# .SYNOPSIS
    Draft one website-language file selected from the status report.
    .DESCRIPTION
    Use the production configuration first to disable the new language, then the
    main configuration, website text and finally eligible guide scaffolds. JSON
    text requires explicitly selected JSON pointers. Existing text is preserved.
    .EXAMPLE
    New-OGPWrapperDraft -Language kn -RelativePath site/hugo.production.yaml
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Language,[Parameter(Mandatory)][string]$RelativePath,[string[]]$JsonTextPaths,[string]$WorkspaceRoot=$PWD.Path,[string]$PlatformPath)
    $context=New-OGPContext $WorkspaceRoot $PlatformPath
    $work=Invoke-OGPCore $context Get-GuideSiteTranslationWork (Get-OGPSelection $context @{Language=$Language})
    $source=$null;$targetHash=$null;$sourceHash=$null
    if ($RelativePath -ceq $work.Configuration.ProductionPath) { $targetHash=$work.Configuration.ProductionSha256 }
    elseif ($RelativePath -ceq $work.Configuration.MainPath) { $targetHash=$work.Configuration.MainSha256 }
    else {
        $rows=@($work.Wrappers|Where-Object TargetPath -CEQ $RelativePath)
        if ($rows.Count -ne 1 -or -not $rows[0].SupportedOperation) { throw 'Choose one supported TargetPath from Get-OGPTranslationStatus. Unsupported resources need maintainer help.' }
        $source=$rows[0].SourcePath;$sourceHash=$rows[0].SourceSha256;$targetHash=$rows[0].TargetSha256
        if ($rows[0].Kind -eq 'json-text-selection-required' -and -not $JsonTextPaths) { throw 'Select the JSON text fields explicitly with -JsonTextPaths; machine values must remain unchanged.' }
    }
    $starting=if($targetHash){$RelativePath}else{$source}
    if (-not $starting) { throw 'The configuration file is missing. Ask the site maintainer to repair setup.' }
    $path=Invoke-OGPCore $context Resolve-GuideWorkspacePath @{WorkspaceRoot=$context.WorkspaceRoot;RelativePath=$starting}
    Write-OGPDraft $context @{kind='wrapper';selection=@{Language=$Language};target=$RelativePath;targetHash=$targetHash;source=$source;sourceHash=$sourceHash;jsonTextPaths=@($JsonTextPaths)} ([IO.File]::ReadAllText($path)) ([IO.Path]::GetExtension($path))
}

function Save-OGPDraft {
    <# .SYNOPSIS
    Apply an explicitly reviewed draft through the site's protected Core writer.
    .DESCRIPTION
    Refuses a different workspace, changed runtime, or changed source/target.
    Review the site diff afterwards. This command does not approve publication.
    .EXAMPLE
    Save-OGPDraft -Path .processing/contributor/example/draft/candidate.md -Reviewed -WhatIf
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory)][string]$Path,[switch]$Reviewed,[string]$WorkspaceRoot=$PWD.Path,[string]$PlatformPath)
    if (-not $Reviewed) { throw 'Review the exact candidate wording first, then supply -Reviewed. This records your review, not publication approval.' }
    $context=New-OGPContext $WorkspaceRoot $PlatformPath
    $candidate=[IO.Path]::GetFullPath($Path,$context.WorkspaceRoot)
    $receipt=Get-Content -LiteralPath "$candidate.ogp.json" -Raw|ConvertFrom-Json -AsHashtable
    if ($receipt.schemaVersion -ne 1 -or $receipt.workspace -cne $context.WorkspaceRoot -or $receipt.version -cne $context.Identity.version -or $receipt.sourceCommit -cne $context.Identity.sourceCommit) { throw 'This draft belongs to another workspace or OGP runtime. Create and review a fresh draft.' }
    foreach ($pair in @(@('target','targetHash'),@('source','sourceHash'))) {
        $relative=$receipt[$pair[0]];$expected=$receipt[$pair[1]]
        if (-not $relative) { continue }
        $file=Invoke-OGPCore $context Resolve-GuideWorkspacePath @{WorkspaceRoot=$context.WorkspaceRoot;RelativePath=$relative}
        $actual=if([IO.File]::Exists($file)){(Get-FileHash -LiteralPath $file).Hash}else{$null}
        if ($actual -ine $expected) { throw 'A source or target changed since this draft began. Compare the changes and create a fresh reviewed draft.' }
    }
    $values=Get-OGPSelection $context $receipt.selection
    $values.CandidateContent=[IO.File]::ReadAllText($candidate)
    if ($receipt.targetHash) { $values.ExpectedSha256=$receipt.targetHash }
    if ($receipt.kind -eq 'translation') { $command='Set-GuideTranslation';$values.ExpectedSourceSha256=$receipt.sourceHash }
    elseif ($receipt.kind -eq 'wrapper') {
        $command='Set-GuideWrapperTranslation';$values.RelativePath=$receipt.target
        if ($receipt.jsonTextPaths.Count) { $values.JsonTextPaths=$receipt.jsonTextPaths;$values.ExpectedSourceSha256=$receipt.sourceHash }
    } else { throw 'Unsupported draft kind.' }
    # Core implements WhatIf too: validation still runs before its write decision.
    $proceed=$PSCmdlet.ShouldProcess($receipt.target,'Apply reviewed draft')
    if (-not $proceed -and -not $WhatIfPreference) { return }
    $values.WhatIf=[bool]$WhatIfPreference
    $values.Confirm=$false
    Invoke-OGPCore $context $command $values
}

function Get-OGPCredits {
    <# .SYNOPSIS
    Show the existing credits for one guide edition and language.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$GuideId,[Parameter(Mandatory)][string]$EditionId,[Parameter(Mandatory)][string]$Language,[string]$WorkspaceRoot=$PWD.Path,[string]$PlatformPath)
    $context=New-OGPContext $WorkspaceRoot $PlatformPath
    Invoke-OGPCore $context Get-GuideCredits (Get-OGPSelection $context @{GuideId=$GuideId;EditionId=$EditionId;Language=$Language;TranslatorRoles=@('translator','reviewer','contributor','translation reviewer')})
}

function New-OGPContribution {
    <# .SYNOPSIS
    Add one consented translation credit while preserving existing records.
    .EXAMPLE
    New-OGPContribution -GuideId guide-a -EditionId 2026 -Language kn -Name 'Example Person' -Role translator -ConsentConfirmed -WhatIf
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory)][string]$GuideId,[Parameter(Mandatory)][string]$EditionId,[Parameter(Mandatory)][string]$Language,[Parameter(Mandatory)][string]$Name,[Parameter(Mandatory)][ValidateSet('translator','reviewer','contributor','translation reviewer')][string]$Role,[string]$GitHubUsername,[switch]$ConsentConfirmed,[string]$WorkspaceRoot=$PWD.Path,[string]$PlatformPath)
    if (-not $ConsentConfirmed) { throw 'Obtain consent to publish this name, then supply -ConsentConfirmed.' }
    $context=New-OGPContext $WorkspaceRoot $PlatformPath
    $guide=@($context.Policy.guides|Where-Object id -CEQ $GuideId)
    if ($guide.Count -ne 1 -or $EditionId -cnotin @($guide[0].editions.id)) { throw 'Choose an existing guide and edition from the translation status report.' }
    $record=@{name=$Name;role=$Role;contributions=@($EditionId)}
    if ($GitHubUsername) { $record.githubUsername=$GitHubUsername }
    $selection=Invoke-OGPCore $context Get-GuideContributionWork (Get-OGPSelection $context @{GuideId=$GuideId;Language=$Language})
    if (-not $selection.WriteAllowed) { throw 'This contribution file is protected. Ask the site maintainer to review the requested attribution.' }
    $values=Get-OGPSelection $context @{GuideId=$GuideId;Language=$Language;WhatIf=[bool]$WhatIfPreference;Confirm=$false}
    $proceed=$PSCmdlet.ShouldProcess($selection.Path,"Record consented credit for $Name locally")
    if (-not $proceed -and -not $WhatIfPreference) { return }
    if ($selection.Exists) {
        $values.ExpectedSha256=$selection.Sha256
        $values.CandidateYaml=$selection.Content+"`n"+(ConvertTo-Yaml -Data @($record))
        Invoke-OGPCore $context Add-GuideContribution $values
    } else {
        $values.Contributors=@($record)
        Invoke-OGPCore $context New-GuideContributions $values
    }
}

function Get-OGPPdfPlan {
    <# .SYNOPSIS
    Plan one declared generated PDF; supplied and protected PDFs are preserved.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$GuideId,[Parameter(Mandatory)][string]$EditionId,[Parameter(Mandatory)][string]$Language,[Parameter(Mandatory)][string]$DownloadPath,[string]$WorkspaceRoot=$PWD.Path,[string]$PlatformPath)
    $context=New-OGPContext $WorkspaceRoot $PlatformPath
    Invoke-OGPCore $context Get-GuidePdfPlan (Get-OGPSelection $context @{GuideId=$GuideId;EditionId=$EditionId;Language=$Language;DownloadPath=$DownloadPath})
}

function New-OGPPdf {
    <# .SYNOPSIS
    Generate one eligible PDF through Core, then require human visual review.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory)][string]$GuideId,[Parameter(Mandatory)][string]$EditionId,[Parameter(Mandatory)][string]$Language,[Parameter(Mandatory)][string]$DownloadPath,[string]$WorkspaceRoot=$PWD.Path,[string]$PlatformPath)
    $context=New-OGPContext $WorkspaceRoot $PlatformPath
    $plan=Invoke-OGPCore $context Get-GuidePdfPlan (Get-OGPSelection $context @{GuideId=$GuideId;EditionId=$EditionId;Language=$Language;DownloadPath=$DownloadPath})
    if ([IO.File]::Exists($plan.Output)) { throw 'This PDF already exists. Use the installed guide.genpdfs skill or maintainer procedure to review regeneration against the existing PDF; this command creates new PDFs only.' }
    $requirements=Invoke-OGPCore $context Get-GuideDownloadRequirements (Get-OGPSelection $context @{Target='preview';EnabledLanguages=@($Language)})
    $downloads=@(@($requirements.Required)+@($requirements.Forbidden)|Where-Object { $_.Guide -ceq $GuideId -and $_.Edition -ceq $EditionId -and $_.Language -ceq $Language -and $_.SourcePath -ceq $plan.RelativeOutput })
    if ($downloads.Count -ne 1 -or -not $downloads[0].GenerationReceipt -or $downloads[0].GenerationReceipt.environmentSha256 -cnotmatch '^[a-f0-9]{64}$') { throw 'Generation requires a declared receipt path and an approved generation environment in the selected site policy. Ask the maintainer to supply separately reviewed site-policy setup and environment evidence; the installed skill does not create that approval. Do not invent a digest or bypass discovery.' }
    $declaration=$downloads[0].GenerationReceipt
    $receiptPath=Invoke-OGPCore $context Resolve-GuideWorkspacePath @{WorkspaceRoot=$context.WorkspaceRoot;RelativePath=$declaration.path}
    if ([IO.File]::Exists($receiptPath)) { throw 'Generation evidence already exists. Ask the maintainer to review the existing PDF and receipt before regeneration.' }
    $values=Get-OGPSelection $context @{GuideId=$GuideId;EditionId=$EditionId;Language=$Language;DownloadPath=$DownloadPath;WhatIf=[bool]$WhatIfPreference;Confirm=$false}
    $values.EnvironmentSha256=$declaration.environmentSha256
    $proceed=$PSCmdlet.ShouldProcess($DownloadPath,'Generate PDF; human visual review is still required')
    if ($proceed -or $WhatIfPreference) {
        $generated=Invoke-OGPCore $context New-GuidePdf $values
        if ($WhatIfPreference) { return }
        try { $saved=Invoke-OGPCore $context Save-GuidePdfReceipt (Get-OGPSelection $context @{Receipt=$generated;ReceiptPath=$declaration.path;Confirm=$false}) }
        catch { throw "The PDF was generated, but its required receipt could not be saved: $($_.Exception.Message). Keep both the PDF and diagnostics for maintainer recovery; validation has not passed." }
        [pscustomobject]@{Status=$generated.Status;Path=$generated.Path;ReceiptPath=$saved.Path;VisualReviewRequired=$true;ValidationRequired=$true}
    }
}

function Test-OGPSite {
    <# .SYNOPSIS
    Build and validate preview and production locally without publishing.
    .EXAMPLE
    Test-OGPSite
    #>
    [CmdletBinding()]
    param([string]$WorkspaceRoot=$PWD.Path,[string]$PlatformPath)
    $context=New-OGPContext $WorkspaceRoot $PlatformPath
    foreach ($target in @('preview','production')) {
        $output='.processing/contributor/'+[guid]::NewGuid().ToString('N')
        & $context.Build { param($r,$o,$t) Invoke-GuideSiteBuild -WorkspaceRoot $r -Stage All -Target $t -OutputPath $o } $context.WorkspaceRoot $output $target
    }
}

function Show-OGPSite {
    <# .SYNOPSIS
    Open a local preview server for inspecting the website; stop with Ctrl+C.
    .EXAMPLE
    Show-OGPSite
    #>
    [CmdletBinding()]
    param([string]$WorkspaceRoot=$PWD.Path,[string]$PlatformPath)
    $context=New-OGPContext $WorkspaceRoot $PlatformPath
    $output='.processing/contributor/'+[guid]::NewGuid().ToString('N')
    & $context.Build { param($r,$o) Invoke-GuideSiteBuild -WorkspaceRoot $r -Stage Serve -Target preview -OutputPath $o } $context.WorkspaceRoot $output
}
