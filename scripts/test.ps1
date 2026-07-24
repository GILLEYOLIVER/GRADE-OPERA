$ErrorActionPreference = "Stop"

$utf8 = [System.Text.UTF8Encoding]::new($false)
[Console]::InputEncoding = $utf8
[Console]::OutputEncoding = $utf8
$OutputEncoding = $utf8

Write-Host "GRADE OPERA - Análise e testes" -ForegroundColor Cyan

$flutterCommand = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutterCommand) {
    Write-Host "ERRO: Flutter não foi encontrado no PATH." -ForegroundColor Red
    exit 1
}

$flutterRoot = Split-Path (Split-Path $flutterCommand.Source -Parent) -Parent
$dartCommand = Join-Path $flutterRoot "bin\dart.bat"
$env:FLUTTER_ROOT = $flutterRoot

& $dartCommand pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: Falha ao obter dependências." -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host "`nExecutando análise estática..." -ForegroundColor Cyan
& $dartCommand analyze
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: A análise estática encontrou problemas." -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host "`nExecutando todos os testes..." -ForegroundColor Cyan
flutter test --no-pub
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: Um ou mais testes falharam." -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host "`nAnálise e testes concluídos com sucesso." -ForegroundColor Green
exit 0
