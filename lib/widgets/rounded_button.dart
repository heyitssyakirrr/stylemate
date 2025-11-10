import 'package:flutter/material.dart';
import '../utils/constants.dart';

class RoundedButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const RoundedButton({required this.label, required this.onPressed, super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppConstants.primaryAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.kRadius)),
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      ),
      child: Text(label),
    );
  }
}
