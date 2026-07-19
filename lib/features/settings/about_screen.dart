import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('عن التطبيق')),
      body: const Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Text('💌', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text('دعواتي', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            SizedBox(height: 6),
            Text('الإصدار 1.0.0'),
            SizedBox(height: 16),
            Text(
              'تطبيق لإدارة العائلة والأصدقاء والمناسبات والمدعوين والمهام في مكان واحد.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
