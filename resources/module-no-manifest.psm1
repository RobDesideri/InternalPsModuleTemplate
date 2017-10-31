[version]$script:ModuleVersion = '<%= $PLASTER_PARAM_ModuleVersion %>'
[string]$script:Author = '<%= $PLASTER_PARAM_AuthorName %>'
[string]$script:AuthorEmail = '<%= $PLASTER_PARAM_AuthorEmail %>'

$functionFolders = @('public', 'private', 'classes')
ForEach ($folder in $functionFolders)
{
    $folderPath = Join-Path -Path "$PSScriptRoot\src" -ChildPath $folder
    If (Test-Path -Path $folderPath)
    {
        Write-Verbose -Message "Importing from $folder"
        $functions = Get-ChildItem -Path $folderPath -Filter '*.ps1'
        ForEach ($function in $functions)
        {
            Write-Verbose -Message "  Importing $($function.BaseName)"
            . $($function.FullName)
        }
    }
}
$publicFunctions = (Get-ChildItem -Path "$PSScriptRoot\src\public" -Filter '*.ps1' -Recurse).BaseName
Export-ModuleMember -Function $publicFunctions