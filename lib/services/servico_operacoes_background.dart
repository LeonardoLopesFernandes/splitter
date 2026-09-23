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
      parametros: <String, Object>{
        'arquivoOrigem': arquivoOrigem,
        'diretorioDestino': diretorioDestino,
        'nome': nome,
        'separador': separador,
        'extensao': extensao,
        'inicio': inicio,
        'quantidade': quantidade,
      },
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
      parametros: <String, Object>{
        'arquivoOrigem': arquivoOrigem,
        'diretorioDestino': diretorioDestino,
        'nome': nome,
        'separador': separador,
        'extensao': extensao,
        'inicio': inicio,
        'tamanho': tamanho,
        'unidade': unidade,
      },
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
      parametros: <String, Object>{
        'partes': partes,
        'diretorioDestino': diretorioDestino,
        'nome': nome,
        'extensao': extensao,
      },
      titulo: 'Juntando...',
    );
  }

  Stream<EventoProgressoOperacao> _executar({
    required String tipo,
    required Map<String, Object> parametros,
    required String titulo,
  }) {
    final controller = StreamController<EventoProgressoOperacao>();
    final receivePort = ReceivePort();

    receivePort.listen((mensagem) {
      if (mensagem is List) {
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
      <Object>[tipo, parametros, receivePort.sendPort],
    ).then((isolate) {
      // Mantém o isolate vivo enquanto a operação roda.
      // O isolate se encerra sozinho após enviar 'concluido'/'erro'.
    }).catchError((erro) {
      if (!controller.isClosed) {
        controller.add(EventoProgressoOperacao(
          bytesLidos: 0,
          bytesTotal: 0,
          percentual: 0,
          concluido: false,
          titulo: titulo,
          erro: 'Falha ao iniciar o processamento: $erro',
        ));
        controller.close();
        receivePort.close();
      }
    });

    return controller.stream;
  }
}

void _worker(dynamic mensagem) {
  final tipo = mensagem[0] as String;
  final params = mensagem[1] as Map;
  final sendPort = mensagem[2] as SendPort;

  void enviarProgresso(int lidos, int total, double percentual) {
    sendPort.send(<Object>['progresso', <Object>[lidos, total, percentual]]);
  }

  try {
    if (tipo == 'dividir_numero') {
      final resultado = ArquivoUtils.dividirPorNumero(
        arquivoOrigem: params['arquivoOrigem'] as String,
        diretorioDestino: params['diretorioDestino'] as String,
        nome: params['nome'] as String,
        separador: params['separador'] as String,
        extensao: params['extensao'] as String,
        inicio: params['inicio'] as int,
        quantidade: params['quantidade'] as int,
        aoProgresso: enviarProgresso,
      );
      resultado.then((partes) {
        sendPort.send(<Object>['concluido', <Object>[partes, 0, 0]]);
      }).catchError((e) {
        sendPort.send(<Object>['erro', e.toString()]);
      });
    } else if (tipo == 'dividir_tamanho') {
      final resultado = ArquivoUtils.dividirPorTamanho(
        arquivoOrigem: params['arquivoOrigem'] as String,
        diretorioDestino: params['diretorioDestino'] as String,
        nome: params['nome'] as String,
        separador: params['separador'] as String,
        extensao: params['extensao'] as String,
        inicio: params['inicio'] as int,
        tamanho: (params['tamanho'] as num).toDouble(),
        unidade: params['unidade'] as String,
        aoProgresso: enviarProgresso,
      );
      resultado.then((partes) {
        sendPort.send(<Object>['concluido', <Object>[partes, 0, 0]]);
      }).catchError((e) {
        sendPort.send(<Object>['erro', e.toString()]);
      });
    } else if (tipo == 'juntar') {
      final resultado = ArquivoUtils.juntarArquivos(
        partes: (params['partes'] as List).cast<String>(),
        diretorioDestino: params['diretorioDestino'] as String,
        nome: params['nome'] as String,
        extensao: params['extensao'] as String,
        aoProgresso: enviarProgresso,
      );
      resultado.then((caminho) {
        sendPort.send(<Object>['concluido', <Object>[caminho, 0, 0]]);
      }).catchError((e) {
        sendPort.send(<Object>['erro', e.toString()]);
      });
    }
  } catch (e) {
    sendPort.send(<Object>['erro', e.toString()]);
  }
}