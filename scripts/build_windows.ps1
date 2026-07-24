$ErrorActionPreference = "Stop"

$utf8 = [System.Text.UTF8Encoding]::new($false)
[Console]::InputEncoding = $utf8
[Console]::OutputEncoding = $utf8
$OutputEncoding = $utf8

Write-Host "GRADE OPERA - Compilação Windows release" -ForegroundColor Cyan

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "ERRO: Flutter não foi encontrado no PATH." -ForegroundColor Red
    exit 1
}

flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: Falha ao obter dependências." -ForegroundColor Red
    exit $LASTEXITCODE
}

flutter analyze
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: Corrija a análise estática antes de compilar." -ForegroundColor Red
    exit $LASTEXITCODE
}

flutter test
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: Corrija os testes antes de compilar." -ForegroundColor Red
    exit $LASTEXITCODE
}

flutter build windows --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: A compilação Windows falhou." -ForegroundColor Red
    exit $LASTEXITCODE
}

$releaseDirectory = Join-Path $PSScriptRoot "..\build\windows\x64\runner\Release"
$resolvedReleaseDirectory = [System.IO.Path]::GetFullPath($releaseDirectory)
Write-Host "`nVersão Windows gerada com sucesso." -ForegroundColor Green
Write-Host "Executável e arquivos necessários: $resolvedReleaseDirectory"
exit 0
