import 'package:flutter/material.dart';

/// Diálogo de confirmação ao tentar sair do app (estilo do SortDialog).
class DialogSair extends StatelessWidget {
  const DialogSair({super.key});

  static const Color _teal = Color(0xFF009688);
  static const Color _fundoDialog = Color(0xFF283342);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _fundoDialog,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 360,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.logout, color: _teal, size: 32),
            const SizedBox(height: 12),
            const Text(
              'Deseja sair do app?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _teal,
                fontSize: 17,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Se você sair, os arquivos já criados não serão afetados.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF9CB0C1), fontSize: 13),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Material(
                    color: const Color(0xFF4C5B6D),
                    borderRadius: BorderRadius.circular(6),
                    elevation: 0,
                    child: InkWell(
                      onTap: () => Navigator.pop(context, false),
                      borderRadius: BorderRadius.circular(6),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'CANCELAR',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Material(
                    color: const Color(0xFF00897B),
                    borderRadius: BorderRadius.circular(6),
                    elevation: 0,
                    child: InkWell(
                      onTap: () => Navigator.pop(context, true),
                      borderRadius: BorderRadius.circular(6),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'SAIR',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}