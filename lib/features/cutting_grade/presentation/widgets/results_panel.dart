import 'package:flutter/material.dart';
import 'package:grade_opera/core/formatting/brazilian_number.dart';
import 'package:grade_opera/core/widgets/horizontal_scroll_area.dart';
import 'package:grade_opera/core/widgets/section_card.dart';
import 'package:grade_opera/features/cutting_grade/domain/entities/grade_entities.dart';

class ResultsPanel extends StatelessWidget {
  const ResultsPanel({required this.result, super.key});

  final CalculationResult result;

  @override
  Widget build(BuildContext context) => SectionCard(
    key: const Key('painel-resultados'),
    title: 'Resultados do cálculo',
    subtitle:
        'Distribuição inteira otimizada sem ultrapassar o tecido disponível.',
    icon: Icons.analytics_outlined,
    trailing: Chip(
      avatar: const Icon(Icons.check_circle_outline, size: 18),
      label: const Text('Cálculo válido'),
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'Distribuição calculada com sucesso. Foram utilizados '
            '${BrazilianNumber.metersFromMicrometers(result.usedMicrometers)} '
            'metros dos '
            '${BrazilianNumber.metersFromMicrometers(result.availableMicrometers)} '
            'metros disponíveis, restando '
            '${BrazilianNumber.metersFromMicrometers(result.remainingMicrometers)} '
            'metro.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            _SummaryTile(
              label: 'Tecido disponível',
              value:
                  '${BrazilianNumber.metersFromMicrometers(result.availableMicrometers)} m',
              icon: Icons.inventory_2_outlined,
            ),
            _SummaryTile(
              label: 'Total utilizado',
              value:
                  '${BrazilianNumber.metersFromMicrometers(result.usedMicrometers)} m',
              icon: Icons.straighten,
            ),
            _SummaryTile(
              label: 'Sobra',
              value:
                  '${BrazilianNumber.metersFromMicrometers(result.remainingMicrometers)} m',
              icon: Icons.content_cut,
            ),
            _SummaryTile(
              label: 'Aproveitamento',
              value: BrazilianNumber.percent(result.utilizationPercentage),
              icon: Icons.donut_large,
            ),
            _SummaryTile(
              label: 'Margem por folha',
              value:
                  '${BrazilianNumber.decimal(result.overlapMicrometers / 10000)} cm',
              icon: Icons.swap_horiz,
            ),
            _SummaryTile(
              label: 'Total de folhas',
              value: result.totalSheets.toString(),
              icon: Icons.layers_outlined,
            ),
            _SummaryTile(
              label: 'Total de peças',
              value: result.totalPieces.toString(),
              icon: Icons.checkroom_outlined,
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Quantidade de fios por cor',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        _horizontalTable(
          context,
          DataTable(
            columns: const <DataColumn>[
              DataColumn(label: Text('Cor')),
              DataColumn(label: Text('Disponível')),
              DataColumn(label: Text('Bloco')),
              DataColumn(label: Text('Tamanhos')),
              DataColumn(label: Text('Fios'), numeric: true),
              DataColumn(label: Text('Consumo')),
              DataColumn(label: Text('Sobra da cor')),
            ],
            rows: result.fabricColors
                .expand(
                  (fabric) => fabric.blocks.map(
                    (block) => DataRow(
                      cells: <DataCell>[
                        DataCell(
                          Text(
                            fabric.colorName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        DataCell(
                          Text(
                            '${BrazilianNumber.metersFromMicrometers(fabric.availableMicrometers)} m',
                          ),
                        ),
                        DataCell(Text(block.blockName)),
                        DataCell(Text(block.sizeNames.join(', '))),
                        DataCell(Text(block.quantity.toString())),
                        DataCell(
                          Text(
                            '${BrazilianNumber.metersFromMicrometers(block.consumptionMicrometers)} m',
                          ),
                        ),
                        DataCell(
                          Text(
                            '${BrazilianNumber.metersFromMicrometers(fabric.remainingMicrometers)} m',
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Quantidade agrupada por bloco',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        _horizontalTable(
          context,
          DataTable(
            columns: const <DataColumn>[
              DataColumn(label: Text('Bloco')),
              DataColumn(label: Text('Tamanhos')),
              DataColumn(label: Text('Desejada')),
              DataColumn(label: Text('Original')),
              DataColumn(label: Text('Margem')),
              DataColumn(label: Text('Efetivo')),
              DataColumn(label: Text('Folhas/fios'), numeric: true),
              DataColumn(label: Text('Consumo'), numeric: true),
            ],
            rows: result.blocks
                .map(
                  (block) => DataRow(
                    cells: <DataCell>[
                      DataCell(
                        Text(
                          block.blockName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      DataCell(Text(block.sizeNames.join(', '))),
                      DataCell(
                        Text(BrazilianNumber.percent(block.desiredPercentage)),
                      ),
                      DataCell(
                        Text(
                          '${BrazilianNumber.metersFromMicrometers(block.originalLengthMicrometers)} m',
                        ),
                      ),
                      DataCell(
                        Text(
                          '${BrazilianNumber.decimal(block.overlapMicrometers / 10000)} cm',
                        ),
                      ),
                      DataCell(
                        Text(
                          '${BrazilianNumber.metersFromMicrometers(block.effectiveLengthMicrometers)} m',
                        ),
                      ),
                      DataCell(Text(block.quantity.toString())),
                      DataCell(
                        Text(
                          '${BrazilianNumber.metersFromMicrometers(block.consumptionMicrometers)} m',
                        ),
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Resultado por tamanho',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        _horizontalTable(
          context,
          DataTable(
            columns: const <DataColumn>[
              DataColumn(label: Text('Tamanho')),
              DataColumn(label: Text('Peças'), numeric: true),
              DataColumn(label: Text('Consumo por peça'), numeric: true),
              DataColumn(label: Text('Desejada')),
              DataColumn(label: Text('Alcançada')),
              DataColumn(label: Text('Diferença')),
              DataColumn(label: Text('Situação')),
            ],
            rows: result.sizes
                .map(
                  (size) => DataRow(
                    cells: <DataCell>[
                      DataCell(
                        Text(
                          size.sizeName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      DataCell(Text(size.quantity.toString())),
                      DataCell(
                        Text(
                          '${BrazilianNumber.metersFromMicrometers(size.consumptionPerPieceMicrometers)} m',
                        ),
                      ),
                      DataCell(
                        Text(BrazilianNumber.percent(size.desiredPercentage)),
                      ),
                      DataCell(
                        Text(BrazilianNumber.percent(size.achievedPercentage)),
                      ),
                      DataCell(
                        Text(
                          '${size.difference >= 0 ? '+' : ''}'
                          '${BrazilianNumber.decimal(size.difference)} p.p.',
                        ),
                      ),
                      DataCell(_StatusIndicator(status: size.status)),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ],
    ),
  );

  Widget _horizontalTable(BuildContext context, Widget table) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      borderRadius: BorderRadius.circular(10),
    ),
    child: HorizontalScrollArea(child: table),
  );
}

class CompactResultsPanel extends StatelessWidget {
  const CompactResultsPanel({
    required this.result,
    required this.onBack,
    required this.onPdf,
    required this.onPrint,
    super.key,
  });

  final CalculationResult result;
  final VoidCallback onBack;
  final VoidCallback onPdf;
  final VoidCallback onPrint;

  @override
  Widget build(BuildContext context) => Card(
    key: const Key('painel-resultados'),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.analytics_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Resultados do cálculo',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Voltar aos dados'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                key: const Key('gerar-pdf'),
                onPressed: onPdf,
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('PDF'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                key: const Key('imprimir-resultado'),
                onPressed: onPrint,
                icon: const Icon(Icons.print_outlined),
                label: const Text('Imprimir'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _CompactMetric(
                label: 'Disponível',
                value:
                    '${BrazilianNumber.metersFromMicrometers(result.availableMicrometers)} m',
              ),
              _CompactMetric(
                label: 'Utilizado',
                value:
                    '${BrazilianNumber.metersFromMicrometers(result.usedMicrometers)} m',
              ),
              _CompactMetric(
                label: 'Sobra',
                value:
                    '${BrazilianNumber.metersFromMicrometers(result.remainingMicrometers)} m',
              ),
              _CompactMetric(
                label: 'Aproveitamento',
                value: BrazilianNumber.percent(result.utilizationPercentage),
              ),
              _CompactMetric(
                label: 'Margem/folha',
                value:
                    '${BrazilianNumber.decimal(result.overlapMicrometers / 10000)} cm',
              ),
              _CompactMetric(
                label: 'Folhas/fios',
                value: result.totalSheets.toString(),
              ),
              _CompactMetric(
                label: 'Peças',
                value: result.totalPieces.toString(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: Column(
                    children: <Widget>[
                      Expanded(
                        child: _CompactResultTable(
                          title: 'Fios por cor',
                          child: DataTable(
                            dataRowMinHeight: 34,
                            dataRowMaxHeight: 38,
                            headingRowHeight: 36,
                            horizontalMargin: 8,
                            columnSpacing: 12,
                            columns: const <DataColumn>[
                              DataColumn(label: Text('Cor')),
                              DataColumn(label: Text('Bloco')),
                              DataColumn(label: Text('Fios'), numeric: true),
                              DataColumn(label: Text('Consumo')),
                            ],
                            rows: result.fabricColors
                                .expand(
                                  (fabric) => fabric.blocks.map(
                                    (block) => DataRow(
                                      cells: <DataCell>[
                                        DataCell(
                                          Text(
                                            fabric.colorName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        DataCell(Text(block.blockName)),
                                        DataCell(
                                          Text(block.quantity.toString()),
                                        ),
                                        DataCell(
                                          Text(
                                            '${BrazilianNumber.metersFromMicrometers(block.consumptionMicrometers)} m',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _CompactResultTable(
                          title: 'Quantidade agrupada',
                          child: DataTable(
                            dataRowMinHeight: 34,
                            dataRowMaxHeight: 38,
                            headingRowHeight: 36,
                            horizontalMargin: 8,
                            columnSpacing: 12,
                            columns: const <DataColumn>[
                              DataColumn(label: Text('Bloco')),
                              DataColumn(
                                label: Text('Folhas/fios'),
                                numeric: true,
                              ),
                              DataColumn(label: Text('Efetivo')),
                              DataColumn(label: Text('Consumo')),
                            ],
                            rows: result.blocks
                                .map(
                                  (block) => DataRow(
                                    cells: <DataCell>[
                                      DataCell(
                                        Text(
                                          block.blockName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      DataCell(Text(block.quantity.toString())),
                                      DataCell(
                                        Text(
                                          '${BrazilianNumber.metersFromMicrometers(block.effectiveLengthMicrometers)} m',
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          '${BrazilianNumber.metersFromMicrometers(block.consumptionMicrometers)} m',
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CompactResultTable(
                    title: 'Peças por tamanho',
                    child: DataTable(
                      dataRowMinHeight: 36,
                      dataRowMaxHeight: 40,
                      headingRowHeight: 38,
                      horizontalMargin: 8,
                      columnSpacing: 14,
                      columns: const <DataColumn>[
                        DataColumn(label: Text('Tamanho')),
                        DataColumn(label: Text('Peças'), numeric: true),
                        DataColumn(label: Text('Consumo/peça')),
                        DataColumn(label: Text('Desejada')),
                        DataColumn(label: Text('Alcançada')),
                      ],
                      rows: result.sizes
                          .map(
                            (size) => DataRow(
                              cells: <DataCell>[
                                DataCell(
                                  Text(
                                    size.sizeName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                DataCell(Text(size.quantity.toString())),
                                DataCell(
                                  Text(
                                    '${BrazilianNumber.metersFromMicrometers(size.consumptionPerPieceMicrometers)} m',
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    BrazilianNumber.percent(
                                      size.desiredPercentage,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    BrazilianNumber.percent(
                                      size.achievedPercentage,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _CompactMetric extends StatelessWidget {
  const _CompactMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text('$label: ', style: Theme.of(context).textTheme.bodySmall),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    ),
  );
}

class _CompactResultTable extends StatefulWidget {
  const _CompactResultTable({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  State<_CompactResultTable> createState() => _CompactResultTableState();
}

class _CompactResultTableState extends State<_CompactResultTable> {
  final ScrollController _verticalController = ScrollController();

  @override
  void dispose() {
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          widget.title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: ClipRect(
            child: Scrollbar(
              key: Key('barra-vertical-${widget.title}'),
              controller: _verticalController,
              thumbVisibility: true,
              trackVisibility: true,
              thickness: 7,
              radius: const Radius.circular(7),
              child: SingleChildScrollView(
                controller: _verticalController,
                padding: const EdgeInsets.only(right: 10),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: HorizontalScrollArea(child: widget.child),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 210,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Row(
      children: <Widget>[
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _StatusIndicator extends StatelessWidget {
  const _StatusIndicator({required this.status});

  final AllocationStatus status;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (status) {
      AllocationStatus.exact => (Icons.check_circle, Colors.green),
      AllocationStatus.veryClose => (Icons.check_circle_outline, Colors.teal),
      AllocationStatus.withinTolerance => (Icons.info_outline, Colors.orange),
      AllocationStatus.outsideTolerance => (Icons.warning_amber, Colors.red),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6),
        Text(status.label),
      ],
    );
  }
}
