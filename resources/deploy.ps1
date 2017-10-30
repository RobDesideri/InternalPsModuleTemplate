param(
  [string]$DeployDirPath,
  [version]$Version,
  [switch]$NoVersionDirInDeploy
)

$srcPath = "$PSScriptRoot\src"
$moduleName = '<%= $PLASTER_PARAM_ModuleName %>'
$manifestObj = Import-PowerShellDataFile "$srcPath\$moduleName.psd1"

$script:moduleData = @{
  code = ''
  functions = @()
}

function GetModuleData () {
  $functionFolders = @('public', 'private', 'classes')
  $moduleContent = ''
  $publicFunctions = @()
  
  ForEach ($folder in $functionFolders) {
    $folderPath = Join-Path -Path $srcPath -ChildPath $folder
    If (Test-Path -Path $folderPath) {
      Write-Verbose -Message "Importing from $folder"
      $functions = Get-ChildItem -Path $folderPath -Filter '*.ps1' -Recurse -File
      ForEach ($function in $functions) {
        Write-Verbose -Message "  Importing $($function.BaseName)"
        $moduleContent += $(Get-Content $($function.FullName) -Raw).Trim()
        $moduleContent += "`n`n"
        if ($folder -eq 'public') { $publicFunctions += $function.BaseName }
      }
    }
  }
  $script:moduleData.code = $moduleContent.Trim()
  $script:moduleData.functions = $publicFunctions
}

if ([version]$manifestObj.ModuleVersion -ge $Version) {
  throw "Version '$Version' cannot be equal or lower to the existing version '$($manifestObj.ModuleVersion)'"
}

$firstExecution = $false

# Check deploy dir
if (-not(Test-Path $DeployDirPath)) {
  New-Item -Path $DeployDirPath -ItemType Directory -Force -ErrorAction Stop | Out-Null
  $firstExecution = $true
}

$deployDir = $DeployDirPath

# If enabled, create deploy dir by version
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

GetModuleData

# Set the module script
New-Item "$deployDir\$moduleName.psm1" -ItemType File -Value $script:moduleData.code | Out-Null

# Update manifest version
$manifestObj.ModuleVersion = $Version

# Update manifest file in src
Remove-Item "$srcPath\$moduleName.psd1" -Force | Out-Null
New-ModuleManifest "$srcPath\$moduleName.psd1" @manifestObj | Out-Null

# Update manifest functions to export
$manifestObj.FunctionsToExport = $script:moduleData.functions

# Create manifest file in deploy dir
New-ModuleManifest "$deployDir\$moduleName.psd1" @manifestObj | Out-Null

# Copy module resources
Copy-Item "$srcPath\resources" $deployDir | Out-Null