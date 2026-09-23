import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

import '../services/arquivo_utils.dart';
import '../services/permissao_utils.dart';
import '../widgets/modal_progresso.dart';

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
  double _progresso = 0;
  int _bytesLidos = 0;
  int _bytesTotal = 1;
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

  void _ordenarAZ() {
    setState(
      () =>
          _partesSelecionadas = ArquivoUtils.ordenarPartes(_partesSelecionadas),
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
      _bytesLidos = 0;
      _bytesTotal = 1;
    });

    void aoProgresso(int bytesLidos, int bytesTotal, double percentual) {
      if (!mounted) return;
      setState(() {
        _bytesLidos = bytesLidos;
        _bytesTotal = bytesTotal;
        _progresso = percentual;
      });
    }

    try {
      final resultado = await ArquivoUtils.juntarArquivos(
        partes: _partesSelecionadas,
        diretorioDestino: _caminhoSaida!,
        nome: nome,
        extensao: _extensaoController.text.trim(),
        aoProgresso: aoProgresso,
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
        _mensagemErro = 'Falha ao juntar - $e';
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
                _barraDeStatus(),
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
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _barraDeStatus() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '9:27',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          Row(
            children: [
              Text(
                '0,02 KB/s ',
                style: TextStyle(color: Colors.white, fontSize: 11),
              ),
              Icon(Icons.alarm, size: 14, color: Colors.white),
              SizedBox(width: 4),
              Icon(Icons.volume_off, size: 14, color: Colors.white),
              SizedBox(width: 4),
              Icon(Icons.signal_cellular_alt, size: 14, color: Colors.white),
              SizedBox(width: 4),
              Icon(Icons.battery_full, size: 14, color: Colors.white),
              Text('94', style: TextStyle(color: Colors.white, fontSize: 11)),
            ],
          ),
        ],
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
              Icon(
                Icons.insert_drive_file_outlined,
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
                  ElevatedButton(
                    onPressed: _selecionarPartes,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryTeal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text(
                      'SELECIONAR',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _ordenarAZ,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _primaryTeal,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.sort_by_alpha,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
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
              Icon(Icons.file_download_outlined, color: _headerTeal, size: 20),
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
              ElevatedButton(
                onPressed: _selecionarCaminho,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryTeal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text(
                  'SELECIONAR',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _botaoJuntar() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _processando ? null : _juntar,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryTeal,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
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
    );
  }
}