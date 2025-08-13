import 'package:flutter/material.dart';

class TextWidget extends StatelessWidget {
  const TextWidget({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}
