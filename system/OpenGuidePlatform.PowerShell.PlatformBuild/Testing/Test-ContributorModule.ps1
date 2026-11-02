#Requires -Version 7.4
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$WorkspaceRoot,
    [Parameter(Mandatory)][string]$CandidateRoot,
    [Parameter(Mandatory)][string]$OutputPath,
    [switch]$Install
)
$ErrorActionPreference='Stop'
$scratch=Join-Path $WorkspaceRoot "$OutputPath/module-install-$([guid]::NewGuid().ToString('N'))"
[IO.Directory]::CreateDirectory("$scratch/feed")|Out-Null
[IO.Directory]::CreateDirectory("$scratch/staging")|Out-Null
[IO.Directory]::CreateDirectory("$scratch/saved")|Out-Null
Copy-Item "$CandidateRoot/system/OpenGuidePlatform.PowerShell.Contributor" "$scratch/staging/OpenGuidePlatform" -Recurse
$identity=Get-Content "$scratch/staging/OpenGuidePlatform/ogp-module.json" -Raw|ConvertFrom-Json
$repository='OGPTest'+[guid]::NewGuid().ToString('N')
$installedPath=$null
$site=$null
$priorProxy=$env:GOPROXY;$priorSumDb=$env:GOSUMDB;$priorGoCache=$env:GOMODCACHE
$priorModulePath=$env:PSModulePath
try {
    Import-Module PowerShellGet -MinimumVersion 2.2.5 -ErrorAction Stop
    Register-PSRepository -Name $repository -SourceLocation "$scratch/feed" -PublishLocation "$scratch/feed" -InstallationPolicy Trusted
    # The disposable feed also supplies the real YAML dependency, avoiding a
    # hidden dependence on the machine's existing modules or Gallery downloads.
    $yaml=Get-Module -ListAvailable powershell-yaml|Where-Object Version -GE ([version]'0.4.12')|Sort-Object Version -Descending|Select-Object -First 1
    if(-not $yaml){throw 'Install the platform test dependencies first.'}
    Publish-Module -Path $yaml.ModuleBase -Repository $repository -NuGetApiKey 'local-test-only' -ErrorAction Stop
    & "$PSScriptRoot/../Release/Publish-ContributorModule.ps1" -ModulePath "$scratch/staging/OpenGuidePlatform" -ExpectedVersion $identity.version -ExpectedCommit $identity.sourceCommit -Repository $repository -NuGetApiKey 'local-test-only'
    Save-Module -Name OpenGuidePlatform -RequiredVersion $identity.galleryVersion -AllowPrerelease -Repository $repository -Path "$scratch/saved" -ErrorAction Stop
    $savedManifest=Get-ChildItem "$scratch/saved/OpenGuidePlatform" -Filter OpenGuidePlatform.psd1 -Recurse|Select-Object -First 1
    if(-not $savedManifest){throw 'Feed restoration did not produce an installable module.'}
    $installedManifest=$savedManifest.FullName
    if($Install){
        # Optional real AllUsers install is deliberately refused if it would
        # replace any developer installation. Normal builds use isolated Save.
        if(Get-Module -ListAvailable OpenGuidePlatform){throw 'A contributor module is already installed. Use a clean account for -Install verification.'}
        Install-Module -Name OpenGuidePlatform -RequiredVersion $identity.galleryVersion -AllowPrerelease -Repository $repository -Scope AllUsers -ErrorAction Stop
        $installed=Get-InstalledModule OpenGuidePlatform -RequiredVersion $identity.galleryVersion -AllowPrerelease -ErrorAction Stop
        $installedPath=$installed.InstalledLocation
        $installedManifest=Join-Path $installedPath 'OpenGuidePlatform.psd1'
    }
    Remove-Module powershell-yaml -Force -ErrorAction SilentlyContinue
    Remove-Module OpenGuidePlatform -Force -ErrorAction SilentlyContinue
    $installationRoot=Split-Path (Split-Path (Split-Path $installedManifest -Parent) -Parent) -Parent
    $env:PSModulePath=$installationRoot+[IO.Path]::PathSeparator+"$scratch/saved"+[IO.Path]::PathSeparator+(Join-Path $PSHOME 'Modules')
    $restoredIdentity=Get-Content (Join-Path (Split-Path $installedManifest) 'ogp-module.json') -Raw|ConvertFrom-Json
    if($restoredIdentity.galleryVersion -cne $identity.galleryVersion -or $restoredIdentity.sourceCommit -cne $identity.sourceCommit){throw 'Installed module identity differs from the candidate.'}
    # A real Git history fixture must be outside every repository checkout.
    # It is disposable test data, never a branch/worktree of the platform.
    $site=Join-Path ([IO.Path]::GetTempPath()) ('ogp-module-site-'+[guid]::NewGuid().ToString('N'))
    [IO.Directory]::CreateDirectory($site)|Out-Null
    Copy-Item "$WorkspaceRoot/examples/reference-guide-site" "$site/site" -Recurse
    & git init -q $site
    if($LASTEXITCODE -ne 0){throw 'Cannot initialise the disposable Git fixture.'}
    $fixtureRoot=(& git -C $site rev-parse --show-toplevel).Trim()
    if($LASTEXITCODE -ne 0 -or [IO.Path]::GetFullPath($fixtureRoot) -ne [IO.Path]::GetFullPath($site)){throw 'Git history fixture does not own its intended temporary root.'}
    & git -C $site add -- site
    if($LASTEXITCODE -ne 0){throw 'Cannot stage the disposable Git fixture.'}
    & git -C $site -c user.name=OGPModuleTest -c user.email=module-test@example.invalid commit -qm baseline
    if($LASTEXITCODE -ne 0){throw 'Cannot establish the disposable source-comparison history fixture.'}
    $baseline=(& git -C $site rev-parse HEAD).Trim()
    $runtime=Join-Path $WorkspaceRoot "$OutputPath/OpenGuidePlatform-GuideSite.zip"
    $release=Get-Content (Join-Path $WorkspaceRoot "$OutputPath/release-manifest.json") -Raw|ConvertFrom-Json
    # Supply a real native Go dependency through a disposable file proxy. This
    # permits the normal locked-release route, without replacements, network,
    # resolver mocks, changed consumer sites, or claiming remote publication.
    $canonical=[string]$release.nativeHugoModule.path;$tag=[string]$release.nativeHugoModule.version
    $escaped=[regex]::Replace($canonical,'[A-Z]',{param($m)'!'+$m.Value.ToLowerInvariant()})
    $proxy="$scratch/go-proxy";$versions="$proxy/$escaped/@v"
    [IO.Directory]::CreateDirectory($versions)|Out-Null
    $native="$CandidateRoot/system/OpenGuidePlatform.Hugo.Guides"
    Copy-Item "$native/go.mod" "$versions/$tag.mod"
    @{Version=$tag;Time='2020-01-01T00:00:00Z'}|ConvertTo-Json|Set-Content "$versions/$tag.info"
    [IO.File]::WriteAllText("$versions/list","$tag`n")
    $zip=[IO.Compression.ZipFile]::Open("$versions/$tag.zip",[IO.Compression.ZipArchiveMode]::Create)
    try { foreach($file in Get-ChildItem $native -File -Recurse){
        $relative=[IO.Path]::GetRelativePath($native,$file.FullName).Replace('\','/')
        $null=[IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip,$file.FullName,"$canonical@$tag/$relative")
    }} finally {$zip.Dispose()}
    $env:GOPROXY=([uri]([IO.Path]::GetFullPath($proxy)+[IO.Path]::DirectorySeparatorChar)).AbsoluteUri
    $env:GOSUMDB='off';$env:GOMODCACHE="$scratch/go-cache"
    [IO.File]::AppendAllText("$site/site/go.mod","`nrequire $canonical $tag`n")
    & go -C "$site/site" mod download $canonical
    if($LASTEXITCODE -ne 0){throw 'Local native-module fixture restoration failed.'}
    [IO.Directory]::CreateDirectory("$site/.OpenGuidePlatform")|Out-Null
    @{releaseTag=$tag;release=$release}|ConvertTo-Json -Depth 50|Set-Content "$site/.OpenGuidePlatform/installation.json"
    $cache="$site/.processing/platform-cache/$($release.packages.GuideSite.sha256)"
    [IO.Directory]::CreateDirectory($cache)|Out-Null
    Copy-Item $runtime "$cache/OpenGuidePlatform-GuideSite.zip"
    $task=@{WorkspaceRoot=$site}
    $work=Get-OGPTranslationStatus @task -Language min
    # Calling the task itself must autoload the installed module; contributors
    # do not discover a manifest path or issue an Import-Module command.
    $module=Get-Module OpenGuidePlatform
    $expectedModule=Join-Path (Split-Path $installedManifest) 'OpenGuidePlatform.psm1'
    $comparison=if($IsWindows){[StringComparison]::OrdinalIgnoreCase}else{[StringComparison]::Ordinal}
    if(-not $module -or -not $module.Path.Equals($expectedModule,$comparison)){throw 'Task autoload did not select the feed-restored contributor module.'}
    $dependency=Get-Module powershell-yaml
    $dependencyRoot=if($Install){$installationRoot}else{"$scratch/saved"}
    if(-not $dependency -or -not $dependency.ModuleBase.StartsWith([IO.Path]::GetFullPath($dependencyRoot),$comparison)){throw 'The clean module environment did not load YAML from the tested installation scope.'}
    $selection=$work.Guides|Where-Object { $_.State -eq 'populated' -and $_.Intent -eq 'web' }|Select-Object -First 1
    if(-not $selection){throw 'Sample requires an existing web translation.'}
    $argsForTranslation=@{GuideId=$selection.GuideId;EditionId=$selection.EditionId;Language='min'}
    $production="$site/site/hugo.production.yaml"
    $productionHash=(Get-FileHash $production).Hash
    $target=Join-Path $site $selection.TargetPath
    $before=(Get-FileHash $target).Hash
    [IO.File]::AppendAllText((Join-Path $site $selection.SourcePath),"`n`nModule source comparison acceptance note.`n")
    $draft=New-OGPTranslationDraft @task @argsForTranslation -SourceRevision $baseline
    if($draft.ComparisonCommit -cne $baseline -or [IO.File]::ReadAllText($draft.SourceDifferencePath) -notmatch 'Module source comparison acceptance note'){throw 'The installed command did not retain the selected historical source comparison.'}
    [IO.File]::AppendAllText($draft.Path,"`n`nInstalled contributor module acceptance note.`n")
    $preview=Save-OGPDraft @task -Path $draft.Path -Reviewed -WhatIf
    if($preview.Status -ne 'planned' -or (Get-FileHash $target).Hash -cne $before){throw 'Installed draft preview changed the target or did not plan the update.'}
    $saved=Save-OGPDraft @task -Path $draft.Path -Reviewed
    if($saved.Status -ne 'updated' -or (Get-FileHash $target).Hash -ceq $before -or $saved.Comparison.Commit -cne $baseline){throw 'Installed draft application or retained source comparison failed.'}
    $refused=$false
    try { Save-OGPDraft @task -Path $draft.Path -Reviewed | Out-Null } catch { $refused=$_.Exception.Message -like '*changed since this draft*' }
    if(-not $refused){throw 'Installed command accepted stale draft evidence.'}
    $wrapper=New-OGPWrapperDraft @task -Language min -RelativePath 'site/content/_index.min.md'
    [IO.File]::AppendAllText($wrapper.Path,"`n`nInstalled website draft acceptance note.`n")
    Save-OGPDraft @task -Path $wrapper.Path -Reviewed -WhatIf | Out-Null
    Save-OGPDraft @task -Path $wrapper.Path -Reviewed | Out-Null
    $credits=Get-OGPCredits @task @argsForTranslation
    $creditFiles=@($credits.Files|Where-Object { $_ -match '\.min\.ya?ml$' })
    if($creditFiles.Count -ne 1){throw 'Sample requires one existing translation-team credit file.'}
    $creditFile=Join-Path $site $creditFiles[0]
    $originalCredit=[IO.File]::ReadAllBytes($creditFile)
    # Keep the sample's actual encoding. BOM preservation has separate Core
    # regression coverage; Hugo's data decoder rejects a synthetic BOM here.
    New-OGPContribution @task @argsForTranslation -Name 'Module acceptance reviewer' -Role reviewer -GitHubUsername ogp-module-acceptance -ConsentConfirmed -WhatIf | Out-Null
    if([Convert]::ToBase64String([IO.File]::ReadAllBytes($creditFile)) -cne [Convert]::ToBase64String($originalCredit)){throw 'Credit preview changed existing bytes.'}
    New-OGPContribution @task @argsForTranslation -Name 'Module acceptance reviewer' -Role reviewer -GitHubUsername ogp-module-acceptance -ConsentConfirmed | Out-Null
    $appendedCredit=[IO.File]::ReadAllBytes($creditFile)
    if($appendedCredit.Length -lt $originalCredit.Length -or [Convert]::ToBase64String($appendedCredit,0,$originalCredit.Length) -cne [Convert]::ToBase64String($originalCredit)){throw 'Appending a credit changed existing bytes or the BOM.'}
    $afterCredits=Get-OGPCredits @task @argsForTranslation
    if(-not @($afterCredits.Translators|Where-Object { $_.name -eq 'Module acceptance reviewer' -and $_.role -eq 'reviewer' }).Count){throw 'Translation reviewer is missing from the credit inspection result.'}
    if((Get-FileHash $production).Hash -cne $productionHash){throw 'Contributor workflow changed production configuration.'}
    Test-OGPSite @task
    # Verify the actual viewing command, not merely its delegation to Serve.
    $serveScript="$scratch/serve.ps1"
    [IO.File]::WriteAllText($serveScript,@'
param([string]$ModuleManifest,[string]$SiteRoot)
$ErrorActionPreference='Stop'
Import-Module $ModuleManifest -Force
Show-OGPSite -WorkspaceRoot $SiteRoot
'@)
    $shell=Join-Path $PSHOME $(if($IsWindows){'pwsh.exe'}else{'pwsh'})
    $start=@{FilePath=$shell;ArgumentList=@('-NoProfile','-NonInteractive','-File',('"'+$serveScript+'"'),'-ModuleManifest',('"'+$installedManifest+'"'),'-SiteRoot',('"'+$site+'"'));WorkingDirectory=$site;RedirectStandardOutput="$scratch/serve.log";RedirectStandardError="$scratch/serve-error.log";PassThru=$true}
    if($IsWindows){$start.WindowStyle='Hidden'}
    $server=Start-Process @start
    try {
        $deadline=[DateTime]::UtcNow.AddSeconds(60);$previewUrl=$null
        while([DateTime]::UtcNow -lt $deadline -and -not $server.HasExited){
            $text=''
            if(Test-Path "$scratch/serve.log"){
                # Start-Process retains a writer. Permit its write access while
                # reading the live log, rather than opening it with ReadAllText.
                $stream=[IO.File]::Open("$scratch/serve.log",[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::ReadWrite)
                $reader=[IO.StreamReader]::new($stream)
                try {$text=$reader.ReadToEnd()} finally {$reader.Dispose()}
            }
            if($text -match 'Web Server is available at (https?://\S+)'){$previewUrl=$Matches[1];break}
            Start-Sleep -Milliseconds 200
        }
        if(-not $previewUrl){throw "Show-OGPSite did not start its local server. Inspect $scratch/serve-error.log and serve.log."}
        $address=[uri]$previewUrl
        if($address.Host -notin @('localhost','127.0.0.1','::1')){throw 'Local preview advertised a non-loopback address.'}
        $response=Invoke-WebRequest $previewUrl -TimeoutSec 10
        if($response.StatusCode -ne 200 -or $response.Content -notmatch '<html'){throw 'The local preview did not serve the rendered website.'}
    } finally {
        if(-not $server.HasExited){$server.Kill($true);$null=$server.WaitForExit(5000)}
        $server.Dispose()
    }
    [ordered]@{schemaVersion=1;outcome='pass';modulePath=$module.Path;dependencyModulePath=$dependency.ModuleBase;galleryVersion=$identity.galleryVersion;ogpVersion=$identity.version;sourceCommit=$identity.sourceCommit;sourceComparisonCommit=$baseline;allUsersInstall=[bool]$Install;runtimeTransport='site installation record and cached ZIP; native module via local Go proxy';visualApproval=$false;checks=@('local feed publication','Save-Module with dependency','task command autoload without Import-Module',$(if($Install){'AllUsers YAML dependency'}else{'feed-restored YAML dependency'}),'normal site-selected runtime loading','real Prepare and discovery','historical source comparison retained through save','translation draft WhatIf and apply','stale draft refusal','website draft WhatIf and apply','credit WhatIf and apply; existing bytes preserved','reviewer inspection','production configuration preserved','preview and production builds','Show-OGPSite local HTTP response')}|ConvertTo-Json -Depth 5|Set-Content "$scratch/result.json"
    Write-Host "PASS contributor module feed and task acceptance. Evidence: $scratch/result.json"
} finally {
    $env:GOPROXY=$priorProxy;$env:GOSUMDB=$priorSumDb;$env:GOMODCACHE=$priorGoCache
    $env:PSModulePath=$priorModulePath
    Remove-Module OpenGuidePlatform -ErrorAction SilentlyContinue
    if($installedPath){
        # Delete only this invocation's verified installation, never another
        # version, a parent module directory, or an unverified computed path.
        $absolute=[IO.Path]::GetFullPath($installedPath)
        $parent=Split-Path $absolute -Parent
        $manifest=Join-Path $absolute 'OpenGuidePlatform.psd1'
        if((Split-Path $parent -Leaf) -cne 'OpenGuidePlatform' -or (Import-PowerShellDataFile $manifest).GUID -cne '6121c008-4c93-4af2-9daf-bd66b00e9e59' -or (Get-Content "$absolute/ogp-module.json" -Raw|ConvertFrom-Json).sourceCommit -cne $identity.sourceCommit){throw 'Refusing cleanup of an unverified module installation.'}
        Uninstall-Module -Name OpenGuidePlatform -RequiredVersion $identity.galleryVersion -AllowPrerelease -Force -ErrorAction Stop
    }
    Unregister-PSRepository -Name $repository -ErrorAction SilentlyContinue
    if($site){
        $absolute=[IO.Path]::GetFullPath($site)
        if([IO.Path]::GetDirectoryName($absolute) -cne [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('/','\') -or [IO.Path]::GetFileName($absolute) -cnotmatch '^ogp-module-site-[a-f0-9]{32}$'){throw 'Refusing cleanup outside the owned temporary Git fixture.'}
        if(Test-Path -LiteralPath $absolute){Remove-Item -LiteralPath $absolute -Recurse -Force}
    }
}
