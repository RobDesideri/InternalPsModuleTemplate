param(
  [string]$DeployDirPath,
  [version]$Version,
  [switch]$NoVersionDirInDeploy
)

$srcPath = "$PSScriptRoot\src"
$moduleName = '<%= $PLASTER_PARAM_ModuleName %>'

function GetModuleCode () {
  $functionFolders = @('public', 'private', 'classes')
  $moduleCode = ''

  ForEach ($folder in $functionFolders) {
    $folderPath = Join-Path -Path $srcPath -ChildPath $folder
    If (Test-Path -Path $folderPath) {
      Write-Verbose -Message "Importing from $folder"
      $functions = Get-ChildItem -Path $folderPath -Filter '*.ps1' -Recurse -File
      ForEach ($function in $functions) {
        Write-Verbose -Message "  Importing $($function.BaseName)"
        $moduleCode += $(Get-Content $($function.FullName) -Raw).Trim()
        $moduleCode += "`n`n"
      }
    }
  }
  return $($moduleCode.Trim())
}

# Check version
$manifestObj = Import-PowerShellDataFile "$PSScriptRoot\$moduleName.psd1"
$lastVersion = [version]$manifestObj.ModuleVersion
if ($lastVersion -ge $Version) {
  throw "Version '$Version' cannot be equal or lower to the existing version '$($manifestObj.ModuleVersion)'"
}

# Check deploy dir
$firstExecution = $false
if (-not(Test-Path $DeployDirPath)) {
  New-Item -Path $DeployDirPath -ItemType Directory -Force -ErrorAction Stop | Out-Null
  $firstExecution = $true
}

# If enabled, create deploy dir by version
$deployDir = $DeployDirPath
if (-not ($NoVersionDirInDeploy)) {
  $deployDir = "$DeployDirPath\$($Version.ToString())"
  if (Test-Path $deployDir) {
    throw "Version '$Version' already exists in deploy path."
  }
  else {
    New-Item -Path $deployDir -ItemType Directory -Force -ErrorAction Stop | Out-Null
  }
}
# else clean the main deploy dir
elseif (-not ($firstExecution)) {
  Remove-Item -Path $deployDir -Recurse -Force -ErrorAction Stop | Out-Null
  New-Item -Path $deployDir -Force -ErrorAction Stop | Out-Null
}

# Update version in both src and deploy manifest file
$manifestObj.ModuleVersion = $Version
Remove-Item "$PSScriptRoot\$moduleName.psd1" -Force | Out-Null
New-ModuleManifest "$PSScriptRoot\$moduleName.psd1" @manifestObj | Out-Null

# Get joined code for module creation
$moduleCode = GetModuleCode

# Update functions to export
$publicFunctions = (Get-ChildItem -Path "$srcPath\public" -Filter '*.ps1' -Recurse).BaseName
$manifestObj.FunctionsToExport = $publicFunctions

# Write out the module script
New-Item "$deployDir\$moduleName.psm1" -ItemType File -Value $moduleCode | Out-Null

# Write out manifest file in deploy dir
New-ModuleManifest "$deployDir\$moduleName.psd1" @manifestObj | Out-Null

# Copy module resources
if (Test-Path "$srcPath\resources") {
  if ($(Get-ChildItem "$srcPath\resources").Length -gt 1 ) {
    Copy-Item "$srcPath\resources" $deployDir | Out-Null
  }
}