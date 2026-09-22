import 'dart:io';

import 'package:path/path.dart' as p;

/// Serviço com a lógica de dividir, juntar e visualizar arquivos.
class ArquivoUtils {
  ArquivoUtils._();

  /// Divide [arquivoOrigem] em partes de [tamanhoMb] megabytes.
  /// Retorna a lista de caminhos das partes criadas.
  static Future<List<String>> dividirArquivo({
    required String arquivoOrigem,
    required String diretorioDestino,
    required double tamanhoMb,
    void Function(int parte, int total, double percentual)? aoProgresso,
  }) async {
    final origem = File(arquivoOrigem);
    final tamanhoTotal = await origem.length();
    if (tamanhoTotal == 0) {
      throw const FormatException('O arquivo selecionado está vazio.');
    }

    final bytesPorParte = (tamanhoMb * 1024 * 1024).round();
    if (bytesPorParte <= 0) {
      throw const FormatException('Informe um tamanho válido.');
    }

    final nomeBase = p.basenameWithoutExtension(arquivoOrigem);
    final extensao = p.extension(arquivoOrigem);
    final totalPartes = (tamanhoTotal / bytesPorParte).ceil();
    final digitos = totalPartes.toString().length;

    final origemReader = origem.openSync();
    final buffer = List<int>.filled(1 << 20, 0);
    final partes = <String>[];

    try {
      for (var i = 1; i <= totalPartes; i++) {
        final nomeParte =
            '${nomeBase}_parte${i.toString().padLeft(digitos, '0')}$extensao';
        final caminhoParte = p.join(diretorioDestino, nomeParte);
        final destino = File(caminhoParte);
        final destinoWriter = destino.openSync(mode: FileMode.write);
        var bytesEscritos = 0;

        try {
          while (bytesEscritos < bytesPorParte) {
            final restante = bytesPorParte - bytesEscritos;
            final leitura =
                restante < buffer.length ? restante : buffer.length;
            final lidos = origemReader.readIntoSync(buffer, 0, leitura);
            if (lidos <= 0) break;
            destinoWriter.writeFromSync(buffer, 0, lidos);
            bytesEscritos += lidos;
          }
        } finally {
          destinoWriter.closeSync();
        }

        partes.add(caminhoParte);
        aoProgresso?.call(i, totalPartes, i / totalPartes);
      }
    } finally {
      origemReader.closeSync();
    }

    return partes;
  }

  /// Junta [partes] em um único arquivo [nomeSaida] no [diretorioDestino].
  /// Retorna o caminho do arquivo criado.
  static Future<String> juntarArquivos({
    required List<String> partes,
    required String diretorioDestino,
    required String nomeSaida,
    void Function(int parte, int total, double percentual)? aoProgresso,
  }) async {
    if (partes.isEmpty) {
      throw const FormatException('Nenhuma parte foi selecionada.');
    }

    final partesOrdenadas = _ordenarPartes(partes);
    final caminhoSaida = p.join(diretorioDestino, nomeSaida);
    final destino = File(caminhoSaida);
    final destinoWriter = destino.openSync(mode: FileMode.write);
    final buffer = List<int>.filled(1 << 20, 0);

    try {
      for (var i = 0; i < partesOrdenadas.length; i++) {
        final origem = File(partesOrdenadas[i]);
        final origemReader = origem.openSync();
        try {
          while (true) {
            final lidos = origemReader.readIntoSync(buffer, 0, buffer.length);
            if (lidos <= 0) break;
            destinoWriter.writeFromSync(buffer, 0, lidos);
          }
        } finally {
          origemReader.closeSync();
        }
        aoProgresso?.call(i + 1, partesOrdenadas.length, (i + 1) / partesOrdenadas.length);
      }
    } finally {
      destinoWriter.closeSync();
    }

    return caminhoSaida;
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

    final limite = tokensA.length < tokensB.length
        ? tokensA.length
        : tokensB.length;

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