import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widget/section_header.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/plate_math.dart';
import '../../../utils/units.dart';
import '../viewmodel/settings_provider.dart';

/// Which plates to load per side for a target weight, in the display unit.
/// Selections are not stored: the defaults cover common gyms (kept simple on purpose).
class PlateCalculatorScreen extends ConsumerStatefulWidget {
  const PlateCalculatorScreen({super.key});

  @override
  ConsumerState<PlateCalculatorScreen> createState() =>
      _PlateCalculatorScreenState();
}

class _PlateCalculatorScreenState extends ConsumerState<PlateCalculatorScreen> {
  final _target = TextEditingController();
  late final TextEditingController _bar;
  late WeightUnit _unit;
  late Set<double> _available;

  @override
  void initState() {
    super.initState();
    _unit = ref.read(weightUnitProvider);
    _bar = TextEditingController(text: formatNumber(defaultBar[_unit]!));
    _available = {...defaultPlates[_unit]!};
  }

  @override
  void dispose() {
    _target.dispose();
    _bar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final target = parseWeightInput(_target.text);
    final bar = parseWeightInput(_bar.text);
    final result = (target == null || bar == null)
        ? null
        : calculatePlates(
            target: target,
            bar: bar,
            plates: _available.toList(),
          );
    final u = _unit.symbol;
    final formatters = [
      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      LengthLimitingTextInputFormatter(7),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Plate calculator')),
      body: ListView(
        padding: AppInsets.screen,
        children: [
          TextField(
            controller: _target,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: formatters,
            decoration: InputDecoration(labelText: 'Target weight ($u)'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _bar,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: formatters,
            decoration: InputDecoration(labelText: 'Bar weight ($u)'),
            onChanged: (_) => setState(() {}),
          ),
          const SectionHeader(title: 'Plates available'),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (final p in defaultPlates[_unit]!)
                FilterChip(
                  label: Text('${formatNumber(p)} $u'),
                  selected: _available.contains(p),
                  onSelected: (on) => setState(
                    () => on ? _available.add(p) : _available.remove(p),
                  ),
                ),
            ],
          ),
          const SectionHeader(title: 'Each side'),
          Semantics(
            liveRegion: true,
            child: switch (result) {
              null => const Text('Enter a target and bar weight.'),
              PlateResult(perSide: []) when target! <= bar! => const Text(
                'Just the bar.',
              ),
              final r => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.perSide.isEmpty
                        ? 'No plates fit.'
                        : r.perSide.map(formatNumber).join(' + '),
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    r.exact
                        ? 'Total ${formatNumber(r.achieved)} $u'
                        : 'Closest: ${formatNumber(r.achieved)} $u '
                              '(${formatNumber(r.shortBy)} $u short)',
                  ),
                ],
              ),
            },
          ),
        ],
      ),
    );
  }
}
