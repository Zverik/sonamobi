import 'package:flutter/material.dart';

class MessagePanel extends StatelessWidget {
  final String? message;
  final bool isError;
  
  const MessagePanel(this.message, {this.isError = false, super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message ?? 'viga',
        style: TextStyle(
          fontSize: 20,
          color: isError ? Colors.red : null,
        ),
      ),
    );
  }
}
