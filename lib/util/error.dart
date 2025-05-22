import 'package:flutter/material.dart';

class MessagePanel extends StatelessWidget {
  final String? message;
  final bool isError;
  final Function()? onReload;

  const MessagePanel(this.message,
      {this.isError = false, super.key, this.onReload});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          message ?? 'viga',
          style: TextStyle(
            fontSize: 20,
            color: isError ? Colors.red : null,
          ),
        ),
        if (isError && onReload != null) ...[
          SizedBox(height: 20),
          ElevatedButton(
            child: Text('Proovi uuesti'),
            onPressed: () {
              onReload!();
            },
          ),
        ],
      ],
    );
  }
}
