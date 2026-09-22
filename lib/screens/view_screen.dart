import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../services/arquivo_utils.dart';
import '../widgets/theme_widgets.dart';

class ViewScreen extends StatefulWidget {
  const ViewScreen({super.key});

  @override
  State<ViewScreen> createState() => _ViewScreenState();
}

class _ViewScreenState extends State<ViewScreen> {
  String? _arquivoSelecionado;
  String? _conteudo;
  bool _carregando = false;
  bool _mostrarNumerosLinha = true;
  bool _mostrarInfo = false;
  double _tamanhoFonte = 14;
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
      final conteudo = await ArquivoUtils.lerConteudo(_arquivoSelecionado!);
      if (!mounted) return;
      setState(() {
        _conteudo = conteudo;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _carregando = false;
        _mensagemErro = 'Não foi possível ler o arquivo - $e';
      });
    }
  }

  void _abrirConfiguracoes() {
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocalState) => AlertDialog(
          title: const Text('Configurações'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CheckboxListTile(
                title: const Text('Mostrar números de linha'),
                value: _mostrarNumerosLinha,
                activeColor: const Color(0xFF1FB196),
                onChanged: (v) => setLocalState(
                  () => _mostrarNumerosLinha = v ?? true,
                ),
              ),
              CheckboxListTile(
                title: const Text('Mostrar informações'),
                value: _mostrarInfo,
                activeColor: const Color(0xFF1FB196),
                onChanged: (v) => setLocalState(
                  () => _mostrarInfo = v ?? false,
                ),
              ),
              ListTile(
                title: const Text('Tamanho da fonte'),
                trailing: Text(_tamanhoFonte.toStringAsFixed(0)),
              ),
              Slider(
                value: _tamanhoFonte,
                min: 8,
                max: 32,
                activeColor: const Color(0xFF1FB196),
                onChanged: (v) =>
                    setLocalState(() => _tamanhoFonte = v.roundToDouble()),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {});
                Navigator.pop(ctx);
              },
              child: const Text('Fechar'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _montarLinhas() {
    if (_conteudo == null) return const [];
    final linhas = _conteudo!.split('\n');
    final widgets = <Widget>[];
    for (var i = 0; i < linhas.length; i++) {
      widgets.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_mostrarNumerosLinha)
              SizedBox(
                width: 40,
                child: Text(
                  '${i + 1}',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: _tamanhoFonte - 2,
                    color: const Color(0xFF6B7C93),
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Expanded(
              child: SelectableText(
                linhas[i],
                style: TextStyle(
                  fontSize: _tamanhoFonte,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      );
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  CardArquivoEntrada(
                    titulo: 'Entrada',
                    icone: 'assets/icons/ic_document.png',
                    subtitulo: 'O arquivo que você deseja visualizar.',
                    botao: 'SELECIONAR',
                    acoesExtras: [
                      BotaoTeal(
                        rotulo: 'Config',
                        onPressed: _abrirConfiguracoes,
                      ),
                    ],
                    texto: _arquivoSelecionado == null
                        ? 'Nenhum arquivo selecionado'
                        : p.basename(_arquivoSelecionado!),
                    onBotao: _selecionarArquivo,
                  ),
                  const SizedBox(height: 12),
                  ThemeCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_mostrarInfo && _arquivoSelecionado != null) ...[
                          Subtexto(
                            'Nome: ${p.basename(_arquivoSelecionado!)}',
                          ),
                          Subtexto(
                            'Tamanho: ${ArquivoUtils.formatarBytes(File(_arquivoSelecionado!).lengthSync())}',
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (_carregando)
                          const SizedBox(
                            height: 200,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF1FB196),
                              ),
                            ),
                          )
                        else if (_mensagemErro != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Text(
                              _mensagemErro!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Color(0xFFEF5350)),
                            ),
                          )
                        else if (_conteudo == null)
                          const SizedBox(
                            height: 380,
                            child: Center(
                              child: Subtexto(
                                'Área de visualização do conteúdo',
                              ),
                            ),
                          )
                        else ...[
                          ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxHeight: 420,
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: _montarLinhas(),
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
          ],
        ),
      ),
    );
  }
}