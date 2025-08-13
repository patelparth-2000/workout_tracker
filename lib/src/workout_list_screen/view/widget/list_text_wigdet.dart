import 'package:flutter/material.dart';

// This widget displays a row with a label and a value, typically used for displaying workout details.
class ListTextWigdet extends StatelessWidget {
  const ListTextWigdet({super.key, required this.text, required this.value});
  final String text;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          "$text : ",
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: Colors.black, fontSize: 14),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
