import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'clock.g.dart';

/// Returns "now". Everything time-dependent reads time through this so tests can fake it.
typedef Clock = DateTime Function();

@Riverpod(keepAlive: true)
Clock clock(Ref ref) => DateTime.now;
