$ErrorActionPreference = "Stop"

$utf8 = [System.Text.UTF8Encoding]::new($false)
[Console]::InputEncoding = $utf8
[Console]::OutputEncoding = $utf8
$OutputEncoding = $utf8

Write-Host "GRADE OPERA - Execução no Windows" -ForegroundColor Cyan

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "ERRO: Flutter não foi encontrado no PATH." -ForegroundColor Red
    Write-Host "Execute .\scripts\check_environment.ps1 para obter instruções."
    exit 1
}

Write-Host "Obtendo dependências compatíveis..." -ForegroundColor Cyan
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: Não foi possível obter as dependências." -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host "Verificando o suporte a Windows desktop..." -ForegroundColor Cyan
flutter config --enable-windows-desktop
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: Não foi possível habilitar o Windows desktop." -ForegroundColor Red
    exit $LASTEXITCODE
}

$deviceList = flutter devices
if ($LASTEXITCODE -ne 0 -or -not ($deviceList -match "Windows")) {
    Write-Host "ERRO: O dispositivo Windows não está disponível no Flutter." -ForegroundColor Red
    Write-Host "Instale o Visual Studio com a carga 'Desenvolvimento para desktop com C++'."
    exit 1
}

Write-Host "Iniciando o GRADE OPERA..." -ForegroundColor Green
flutter run -d windows
exit $LASTEXITCODE
