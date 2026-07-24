# Relatório final — GRADE OPERA

Data da validação: 23/07/2026.

## Entrega

O repositório local do GRADE OPERA foi criado com:

- aplicativo Flutter em português do Brasil;
- domínio e algoritmo independentes da interface;
- cálculo assíncrono em isolate;
- valores de comprimento armazenados em micrômetros inteiros;
- busca branch-and-bound com poda e comparação lexicográfica;
- cadastro e exclusão confirmada de tamanhos;
- formação automática dos blocos quando as porcentagens dos tamanhos coincidem;
- edição do comprimento de cada bloco formado;
- validação de nomes, associações e porcentagens;
- exemplo automático de 115 metros;
- resultados por bloco e tamanho;
- painel compacto de desktop sem rolagem vertical na janela padrão;
- abertura maximizada da janela;
- logo oficial da Opera Fashion na interface e nas duas páginas do PDF;
- tema claro como padrão, com alternância para o tema escuro;
- atalhos de teclado e ordem de foco;
- aviso de alterações não salvas, inclusive pelo botão de fechar da janela;
- persistência estruturada na pasta de dados do usuário;
- projetos salvos, duplicados, excluídos e reabertos;
- histórico dos 100 cálculos mais recentes;
- PDF A4 de duas páginas: Ordem de Corte industrial e relatório completo;
- porcentagens e fios/folhas por tamanho preenchidos na primeira página;
- escolha do local do PDF, abertura e impressão;
- executor nativo Windows;
- executor nativo macOS preparado para compilação em um Mac com Xcode;
- scripts PowerShell e configuração do VS Code;
- documentação completa no `README.md`;
- repositório Git local, sem remoto.

## Validações executadas

Ambiente de validação temporário:

```text
Flutter 3.44.7
Dart 3.12.2
Visual Studio Community 2026 18.7.4
Windows SDK 10.0.26100.0
```

Resultados:

```text
flutter pub get              APROVADO
flutter analyze              APROVADO — No issues found
flutter test                 APROVADO — 25/25 testes
flutter build windows        APROVADO
PDF com fonte Unicode        APROVADO
Execução da janela           APROVADO — GRADE OPERA aberta
```

O teste obrigatório retornou:

```text
M/G:   14 folhas
P/GG:   7 folhas
PP:     2 folhas
Usado: 114,71 m
Sobra:   0,29 m
```

## Ambiente instalado e execução

- Flutter 3.44.7 instalado permanentemente em
  `C:\Users\User\development\flutter`;
- `flutter\bin` adicionado ao `PATH` do usuário;
- extensões oficiais Dart e Flutter instaladas no VS Code;
- Modo de Desenvolvedor do Windows habilitado;
- Visual Studio e Windows SDK reconhecidos;
- perfil único **GRADE OPERA — Windows** configurado em `.vscode/launch.json`;
- F5 configurado para executar `lib/main.dart` no dispositivo Windows;
- aplicativo release compilado e aberto com a janela `GRADE OPERA`.

Não há pendência para executar o aplicativo no Windows.

## Gerar a versão Windows

Depois de ativar o Modo de Desenvolvedor:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build_windows.ps1
```

O executável será criado em:

```text
build\windows\x64\runner\Release\grade_opera.exe
```

É necessário distribuir a pasta `Release` inteira.

## Plataformas futuras

O Android SDK não está instalado nesta máquina, mas não é necessário para a
primeira execução Windows. Android exige Android Studio/SDK. macOS e iOS exigem
um Mac com Xcode. O domínio, persistência, PDF e controlador já foram separados
para permitir essas compilações futuras.
