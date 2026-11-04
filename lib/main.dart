import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      // Never retry silently: failures surface with a Retry button (ARCHITECTURE §7).
      retry: (retryCount, error) => null,
      child: const App(),
    ),
  );
}
