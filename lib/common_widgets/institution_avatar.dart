import 'package:flutter/material.dart';

class InstitutionAvatar extends StatelessWidget {
  final String logoUrl;
  final String name;

  const InstitutionAvatar({super.key, required this.logoUrl, required this.name});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          child: Icon(Icons.business), // Placeholder for logoUrl
        ),
        const SizedBox(height: 8),
        Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
