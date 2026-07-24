# GRADE OPERA

O **GRADE OPERA** é um aplicativo Flutter totalmente offline para empresas de
confecção. Ele calcula quantas folhas, fios ou camadas devem ser usadas em cada
bloco de corte, respeitando o tecido disponível, a margem de traspasso e as
proporções desejadas entre tamanhos.

Toda a interface está em português do Brasil. O projeto possui executores
nativos para Windows e macOS, mantendo as regras de negócio independentes da
interface.

## Funcionalidades

- inicialização automática com a grade padrão PP, P, M, G, GG, G1 e G2;
- cadastro livre de outros tamanhos (42 ou qualquer outro nome);
- formação automática de blocos ao identificar tamanhos com porcentagens iguais;
- entrada direta do comprimento de encaixe próprio para cada bloco formado;
- cadastro de tecidos por cor, cada um com sua própria metragem disponível;
- uma única margem global em centímetros aplicada a todas as cores e blocos;
- leitura de números com vírgula ou ponto e apresentação no padrão brasileiro;
- margem de traspasso aplicada a cada folha de cada bloco;
- otimização inteira por cor, priorizando o maior aproveitamento possível sem
  misturar metragens ou ultrapassar o disponível;
- preservação dos percentuais informados na exibição, inclusive acima de 100%;
- comparação entre porcentagem desejada e alcançada;
- resultado com fios por cor e, logo abaixo, quantidade total agrupada;
- rolagem própria nas listas de cores e nas tabelas compactas de resultados;
- quantidade de peças por tamanho e consumo médio de tecido por peça;
- painel compacto de desktop com os campos principais em uma única página;
- abertura maximizada e identidade visual oficial da Opera Fashion;
- indicador textual e visual: Exato, Muito próximo, Dentro da tolerância ou
  Fora da tolerância;
- projetos salvos, editados, duplicados, excluídos e reabertos localmente,
  incluindo a opção **Salvar como**;
- histórico dos 100 cálculos mais recentes;
- relatório PDF A4, escolha do local de salvamento, abertura do arquivo,
  pré-visualização e impressão pela janela moderna do Windows;
- consumo médio por peça na primeira página do PDF, calculado somente com o
  tecido utilizado dividido pelo total de peças produzidas em todas as cores;
- tema claro na inicialização, com alternância entre claro e escuro;
- navegação por teclado, confirmações antes de excluir e aviso de alterações não
  salvas;
- exemplo oficial de 115 metros disponível em um clique.

## Lógica de cálculo

Os comprimentos são convertidos para **micrômetros inteiros**. Isso evita
imprecisões comuns de ponto flutuante no consumo e garante que a soma nunca
ultrapasse o tecido disponível.

Para cada bloco:

```text
margem_em_metros = margem_em_centímetros / 100
comprimento_efetivo = comprimento_do_encaixe + margem_em_metros
consumo_do_bloco = quantidade_inteira_de_folhas × comprimento_efetivo
```

Internamente, a maior porcentagem vira a referência proporcional da busca, mas
os valores desejados e alcançados continuam na escala informada pelo usuário,
inclusive acima de 100%. Cada cor é otimizada separadamente; ao final, o app
soma as quantidades equivalentes para formar o resultado agrupado. O motor cria
uma solução inicial e executa uma busca branch-and-bound. Ramos são descartados
quando excedem a metragem da cor ou já não podem melhorar a solução. Dentro da
tolerância de cinco pontos percentuais, a comparação é lexicográfica:

1. maior uso do tecido e menor sobra;
2. menor erro percentual máximo;
3. menor soma dos erros percentuais;
4. em empate, menor quantidade total de folhas.

Quando a metragem é pequena demais para existir uma combinação dentro dessa
tolerância, o motor usa a combinação proporcional mais próxima possível e,
entre soluções equivalentes, escolhe a que mais aproveita o tecido.
Depois de formar a grade-base, qualquer sobra que ainda comporte um bloco é
aproveitada pelo bloco que menos altera as porcentagens. O processo continua
até o saldo ser menor que o comprimento do menor bloco disponível.

O cálculo pesado roda em um isolate para manter a interface responsiva.

O caso de regressão obrigatório produz:

| Bloco | Folhas | Efetivo | Consumo |
|---|---:|---:|---:|
| M/G | 14 | 5,24 m | 73,36 m |
| P/GG | 7 | 5,21 m | 36,47 m |
| PP | 2 | 2,44 m | 4,88 m |
| **Total** | **23** |  | **114,71 m** |

Sobra: **0,29 m**.

## Estrutura do projeto

```text
lib/
  app/                         configuração do aplicativo
  core/
    constants/                 constantes e escalas
    formatting/                leitura e formatação brasileira
    theme/                     temas claro e escuro
    utils/                     utilitários
    widgets/                   componentes compartilhados
  features/
    cutting_grade/
      domain/                  entidades, validação e otimização
      presentation/            controlador, tela e componentes
    projects/
      data/                    persistência JSON estruturada
      domain/                  documento e contrato do repositório
    reports/
      services/                PDF A4, salvamento, abertura e impressão
test/                          testes unitários, de PDF e de interface
scripts/                       automação PowerShell
windows/                       executor nativo para Windows
macos/                         executor nativo para macOS
```

## Pré-requisitos no Windows

- Windows 10 ou superior;
- Flutter estável 3.44 ou superior, com Dart 3.12 ou superior;
- Git;
- VS Code;
- extensões oficiais **Flutter** e **Dart**;
- Visual Studio 2022 ou superior com a carga
  **Desenvolvimento para desktop com C++**, incluindo CMake e o Windows SDK.

O VS Code é o editor usado no projeto. A extensão do Flutter não substitui as
ferramentas nativas do Visual Studio exigidas para compilar um executável
Windows.

Verifique o ambiente:

```powershell
flutter doctor -v
powershell -ExecutionPolicy Bypass -File .\scripts\check_environment.ps1
```

## Abrir e executar no VS Code

1. Abra esta pasta no VS Code.
2. Aceite as extensões recomendadas.
3. Abra um terminal PowerShell na raiz.
4. Execute:

```powershell
flutter pub get
flutter run -d windows
```

Ou use:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_windows.ps1
```

Também é possível pressionar `F5` e escolher **GRADE OPERA — Windows**.

## Análise e testes

```powershell
flutter analyze
flutter test
```

O script executa as duas verificações e retorna código diferente de zero ao
encontrar qualquer falha:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\test.ps1
```

Os testes cobrem conversões, margem, consumos, sobra, percentuais acima de 100%,
cálculo e agrupamento por cor, formação automática de blocos por porcentagem,
preservação dos comprimentos, validações, limite de tecido, números brasileiros,
o caso real de 115 metros, geração do PDF e os principais fluxos da interface.

## Ordem de corte impressa

O PDF possui duas páginas:

1. **Ordem de Corte** em preto e branco, baseada no formulário industrial
   fornecido, com código, modelo, grade horizontal, porcentagem escolhida,
   folhas totais de todas as cores por tamanho, quadros de tecidos e
   observações.
2. **Informações completas do cálculo**, onde os tecidos são detalhados por
   cor, seguidos pela quantidade agrupada por bloco, peças por tamanho, consumo
   por peça, tecido utilizado, sobra e aproveitamento.

Uma prévia visual reproduzível pode ser gerada com:

```powershell
flutter test .\tool\generate_pdf_preview.dart
```

O arquivo é salvo em `output\pdf\ordem_corte_preview.pdf`.

## Gerar o executável Windows

```powershell
flutter build windows --release
```

Ou:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build_windows.ps1
```

Os arquivos de distribuição ficam em:

```text
build\windows\x64\runner\Release\
```

O executável principal é `grade_opera.exe`. Distribua a pasta `Release` inteira,
não apenas o `.exe`.

## Gerar o instalador Windows

O instalador cria os atalhos do menu Iniciar e, por padrão, da Área de
Trabalho, usando o ícone oficial do GRADE OPERA:

```powershell
python .\tool\generate_app_icons.py
flutter build windows --release
& "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" .\windows\installer\grade_opera.iss
```

O instalador será criado em
`output\installers\GRADE_OPERA_Setup_Windows_x64.exe`.

## Gerar o aplicativo macOS

A compilação macOS precisa ser executada em um Mac com Xcode e CocoaPods:

```bash
./scripts/build_macos.sh
```

O aplicativo será criado em:

```text
build/macos/Build/Products/Release/grade_opera.app
```

## Dados locais e PDFs

Projetos e histórico são salvos fora do código-fonte, na pasta de suporte da
aplicação fornecida pelo sistema. No Windows, ela fica dentro de `%APPDATA%` ou
do diretório de dados resolvido pelo Flutter, na subpasta `GRADE OPERA`.

O banco é um arquivo JSON estruturado gravado de forma atômica. Caso seja
detectado conteúdo corrompido, o arquivo anterior é renomeado com o sufixo
`.corrompido_<data>` antes da criação de uma base vazia.

PDFs são salvos somente no local escolhido pelo usuário e não entram no Git.

## Atalhos

| Atalho | Ação |
|---|---|
| `Ctrl+N` | nova ordem/limpar formulário |
| `Ctrl+S` | salvar projeto |
| `Ctrl+O` | abrir projeto |
| `Ctrl+P` | gerar PDF ou imprimir |
| `F5` | calcular distribuição |
| `Delete` | remover a linha selecionada após confirmação |
| `Esc` | fechar caixas de diálogo pelo comportamento padrão do sistema |

## Solução de problemas

### `flutter` não é reconhecido

Instale o Flutter e adicione `flutter\bin` ao `PATH`. Feche e reabra o VS Code:

```powershell
where.exe flutter
flutter doctor -v
```

### Windows não aparece em `flutter devices`

```powershell
flutter config --enable-windows-desktop
flutter devices
```

Confira no Visual Studio Installer se **Desenvolvimento para desktop com C++**,
CMake e o Windows SDK estão instalados.

### `Building with plugins requires symlink support`

Ative o **Modo de Desenvolvedor** do Windows em
**Configurações > Sistema > Avançado > Para desenvolvedores**. É possível abrir
a página correta diretamente:

```powershell
start ms-settings:developers
```

Depois, feche e reabra o VS Code e execute `flutter pub get` novamente.

### Dependências não são obtidas

O aplicativo funciona offline depois de compilado, mas a primeira restauração
das bibliotecas requer acesso ao cache local do Pub ou à internet:

```powershell
flutter clean
flutter pub get
```

Depois, bibliotecas já presentes no cache podem ser reutilizadas com:

```powershell
flutter pub get --offline
```

### PDF não abre

O PDF permanece salvo mesmo que nenhum leitor esteja associado. Abra o caminho
mostrado pelo aplicativo diretamente no Explorador do Windows.

### Limpar artefatos de compilação

```powershell
flutter clean
flutter pub get
```

## Futuras plataformas

As entidades, validação, otimização, persistência e PDF não dependem da tela
Windows. Em uma máquina com o ambiente da plataforma desejada, gere os
executores ausentes:

```powershell
flutter create --platforms=android,ios,macos .
flutter pub get
```

- Android: instale Android Studio/SDK e execute `flutter build apk`.
- macOS: use um Mac com Xcode e execute `flutter build macos`.
- iOS: use um Mac com Xcode e execute `flutter build ios`.

Revise permissões e assinatura exigidas por cada loja. O `path_provider`,
`file_picker`, `pdf` e `printing` usados aqui suportam essas plataformas.

## Limitações da primeira versão

- tamanhos do mesmo bloco precisam compartilhar a mesma porcentagem, porque cada
  folha produz uma unidade de cada tamanho do bloco;
- cada tamanho pertence a exatamente um bloco;
- a persistência é local e de usuário único, sem sincronização em nuvem;
- o histórico guarda os 100 cálculos mais recentes;
- compilações iOS e macOS exigem um Mac, apesar da arquitetura compartilhada.

## Controle de versão

O repositório é somente local e não possui remoto configurado. Artefatos de
build, banco local, PDFs, temporários, segredos e configurações pessoais estão
excluídos pelo `.gitignore`.
