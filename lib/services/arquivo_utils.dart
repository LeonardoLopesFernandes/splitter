import 'dart:io';

import 'package:path/path.dart' as p;

/// Serviço com a lógica de dividir, juntar e visualizar arquivos.
/// Replicado fielmente do app "Divisor de Arquivos" (com.direstudio.utils.filesplitter).
///
/// Todo o IO é assíncrono para não bloquear a interface e permitir
/// atualização de progresso sem travar/crashar o app.
class ArquivoUtils {
  ArquivoUtils._();

  static const int _tamanhoBuffer = 1 << 20;

  /// Divide [arquivoOrigem] em [quantidade] partes.
  /// [inicio] é o índice da primeira parte (padrão original: 1).
  /// [separador] é o texto entre nome e número (padrão original: "_").
  /// [extensao] vazia = partes sem extensão; senão "nome_separador_numero.ext".
  /// Distribui o resto (leftover) uma parte por vez, como o original.
  static Future<List<String>> dividirPorNumero({
    required String arquivoOrigem,
    required String diretorioDestino,
    required String nome,
    required String separador,
    required String extensao,
    required int inicio,
    required int quantidade,
    void Function(int parte, int total, double percentual)? aoProgresso,
  }) async {
    final origem = File(arquivoOrigem);
    final tamanhoTotal = await origem.length();
    if (tamanhoTotal <= 0) {
      throw const FormatException(
          'Arquivo inválido ou vazio. Selecione um arquivo válido.');
    }
    if (quantidade <= 0) {
      throw const FormatException('Número de arquivos inválido.');
    }
    if (tamanhoTotal < quantidade) {
      throw const FormatException(
          'O número de arquivos não pode ser maior que o tamanho do arquivo.');
    }

    final tamanhoPorParte = tamanhoTotal ~/ quantidade;
    if (tamanhoPorParte <= 0) {
      throw const FormatException('Tamanho da parte inválido.');
    }
    var leftover = tamanhoTotal % (tamanhoPorParte * quantidade);

    final reader = await origem.open();
    final buffer = List<int>.filled(_tamanhoBuffer, 0);
    final partes = <String>[];

    try {
      for (var i = 0; i < quantidade; i++) {
        var tamanhoParte = tamanhoPorParte;
        if (leftover > 0) {
          leftover--;
          tamanhoParte += 1;
        }

        final numero = inicio + i;
        final nomeParte = extensao.isEmpty
            ? '$nome$separador$numero'
            : '$nome$separador$numero.$extensao';
        final caminhoParte = p.join(diretorioDestino, nomeParte);
        final destino = File(caminhoParte);

        if (await destino.exists()) {
          throw const FormatException(
              'O arquivo já existe. Escolha outro nome!');
        }
        await destino.create();

        final writer = await destino.open(mode: FileMode.write);
        var bytesEscritos = 0;
        try {
          while (bytesEscritos < tamanhoParte) {
            final restante = tamanhoParte - bytesEscritos;
            final leitura =
                restante < buffer.length ? restante : buffer.length;
            final lidos = await reader.readInto(buffer, 0, leitura);
            if (lidos <= 0) break;
            await writer.writeFrom(buffer, 0, lidos);
            bytesEscritos += lidos;
          }
        } finally {
          await writer.close();
        }

        partes.add(caminhoParte);
        aoProgresso?.call(i + 1, quantidade, (i + 1) / quantidade);
      }
    } finally {
      await reader.close();
    }

    return partes;
  }

  /// Divide [arquivoOrigem] em partes de [tamanho] na [unidade] ("B", "KB", "MB").
  static Future<List<String>> dividirPorTamanho({
    required String arquivoOrigem,
    required String diretorioDestino,
    required String nome,
    required String separador,
    required String extensao,
    required int inicio,
    required double tamanho,
    required String unidade,
    void Function(int parte, int total, double percentual)? aoProgresso,
  }) async {
    final origem = File(arquivoOrigem);
    final tamanhoTotal = await origem.length();
    if (tamanhoTotal <= 0) {
      throw const FormatException(
          'Arquivo inválido ou vazio. Selecione um arquivo válido.');
    }

    final multiplicador = _multiplicadorDaUnidade(unidade);
    final tamanhoPorParte = (tamanho * multiplicador).round();
    if (tamanhoPorParte <= 0) {
      throw const FormatException('Tamanho da parte inválido.');
    }
    if (tamanhoPorParte > tamanhoTotal) {
      throw const FormatException(
          'O tamanho da parte não pode ser maior que o arquivo.');
    }

    final totalPartes = (tamanhoTotal / tamanhoPorParte).ceil();
    final reader = await origem.open();
    final buffer = List<int>.filled(_tamanhoBuffer, 0);
    final partes = <String>[];

    try {
      for (var i = 0; i < totalPartes; i++) {
        final numero = inicio + i;
        final nomeParte = extensao.isEmpty
            ? '$nome$separador$numero'
            : '$nome$separador$numero.$extensao';
        final caminhoParte = p.join(diretorioDestino, nomeParte);
        final destino = File(caminhoParte);

        if (await destino.exists()) {
          throw const FormatException(
              'O arquivo já existe. Escolha outro nome!');
        }
        await destino.create();

        final writer = await destino.open(mode: FileMode.write);
        var bytesEscritos = 0;
        try {
          while (bytesEscritos < tamanhoPorParte) {
            final restante = tamanhoPorParte - bytesEscritos;
            final leitura =
                restante < buffer.length ? restante : buffer.length;
            final lidos = await reader.readInto(buffer, 0, leitura);
            if (lidos <= 0) break;
            await writer.writeFrom(buffer, 0, lidos);
            bytesEscritos += lidos;
          }
        } finally {
          await writer.close();
        }

        partes.add(caminhoParte);
        aoProgresso?.call(i + 1, totalPartes, (i + 1) / totalPartes);
      }
    } finally {
      await reader.close();
    }

    return partes;
  }

  static int _multiplicadorDaUnidade(String unidade) {
    switch (unidade.toUpperCase()) {
      case 'KB':
        return 1000;
      case 'MB':
        return 1000000;
      default:
        return 1;
    }
  }

  /// Junta [partes] em um único arquivo, na ordem em que foram passadas
  /// (a ordenação é responsabilidade da interface, como no app original).
  /// Nome final: "nome" ou "nome.extensao" (o original usava nome + "_merge").
  static Future<String> juntarArquivos({
    required List<String> partes,
    required String diretorioDestino,
    required String nome,
    String extensao = '',
    void Function(int parte, int total, double percentual)? aoProgresso,
  }) async {
    if (partes.isEmpty) {
      throw const FormatException('Nenhum arquivo foi selecionado.');
    }

    final nomeSaida = extensao.isEmpty ? nome : '$nome.$extensao';
    final caminhoSaida = p.join(diretorioDestino, nomeSaida);
    final destino = File(caminhoSaida);

    if (await destino.exists()) {
      throw const FormatException(
          'O arquivo já existe. Escolha outro nome!');
    }
    await destino.create();

    final writer = await destino.open(mode: FileMode.write);
    final buffer = List<int>.filled(_tamanhoBuffer, 0);

    try {
      for (var i = 0; i < partes.length; i++) {
        final origem = File(partes[i]);
        final reader = await origem.open();
        try {
          while (true) {
            final lidos = await reader.readInto(buffer, 0, buffer.length);
            if (lidos <= 0) break;
            await writer.writeFrom(buffer, 0, lidos);
          }
        } finally {
          await reader.close();
        }
        aoProgresso?.call(
          i + 1,
          partes.length,
          (i + 1) / partes.length,
        );
      }
    } finally {
      await writer.close();
    }

    return caminhoSaida;
  }

  /// Ordena [partes] de forma natural (001, 002, ..., 010, ...).
  /// Usado pelo botão de ordenação da interface, como o SortDialog original.
  static List<String> ordenarPartes(List<String> partes) {
    return _ordenarPartes(partes);
  }

  /// Lê e retorna o conteúdo textual de [caminho] (máx. ~10 MB).
  static Future<String> lerConteudo(String caminho) async {
    final arquivo = File(caminho);
    final tamanho = await arquivo.length();
    if (tamanho > 10 * 1024 * 1024) {
      throw const FormatException(
          'Arquivo muito grande para visualização. Limite: 10 MB.');
    }
    return arquivo.readAsString();
  }

  /// Ordena nomes de partes de forma natural (001, 002, ..., 010, ...).
  static List<String> _ordenarPartes(List<String> partes) {
    final ordenadas = [...partes];
    ordenadas.sort((a, b) => _compararNatural(a, b));
    return ordenadas;
  }

  static int _compararNatural(String a, String b) {
    final regex = RegExp(r'(\d+|\D+)');
    final tokensA = regex.allMatches(a).map((m) => m.group(0)!).toList();
    final tokensB = regex.allMatches(b).map((m) => m.group(0)!).toList();

    final limite =
        tokensA.length < tokensB.length ? tokensA.length : tokensB.length;

    for (var i = 0; i < limite; i++) {
      final ta = tokensA[i];
      final tb = tokensB[i];
      final na = int.tryParse(ta);
      final nb = int.tryParse(tb);
      if (na != null && nb != null) {
        if (na != nb) return na.compareTo(nb);
      } else {
        final cmp = ta.compareTo(tb);
        if (cmp != 0) return cmp;
      }
    }
    return tokensA.length.compareTo(tokensB.length);
  }

  /// Formata um tamanho em bytes para exibição amigável.
  static String formatarBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}