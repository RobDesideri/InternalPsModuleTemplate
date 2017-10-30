if (-not $(Get-Module -Name "PSScriptAnalyzer" -ListAvailable -All)) {
  Write-Verbose "Installing latest version of PSScriptAnalyzer"
  Install-Module "PSScriptAnalyzer" -Force -Scope CurrentUser
}

$excludeRules = $(ConvertFrom-Json $(Get-content "$PSScriptRoot\test.cfg.json" -Raw)).Static.excludeRules

Describe "Code static analysis by PSScriptAnalyzer" -Tag Static, Deploy {

  $Rules = Get-ScriptAnalyzerRule
  $scripts = Get-ChildItem $PSScriptRoot\..\src -Include *.ps1, *.psm1, *.psd1 -Recurse |
    Where-Object fullname -notmatch '\\classes\\'

  foreach ( $Script in $scripts ) {
    Context "Script '$($script.FullName)'" {
      foreach ( $rule in $rules ) {
        if (-not $($excludeRules -contains $rule.RuleName)) { 
          It "Rule [$rule]" {
            (Invoke-ScriptAnalyzer -Path $script.FullName -IncludeRule $rule.RuleName ).Count | Should Be 0
          }
        }
      }
    }
  }
}