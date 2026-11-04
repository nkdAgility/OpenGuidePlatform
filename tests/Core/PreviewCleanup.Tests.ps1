BeforeAll {
    $root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    . "$root/system/OpenGuidePlatform.PowerShell.GuideSiteBuild/GitHubActions/GuidePreviewCleanup.ps1"
}
Describe 'Obsolete preview cleanup selection' {
    BeforeEach {
        $priorToken=$env:GH_TOKEN;$env:GH_TOKEN='test-only'
        $script:pr=@{number=58;state='closed';base=@{repo=@{full_name='nkdAgility/OpenGuidePlatform'}};head=@{repo=@{full_name='nkdAgility/OpenGuidePlatform'}}}
        Mock Invoke-RestMethod { $script:pr }
    }
    AfterEach {$env:GH_TOKEN=$priorToken}
    It 'selects the exact closed same-repository PR number' {
        Resolve-GuidePreviewCleanup -Repository nkdAgility/OpenGuidePlatform -PullRequest 58 | Should -BeExactly '58'
        Should -Invoke Invoke-RestMethod -Times 1 -ParameterFilter {$Uri -ceq 'https://api.github.com/repos/nkdAgility/OpenGuidePlatform/pulls/58'}
    }
    It 'rejects an open PR' {
        $script:pr.state='open'
        {Resolve-GuidePreviewCleanup -Repository nkdAgility/OpenGuidePlatform -PullRequest 58}|Should -Throw '*exact closed*'
    }
    It 'rejects a fork PR' {
        $script:pr.head.repo.full_name='someone/OpenGuidePlatform'
        {Resolve-GuidePreviewCleanup -Repository nkdAgility/OpenGuidePlatform -PullRequest 58}|Should -Throw '*exact closed*'
    }
    It 'rejects a different returned PR identity' {
        $script:pr.number=57
        {Resolve-GuidePreviewCleanup -Repository nkdAgility/OpenGuidePlatform -PullRequest 58}|Should -Throw '*exact closed*'
    }
    It 'rejects arbitrary and production environment names before API access' {
        foreach($value in @('production','preview','0','058','58/../production',"58`nproduction")){
            {Resolve-GuidePreviewCleanup -Repository nkdAgility/OpenGuidePlatform -PullRequest $value}|Should -Throw
        }
        Should -Invoke Invoke-RestMethod -Times 0
    }
    It 'fails closed when GitHub validation is unavailable' {
        Mock Invoke-RestMethod {throw 'API unavailable'}
        {Resolve-GuidePreviewCleanup -Repository nkdAgility/OpenGuidePlatform -PullRequest 58}|Should -Throw '*API unavailable*'
    }
}
