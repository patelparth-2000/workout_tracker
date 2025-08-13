import 'package:flutter/material.dart';
import 'package:workout_tracker/utils/color_constant.dart';

class TextFieldWidget extends StatelessWidget {
  const TextFieldWidget({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
  });
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: SizedBox(
        height: 50,
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: BorderColor.grey, width: 1),
            ),
            labelText: labelText,
            hintText: hintText,
          ),
          keyboardType: TextInputType.number,
        ),
      ),
    );
  }
}
