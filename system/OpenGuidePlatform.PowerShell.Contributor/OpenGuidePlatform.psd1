@{
    RootModule = 'OpenGuidePlatform.psm1'
    ModuleVersion = '0.0.0'
    GUID = '6121c008-4c93-4af2-9daf-bd66b00e9e59'
    Author = 'OpenGuidePlatform contributors'
    CompanyName = 'naked Agility'
    Copyright = '(c) OpenGuidePlatform contributors. MIT License.'
    Description = 'Contributor tasks using the OpenGuidePlatform release selected by your guide site.'
    PowerShellVersion = '7.4'
    RequiredModules = @(@{ModuleName='powershell-yaml';ModuleVersion='0.4.12'})
    FunctionsToExport = @('Get-OGPTranslationStatus','New-OGPTranslation','New-OGPTranslationDraft','New-OGPWrapperDraft','Save-OGPDraft','Get-OGPCredits','New-OGPContribution','Get-OGPPdfPlan','New-OGPPdf','Test-OGPSite','Show-OGPSite')
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{ PSData = @{
        Tags = @('OpenGuidePlatform','Translation','Hugo')
        LicenseUri = 'https://github.com/nkdAgility/OpenGuidePlatform/blob/main/LICENSE'
        ProjectUri = 'https://github.com/nkdAgility/OpenGuidePlatform'
    }}
}
