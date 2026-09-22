import 'package:flutter/material.dart';

import '../widgets/theme_widgets.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            SizedBox(height: 24),
            Icon(
              Icons.workspace_premium,
              size: 72,
              color: Color(0xFF1FB196),
            ),
            SizedBox(height: 16),
            Text(
              'Versão Premium',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Subtexto(
              'Remova anúncios e aproveite todos os recursos.',
              tamanho: 14,
              textoCentralizado: true,
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}