import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../utils/clock.dart';
import '../../../../utils/workout_math.dart';

/// "12:34" since [since], repainted every second; the ticker is cancelled on dispose.
class ElapsedText extends ConsumerStatefulWidget {
  const ElapsedText({super.key, required this.since, this.style});

  final DateTime since;
  final TextStyle? style;

  @override
  ConsumerState<ElapsedText> createState() => _ElapsedTextState();
}

class _ElapsedTextState extends ConsumerState<ElapsedText> {
  late final Timer _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = ref.watch(clockProvider)().difference(widget.since);
    final text = formatClock(elapsed);
    return Semantics(
      label: 'Elapsed time $text',
      excludeSemantics: true,
      child: Text(text, style: widget.style),
    );
  }
}
