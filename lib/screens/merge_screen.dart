import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../services/arquivo_utils.dart';

class MergeScreen extends StatefulWidget {
  const MergeScreen({super.key});

  @override
  State<MergeScreen> createState() => _MergeScreenState();
}

class _MergeScreenState extends State<MergeScreen> {
  List<String> _partesSelecionadas = [];
  final TextEditingController _nomeSaidaController = TextEditingController();
  bool _processando = false;
  double _progresso = 0;
  String? _mensagemErro;

  @override
  void dispose() {
    _nomeSaidaController.dispose();
    super.dispose();
  }

  Future<void> _selecionarPartes() async {
    final resultado = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      dialogTitle: 'Selecione as partes do arquivo',
      type: FileType.any,
    );
    if (resultado == null || resultado.files.isEmpty) return;
    setState(() {
      _partesSelecionadas =
          resultado.files.map((f) => f.path!).whereType<String>().toList();
      _mensagemErro = null;
      if (_nomeSaidaController.text.isEmpty &&
          _partesSelecionadas.isNotEmpty) {
        final base = p.basenameWithoutExtension(_partesSelecionadas.first);
        _nomeSaidaController.text =
            '${base.replaceAll(RegExp(r'_parte\d+$'), '')}.arquivo';
      }
    });
  }

  Future<void> _juntar() async {
    if (_partesSelecionadas.isEmpty) {
      setState(() => _mensagemErro = 'Selecione as partes do arquivo.');
      return;
    }

    final nomeSaida = _nomeSaidaController.text.trim();
    if (nomeSaida.isEmpty) {
      setState(() => _mensagemErro = 'Informe um nome para o arquivo final.');
      return;
    }

    setState(() {
      _processando = true;
      _progresso = 0;
      _mensagemErro = null;
    });

    try {
      final dirDocs = await getApplicationDocumentsDirectory();

      final resultado = await ArquivoUtils.juntarArquivos(
        partes: _partesSelecionadas,
        diretorioDestino: dirDocs.path,
        nomeSaida: nomeSaida,
        aoProgresso: (parte, total, percentual) {
          setState(() => _progresso = percentual);
        },
      );

      if (!mounted) return;
      setState(() {
        _processando = false;
      });
      _mostrarResultado(resultado);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _processando = false;
        _mensagemErro = 'Erro ao juntar: $e';
      });
    }
  }

  void _mostrarResultado(String caminho) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Junção concluída'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Arquivo criado: $caminho'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fechar'),
          ),
          FilledButton(
            onPressed: () async {
              await Share.shareXFiles([XFile(caminho)]);
            },
            child: const Text('Compartilhar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Juntar múltiplos arquivos')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton.icon(
              onPressed: _processando ? null : _selecionarPartes,
              icon: const Icon(Icons.library_add),
              label: Text(
                _partesSelecionadas.isEmpty
                    ? 'Selecionar partes do arquivo'
                    : '${_partesSelecionadas.length} parte(s) selecionada(s)',
              ),
            ),
            if (_partesSelecionadas.isNotEmpty) ...[
              const SizedBox(height: 8),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _partesSelecionadas.length,
                  itemBuilder: (ctx, i) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.description),
                    title: Text(
                      p.basename(_partesSelecionadas[i]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _nomeSaidaController,
              enabled: !_processando,
              decoration: const InputDecoration(
                labelText: 'Nome do arquivo final',
                helperText: 'Ex.: video_legenda.mp4',
              ),
            ),
            const SizedBox(height: 16),
            if (_processando) ...[
              LinearProgressIndicator(value: _progresso),
              const SizedBox(height: 8),
              Text(
                'Juntando... ${(_progresso * 100).toStringAsFixed(0)}%',
                textAlign: TextAlign.center,
              ),
            ],
            if (_mensagemErro != null) ...[
              const SizedBox(height: 8),
              Text(
                _mensagemErro!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
            const Spacer(),
            FilledButton.icon(
              onPressed: _processando ? null : _juntar,
              icon: const Icon(Icons.merge),
              label: const Text('Juntar arquivos'),
            ),
          ],
        ),
      ),
    );
  }
}