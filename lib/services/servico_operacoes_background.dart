import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';

import 'arquivo_utils.dart';

/// Evento de progresso de uma operação em segundo plano.
@immutable
class EventoProgressoOperacao {
  const EventoProgressoOperacao({
    required this.bytesLidos,
    required this.bytesTotal,
    required this.percentual,
    required this.concluido,
    required this.titulo,
    this.partes,
    this.caminhoResultado,
    this.erro,
  });

  final int bytesLidos;
  final int bytesTotal;
  final double percentual;
  final bool concluido;
  final String titulo;
  final List<String>? partes;
  final String? caminhoResultado;
  final String? erro;
}

/// Executa divisão/junção em um isolate separado (segundo plano),
/// mantendo a interface fluida e reportando progresso via stream.
class ServicoOperacoesBackground {
  ServicoOperacoesBackground._();

  static final _instance = ServicoOperacoesBackground._();
  static ServicoOperacoesBackground get instance => _instance;

  /// Divide [arquivoOrigem] em [quantidade] partes em segundo plano.
  /// Emite eventos de progresso e um evento final com as partes criadas.
  Stream<EventoProgressoOperacao> dividirPorNumero({
    required String arquivoOrigem,
    required String diretorioDestino,
    required String nome,
    required String separador,
    required String extensao,
    required int inicio,
    required int quantidade,
  }) {
    return _executar(
      tipo: 'dividir_numero',
      parametros: _Parametros(
        arquivoOrigem: arquivoOrigem,
        diretorioDestino: diretorioDestino,
        nome: nome,
        separador: separador,
        extensao: extensao,
        inicio: inicio,
        quantidade: quantidade,
      ),
      titulo: 'Dividindo...',
    );
  }

  /// Divide [arquivoOrigem] em partes de [tamanho] na [unidade].
  Stream<EventoProgressoOperacao> dividirPorTamanho({
    required String arquivoOrigem,
    required String diretorioDestino,
    required String nome,
    required String separador,
    required String extensao,
    required int inicio,
    required double tamanho,
    required String unidade,
  }) {
    return _executar(
      tipo: 'dividir_tamanho',
      parametros: _Parametros(
        arquivoOrigem: arquivoOrigem,
        diretorioDestino: diretorioDestino,
        nome: nome,
        separador: separador,
        extensao: extensao,
        inicio: inicio,
        tamanho: tamanho,
        unidade: unidade,
      ),
      titulo: 'Dividindo...',
    );
  }

  /// Junta [partes] em um único arquivo em segundo plano.
  Stream<EventoProgressoOperacao> juntar({
    required List<String> partes,
    required String diretorioDestino,
    required String nome,
    required String extensao,
  }) {
    return _executar(
      tipo: 'juntar',
      parametros: _Parametros(
        partes: partes,
        diretorioDestino: diretorioDestino,
        nome: nome,
        extensao: extensao,
      ),
      titulo: 'Juntando...',
    );
  }

  Stream<EventoProgressoOperacao> _executar({
    required String tipo,
    required _Parametros parametros,
    required String titulo,
  }) {
    final controller = StreamController<EventoProgressoOperacao>();
    final receivePort = ReceivePort();

    receivePort.listen((mensagem) {
      if (mensagem is List) {
        // [tipo_controle, dados]
        final controle = mensagem[0] as String;
        final dados = mensagem[1];
        switch (controle) {
          case 'progresso':
            controller.add(EventoProgressoOperacao(
              bytesLidos: dados[0] as int,
              bytesTotal: dados[1] as int,
              percentual: dados[2] as double,
              concluido: false,
              titulo: titulo,
            ));
            break;
          case 'concluido':
            controller.add(EventoProgressoOperacao(
              bytesLidos: dados[1] as int,
              bytesTotal: dados[2] as int,
              percentual: 1,
              concluido: true,
              titulo: titulo,
              partes: dados[0] is List<String> ? dados[0] : null,
              caminhoResultado: dados[0] is String ? dados[0] : null,
            ));
            controller.close();
            receivePort.close();
            break;
          case 'erro':
            controller.add(EventoProgressoOperacao(
              bytesLidos: 0,
              bytesTotal: 0,
              percentual: 0,
              concluido: false,
              titulo: titulo,
              erro: dados as String,
            ));
            controller.close();
            receivePort.close();
            break;
        }
      }
    });

    Isolate.spawn(
      _worker,
      (tipo, parametros, receivePort.sendPort),
    );

    return controller.stream;
  }
}

class _Parametros {
  const _Parametros({
    this.arquivoOrigem,
    this.diretorioDestino,
    this.nome,
    this.separador,
    this.extensao,
    this.inicio,
    this.quantidade,
    this.tamanho,
    this.unidade,
    this.partes,
  });

  final String? arquivoOrigem;
  final String? diretorioDestino;
  final String? nome;
  final String? separador;
  final String? extensao;
  final int? inicio;
  final int? quantidade;
  final double? tamanho;
  final String? unidade;
  final List<String>? partes;
}

void _worker(dynamic mensagem) {
  final tipo = mensagem[0] as String;
  final params = mensagem[1] as _Parametros;
  final sendPort = mensagem[2] as SendPort;

  void enviarProgresso(int lidos, int total, double percentual) {
    sendPort.send(['progresso', [lidos, total, percentual]]);
  }

  try {
    if (tipo == 'dividir_numero') {
      final resultado = ArquivoUtils.dividirPorNumero(
        arquivoOrigem: params.arquivoOrigem!,
        diretorioDestino: params.diretorioDestino!,
        nome: params.nome!,
        separador: params.separador!,
        extensao: params.extensao!,
        inicio: params.inicio!,
        quantidade: params.quantidade!,
        aoProgresso: enviarProgresso,
      );
      resultado.then((partes) {
        sendPort.send(['concluido', [partes, 0, 0]]);
      }).catchError((e) {
        sendPort.send(['erro', e.toString()]);
      });
    } else if (tipo == 'dividir_tamanho') {
      final resultado = ArquivoUtils.dividirPorTamanho(
        arquivoOrigem: params.arquivoOrigem!,
        diretorioDestino: params.diretorioDestino!,
        nome: params.nome!,
        separador: params.separador!,
        extensao: params.extensao!,
        inicio: params.inicio!,
        tamanho: params.tamanho!,
        unidade: params.unidade!,
        aoProgresso: enviarProgresso,
      );
      resultado.then((partes) {
        sendPort.send(['concluido', [partes, 0, 0]]);
      }).catchError((e) {
        sendPort.send(['erro', e.toString()]);
      });
    } else if (tipo == 'juntar') {
      final resultado = ArquivoUtils.juntarArquivos(
        partes: params.partes!,
        diretorioDestino: params.diretorioDestino!,
        nome: params.nome!,
        extensao: params.extensao!,
        aoProgresso: enviarProgresso,
      );
      resultado.then((caminho) {
        sendPort.send(['concluido', [caminho, 0, 0]]);
      }).catchError((e) {
        sendPort.send(['erro', e.toString()]);
      });
    }
  } catch (e) {
    sendPort.send(['erro', e.toString()]);
  }
}