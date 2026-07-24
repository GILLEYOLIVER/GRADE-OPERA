import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grade_opera/core/formatting/brazilian_number.dart';
import 'package:grade_opera/core/widgets/horizontal_scroll_area.dart';
import 'package:grade_opera/core/widgets/section_card.dart';
import 'package:grade_opera/features/cutting_grade/presentation/controllers/grade_controller.dart';

class FabricDataSection extends StatelessWidget {
  const FabricDataSection({
    required this.controller,
    this.compact = false,
    super.key,
  });

  final GradeController controller;
  final bool compact;

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'Identificação do modelo',
    subtitle: 'Código e descrição usados ao salvar e gerar o relatório.',
    icon: Icons.assignment_outlined,
    compact: compact,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final fullWidth = constraints.maxWidth;
        final spacing = compact ? 8.0 : 16.0;
        final fieldWidth = fullWidth < 430
            ? fullWidth
            : (fullWidth - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: <Widget>[
            _FieldBox(
              width: fieldWidth,
              child: TextFormField(
                key: const Key('campo-codigo-modelo'),
                controller: controller.modelCodeController,
                decoration: InputDecoration(
                  labelText: 'Código do modelo',
                  helperText: compact
                      ? null
                      : 'Código interno, referência ou SKU.',
                  prefixIcon: compact ? null : const Icon(Icons.qr_code_2),
                  isDense: compact,
                ),
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
              ),
            ),
            _FieldBox(
              width: fieldWidth,
              child: TextFormField(
                key: const Key('campo-descricao-modelo'),
                controller: controller.descriptionController,
                decoration: InputDecoration(
                  labelText: 'Descrição do modelo',
                  helperText: compact
                      ? null
                      : 'Nome comercial ou detalhes do produto.',
                  prefixIcon: compact
                      ? null
                      : const Icon(Icons.description_outlined),
                  isDense: compact,
                ),
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
              ),
            ),
            _FieldBox(
              width: fieldWidth,
              child: TextFormField(
                key: const Key('campo-quantidade-desejada'),
                controller: controller.desiredQuantityController,
                decoration: InputDecoration(
                  labelText: 'Quantidade desejada',
                  helperText: compact
                      ? null
                      : 'Meta exibida na primeira página da impressão.',
                  prefixIcon: compact
                      ? null
                      : const Icon(Icons.inventory_2_outlined),
                  suffixText: 'peças',
                  isDense: compact,
                ),
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: _optionalPositiveIntegerValidator,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
              ),
            ),
            _FieldBox(
              width: fieldWidth,
              child: TextFormField(
                controller: controller.notesController,
                decoration: InputDecoration(
                  labelText: 'Observações',
                  helperText: compact
                      ? null
                      : 'Informações adicionais para a ordem e o PDF.',
                  prefixIcon: compact ? null : const Icon(Icons.notes),
                  alignLabelWithHint: true,
                  isDense: compact,
                ),
                minLines: compact ? 1 : 2,
                maxLines: compact ? 1 : 4,
                textInputAction: TextInputAction.newline,
              ),
            ),
          ],
        );
      },
    ),
  );
}

class SizesSection extends StatelessWidget {
  const SizesSection({
    required this.controller,
    required this.onRemove,
    this.compact = false,
    super.key,
  });

  final GradeController controller;
  final ValueChanged<String> onRemove;
  final bool compact;

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'Tamanhos e porcentagens',
    subtitle:
        'Porcentagens iguais são reunidas automaticamente no mesmo bloco.',
    icon: Icons.format_size,
    compact: compact,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            FilledButton.icon(
              key: const Key('adicionar-tamanho'),
              onPressed: controller.addSize,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar tamanho'),
            ),
            OutlinedButton.icon(
              key: const Key('adicionar-grade-padrao'),
              onPressed: controller.addStandardSizes,
              icon: const Icon(Icons.playlist_add),
              label: const Text('Adicionar grade padrão'),
            ),
          ],
        ),
        SizedBox(height: compact ? 8 : 14),
        if (controller.sizes.isEmpty)
          const _EmptyState(
            icon: Icons.format_size,
            message:
                'Nenhum tamanho cadastrado. Adicione um tamanho ou use a grade padrão.',
          )
        else
          HorizontalScrollArea(
            child: DataTable(
              showCheckboxColumn: true,
              dataRowMinHeight: compact ? 48 : 72,
              dataRowMaxHeight: compact ? 72 : 104,
              headingRowHeight: compact ? 44 : 60,
              horizontalMargin: compact ? 10 : 18,
              checkboxHorizontalMargin: compact ? 8 : 14,
              columnSpacing: compact ? 16 : 34,
              columns: const <DataColumn>[
                DataColumn(
                  label: _TableColumnHeader(
                    label: 'Tamanho',
                    help: 'Informe uma identificação como M, G2 ou 42.',
                  ),
                ),
                DataColumn(
                  label: _TableColumnHeader(
                    label: 'Porcentagem desejada',
                    help: 'Proporção relativa desejada para o tamanho.',
                  ),
                ),
                DataColumn(
                  label: _TableColumnHeader(
                    label: 'Bloco formado',
                    help:
                        'O app reúne automaticamente os tamanhos com a mesma porcentagem.',
                  ),
                ),
                DataColumn(label: Text('Ações')),
              ],
              rows: controller.sizes.map((size) {
                EditableBlock? associatedBlock;
                final percentage = BrazilianNumber.tryParse(
                  size.percentageController.text,
                );
                if (percentage != null && percentage > 0) {
                  for (final block in controller.blocks) {
                    if (block.id == size.blockId) {
                      associatedBlock = block;
                      break;
                    }
                  }
                }
                return DataRow(
                  selected: controller.selectedSizeId == size.id,
                  onSelectChanged: (selected) =>
                      controller.selectSize(selected == true ? size.id : null),
                  cells: <DataCell>[
                    DataCell(
                      SizedBox(
                        width: compact ? 125 : 170,
                        child: TextFormField(
                          key: Key('nome-tamanho-${size.id}'),
                          controller: size.nameController,
                          decoration: InputDecoration(
                            hintText: 'Ex.: M, G2 ou 42',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: compact ? 10 : 14,
                              vertical: compact ? 9 : 13,
                            ),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Informe o tamanho.'
                              : null,
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: compact ? 140 : 190,
                        child: TextFormField(
                          key: Key('porcentagem-tamanho-${size.id}'),
                          controller: size.percentageController,
                          decoration: InputDecoration(
                            hintText: 'Ex.: 100',
                            suffixText: '%',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: compact ? 10 : 14,
                              vertical: compact ? 9 : 13,
                            ),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9,. ]'),
                            ),
                          ],
                          validator: (value) {
                            final number = BrazilianNumber.tryParse(
                              value ?? '',
                            );
                            if (number == null || number <= 0) {
                              return 'Use um valor maior que zero.';
                            }
                            return null;
                          },
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: compact ? 190 : 220,
                        child: InputDecorator(
                          key: Key('bloco-tamanho-${size.id}'),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: compact ? 10 : 14,
                              vertical: compact ? 9 : 13,
                            ),
                          ),
                          child: Row(
                            children: <Widget>[
                              Icon(
                                Icons.auto_awesome,
                                size: 18,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  associatedBlock?.name ??
                                      'Aguardando porcentagem',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      IconButton(
                        tooltip: 'Remover tamanho',
                        onPressed: () => onRemove(size.id),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    ),
  );
}

class BlocksSection extends StatelessWidget {
  const BlocksSection({
    required this.controller,
    this.compact = false,
    super.key,
  });

  final GradeController controller;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final overlap =
        BrazilianNumber.tryParseCentimetersToMicrometers(
          controller.overlapController.text,
        ) ??
        0;
    if (compact) {
      return _buildCompact(context, overlap);
    }
    return SectionCard(
      key: const Key('secao-blocos'),
      title: 'Blocos de corte',
      subtitle:
          'Digite o comprimento usado pelos tamanhos reunidos em cada bloco.',
      icon: Icons.view_module_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.auto_awesome,
                    size: 20,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Exemplo: M/G/GG = 5,35 m e P/G2 = 4,38 m. A margem global será informada logo abaixo.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (controller.blocks.isEmpty)
            const _EmptyState(
              icon: Icons.view_module_outlined,
              message:
                  'Nenhum bloco formado. Cadastre os tamanhos e suas porcentagens.',
            )
          else
            HorizontalScrollArea(
              child: DataTable(
                showCheckboxColumn: false,
                dataRowMinHeight: 72,
                dataRowMaxHeight: 92,
                headingRowHeight: 60,
                horizontalMargin: 18,
                columnSpacing: 30,
                columns: const <DataColumn>[
                  DataColumn(label: Text('Bloco')),
                  DataColumn(label: Text('Tamanhos')),
                  DataColumn(label: Text('Porcentagem desejada')),
                  DataColumn(label: Text('Comprimento do encaixe')),
                  DataColumn(label: Text('Margem global')),
                  DataColumn(label: Text('Total por folha')),
                ],
                rows: controller.blocks.map((block) {
                  final blockSizes = controller.sizes
                      .where((size) => size.blockId == block.id)
                      .toList();
                  final sizeNames = blockSizes
                      .map((size) => size.nameController.text)
                      .where((name) => name.trim().isNotEmpty)
                      .toList();
                  final percentage = blockSizes.isEmpty
                      ? ''
                      : blockSizes.first.percentageController.text.trim();
                  final original =
                      BrazilianNumber.tryParseMetersToMicrometers(
                        block.lengthText,
                      ) ??
                      0;
                  final hasLength = original > 0;
                  return DataRow(
                    cells: <DataCell>[
                      DataCell(
                        Text(
                          block.name.isEmpty ? 'Sem nome' : block.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 180,
                          child: Text(
                            sizeNames.isEmpty
                                ? 'Nenhum tamanho'
                                : sizeNames.join(', '),
                          ),
                        ),
                      ),
                      DataCell(Text(percentage.isEmpty ? '—' : '$percentage%')),
                      DataCell(
                        SizedBox(
                          width: 170,
                          child: TextFormField(
                            key: Key('comprimento-bloco-${block.id}'),
                            initialValue: block.lengthText,
                            decoration: const InputDecoration(
                              hintText: 'Ex.: 5,35',
                              suffixText: 'm',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 13,
                              ),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9,. ]'),
                              ),
                            ],
                            validator: _positiveNumberValidator,
                            onChanged: (value) =>
                                controller.updateBlockLength(block.id, value),
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) =>
                                FocusScope.of(context).nextFocus(),
                          ),
                        ),
                      ),
                      DataCell(
                        Text('${BrazilianNumber.decimal(overlap / 10000)} cm'),
                      ),
                      DataCell(
                        Text(
                          hasLength
                              ? '${BrazilianNumber.metersFromMicrometers(original + overlap)} m'
                              : 'Aguardando comprimento',
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompact(BuildContext context, int overlap) => SectionCard(
    key: const Key('secao-blocos'),
    title: 'Comprimento dos blocos',
    subtitle: 'Informe o encaixe de cada grupo.',
    icon: Icons.view_module_outlined,
    compact: true,
    child: controller.blocks.isEmpty
        ? const _EmptyState(
            icon: Icons.view_module_outlined,
            message: 'Altere as porcentagens para formar os blocos.',
            compact: true,
          )
        : LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 8.0;
              final itemWidth = constraints.maxWidth < 430
                  ? constraints.maxWidth
                  : (constraints.maxWidth - spacing) / 2;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: controller.blocks.map((block) {
                  final original =
                      BrazilianNumber.tryParseMetersToMicrometers(
                        block.lengthText,
                      ) ??
                      0;
                  return Container(
                    width: itemWidth,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                block.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                original > 0
                                    ? 'Com margem: ${BrazilianNumber.metersFromMicrometers(original + overlap)} m'
                                    : 'Informe o comprimento',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 102,
                          child: TextFormField(
                            key: Key('comprimento-bloco-${block.id}'),
                            initialValue: block.lengthText,
                            decoration: const InputDecoration(
                              hintText: '5,35',
                              suffixText: 'm',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 9,
                              ),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9,. ]'),
                              ),
                            ],
                            validator: _positiveNumberValidator,
                            onChanged: (value) =>
                                controller.updateBlockLength(block.id, value),
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) =>
                                FocusScope.of(context).nextFocus(),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
  );
}

class CalculationParametersSection extends StatelessWidget {
  const CalculationParametersSection({
    required this.controller,
    this.compact = false,
    this.fillAvailable = false,
    super.key,
  });

  final GradeController controller;
  final bool compact;
  final bool fillAvailable;

  @override
  Widget build(BuildContext context) => SectionCard(
    key: const Key('secao-tecidos'),
    title: 'Tecidos por cor e margem global',
    subtitle:
        'Informe a metragem de cada cor. A margem global será aplicada a todas elas.',
    icon: Icons.calculate_outlined,
    compact: compact,
    expandChild: fillAvailable,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            FilledButton.icon(
              key: const Key('adicionar-cor'),
              onPressed: controller.addFabricColor,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar cor'),
            ),
            const Spacer(),
            Text(
              'Total: ${_totalFabricMeters(controller)} m',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        SizedBox(height: compact ? 8 : 14),
        if (fillAvailable)
          Expanded(
            child: _FabricColorsScrollArea(
              controller: controller,
              compact: compact,
              fillAvailable: true,
            ),
          )
        else
          _FabricColorsScrollArea(controller: controller, compact: compact),
        SizedBox(height: compact ? 8 : 14),
        LayoutBuilder(
          builder: (context, constraints) => Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: compact ? constraints.maxWidth : 360,
              child: TextFormField(
                key: const Key('campo-margem'),
                controller: controller.overlapController,
                decoration: InputDecoration(
                  labelText: compact
                      ? 'Margem global para todas as cores *'
                      : 'Margem para todas as folhas e cores *',
                  helperText: compact
                      ? null
                      : 'Uma única margem, aplicada em cada folha de cada bloco e de cada cor.',
                  prefixIcon: compact ? null : const Icon(Icons.swap_horiz),
                  suffixText: 'cm',
                  isDense: compact,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9,. ]')),
                ],
                textInputAction: TextInputAction.done,
                validator: _nonNegativeNumberValidator,
              ),
            ),
          ),
        ),
        if (!compact) ...<Widget>[
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Cada cor é calculada separadamente, sem misturar suas metragens. '
              'Na página de resultados, os fios aparecem primeiro por cor e '
              'depois agrupados por bloco.',
            ),
          ),
        ],
      ],
    ),
  );
}

class _FabricColorsScrollArea extends StatefulWidget {
  const _FabricColorsScrollArea({
    required this.controller,
    required this.compact,
    this.fillAvailable = false,
  });

  final GradeController controller;
  final bool compact;
  final bool fillAvailable;

  @override
  State<_FabricColorsScrollArea> createState() =>
      _FabricColorsScrollAreaState();
}

class _FabricColorsScrollAreaState extends State<_FabricColorsScrollArea> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = widget.compact;
      final fullWidth = constraints.maxWidth;
      final spacing = compact ? 8.0 : 16.0;
      final usesOneColumn = compact || fullWidth < 760;
      final colorWidth = usesOneColumn
          ? fullWidth - 14
          : (fullWidth - spacing - 14) / 2;
      final rowCount = usesOneColumn
          ? widget.controller.fabricColors.length
          : (widget.controller.fabricColors.length + 1) ~/ 2;
      final itemHeight = compact ? 64.0 : 70.0;
      final contentHeight =
          (rowCount * itemHeight) +
          ((rowCount - 1).clamp(0, rowCount) * spacing);
      final maximumHeight = compact ? 72.0 : 242.0;
      final viewportHeight = contentHeight.clamp(itemHeight, maximumHeight);

      return SizedBox(
        key: const Key('lista-cores-rolavel'),
        height: widget.fillAvailable ? constraints.maxHeight : viewportHeight,
        child: Scrollbar(
          key: const Key('barra-rolagem-cores'),
          controller: _scrollController,
          thumbVisibility: true,
          trackVisibility: true,
          thickness: 8,
          radius: const Radius.circular(8),
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.only(right: 14),
            child: Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: widget.controller.fabricColors.indexed.map((entry) {
                final index = entry.$1;
                final fabric = entry.$2;
                return Container(
                  width: colorWidth,
                  padding: EdgeInsets.all(compact ? 7 : 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: TextFormField(
                          key: Key('campo-cor-${fabric.id}'),
                          controller: fabric.colorNameController,
                          decoration: InputDecoration(
                            labelText: 'Cor *',
                            hintText: 'Ex.: Preto',
                            isDense: true,
                            prefixIcon: compact
                                ? null
                                : const Icon(Icons.palette_outlined),
                          ),
                          validator: _requiredTextValidator,
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: compact ? 118 : 150,
                        child: TextFormField(
                          key: index == 0
                              ? const Key('campo-tecido')
                              : Key('campo-tecido-${fabric.id}'),
                          controller: fabric.metersController,
                          decoration: const InputDecoration(
                            labelText: 'Metragem *',
                            hintText: '35,50',
                            suffixText: 'm',
                            isDense: true,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9,. ]'),
                            ),
                          ],
                          textInputAction: TextInputAction.next,
                          validator: _positiveNumberValidator,
                        ),
                      ),
                      const SizedBox(width: 2),
                      IconButton(
                        tooltip: widget.controller.fabricColors.length == 1
                            ? 'Mantenha pelo menos uma cor'
                            : 'Remover cor',
                        onPressed: widget.controller.fabricColors.length == 1
                            ? null
                            : () => widget.controller.removeFabricColor(
                                fabric.id,
                              ),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      );
    },
  );
}

String _totalFabricMeters(GradeController controller) {
  final total = controller.fabricColors.fold<int>(0, (sum, fabric) {
    final value = BrazilianNumber.tryParseMetersToMicrometers(
      fabric.metersController.text,
    );
    return sum + (value ?? 0);
  });
  return BrazilianNumber.metersFromMicrometers(total);
}

String? _requiredTextValidator(String? value) =>
    value == null || value.trim().isEmpty ? 'Informe a cor.' : null;

String? _positiveNumberValidator(String? value) {
  final parsed = BrazilianNumber.tryParse(value ?? '');
  if (parsed == null) {
    return 'Informe um número válido.';
  }
  if (parsed <= 0) {
    return 'O valor deve ser maior que zero.';
  }
  return null;
}

String? _nonNegativeNumberValidator(String? value) {
  final parsed = BrazilianNumber.tryParse(value ?? '');
  if (parsed == null) {
    return 'Informe um número válido.';
  }
  if (parsed < 0) {
    return 'O valor não pode ser negativo.';
  }
  return null;
}

String? _optionalPositiveIntegerValidator(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) {
    return null;
  }
  final parsed = int.tryParse(text);
  if (parsed == null || parsed <= 0) {
    return 'Use um inteiro maior que zero.';
  }
  return null;
}

class _FieldBox extends StatelessWidget {
  const _FieldBox({required this.width, required this.child});

  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(width: width, child: child);
}

class _TableColumnHeader extends StatelessWidget {
  const _TableColumnHeader({required this.label, required this.help});

  final String label;
  final String help;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Text(label),
      const SizedBox(width: 6),
      Tooltip(
        message: help,
        child: Icon(
          Icons.info_outline,
          size: 17,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    ],
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.message,
    this.compact = false,
  });

  final IconData icon;
  final String message;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(compact ? 12 : 22),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: <Widget>[
        Icon(icon, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 12),
        Expanded(child: Text(message)),
      ],
    ),
  );
}
