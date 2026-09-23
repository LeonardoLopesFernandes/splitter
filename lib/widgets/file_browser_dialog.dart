import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

/// Navegador de arquivos embutido (estilo do BrowserDialog original),
/// com tema do app e textos em português do Brasil.
/// Navega pelas pastas físicas e retorna o caminho do arquivo selecionado.
/// Funciona com arquivos grandes, pois não usa o Storage Access Framework.
/// Se [selecionarPasta] for true, retorna a pasta atual ao confirmar.
class FileBrowserDialog extends StatefulWidget {
  const FileBrowserDialog({
    super.key,
    this.caminhoInicial,
    this.selecionarPasta = false,
    this.titulo,
  });

  final String? caminhoInicial;
  final bool selecionarPasta;
  final String? titulo;

  @override
  State<FileBrowserDialog> createState() => _FileBrowserDialogState();
}

class _FileBrowserDialogState extends State<FileBrowserDialog> {
  static const Color _teal = Color(0xFF009688);
  static const Color _tealEscuro = Color(0xFF00897B);
  static const Color _fundoTopo = Color(0xFF161E29);
  static const Color _fundoCard = Color(0xFF1B2430);
  static const Color _texto = Color(0xFFA0B0C0);
  static const Color _textoMuted = Color(0xFF5D7182);
  static const Color _divisor = Color(0xFF2A3A4A);

  late String _caminhoAtual;
  List<FileSystemEntity> _entidades = [];
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _caminhoAtual = widget.caminhoInicial ?? _caminhoRaiz();
    _recarregar();
  }

  String _caminhoRaiz() {
    return '/storage/emulated/0';
  }

  Future<void> _recarregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final dir = Directory(_caminhoAtual);
      final lista = await dir.list(followLinks: false).toList();
      lista.sort((a, b) {
        final aDir = a is Directory;
        final bDir = b is Directory;
        if (aDir != bDir) return aDir ? -1 : 1;
        return a.path.toLowerCase().compareTo(b.path.toLowerCase());
      });
      if (!mounted) return;
      setState(() {
        _entidades = lista;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _entidades = [];
        _carregando = false;
        _erro = 'Não foi possível abrir esta pasta.';
      });
    }
  }

  void _navegar(FileSystemEntity entidade) {
    if (entidade is Directory) {
      if (widget.selecionarPasta) {
        Navigator.pop(context, entidade.path);
      } else {
        _caminhoAtual = entidade.path;
        _recarregar();
      }
    } else if (entidade is File) {
      if (widget.selecionarPasta) return;
      Navigator.pop(context, entidade.path);
    }
  }

  void _voltar() {
    final pai = p.dirname(_caminhoAtual);
    if (pai != _caminhoAtual) {
      _caminhoAtual = pai;
      _recarregar();
    }
  }

  String _formatarTamanho(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _fundoTopo,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.72,
        width: MediaQuery.of(context).size.width,
        child: Column(
          children: [
            // Cabeçalho.
            Container(
              padding: const EdgeInsets.fromLTRB(8, 10, 12, 10),
              decoration: const BoxDecoration(
                color: _fundoTopo,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    tooltip: 'Voltar',
                    onPressed: _voltar,
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.folder_open, color: _teal, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.titulo ??
                          (widget.selecionarPasta
                              ? 'Selecionar pasta'
                              : 'Selecionar arquivo'),
                      style: const TextStyle(
                        color: _teal,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    tooltip: 'Atualizar',
                    onPressed: _recarregar,
                  ),
                ],
              ),
            ),
            // Caminho atual.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: _fundoCard,
              child: Row(
                children: [
                  const Icon(
                    Icons.subdirectory_arrow_right,
                    size: 14,
                    color: _textoMuted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _caminhoAtual,
                      style: const TextStyle(
                        color: _texto,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _divisor),
            // Lista.
            Expanded(
              child: _carregando
                  ? const Center(
                      child: CircularProgressIndicator(color: _teal),
                    )
                  : _erro != null
                      ? Center(
                          child: Text(
                            _erro!,
                            style: const TextStyle(color: Color(0xFFEF5350)),
                          ),
                        )
                      : _entidades.isEmpty
                          ? const Center(
                              child: Text(
                                'Esta pasta está vazia.',
                                style: TextStyle(color: _texto),
                              ),
                            )
                          : ListView.separated(
                              itemCount: _entidades.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(
                                    height: 1,
                                    color: _divisor,
                                  ),
                              itemBuilder: (ctx, i) {
                                final entidade = _entidades[i];
                                final isPasta = entidade is Directory;
                                final nome = p.basename(entidade.path);
                                String? detalhe;
                                try {
                                  if (entidade is File) {
                                    detalhe = _formatarTamanho(
                                      entidade.lengthSync(),
                                    );
                                  }
                                } catch (_) {
                                  detalhe = null;
                                }
                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _navegar(entidade),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: isPasta
                                                  ? _teal.withValues(alpha: 0.15)
                                                  : const Color(0xFF232F3D),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              isPasta
                                                  ? Icons.folder
                                                  : Icons.insert_drive_file,
                                              color: isPasta
                                                  ? _teal
                                                  : _textoMuted,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              nome,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (detalhe != null) ...[
                                            const SizedBox(width: 8),
                                            Text(
                                              detalhe,
                                              style: const TextStyle(
                                                color: _textoMuted,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                          if (isPasta) ...[
                                            const SizedBox(width: 4),
                                            const Icon(
                                              Icons.chevron_right,
                                              color: _textoMuted,
                                              size: 18,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
            const Divider(height: 1, color: _divisor),
            // Rodapé.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'CANCELAR',
                      style: TextStyle(
                        color: _texto,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  if (widget.selecionarPasta) ...[
                    const SizedBox(width: 8),
                    Material(
                      color: _tealEscuro,
                      borderRadius: BorderRadius.circular(6),
                      elevation: 0,
                      child: InkWell(
                        onTap: () => Navigator.pop(context, _caminhoAtual),
                        borderRadius: BorderRadius.circular(6),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Text(
                            'SELECIONAR PASTA',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}