param(
  [array]$PesterTagToExecute
)

$moduleName = '<%= $PLASTER_PARAM_ModuleName %>'
Get-Module $moduleName | Remove-Module
Import-Module $PSScriptRoot\src\$moduleName.psd1 -ErrorAction Stop

$params = @{
  Script = "$PSScriptRoot\tests"
}
if ($PesterTagToExecute) {
  $params.Add("Tag", $PesterTagToExecute)
}

Invoke-Pester @params