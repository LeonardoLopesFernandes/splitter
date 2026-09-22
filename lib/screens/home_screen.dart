import 'package:flutter/material.dart';

import 'merge_screen.dart';
import 'split_screen.dart';
import 'view_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Divisor de Arquivos'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.call_split, size: 40, color: Color(0xFF1565C0)),
              title: const Text('Dividir arquivos grandes'),
              subtitle: const Text('Divida um arquivo grande em várias partes menores'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SplitScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.merge, size: 40, color: Color(0xFF2E7D32)),
              title: const Text('Juntar múltiplos arquivos'),
              subtitle: const Text('Junte várias partes em um único arquivo'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MergeScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.visibility, size: 40, color: Color(0xFFEF6C00)),
              title: const Text('Visualizar conteúdo'),
              subtitle: const Text('Ver o conteúdo de arquivos (recomendado para texto)'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ViewScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}