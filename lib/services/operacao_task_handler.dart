import 'dart:convert';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'arquivo_utils.dart';

/// Comandos enviados da UI para o TaskHandler (isolate do serviço).
class ComandosOperacao {
  ComandosOperacao._();

  static const String dividirNumero = 'dividir_numero';
  static const String dividirTamanho = 'dividir_tamanho';
  static const String juntar = 'juntar';
}

/// Callback de entrada do serviço (deve ser top-level/static e
/// anotado com @pragma('vm:entry-point') para rodar no isolate do serviço).
@pragma('vm:entry-point')
void operacaoCallback() {
  FlutterForegroundTask.setTaskHandler(OperacaoTaskHandler());
}

/// Executa a divisão/junção dentro do isolate do foreground service,
/// garantindo que continue em segundo plano mesmo com o app em background.
class OperacaoTaskHandler extends TaskHandler {
  void _executar(Map<String, dynamic> params) {
    final tipo = params['tipo'] as String;

    void enviarProgresso(int lidos, int total, double percentual) {
      final pct = (percentual * 100).round();
      FlutterForegroundTask.updateService(
        notificationTitle: _tituloPara(tipo),
        notificationText: '$pct% ($lidos/$total)',
      );
      FlutterForegroundTask.sendDataToMain(<Object?>[
        'progresso',
        lidos,
        total,
        percentual,
      ]);
    }

    Future<void> executar() async {
      try {
        if (tipo == ComandosOperacao.dividirNumero) {
          final partes = await ArquivoUtils.dividirPorNumero(
            arquivoOrigem: params['arquivoOrigem'] as String,
            diretorioDestino: params['diretorioDestino'] as String,
            nome: params['nome'] as String,
            separador: params['separador'] as String,
            extensao: params['extensao'] as String,
            inicio: (params['inicio'] as num?)?.toInt() ?? 1,
            quantidade: (params['quantidade'] as num).toInt(),
            aoProgresso: enviarProgresso,
          );
          FlutterForegroundTask.sendDataToMain(
            <Object?>['concluido', partes],
          );
        } else if (tipo == ComandosOperacao.dividirTamanho) {
          final partes = await ArquivoUtils.dividirPorTamanho(
            arquivoOrigem: params['arquivoOrigem'] as String,
            diretorioDestino: params['diretorioDestino'] as String,
            nome: params['nome'] as String,
            separador: params['separador'] as String,
            extensao: params['extensao'] as String,
            inicio: (params['inicio'] as num?)?.toInt() ?? 1,
            tamanho: (params['tamanho'] as num).toDouble(),
            unidade: params['unidade'] as String,
            aoProgresso: enviarProgresso,
          );
          FlutterForegroundTask.sendDataToMain(
            <Object?>['concluido', partes],
          );
        } else if (tipo == ComandosOperacao.juntar) {
          final resultado = await ArquivoUtils.juntarArquivos(
            partes: (params['partes'] as List).cast<String>(),
            diretorioDestino: params['diretorioDestino'] as String,
            nome: params['nome'] as String,
            extensao: params['extensao'] as String,
            aoProgresso: enviarProgresso,
          );
          FlutterForegroundTask.sendDataToMain(
            <Object?>['concluido', resultado],
          );
        }
        FlutterForegroundTask.updateService(
          notificationTitle: _tituloPara(tipo),
          notificationText: 'Concluído!',
        );
        FlutterForegroundTask.stopService();
      } catch (e) {
        FlutterForegroundTask.sendDataToMain(<Object?>['erro', e.toString()]);
        FlutterForegroundTask.updateService(
          notificationTitle: _tituloPara(tipo),
          notificationText: 'Falha: $e',
        );
        FlutterForegroundTask.stopService();
      }
    }

    executar();
  }

  String _tituloPara(String tipo) {
    if (tipo == ComandosOperacao.juntar) return 'Juntando arquivos...';
    return 'Dividindo arquivo...';
  }

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  void onReceiveData(Object data) {
    if (data is String && data.isNotEmpty) {
      try {
        final mapa = jsonDecode(data) as Map<String, dynamic>;
        _executar(mapa);
      } catch (_) {
        // Dados inválidos; ignora.
      }
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
}