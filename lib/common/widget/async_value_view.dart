import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'empty_state.dart';
import 'error_state.dart';
import 'loading_state.dart';

/// Maps an [AsyncValue] onto the four UI states: loading, error (+retry), empty, loaded.
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    super.key,
    required this.value,
    required this.data,
    this.isEmpty,
    this.empty,
    this.onRetry,
    this.loadingLabel = 'Loading',
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;

  /// When provided and true for the data, [empty] is shown instead of [data].
  final bool Function(T data)? isEmpty;
  final Widget? empty;
  final VoidCallback? onRetry;
  final String loadingLabel;

  @override
  Widget build(BuildContext context) {
    return switch (value) {
      AsyncData(:final value) =>
        (isEmpty?.call(value) ?? false)
            ? (empty ??
                  const EmptyState(
                    icon: Icons.inbox_outlined,
                    title: 'Nothing here yet',
                  ))
            : data(value),
      AsyncError(:final error) => ErrorState(
        message: '$error',
        onRetry: onRetry,
      ),
      _ => LoadingState(label: loadingLabel),
    };
  }
}
