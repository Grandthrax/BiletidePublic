<#
.SYNOPSIS
Creates Markdown image links for the files in a repository folder.

.EXAMPLE
.\Generate-MarkdownImageList.ps1 0.3.6

.EXAMPLE
.\Generate-MarkdownImageList.ps1 'Press Pack' -Recurse > press-pack.md
#>
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Folder,

    [switch]$Recurse,

    [string]$RawBaseUrl = 'https://raw.githubusercontent.com/Grandthrax/BiletidePublic/main'
)

$ErrorActionPreference = 'Stop'

$repositoryRoot = [System.IO.Path]::GetFullPath($PSScriptRoot)
$folderPath = [System.IO.Path]::GetFullPath((Join-Path $repositoryRoot $Folder))

if (-not (Test-Path -LiteralPath $folderPath -PathType Container)) {
    throw "Folder not found: $Folder"
}

$rootWithSeparator = $repositoryRoot.TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
$isRepositoryRoot = $folderPath.Equals($repositoryRoot, [System.StringComparison]::OrdinalIgnoreCase)
$isInsideRepository = $folderPath.StartsWith($rootWithSeparator, [System.StringComparison]::OrdinalIgnoreCase)
if (-not ($isRepositoryRoot -or $isInsideRepository)) {
    throw "The folder must be inside the repository: $repositoryRoot"
}

function ConvertTo-UrlPath {
    param([Parameter(Mandatory = $true)][string]$Path)

    return (($Path -split '[\\/]') | ForEach-Object {
        [Uri]::EscapeDataString($_)
    }) -join '/'
}

$getChildItemParameters = @{
    LiteralPath = $folderPath
    File        = $true
}

if ($Recurse) {
    $getChildItemParameters.Recurse = $true
}

Get-ChildItem @getChildItemParameters |
    Sort-Object FullName |
    ForEach-Object {
        $relativePath = $_.FullName.Substring($repositoryRoot.Length).TrimStart('\', '/')
        $urlPath = ConvertTo-UrlPath $relativePath
        $words = $_.BaseName.Replace('_', ' ').ToLowerInvariant()
        $title = [System.Globalization.CultureInfo]::InvariantCulture.TextInfo.ToTitleCase($words)

        "![$title]($($RawBaseUrl.TrimEnd('/'))/$urlPath)"
    }
