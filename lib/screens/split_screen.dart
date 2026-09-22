import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../services/arquivo_utils.dart';

class SplitScreen extends StatefulWidget {
  const SplitScreen({super.key});

  @override
  State<SplitScreen> createState() => _SplitScreenState();
}

class _SplitScreenState extends State<SplitScreen> {
  String? _arquivoSelecionado;
  final TextEditingController _tamanhoController =
      TextEditingController(text: '10');
  bool _processando = false;
  double _progresso = 0;
  String? _mensagemErro;
  List<String> _partesCriadas = [];
  String? _diretorioDestino;

  @override
  void dispose() {
    _tamanhoController.dispose();
    super.dispose();
  }

  Future<void> _selecionarArquivo() async {
    final resultado = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      dialogTitle: 'Selecione o arquivo para dividir',
    );
    if (resultado == null || resultado.files.isEmpty) return;
    setState(() {
      _arquivoSelecionado = resultado.files.single.path;
      _partesCriadas = [];
      _mensagemErro = null;
    });
  }

  Future<void> _dividir() async {
    if (_arquivoSelecionado == null) {
      setState(() => _mensagemErro = 'Selecione um arquivo primeiro.');
      return;
    }

    final tamanhoMb = double.tryParse(_tamanhoController.text.trim());
    if (tamanhoMb == null || tamanhoMb <= 0) {
      setState(() => _mensagemErro = 'Informe um tamanho válido em MB.');
      return;
    }

    setState(() {
      _processando = true;
      _progresso = 0;
      _mensagemErro = null;
      _partesCriadas = [];
    });

    try {
      final dirDocs = await getApplicationDocumentsDirectory();
      _diretorioDestino = dirDocs.path;

      final partes = await ArquivoUtils.dividirArquivo(
        arquivoOrigem: _arquivoSelecionado!,
        diretorioDestino: _diretorioDestino!,
        tamanhoMb: tamanhoMb,
        aoProgresso: (parte, total, percentual) {
          setState(() => _progresso = percentual);
        },
      );

      if (!mounted) return;
      setState(() {
        _partesCriadas = partes;
        _processando = false;
      });
      _mostrarResultado();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _processando = false;
        _mensagemErro = 'Erro ao dividir: $e';
      });
    }
  }

  void _mostrarResultado() {
    final tamanhoTotal = File(_arquivoSelecionado!).lengthSync();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Divisão concluída'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Arquivo: ${p.basename(_arquivoSelecionado!)}'
                '\nTamanho: ${ArquivoUtils.formatarBytes(tamanhoTotal)}'
                '\nPartes criadas: ${_partesCriadas.length}'
                '\nPasta: $_diretorioDestino',
              ),
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
              await Share.shareXFiles(
                _partesCriadas.map((parte) => XFile(parte)).toList(),
                text: 'Partes do arquivo ${p.basename(_arquivoSelecionado!)}',
              );
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
      appBar: AppBar(title: const Text('Dividir arquivos grandes')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton.icon(
              onPressed: _processando ? null : _selecionarArquivo,
              icon: const Icon(Icons.folder_open),
              label: Text(
                _arquivoSelecionado == null
                    ? 'Selecionar arquivo'
                    : p.basename(_arquivoSelecionado!),
              ),
            ),
            if (_arquivoSelecionado != null) ...[
              const SizedBox(height: 8),
              Text(
                'Tamanho: '
                '${ArquivoUtils.formatarBytes(File(_arquivoSelecionado!).lengthSync())}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _tamanhoController,
              enabled: !_processando,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Tamanho de cada parte (MB)',
                helperText: 'Ex.: 10 = partes de 10 megabytes',
              ),
            ),
            const SizedBox(height: 16),
            if (_processando) ...[
              LinearProgressIndicator(value: _progresso),
              const SizedBox(height: 8),
              Text(
                'Dividindo... ${(_progresso * 100).toStringAsFixed(0)}%',
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
              onPressed: _processando ? null : _dividir,
              icon: const Icon(Icons.call_split),
              label: const Text('Dividir arquivo'),
            ),
          ],
        ),
      ),
    );
  }
}