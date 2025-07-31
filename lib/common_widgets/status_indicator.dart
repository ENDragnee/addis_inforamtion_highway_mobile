import 'package:flutter/material.dart';

enum RequestStatus { pending, approved, denied }

class StatusIndicator extends StatelessWidget {
  final RequestStatus status;

  const StatusIndicator({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    String text;
    Color backgroundColor;
    Color textColor;

    switch (status) {
      case RequestStatus.pending:
        text = 'Pending';
        backgroundColor = Colors.yellow;
        textColor = Colors.black;
        break;
      case RequestStatus.approved:
        text = 'Approved';
        backgroundColor = Colors.green;
        textColor = Colors.white;
        break;
      case RequestStatus.denied:
        text = 'Denied';
        backgroundColor = Colors.red;
        textColor = Colors.white;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
    );
  }
}
