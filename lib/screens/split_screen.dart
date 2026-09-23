import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

import '../services/arquivo_utils.dart';
import '../services/permissao_utils.dart';
import '../services/servico_operacoes_background.dart';
import '../widgets/file_browser_dialog.dart';
import '../widgets/modal_progresso.dart';
import '../widgets/theme_widgets.dart';

class SplitScreen extends StatefulWidget {
  const SplitScreen({super.key});

  @override
  State<SplitScreen> createState() => _SplitScreenState();
}

class _SplitScreenState extends State<SplitScreen> {
  String? _arquivoSelecionado;
  String? _arquivoNome;
  int _arquivoTamanho = 0;
  String? _arquivoData;
  String? _caminhoSaida;
  bool _porNumero = true;
  bool _processando = false;
  double _progresso = 0;
  int _bytesLidos = 0;
  int _bytesTotal = 1;
  String? _mensagemErro;
  StreamSubscription<EventoProgressoOperacao>? _subscription;

  final _numeroController = TextEditingController(text: '2');
  final _tamanhoController = TextEditingController(text: '10');
  String _unidade = 'MB';

  final _nomeController = TextEditingController();
  final _extensaoController = TextEditingController();
  final _separadorController = TextEditingController(text: '_');
  final _inicioController = TextEditingController(text: '1');

  @override
  void dispose() {
    _subscription?.cancel();
    _numeroController.dispose();
    _tamanhoController.dispose();
    _nomeController.dispose();
    _extensaoController.dispose();
    _separadorController.dispose();
    _inicioController.dispose();
    super.dispose();
  }

  Future<void> _selecionarArquivo() async {
    final caminho = await showDialog<String>(
      context: context,
      builder: (_) => const FileBrowserDialog(),
    );
    if (caminho == null || caminho.isEmpty) return;

    final arquivo = File(caminho);
    setState(() {
      _arquivoSelecionado = caminho;
      _arquivoNome = p.basename(caminho);
      _arquivoData = ArquivoUtils.formatarDataModificacao(arquivo);
      _mensagemErro = null;
      if (_nomeController.text.isEmpty) {
        _nomeController.text = p.basenameWithoutExtension(caminho);
        _extensaoController.text = p.extension(caminho).replaceAll('.', '');
      }
    });

    // Obtém o tamanho de forma assíncrona (evita travar a UI com arquivos grandes).
    try {
      final tamanho = await arquivo.length();
      if (!mounted) return;
      setState(() => _arquivoTamanho = tamanho);
    } catch (_) {
      if (!mounted) return;
      setState(() => _arquivoTamanho = 0);
    }
  }

  Future<void> _selecionarCaminho() async {
    final caminho = await showDialog<String>(
      context: context,
      builder: (_) => const FileBrowserDialog(selecionarPasta: true),
    );
    if (caminho == null || caminho.isEmpty) return;
    setState(() {
      _caminhoSaida = caminho;
      _mensagemErro = null;
    });
  }

  Future<void> _dividir() async {
    setState(() => _mensagemErro = null);

    final nome = _nomeController.text.trim();
    if (nome.isEmpty || _caminhoSaida == null || _arquivoSelecionado == null) {
      setState(() => _mensagemErro = 'Escolha nome, caminho e arquivo.');
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

    final inicio = int.tryParse(_inicioController.text.trim()) ?? 1;
    final separador =
        _separadorController.text.isEmpty ? '' : _separadorController.text;
    final extensao = _extensaoController.text.trim();

    setState(() {
      _processando = true;
      _progresso = 0;
      _bytesLidos = 0;
      _bytesTotal = 1;
    });

    Stream<EventoProgressoOperacao> stream;
    if (_porNumero) {
      final quantidade = int.tryParse(_numeroController.text.trim());
      if (quantidade == null || quantidade <= 0) {
        setState(() {
          _processando = false;
          _mensagemErro = 'Número de arquivos inválido.';
        });
        return;
      }
      stream = ServicoOperacoesBackground.instance.dividirPorNumero(
        arquivoOrigem: _arquivoSelecionado!,
        diretorioDestino: _caminhoSaida!,
        nome: nome,
        separador: separador,
        extensao: extensao,
        inicio: inicio,
        quantidade: quantidade,
      );
    } else {
      final tamanho = double.tryParse(_tamanhoController.text.trim());
      if (tamanho == null || tamanho <= 0) {
        setState(() {
          _processando = false;
          _mensagemErro = 'Tamanho da parte inválido.';
        });
        return;
      }
      stream = ServicoOperacoesBackground.instance.dividirPorTamanho(
        arquivoOrigem: _arquivoSelecionado!,
        diretorioDestino: _caminhoSaida!,
        nome: nome,
        separador: separador,
        extensao: extensao,
        inicio: inicio,
        tamanho: tamanho,
        unidade: _unidade,
      );
    }

    _subscription = stream.listen(
      (evento) {
        if (!mounted) return;
        setState(() {
          _bytesLidos = evento.bytesLidos;
          _bytesTotal = evento.bytesTotal;
          _progresso = evento.percentual;
        });
        if (evento.concluido) {
          setState(() => _processando = false);
          if (evento.partes != null) {
            _mostrarResultado(evento.partes!);
          }
        }
      },
      onError: (erro) {
        if (!mounted) return;
        setState(() {
          _processando = false;
          _mensagemErro = 'Falha ao dividir - $erro';
        });
      },
    );
  }

  void _mostrarResultado(List<String> partes) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Divisão concluída!'),
        content: Text(
          '${partes.length} parte(s) criada(s) em:\n$_caminhoSaida',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fechar'),
          ),
          FilledButton(
            onPressed: () async {
              await Share.shareXFiles(partes.map((p) => XFile(p)).toList());
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
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _cardEntrada(),
                      const SizedBox(height: 12),
                      _cardDividirPor(),
                      const SizedBox(height: 12),
                      _cardSaida(),
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
                    rotulo: 'DIVIDIR',
                    onPressed: _processando ? null : _dividir,
                  ),
                ),
              ],
            ),
            if (_processando)
              Positioned.fill(
                child: ColoredBox(
                  color: const Color(0x99000000),
                  child: Center(
                    child: ModalProgresso(
                      percentual: _progresso,
                      progresso: (_bytesLidos / (1000 * 1000)).round(),
                      limite: (_bytesTotal / (1000 * 1000)).round(),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _cardEntrada() {
    return CardArquivoEntrada(
      icone: 'assets/icons/ic_input.png',
      titulo: 'Arquivo de entrada',
      botao: 'SELECIONAR',
      texto: 'Nenhum arquivo selecionado',
      detalhes: _arquivoSelecionado == null
          ? null
          : DetalhesArquivo(
              nome: _arquivoNome ?? p.basename(_arquivoSelecionado!),
              tamanho: ArquivoUtils.formatarBytes(_arquivoTamanho),
              dataModificacao: _arquivoData ?? '--',
            ),
      onBotao: _selecionarArquivo,
    );
  }

  Widget _cardDividirPor() {
    return ThemeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TituloCard(
            'Dividir por',
            icone: 'assets/icons/ic_size.png',
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              OpcaoRadio(
                rotulo: 'Número de arquivos',
                valor: _porNumero,
                onChanged: (_) => setState(() => _porNumero = true),
              ),
              const SizedBox(width: 20),
              OpcaoRadio(
                rotulo: 'Tamanho',
                valor: !_porNumero,
                onChanged: (_) => setState(() => _porNumero = false),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_porNumero)
            CampoLinha(
              rotulo: 'Número de arquivos:',
              controller: _numeroController,
            )
          else
            Row(
              children: [
                Expanded(
                  child: CampoLinha(
                    rotulo: 'Tamanho:',
                    controller: _tamanhoController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _unidade,
                  dropdownColor: const Color(0xFF232D37),
                  items: ['B', 'KB', 'MB']
                      .map(
                        (u) => DropdownMenuItem(value: u, child: Text(u)),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _unidade = v ?? 'MB'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _cardSaida() {
    return ThemeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TituloCard(
            'Arquivos de saída',
            icone: 'assets/icons/ic_output.png',
          ),
          const SizedBox(height: 8),
          CampoLinha(
            rotulo: 'Nome:',
            controller: _nomeController,
          ),
          CampoLinha(
            rotulo: 'Extensão:',
            controller: _extensaoController,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: CampoLinha(
                  rotulo: 'Separador:',
                  controller: _separadorController,
                  centralizado: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CampoLinha(
                  rotulo: 'Início:',
                  controller: _inicioController,
                  centralizado: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Caminho: ${_caminhoSaida ?? 'Não selecionado'}',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF8E9BA8),
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: BotaoTeal(
              rotulo: 'SELECIONAR',
              onPressed: _selecionarCaminho,
            ),
          ),
        ],
      ),
    );
  }
}
