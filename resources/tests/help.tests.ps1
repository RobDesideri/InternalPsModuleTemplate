$moduleName = '<%= $PLASTER_PARAM_ModuleName %>'
$commands = Get-Command -Module $moduleName -CommandType Cmdlet, Function, Workflow  # Not alias
$excludeRules = $(ConvertFrom-Json $(Get-content "$PSScriptRoot\test.cfg.json" -Raw)).help.excludeFunctions

foreach ($command in $commands) {
  $commandName = $command.Name

  if ($testExceptions -notcontains $commandName) { 
    $help = Get-Help $commandName -ErrorAction SilentlyContinue
    
    Describe 'CBH tests for <%= $PLASTER_PARAM_ModuleName %> module' {
      
      Describe "CBH test for $($command.CommandType) '$commandName'" -Tag Help, Deploy {
        It "should not be auto-generated" {
          $help.Synopsis | Should Not BeLike '*`[`<CommonParameters`>`]*'
        }
        It "gets description for $commandName" {
          $help.Description | Should Not BeNullOrEmpty
        }
        It "gets example code from $commandName" {
          ($help.Examples.Example | Select-Object -First 1).Code | Should Not BeNullOrEmpty
        }
        It "gets example help from $commandName" {
          ($help.Examples.Example.Remarks | Select-Object -First 1).Text | Should Not BeNullOrEmpty
        }
      
        Context "Test parameter help for $commandName" {
          $common = 
          'Debug',
          'ErrorAction', 
          'ErrorVariable', 
          'InformationAction',
          'InformationVariable',
          'OutBuffer',
          'OutVariable',
          'PipelineVariable',
          'Verbose',
          'WarningAction',
          'WarningVariable'
      
          $parameters = $command.ParameterSets.Parameters |
            Sort-Object -Property Name -Unique |
            Where-Object Name -notin $common
  
          $parameterNames = $parameters.Name
          $helpParameterNames = $help.Parameters.Parameter.Name | Sort-Object -Unique
      
          foreach ($parameter in $parameters) {
            $parameterName = $parameter.Name
            $parameterHelp = $help.parameters.parameter | Where-Object Name -EQ $parameterName
      
            It "gets help for parameter: $parameterName : in $commandName" {
              $parameterHelp.Description.Text | Should Not BeNullOrEmpty
            }
      
            It "help for $parameterName parameter in $commandName has correct Mandatory value" {
              $codeMandatory = $parameter.IsMandatory.toString()
              $parameterHelp.Required | Should Be $codeMandatory
            }
      
            It "help for $commandName has correct parameter type for $parameterName" {
              $codeType = $parameter.ParameterType.Name
              # To avoid calling Trim method on a null object.
              $helpType = if ($parameterHelp.parameterValue) { $parameterHelp.parameterValue.Trim() }
              $helpType | Should be $codeType
            }
          }
      
          foreach ($helpParm in $HelpParameterNames) {
            It "finds all help parameter in code: $helpParm" {
              $helpParm -in $parameterNames | Should Be $true
            }
          }
        }
      }
    }
  }
}