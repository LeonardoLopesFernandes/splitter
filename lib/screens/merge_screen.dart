import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

import '../services/arquivo_utils.dart';
import '../services/permissao_utils.dart';
import '../widgets/theme_widgets.dart';

class MergeScreen extends StatefulWidget {
  const MergeScreen({super.key});

  @override
  State<MergeScreen> createState() => _MergeScreenState();
}

class _MergeScreenState extends State<MergeScreen> {
  List<String> _partesSelecionadas = [];
  String? _caminhoSaida;
  bool _processando = false;
  double _progresso = 0;
  String? _mensagemErro;

  final _nomeController = TextEditingController();
  final _extensaoController = TextEditingController();

  @override
  void dispose() {
    _nomeController.dispose();
    _extensaoController.dispose();
    super.dispose();
  }

  Future<void> _selecionarPartes() async {
    final resultado = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      dialogTitle: 'Selecione os arquivos para unir',
      type: FileType.any,
    );
    if (resultado == null || resultado.files.isEmpty) return;
    setState(() {
      _partesSelecionadas = resultado.files
          .map((f) => f.path)
          .whereType<String>()
          .toList();
      _mensagemErro = null;
      if (_nomeController.text.isEmpty && _partesSelecionadas.isNotEmpty) {
        final base = p.basenameWithoutExtension(_partesSelecionadas.first);
        _nomeController.text = base.replaceAll(RegExp(r'(_parte|_\d+)'), '');
      }
    });
  }

  void _ordenarAZ() {
    setState(
      () => _partesSelecionadas = ArquivoUtils.ordenarPartes(_partesSelecionadas),
    );
  }

  Future<void> _selecionarCaminho() async {
    final caminho = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Selecione a pasta de destino',
    );
    if (caminho == null || caminho.isEmpty) return;
    setState(() {
      _caminhoSaida = caminho;
      _mensagemErro = null;
    });
  }

  Future<void> _juntar() async {
    setState(() => _mensagemErro = null);

    final nome = _nomeController.text.trim();
    if (nome.isEmpty || _caminhoSaida == null || _partesSelecionadas.isEmpty) {
      setState(() => _mensagemErro = 'Escolha nome, caminho e arquivos.');
      return;
    }

    final temPermissao = await PermissaoUtils.solicitarAcessoArmazenamento();
    if (!mounted) return;
    if (!temPermissao) {
      setState(() {
        _mensagemErro =
            'Sem permissão de escrita. Vá em Configurações e permita '
            '"Todos os arquivos" para o app.';
      });
      return;
    }

    setState(() {
      _processando = true;
      _progresso = 0;
    });

    try {
      final resultado = await ArquivoUtils.juntarArquivos(
        partes: _partesSelecionadas,
        diretorioDestino: _caminhoSaida!,
        nome: nome,
        extensao: _extensaoController.text.trim(),
        aoProgresso: (parte, total, percentual) {
          if (mounted) setState(() => _progresso = percentual);
        },
      );

      if (!mounted) return;
      setState(() {
        _processando = false;
        _mensagemErro = null;
      });
      _mostrarResultado(resultado);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _processando = false;
        _mensagemErro = 'Falha ao unir - $e';
      });
    }
  }

  void _mostrarResultado(String caminho) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Junção concluída!'),
        content: Text('Arquivo criado:\n$caminho'),
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
                    icone: 'assets/icons/ic_folder_48dp.png',
                    titulo: 'Arquivos de entrada',
                    botao: 'SELECIONAR',
                    acoesExtras: [
                      BotaoTeal(rotulo: 'AZ', onPressed: _ordenarAZ),
                    ],
                    texto: _partesSelecionadas.isEmpty
                        ? '0 arquivos selecionados.'
                        : '${_partesSelecionadas.length} arquivo(s) selecionado(s).',
                    onBotao: _selecionarPartes,
                  ),
                  if (_partesSelecionadas.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ThemeCard(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _partesSelecionadas.length,
                          itemBuilder: (ctx, i) => ListTile(
                            dense: true,
                            leading: const Icon(
                              Icons.description,
                              color: Color(0xFF8E9BA8),
                            ),
                            title: Text(
                              p.basename(_partesSelecionadas[i]),
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  ThemeCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const TituloCard('Arquivo de saída'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: CampoLinha(
                                rotulo: 'Nome:',
                                controller: _nomeController,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CampoLinha(
                                rotulo: 'Extensão:',
                                controller: _extensaoController,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Caminho: ${_caminhoSaida ?? 'Não selecionado'}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF8E9BA8),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            BotaoTeal(
                              rotulo: 'SELECIONAR',
                              onPressed: _selecionarCaminho,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (_processando) ...[
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: _progresso,
                      color: const Color(0xFF1FB196),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Juntando... ${(_progresso * 100).toStringAsFixed(0)}%',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF8E9BA8)),
                    ),
                  ],
                  if (_mensagemErro != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _mensagemErro!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFFEF5350)),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: BotaoPrincipal(
                rotulo: 'UNIR',
                onPressed: _processando ? null : _juntar,
              ),
            ),
          ],
        ),
      ),
    );
  }
}