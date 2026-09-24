import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

import '../services/arquivo_utils.dart';
import '../services/permissao_utils.dart';
import '../services/servico_notificacao.dart';
import '../services/servico_operacoes_background.dart';
import '../widgets/dialog_ordenacao.dart';
import '../widgets/file_browser_dialog.dart';
import '../widgets/modal_progresso.dart';

import 'package:flutter_foreground_task/flutter_foreground_task.dart'
    show NotificationPermission;

class MergeScreen extends StatefulWidget {
  const MergeScreen({super.key});

  @override
  State<MergeScreen> createState() => _MergeScreenState();
}

class _MergeScreenState extends State<MergeScreen> {
  static const Color _primaryTeal = Color(0xFF00897B);
  static const Color _headerTeal = Color(0xFF009688);
  static const Color _cardBg = Color(0xFF1B2430);
  static const Color _innerBoxBg = Color(0xFF353E4B);
  static const Color _labelTextColor = Color(0xFF8E9FAE);
  static const Color _placeholderColor = Color(0xFF4E5C6A);

  List<String> _partesSelecionadas = [];
  String? _caminhoSaida;
  bool _processando = false;
  bool _emSegundoPlano = false;
  bool _emSegundoPlanoFoiAtivado = false;
  double _progresso = 0;
  int _bytesLidos = 0;
  int _bytesTotal = 1;
  String? _mensagemErro;
  StreamSubscription<EventoProgressoOperacao>? _subscription;

  final _nomeController = TextEditingController();
  final _extensaoController = TextEditingController();

  @override
  void dispose() {
    ServicoNotificacao.removeListener(_aoDadosDoServico);
    _subscription?.cancel();
    _nomeController.dispose();
    _extensaoController.dispose();
    super.dispose();
  }

  Future<void> _selecionarPartes() async {
    final resultado = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      dialogTitle: 'Selecione os arquivos para juntar',
      type: FileType.any,
    );
    if (resultado == null || resultado.files.isEmpty) return;
    setState(() {
      final novos = resultado.files
          .map((f) => f.path)
          .whereType<String>()
          .toList();
      _partesSelecionadas = [..._partesSelecionadas, ...novos];
      _mensagemErro = null;
      if (_nomeController.text.isEmpty && _partesSelecionadas.isNotEmpty) {
        final base = p.basenameWithoutExtension(_partesSelecionadas.first);
        _nomeController.text = base.replaceAll(RegExp(r'(_parte|_\d+)'), '');
      }
    });
  }

  void _removerParte(int indice) {
    setState(() {
      _partesSelecionadas.removeAt(indice);
    });
  }

  Future<void> _ordenarAZ() async {
    final resultado = await showDialog<ResultadoOrdenacao>(
      context: context,
      builder: (_) => const DialogOrdenacao(),
    );
    if (resultado == null || !mounted) return;
    setState(() {
      _partesSelecionadas = ArquivoUtils.ordenarPartesPor(
        partes: _partesSelecionadas,
        criterio: resultado.criterio,
        decrescente: resultado.decrescente,
      );
    });
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
      _bytesLidos = 0;
      _bytesTotal = 1;
    });

    // Tenta executar no TaskHandler do serviço (continua em segundo plano).
    final permissaoNotificacao =
        await ServicoNotificacao.pedirPermissao();
    if (!mounted) return;

    final notificacaoPermitida =
        permissaoNotificacao == NotificationPermission.granted;

    if (notificacaoPermitida) {
      await ServicoNotificacao.iniciar(
        titulo: 'Juntando arquivos...',
        texto: '0%',
      );
      _emSegundoPlanoFoiAtivado = true;
      ServicoNotificacao.addListener(_aoDadosDoServico);
      setState(() {
        _emSegundoPlano = true;
        _mensagemErro = null;
      });
      await ServicoNotificacao.enviarOperacao({
        'tipo': 'juntar',
        'partes': _partesSelecionadas,
        'diretorioDestino': _caminhoSaida,
        'nome': nome,
        'extensao': _extensaoController.text.trim(),
      });
      return;
    }

    // Sem permissão de notificação: executa no isolate local (só em foreground).
    final stream = ServicoOperacoesBackground.instance.juntar(
      partes: _partesSelecionadas,
      diretorioDestino: _caminhoSaida!,
      nome: nome,
      extensao: _extensaoController.text.trim(),
    );

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
          if (evento.caminhoResultado != null) {
            _mostrarResultado(evento.caminhoResultado!);
          }
        }
      },
      onError: (erro) {
        if (!mounted) return;
        setState(() {
          _processando = false;
          _mensagemErro = 'Falha ao juntar - $erro';
        });
      },
    );
  }

  void _aoDadosDoServico(List<Object?> dados) {
    if (dados.isEmpty || !mounted) return;
    final controle = dados[0] as String;
    switch (controle) {
      case 'progresso':
        setState(() {
          _bytesLidos = dados[1] as int;
          _bytesTotal = dados[2] as int;
          _progresso = dados[3] as double;
        });
        break;
      case 'concluido':
        ServicoNotificacao.removeListener(_aoDadosDoServico);
        setState(() {
          _processando = false;
          _emSegundoPlano = false;
        });
        if (_emSegundoPlanoFoiAtivado) {
          ServicoNotificacao.parar();
          _emSegundoPlanoFoiAtivado = false;
        }
        if (dados.length > 1 && dados[1] is String) {
          _mostrarResultado(dados[1] as String);
        }
        break;
      case 'erro':
        ServicoNotificacao.removeListener(_aoDadosDoServico);
        setState(() {
          _processando = false;
          _emSegundoPlano = false;
          _mensagemErro = 'Falha ao juntar - ${dados[1]}';
        });
        if (_emSegundoPlanoFoiAtivado) {
          ServicoNotificacao.parar();
          _emSegundoPlanoFoiAtivado = false;
        }
        break;
      case 'cancelado':
        ServicoNotificacao.removeListener(_aoDadosDoServico);
        setState(() {
          _processando = false;
          _emSegundoPlano = false;
          _mensagemErro = 'Junção cancelada.';
        });
        if (_emSegundoPlanoFoiAtivado) {
          ServicoNotificacao.parar();
          _emSegundoPlanoFoiAtivado = false;
        }
        break;
    }
  }

  void _cancelarOperacao() {
    if (_emSegundoPlano) {
      ServicoNotificacao.cancelarOperacao();
    } else {
      // Executando no isolate local (sem notificação): cancela o isolate.
      _subscription?.cancel();
      _subscription = null;
      ServicoOperacoesBackground.cancelar();
      setState(() {
        _processando = false;
        _mensagemErro = 'Junção cancelada.';
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
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14.0,
                      vertical: 8.0,
                    ),
                    child: Column(
                      children: [
                        Expanded(child: _cardArquivosEntrada()),
                        const SizedBox(height: 12),
                        _cardArquivoSaida(),
                        const SizedBox(height: 12),
                        _botaoJuntar(),
                        if (_mensagemErro != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _mensagemErro!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xFFEF5350)),
                          ),
                        ],
                      ],
                    ),
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
                      titulo: 'Juntando...',
                      emSegundoPlano: _emSegundoPlano,
                      onSegundoPlano: null,
                      onCancelar: _cancelarOperacao,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _cardArquivosEntrada() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              ImageIcon(
                AssetImage('assets/icons/ic_input.png'),
                color: _headerTeal,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Arquivos de entrada',
                style: TextStyle(
                  color: _headerTeal,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _partesSelecionadas.isEmpty
                    ? 'Nenhum arquivo selecionado.'
                    : '${_partesSelecionadas.length} arquivo(s) selecionado(s).',
                style: const TextStyle(
                  color: _labelTextColor,
                  fontSize: 13,
                ),
              ),
              Row(
                children: [
                  _botaoSelecionar(_selecionarPartes),
                  const SizedBox(width: 8),
                  _botaoAz(),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _partesSelecionadas.isEmpty
                ? Container(
                    decoration: BoxDecoration(
                      color: _innerBoxBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: _innerBoxBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: ListView.builder(
                      itemCount: _partesSelecionadas.length,
                      itemBuilder: (ctx, i) {
                        final caminho = _partesSelecionadas[i];
                        final arquivo = File(caminho);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.basename(caminho),
                                      style: const TextStyle(
                                        color: Color(0xFFA0B0C0),
                                        fontSize: 13,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${ArquivoUtils.formatarBytes(arquivo.lengthSync())}'
                                      '  '
                                      '${ArquivoUtils.formatarDataModificacao(arquivo)}',
                                      style: const TextStyle(
                                        color: Color(0xFF5D7182),
                                        fontSize: 11,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () => _removerParte(i),
                                borderRadius: BorderRadius.circular(50),
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEF5350),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _cardArquivoSaida() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              ImageIcon(
                AssetImage('assets/icons/ic_output.png'),
                color: _headerTeal,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Arquivo de saída',
                style: TextStyle(
                  color: _headerTeal,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                'Nome:  ',
                style: TextStyle(color: _labelTextColor, fontSize: 13),
              ),
              Expanded(
                child: TextField(
                  controller: _nomeController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Nome do arquivo',
                    hintStyle: TextStyle(
                      color: _placeholderColor,
                      fontSize: 13,
                    ),
                    isDense: true,
                    contentPadding: EdgeInsets.only(bottom: 4),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: _placeholderColor),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: _headerTeal),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Extensão:  ',
                style: TextStyle(color: _labelTextColor, fontSize: 13),
              ),
              SizedBox(
                width: 70,
                child: TextField(
                  controller: _extensaoController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Extensão',
                    hintStyle: TextStyle(
                      color: _placeholderColor,
                      fontSize: 13,
                    ),
                    isDense: true,
                    contentPadding: EdgeInsets.only(bottom: 4),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: _placeholderColor),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: _headerTeal),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Text(
                      'Caminho:  ',
                      style: TextStyle(color: _labelTextColor, fontSize: 13),
                    ),
                    Expanded(
                      child: Text(
                        _caminhoSaida ?? 'Não selecionado',
                        style: const TextStyle(
                          color: _placeholderColor,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _botaoSelecionar(_selecionarCaminho),
            ],
          ),
        ],
      ),
    );
  }

  Widget _botaoJuntar() {
    return Material(
      color: _primaryTeal,
      borderRadius: BorderRadius.circular(6),
      elevation: 0,
      child: InkWell(
        onTap: _processando ? null : _juntar,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: double.infinity,
          height: 48,
          alignment: Alignment.center,
          child: const Text(
            'JUNTAR',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
    );
  }

  Widget _botaoSelecionar(VoidCallback? onPressed) {
    return Material(
      color: _primaryTeal,
      borderRadius: BorderRadius.circular(6),
      elevation: 0,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            'SELECIONAR',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _botaoAz() {
    return Material(
      color: _primaryTeal,
      borderRadius: BorderRadius.circular(6),
      elevation: 0,
      child: InkWell(
        onTap: _ordenarAZ,
        borderRadius: BorderRadius.circular(6),
        child: const Padding(
          padding: EdgeInsets.all(6),
          child: ImageIcon(
            AssetImage('assets/icons/ic_sort_name.png'),
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }
}