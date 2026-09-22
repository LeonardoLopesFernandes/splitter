import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../services/arquivo_utils.dart';

class ViewScreen extends StatefulWidget {
  const ViewScreen({super.key});

  @override
  State<ViewScreen> createState() => _ViewScreenState();
}

class _ViewScreenState extends State<ViewScreen> {
  String? _arquivoSelecionado;
  String? _conteudo;
  bool _carregando = false;
  String? _mensagemErro;

  Future<void> _selecionarArquivo() async {
    final resultado = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      dialogTitle: 'Selecione um arquivo de texto',
      type: FileType.any,
    );
    if (resultado == null || resultado.files.isEmpty) return;
    setState(() {
      _arquivoSelecionado = resultado.files.single.path;
      _conteudo = null;
      _mensagemErro = null;
      _carregando = true;
    });

    try {
      final conteudo =
          await ArquivoUtils.lerConteudo(_arquivoSelecionado!);
      if (!mounted) return;
      setState(() {
        _conteudo = conteudo;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _carregando = false;
        _mensagemErro = 'Não foi possível ler o arquivo: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Visualizar conteúdo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton.icon(
              onPressed: _carregando ? null : _selecionarArquivo,
              icon: const Icon(Icons.folder_open),
              label: Text(
                _arquivoSelecionado == null
                    ? 'Selecionar arquivo de texto'
                    : p.basename(_arquivoSelecionado!),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _carregando
                  ? const Center(child: CircularProgressIndicator())
                  : _mensagemErro != null
                      ? Center(
                          child: Text(
                            _mensagemErro!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        )
                      : _conteudo == null
                          ? const Center(
                              child: Text(
                                'Selecione um arquivo de texto para visualizar '
                                'o conteúdo aqui.',
                                textAlign: TextAlign.center,
                              ),
                            )
                          : Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Theme.of(context).dividerColor,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: SingleChildScrollView(
                                child: SelectableText(
                                  _conteudo!,
                                  style: const TextStyle(fontFamily: 'monospace'),
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