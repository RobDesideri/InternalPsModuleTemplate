param(
  [array]$PesterTagToExecute
)

$root = Split-Path $PSScriptRoot -Parent

$moduleName = '<%= $PLASTER_PARAM_ModuleName %>'
Get-Module $moduleName | Remove-Module
Import-Module $root\$moduleName.psd1 -ErrorAction Stop

$params = @{
  Script = "$root\tests"
}
if ($PesterTagToExecute) {
  $params.Add("Tag", $PesterTagToExecute)
}

Invoke-Pester @params