
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  final Map<String, dynamic> userInfo;

  const ProfileScreen({super.key, required this.userInfo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: ListView.builder(
        itemCount: userInfo.length,
        itemBuilder: (context, index) {
          final key = userInfo.keys.elementAt(index);
          final value = userInfo[key];

          // Handle multi-language format (e.g., name#en, name#am)
          final keyParts = key.split('#');
          final fieldName = keyParts[0];
          final language = keyParts.length > 1 ? keyParts[1] : 'N/A';

          return ListTile(
            title: Text(fieldName),
            subtitle: Text('$value (Language: $language)'),
          );
        },
      ),
    );
  }
}
