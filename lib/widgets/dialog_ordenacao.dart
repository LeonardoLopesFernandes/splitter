import 'package:flutter/material.dart';

/// Resultado da ordenação escolhida no diálogo.
class ResultadoOrdenacao {
  const ResultadoOrdenacao({
    required this.criterio,
    required this.decrescente,
  });

  final String criterio;
  final bool decrescente;
}

/// Diálogo de ordenação (estilo do SortDialog original).
/// Escolhe o critério (Nome/Data/Tamanho) e a direção (Crescente/Decrescente).
class DialogOrdenacao extends StatefulWidget {
  const DialogOrdenacao({super.key});

  @override
  State<DialogOrdenacao> createState() => _DialogOrdenacaoState();
}

class _DialogOrdenacaoState extends State<DialogOrdenacao> {
  static const Color _teal = Color(0xFF009688);
  static const Color _fundoDialog = Color(0xFF283342);
  static const Color _fundoInner = Color(0xFF384556);
  static const Color _rotulo = Color(0xFF9CB0C1);
  static const Color _opcao = Color(0xFFD8E2EC);
  static const Color _bordaRadio = Color(0xFF6B7C8D);

  String _criterio = 'nome';
  bool _decrescente = false;

  Widget _radio(String rotulo, String valor, bool grupoCriterio) {
    final selecionado =
        grupoCriterio ? _criterio == valor : _decrescente == (valor == 'desc');
    return InkWell(
      onTap: () {
        setState(() {
          if (grupoCriterio) {
            _criterio = valor;
          } else {
            _decrescente = valor == 'desc';
          }
        });
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selecionado ? _teal : _bordaRadio,
                width: 2,
              ),
            ),
            child: selecionado
                ? Container(
                    margin: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: _teal,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            rotulo,
            style: const TextStyle(color: _opcao, fontSize: 13),
          ),
        ],
      ),
    );
  }

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
            const Text(
              'Ordenar',
              style: TextStyle(
                color: _teal,
                fontSize: 17,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _fundoInner,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ordenar por',
                    style: TextStyle(color: _rotulo, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _radio('Nome', 'nome', true),
                      _radio('Data', 'data', true),
                      _radio('Tamanho', 'tamanho', true),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFF4C5B6D),
                    ),
                  ),
                  const Text(
                    'Ordem',
                    style: TextStyle(color: _rotulo, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _radio('Crescente', 'asc', false),
                      _radio('Decrescente', 'desc', false),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Material(
              color: const Color(0xFF00897B),
              borderRadius: BorderRadius.circular(6),
              elevation: 0,
              child: InkWell(
                onTap: () {
                  Navigator.pop(
                    context,
                    ResultadoOrdenacao(
                      criterio: _criterio,
                      decrescente: _decrescente,
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                  child: Text(
                    'ORDENAR',
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
          ],
        ),
      ),
    );
  }
}