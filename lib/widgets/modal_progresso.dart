import 'package:flutter/material.dart';

/// Modal de progresso: caixa branca com título, barra de progresso fina,
/// informações (percentual + progresso/limite) e botão opcional
/// para continuar em segundo plano.
class ModalProgresso extends StatelessWidget {
  const ModalProgresso({
    super.key,
    required this.percentual,
    required this.progresso,
    required this.limite,
    this.titulo = 'Processando...',
    this.emSegundoPlano = false,
    this.onSegundoPlano,
    this.onCancelar,
  });

  final double percentual;
  final int progresso;
  final int limite;
  final String titulo;
  final bool emSegundoPlano;
  final VoidCallback? onSegundoPlano;
  final VoidCallback? onCancelar;

  @override
  Widget build(BuildContext context) {
    final pct = (percentual.clamp(0.0, 1.0) * 100).round();

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              titulo,
              style: const TextStyle(
                color: Color(0xFF111111),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: percentual.clamp(0.0, 1.0),
                minHeight: 4,
                backgroundColor: const Color(0xFFE0E0E0),
                color: const Color(0xFF00897B),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$pct%',
                  style: const TextStyle(
                    color: Color(0xFF555555),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '$progresso/$limite',
                  style: const TextStyle(
                    color: Color(0xFF555555),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (onSegundoPlano != null) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onCancelar != null) ...[
                    TextButton(
                      onPressed: onCancelar,
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(color: Color(0xFF555555)),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Material(
                    color: const Color(0xFF00897B),
                    borderRadius: BorderRadius.circular(6),
                    elevation: 0,
                    child: InkWell(
                      onTap: onSegundoPlano,
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.picture_in_picture_alt,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              emSegundoPlano
                                  ? 'Em segundo plano'
                                  : 'Segundo plano',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}