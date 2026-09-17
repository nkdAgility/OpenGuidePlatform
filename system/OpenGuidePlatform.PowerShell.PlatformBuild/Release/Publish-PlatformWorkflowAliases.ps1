function Publish-PlatformWorkflowAliases {
    param([string]$WorkspaceRoot,[string]$Repository,[string]$Version,[string]$Commit)
    $versionNumber=[System.Management.Automation.SemanticVersion]$Version
    $suffix=if($versionNumber.PreReleaseLabel){'-preview'}else{''}
    $aliases=@("v$($versionNumber.Major)$suffix","v$($versionNumber.Major).$($versionNumber.Minor)$suffix")
    $raw=& gh api "repos/$Repository/git/matching-refs/tags/v" --paginate --slurp
    if($LASTEXITCODE -ne 0){throw 'Cannot inspect workflow aliases. The immutable release is published; rerun Release to finish alias publication.'}
    $refs=@{}
    foreach($page in @($raw|ConvertFrom-Json)){foreach($item in $page){$refs[$item.ref]=$item}}
    foreach($alias in $aliases){
        $ref="refs/tags/$alias";$prior=if($refs.ContainsKey($ref)){$refs[$ref]}else{$null}
        $expected=if($prior){$prior.object.sha}else{''}
        if($expected -ceq $Commit){continue}
        if($expected){
            $priorVersions=@(foreach($name in $refs.Keys){
                if($refs[$name].object.sha -cne $expected -or $name -cnotmatch '^refs/tags/v[0-9]+\.[0-9]+\.[0-9]+(?:-[A-Za-z0-9.-]+)?$'){continue}
                $prior=[System.Management.Automation.SemanticVersion]$name.Substring(11)
                if([bool]$prior.PreReleaseLabel -eq [bool]$versionNumber.PreReleaseLabel){$prior}
            })
            if(-not $priorVersions.Count){throw "Workflow alias $alias does not identify an immutable release tag. Reconcile it before publishing aliases."}
            if(@($priorVersions|Where-Object {$_ -gt $versionNumber}).Count){Write-Host "Keeping newer workflow alias $alias.";continue}
            $query='query($owner:String!,$name:String!,$ref:String!){repository(owner:$owner,name:$name){id ref(qualifiedName:$ref){target{oid}}}}'
            $owner,$repoName=$Repository.Split('/')
            $result=& gh api graphql -f "query=$query" -f "owner=$owner" -f "name=$repoName" -f "ref=$ref" | ConvertFrom-Json
            if($LASTEXITCODE -ne 0 -or $result.PSObject.Properties['errors'] -or $result.data.repository.ref.target.oid -cne $expected){throw "Workflow alias $alias changed concurrently."}
            $repositoryId=$result.data.repository.id
            if(-not $repositoryId){throw 'Cannot identify the repository for alias publication.'}
            $mutation='mutation{updateRefs(input:{repositoryId:"'+$repositoryId+'",refUpdates:[{name:"'+$ref+'",beforeOid:"'+$expected+'",afterOid:"'+$Commit+'",force:true}]}){clientMutationId}}'
            $response=& gh api graphql -f "query=$mutation" | ConvertFrom-Json
            if($LASTEXITCODE -ne 0 -or -not $response -or $response.PSObject.Properties['errors']){throw "Workflow alias $alias changed concurrently or could not be published."}
        }else{
            $null=& gh api "repos/$Repository/git/refs" --method POST -f "ref=$ref" -f "sha=$Commit"
        }
        if($LASTEXITCODE -ne 0){throw "Workflow alias $alias changed concurrently or could not be published. The release is intact; rerun Release."}
        Write-Host "Published workflow alias $alias -> v$Version."
    }
}
