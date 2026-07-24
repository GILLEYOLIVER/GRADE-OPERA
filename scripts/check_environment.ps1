$ErrorActionPreference = "Stop"

$utf8 = [System.Text.UTF8Encoding]::new($false)
[Console]::InputEncoding = $utf8
[Console]::OutputEncoding = $utf8
$OutputEncoding = $utf8

Write-Host "GRADE OPERA - Verificação do ambiente" -ForegroundColor Cyan

$flutterCommand = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutterCommand) {
    Write-Host "ERRO: Flutter não foi encontrado no PATH." -ForegroundColor Red
    Write-Host "Instale o Flutter SDK e adicione a pasta 'flutter\bin' ao PATH."
    Write-Host "Guia oficial: https://docs.flutter.dev/get-started/install/windows/desktop"
    exit 1
}

Write-Host "Flutter encontrado em: $($flutterCommand.Source)" -ForegroundColor Green
flutter --version
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: O comando 'flutter --version' falhou." -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host "`nDiagnóstico detalhado:" -ForegroundColor Cyan
flutter doctor -v
$doctorExitCode = $LASTEXITCODE

Write-Host "`nDispositivos disponíveis:" -ForegroundColor Cyan
flutter devices

$developerMode = $null
try {
    $developerMode = Get-ItemPropertyValue `
        -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" `
        -Name "AllowDevelopmentWithoutDevLicense" `
        -ErrorAction Stop
}
catch {
    $developerMode = $null
}
if ($developerMode -ne 1) {
    Write-Host "`nATENÇÃO: o Modo de Desenvolvedor do Windows está desativado." -ForegroundColor Yellow
    Write-Host "O Flutter precisa dele para compilar plugins no Windows."
    Write-Host "Abra Configurações > Sistema > Avançado > Para desenvolvedores."
    Write-Host "Atalho: start ms-settings:developers"
}

if ($doctorExitCode -ne 0) {
    Write-Host "`nO Flutter foi encontrado, mas há componentes pendentes no ambiente." -ForegroundColor Yellow
    exit $doctorExitCode
}

if ($developerMode -ne 1) {
    Write-Host "`nO ambiente ainda precisa do Modo de Desenvolvedor para compilar o aplicativo." -ForegroundColor Yellow
    exit 1
}

Write-Host "`nAmbiente pronto para o GRADE OPERA." -ForegroundColor Green
