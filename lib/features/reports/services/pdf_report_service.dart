import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:grade_opera/core/formatting/brazilian_number.dart';
import 'package:grade_opera/features/cutting_grade/domain/entities/grade_entities.dart';
import 'package:grade_opera/features/projects/domain/entities/project_document.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfReportService {
  const PdfReportService();

  Future<Uint8List> generate(ProjectDocument project) async {
    final result = project.result;
    if (result == null) {
      throw StateError('É necessário calcular a distribuição antes do PDF.');
    }
    final fontPair = await _loadSystemFonts();
    final logoData = await rootBundle.load('assets/images/logo_opera.jpg');
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    final pdfTheme = fontPair == null
        ? null
        : pw.ThemeData.withFont(base: fontPair.regular, bold: fontPair.bold);
    final document = pw.Document(
      title: 'GRADE OPERA - ${project.orderName}',
      author: 'GRADE OPERA',
      creator: 'GRADE OPERA',
    );
    final headingStyle = pw.TextStyle(
      fontSize: 12,
      fontWeight: pw.FontWeight.bold,
      color: PdfColor.fromHex('#145C5A'),
    );
    final headerDecoration = pw.BoxDecoration(
      color: PdfColor.fromHex('#E2EFEE'),
    );

    document.addPage(
      pw.Page(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(20, 20, 20, 24),
          theme: pdfTheme,
        ),
        build: (context) => _buildCutOrderPage(project, logoImage),
      ),
    );

    document.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(32, 36, 32, 42),
          theme: pdfTheme,
        ),
        header: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 16),
          padding: const pw.EdgeInsets.only(bottom: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: <pw.Widget>[
              pw.Image(
                logoImage,
                width: 92,
                height: 34,
                fit: pw.BoxFit.contain,
              ),
              pw.Text('Informações completas do cálculo'),
            ],
          ),
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
        ),
        build: (context) => <pw.Widget>[
          pw.Text('Identificação do modelo', style: headingStyle),
          pw.SizedBox(height: 8),
          _infoGrid(<String, String>{
            'Código do modelo': project.modelCode.isEmpty
                ? 'Não informado'
                : project.modelCode,
            'Descrição': project.modelDescription.isEmpty
                ? 'Não informada'
                : project.modelDescription,
            'Data e hora': _formatDate(result.calculatedAt),
            'Tecido disponível':
                '${BrazilianNumber.metersFromMicrometers(result.availableMicrometers)} m',
            'Cores': result.fabricColors
                .map(
                  (fabric) =>
                      '${fabric.colorName}: '
                      '${BrazilianNumber.metersFromMicrometers(fabric.availableMicrometers)} m',
                )
                .join('  •  '),
            'Margem de traspasso':
                '${BrazilianNumber.decimal(result.overlapMicrometers / 10000)} cm',
          }),
          pw.SizedBox(height: 14),
          pw.Text('Quantidade de fios por cor', style: headingStyle),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headerDecoration: headerDecoration,
            headerStyle: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellPadding: const pw.EdgeInsets.all(3),
            headers: const <String>[
              'Cor',
              'Disponível',
              'Bloco',
              'Tamanhos',
              'Fios',
              'Consumo',
              'Sobra',
            ],
            data: result.fabricColors
                .expand(
                  (fabric) => fabric.blocks.map(
                    (block) => <String>[
                      fabric.colorName,
                      '${BrazilianNumber.metersFromMicrometers(fabric.availableMicrometers)} m',
                      block.blockName,
                      block.sizeNames.join(', '),
                      block.quantity.toString(),
                      '${BrazilianNumber.metersFromMicrometers(block.consumptionMicrometers)} m',
                      '${BrazilianNumber.metersFromMicrometers(fabric.remainingMicrometers)} m',
                    ],
                  ),
                )
                .toList(),
          ),
          pw.SizedBox(height: 14),
          pw.Text('Quantidade agrupada por bloco', style: headingStyle),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headerDecoration: headerDecoration,
            headerStyle: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellPadding: const pw.EdgeInsets.all(3),
            headers: const <String>[
              'Bloco',
              'Tamanhos',
              'Desejada',
              'Original',
              'Margem',
              'Efetivo',
              'Folhas',
              'Consumo',
            ],
            data: result.blocks
                .map(
                  (block) => <String>[
                    block.blockName,
                    block.sizeNames.join(', '),
                    BrazilianNumber.percent(block.desiredPercentage),
                    '${BrazilianNumber.metersFromMicrometers(block.originalLengthMicrometers)} m',
                    '${BrazilianNumber.decimal(block.overlapMicrometers / 10000)} cm',
                    '${BrazilianNumber.metersFromMicrometers(block.effectiveLengthMicrometers)} m',
                    block.quantity.toString(),
                    '${BrazilianNumber.metersFromMicrometers(block.consumptionMicrometers)} m',
                  ],
                )
                .toList(),
          ),
          pw.SizedBox(height: 14),
          pw.Text('Resultado por tamanho', style: headingStyle),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headerDecoration: headerDecoration,
            headerStyle: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellPadding: const pw.EdgeInsets.all(3),
            headers: const <String>[
              'Tamanho',
              'Peças',
              'Consumo/peça',
              'Desejada',
              'Alcançada',
              'Diferença',
              'Situação',
            ],
            data: result.sizes
                .map(
                  (size) => <String>[
                    size.sizeName,
                    size.quantity.toString(),
                    '${BrazilianNumber.metersFromMicrometers(size.consumptionPerPieceMicrometers)} m',
                    BrazilianNumber.percent(size.desiredPercentage),
                    BrazilianNumber.percent(size.achievedPercentage),
                    '${size.difference >= 0 ? '+' : ''}${BrazilianNumber.decimal(size.difference)} p.p.',
                    size.status.label,
                  ],
                )
                .toList(),
          ),
          pw.SizedBox(height: 12),
          pw.Text('Resumo', style: headingStyle),
          pw.SizedBox(height: 6),
          _infoGrid(<String, String>{
            'Total utilizado':
                '${BrazilianNumber.metersFromMicrometers(result.usedMicrometers)} m',
            'Sobra':
                '${BrazilianNumber.metersFromMicrometers(result.remainingMicrometers)} m',
            'Aproveitamento': BrazilianNumber.percent(
              result.utilizationPercentage,
            ),
            'Total de folhas': result.totalSheets.toString(),
            'Total de peças': result.totalPieces.toString(),
          }),
          pw.SizedBox(height: 10),
          pw.Text('Observações', style: headingStyle),
          pw.SizedBox(height: 4),
          pw.Container(
            width: double.infinity,
            constraints: const pw.BoxConstraints(minHeight: 36),
            padding: const pw.EdgeInsets.all(6),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              project.notes.isEmpty ? 'Sem observações.' : project.notes,
            ),
          ),
        ],
      ),
    );
    return document.save();
  }

  Future<String?> chooseAndSave(ProjectDocument project) async {
    final safeName = project.orderName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .trim();
    var path = await FilePicker.platform.saveFile(
      dialogTitle: 'Salvar relatório do GRADE OPERA',
      fileName: 'GRADE_OPERA_${safeName.isEmpty ? 'relatorio' : safeName}.pdf',
      type: FileType.custom,
      allowedExtensions: const <String>['pdf'],
    );
    if (path == null) {
      return null;
    }
    if (!path.toLowerCase().endsWith('.pdf')) {
      path = '$path.pdf';
    }
    await File(path).writeAsBytes(await generate(project), flush: true);
    return path;
  }

  Future<void> printReport(
    ProjectDocument project, {
    Uint8List? generatedBytes,
  }) async {
    final bytes = generatedBytes ?? await generate(project);
    await Printing.layoutPdf(
      name: 'GRADE OPERA - ${project.orderName}',
      onLayout: (format) async => bytes,
      windowsModernDialog: Platform.isWindows,
    );
  }

  Future<void> openFile(String path) async {
    ProcessResult result;
    if (Platform.isWindows) {
      result = await Process.run('explorer.exe', <String>[path]);
    } else if (Platform.isMacOS) {
      result = await Process.run('open', <String>[path]);
    } else {
      result = await Process.run('xdg-open', <String>[path]);
    }
    if (result.exitCode != 0) {
      throw FileSystemException('Não foi possível abrir o PDF.', path);
    }
  }

  pw.Widget _infoGrid(Map<String, String> values) {
    final rows = values.entries.toList();
    return pw.Wrap(
      spacing: 10,
      runSpacing: 8,
      children: rows
          .map(
            (entry) => pw.Container(
              width: 250,
              child: pw.RichText(
                text: pw.TextSpan(
                  children: <pw.TextSpan>[
                    pw.TextSpan(
                      text: '${entry.key}: ',
                      style: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.TextSpan(text: entry.value),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  pw.Widget _buildCutOrderPage(
    ProjectDocument project,
    pw.MemoryImage logoImage,
  ) {
    final result = project.result!;
    final sizes = _cutOrderSizes(project);
    const borderColor = PdfColors.grey700;
    const labelStyle = pw.TextStyle(
      fontSize: 8,
      fontWeight: pw.FontWeight.bold,
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: <pw.Widget>[
        pw.Stack(
          alignment: pw.Alignment.center,
          children: <pw.Widget>[
            pw.Align(
              alignment: pw.Alignment.centerLeft,
              child: pw.Image(
                logoImage,
                width: 88,
                height: 34,
                fit: pw.BoxFit.contain,
              ),
            ),
            pw.Center(
              child: pw.Text(
                'ORDEM DE CORTE',
                style: const pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'DATA: ${_formatDateOnly(result.calculatedAt)}',
                style: labelStyle,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 18),
        pw.Row(
          children: <pw.Widget>[
            _cutOrderField(
              label: 'CÓDIGO',
              value: project.modelCode,
              width: 150,
            ),
            pw.SizedBox(width: 12),
            pw.Expanded(
              child: _cutOrderField(
                label: 'MODELO',
                value: project.modelDescription,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 9),
        pw.Row(
          children: <pw.Widget>[
            pw.Expanded(
              child: _cutOrderField(label: 'CORTADOR', value: ''),
            ),
            pw.SizedBox(width: 12),
            pw.Expanded(
              child: _cutOrderField(label: 'AUXILIAR', value: ''),
            ),
            pw.SizedBox(width: 12),
            pw.Expanded(
              child: _cutOrderField(label: 'FINALIZAÇÃO', value: ''),
            ),
          ],
        ),
        pw.SizedBox(height: 14),
        pw.Center(
          child: pw.Text(
            'GRADE DE CORTE',
            style: const pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.SizedBox(height: 7),
        pw.Row(
          children: <pw.Widget>[
            pw.Expanded(
              child: pw.Table(
                border: pw.TableBorder.all(color: borderColor, width: 0.7),
                columnWidths: <int, pw.TableColumnWidth>{
                  0: const pw.FixedColumnWidth(78),
                  for (var index = 0; index < sizes.length; index++)
                    index + 1: const pw.FlexColumnWidth(),
                },
                children: <pw.TableRow>[
                  _cutOrderGradeRow(<String>[
                    'TAMANHOS',
                    ...sizes.map((size) => size.name),
                  ], header: true),
                  _cutOrderGradeRow(<String>[
                    'PORCENTAGEM',
                    ...sizes.map((size) => size.percentage),
                  ]),
                  _cutOrderGradeRow(<String>[
                    'FOLHAS TOTAIS',
                    ...sizes.map((size) => size.quantity.toString()),
                  ], emphasized: true),
                ],
              ),
            ),
            pw.SizedBox(width: 12),
            pw.Container(
              width: 76,
              height: 72,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: borderColor, width: 0.7),
              ),
              child: pw.Column(
                children: <pw.Widget>[
                  pw.Container(
                    height: 24,
                    alignment: pw.Alignment.center,
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey200,
                      border: pw.Border(
                        bottom: pw.BorderSide(
                          color: PdfColors.grey700,
                          width: 0.7,
                        ),
                      ),
                    ),
                    child: pw.Text(
                      'CONSUMO PEÇA',
                      style: const pw.TextStyle(
                        fontSize: 6,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Row(
          children: <pw.Widget>[
            pw.Text('QUANTIDADE DESEJADA:', style: labelStyle),
            pw.SizedBox(width: 5),
            pw.Text(
              project.desiredQuantityText.trim(),
              style: const pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(color: borderColor, width: 0.7),
          columnWidths: const <int, pw.TableColumnWidth>{
            0: pw.FlexColumnWidth(),
            1: pw.FlexColumnWidth(),
            2: pw.FlexColumnWidth(),
            3: pw.FlexColumnWidth(),
            4: pw.FlexColumnWidth(),
          },
          children: <pw.TableRow>[
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: <pw.Widget>[
                _cutOrderHeaderCell('TECIDO 1'),
                _cutOrderHeaderCell('LARGURA/MTS'),
                _cutOrderHeaderCell('TECIDO 2'),
                _cutOrderHeaderCell('TECIDO 3'),
                _cutOrderHeaderCell('FORRO'),
              ],
            ),
          ],
        ),
        ...List<pw.Widget>.generate(
          5,
          (_) => pw.Padding(
            padding: const pw.EdgeInsets.only(top: 5),
            child: _cutOrderFabricBlock(),
          ),
        ),
        pw.Spacer(),
        pw.Text('OBSERVAÇÕES:', style: labelStyle),
        pw.SizedBox(height: 5),
        pw.Container(
          height: 30,
          padding: const pw.EdgeInsets.all(4),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(color: PdfColors.grey700, width: 0.6),
              bottom: pw.BorderSide(color: PdfColors.grey700, width: 0.6),
            ),
          ),
          child: pw.Text(project.notes, style: const pw.TextStyle(fontSize: 8)),
        ),
        pw.SizedBox(height: 8),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Página 1 - Ordem de Corte',
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
          ),
        ),
      ],
    );
  }

  List<_CutOrderSize> _cutOrderSizes(ProjectDocument project) {
    const standardOrder = <String>['PP', 'P', 'M', 'G', 'GG', 'G1', 'G2'];
    final draftsByName = <String, SizeDraftData>{
      for (final size in project.sizes) size.name.trim().toUpperCase(): size,
    };
    final allocationsByName = <String, SizeAllocation>{
      for (final size in project.result!.sizes)
        size.sizeName.trim().toUpperCase(): size,
    };
    final totalsByName = <String, int>{};
    for (final fabric in project.result!.fabricColors) {
      for (final block in fabric.blocks) {
        for (final sizeName in block.sizeNames) {
          final normalized = sizeName.trim().toUpperCase();
          totalsByName.update(
            normalized,
            (quantity) => quantity + block.quantity,
            ifAbsent: () => block.quantity,
          );
        }
      }
    }
    final names = <String>{
      ...draftsByName.keys,
      ...allocationsByName.keys,
    }.toList();
    names.sort((left, right) {
      final leftIndex = standardOrder.indexOf(left);
      final rightIndex = standardOrder.indexOf(right);
      if (leftIndex >= 0 && rightIndex >= 0) {
        return leftIndex.compareTo(rightIndex);
      }
      if (leftIndex >= 0) {
        return -1;
      }
      if (rightIndex >= 0) {
        return 1;
      }
      return left.compareTo(right);
    });
    return names
        .map((name) {
          final draft = draftsByName[name];
          final allocation = allocationsByName[name];
          final rawPercentage =
              draft?.percentageText.trim() ??
              BrazilianNumber.decimal(
                allocation?.desiredPercentage ?? 0,
                decimals: 0,
              );
          return _CutOrderSize(
            name: draft?.name.trim().isNotEmpty == true
                ? draft!.name.trim()
                : allocation?.sizeName ?? name,
            percentage: rawPercentage.endsWith('%')
                ? rawPercentage
                : '$rawPercentage%',
            quantity: totalsByName[name] ?? allocation?.quantity ?? 0,
          );
        })
        .toList(growable: false);
  }

  pw.Widget _cutOrderField({
    required String label,
    required String value,
    double? width,
  }) => pw.Container(
    width: width,
    padding: const pw.EdgeInsets.only(bottom: 3),
    decoration: const pw.BoxDecoration(
      border: pw.Border(
        bottom: pw.BorderSide(color: PdfColors.grey700, width: 0.6),
      ),
    ),
    child: pw.RichText(
      text: pw.TextSpan(
        children: <pw.TextSpan>[
          pw.TextSpan(
            text: '$label: ',
            style: const pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.TextSpan(text: value, style: const pw.TextStyle(fontSize: 8)),
        ],
      ),
    ),
  );

  pw.TableRow _cutOrderGradeRow(
    List<String> values, {
    bool header = false,
    bool emphasized = false,
  }) => pw.TableRow(
    decoration: header
        ? const pw.BoxDecoration(color: PdfColors.grey200)
        : null,
    children: values
        .map(
          (value) => pw.Container(
            height: 24,
            alignment: pw.Alignment.center,
            padding: const pw.EdgeInsets.all(3),
            child: pw.Text(
              value,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                fontSize: 7.5,
                fontWeight: header || emphasized
                    ? pw.FontWeight.bold
                    : pw.FontWeight.normal,
              ),
            ),
          ),
        )
        .toList(),
  );

  pw.Widget _cutOrderFabricBlock() => pw.Table(
    border: pw.TableBorder.all(color: PdfColors.grey700, width: 0.6),
    columnWidths: const <int, pw.TableColumnWidth>{
      0: pw.FlexColumnWidth(),
      1: pw.FlexColumnWidth(),
      2: pw.FlexColumnWidth(),
      3: pw.FlexColumnWidth(),
      4: pw.FlexColumnWidth(),
    },
    children: <pw.TableRow>[
      pw.TableRow(
        children: <pw.Widget>[
          pw.Container(
            height: 92,
            padding: const pw.EdgeInsets.all(5),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: <pw.Widget>[
                pw.Text(
                  'CÓDIGO: __________________',
                  style: const pw.TextStyle(fontSize: 7),
                ),
                pw.Text(
                  'NOME: ___________________',
                  style: const pw.TextStyle(fontSize: 7),
                ),
                pw.Text(
                  'COMPOSIÇÃO: ____________',
                  style: const pw.TextStyle(fontSize: 7),
                ),
              ],
            ),
          ),
          for (var column = 0; column < 4; column++)
            pw.Container(
              height: 92,
              padding: const pw.EdgeInsets.symmetric(horizontal: 6),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                children: List<pw.Widget>.generate(
                  4,
                  (line) => pw.Container(
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(
                          color: PdfColors.grey500,
                          width: 0.4,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ],
  );

  pw.Widget _cutOrderHeaderCell(String text) => pw.Container(
    height: 18,
    alignment: pw.Alignment.center,
    child: pw.Text(
      text,
      style: const pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
    ),
  );

  String _formatDateOnly(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year}';
  }

  String _formatDate(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year} '
        '${two(date.hour)}:${two(date.minute)}';
  }

  Future<_PdfFontPair?> _loadSystemFonts() async {
    final candidates = <(String, String)>[];
    if (Platform.isWindows) {
      final windowsDirectory = Platform.environment['WINDIR'] ?? r'C:\Windows';
      candidates.add((
        '$windowsDirectory${Platform.pathSeparator}Fonts'
            '${Platform.pathSeparator}arial.ttf',
        '$windowsDirectory${Platform.pathSeparator}Fonts'
            '${Platform.pathSeparator}arialbd.ttf',
      ));
      candidates.add((
        '$windowsDirectory${Platform.pathSeparator}Fonts'
            '${Platform.pathSeparator}segoeui.ttf',
        '$windowsDirectory${Platform.pathSeparator}Fonts'
            '${Platform.pathSeparator}segoeuib.ttf',
      ));
    } else if (Platform.isMacOS || Platform.isIOS) {
      candidates.add(const (
        '/System/Library/Fonts/Supplemental/Arial.ttf',
        '/System/Library/Fonts/Supplemental/Arial Bold.ttf',
      ));
    } else if (Platform.isAndroid) {
      candidates.add(const (
        '/system/fonts/Roboto-Regular.ttf',
        '/system/fonts/Roboto-Bold.ttf',
      ));
    } else {
      candidates.add(const (
        '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
        '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',
      ));
    }

    for (final candidate in candidates) {
      final regularFile = File(candidate.$1);
      final boldFile = File(candidate.$2);
      if (await regularFile.exists() && await boldFile.exists()) {
        final regularBytes = await regularFile.readAsBytes();
        final boldBytes = await boldFile.readAsBytes();
        return _PdfFontPair(
          regular: pw.Font.ttf(regularBytes.buffer.asByteData()),
          bold: pw.Font.ttf(boldBytes.buffer.asByteData()),
        );
      }
    }
    return null;
  }
}

class _PdfFontPair {
  const _PdfFontPair({required this.regular, required this.bold});

  final pw.Font regular;
  final pw.Font bold;
}

class _CutOrderSize {
  const _CutOrderSize({
    required this.name,
    required this.percentage,
    required this.quantity,
  });

  final String name;
  final String percentage;
  final int quantity;
}
