import 'package:flutter/material.dart';

class SulgeButton extends StatelessWidget {
  const SulgeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () {
        Navigator.of(context).pop();
      },
      style: TextButton.styleFrom(textStyle: TextStyle(fontSize: 20)),
      label: Text('Sulge'),
      icon: Icon(
        Icons.close,
        color: Colors.redAccent,
      ),
    );
  }
}
