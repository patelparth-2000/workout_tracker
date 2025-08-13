import 'package:flutter/material.dart';

class ButtonWidget extends StatelessWidget {
  const ButtonWidget({
    super.key,
    this.text,
    this.onPressed,
    this.color,
    this.icon,
  });
  final String? text;
  final VoidCallback? onPressed;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return text != null && text!.isNotEmpty
        ? TextButton(
            child: Text(text!, style: TextStyle(color: color)),
            onPressed: () {
              onPressed?.call();
            },
          )
        : IconButton(
            padding: const EdgeInsets.all(0.0),
            icon: Icon(icon, color: color),
            onPressed: () {
              onPressed?.call();
            },
          );
  }
}
