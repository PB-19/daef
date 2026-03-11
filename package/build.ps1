param(
    [switch]$Publish
)

if (Test-Path dist) {
    Remove-Item -Recurse -Force dist
}

python -m build

if ($Publish) {
    twine upload dist/*
}
