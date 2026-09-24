import 'dart:convert';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'operacao_task_handler.dart';

/// Gerencia a notificação de progresso na barra de status
/// (serviço em primeiro plano) e a comunicação com o TaskHandler.
class ServicoNotificacao {
  ServicoNotificacao._();

  static bool _inicializado = false;

  /// Callbacks que recebem dados enviados pelo TaskHandler (isolate do serviço).
  static final List<void Function(List<Object?> dados)> _listeners = [];

  /// Inicializa o serviço (chamar uma vez no app).
  static Future<void> inicializar() async {
    if (_inicializado) return;
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'divisor_arquivos_progresso',
        channelName: 'Divisor de Arquivos - Progresso',
        channelDescription: 'Mostra o progresso das operações em segundo plano',
        priority: NotificationPriority.LOW,
        onlyAlertOnce: true,
        showWhen: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
    FlutterForegroundTask.initCommunicationPort();
    FlutterForegroundTask.addTaskDataCallback(_aoReceberDados);
    _inicializado = true;
  }

  static void _aoReceberDados(Object data) {
    if (data is List && data.isNotEmpty) {
      for (final listener in List.of(_listeners)) {
        listener(data.cast<Object?>());
      }
    }
  }

  /// Registra um listener para dados vindos do TaskHandler.
  static void addListener(void Function(List<Object?> dados) listener) {
    _listeners.add(listener);
  }

  /// Remove um listener.
  static void removeListener(void Function(List<Object?> dados) listener) {
    _listeners.remove(listener);
  }

  /// Solicita a permissão de notificação (Android 13+).
  static Future<NotificationPermission> pedirPermissao() {
    return FlutterForegroundTask.requestNotificationPermission();
  }

  /// Inicia o serviço em primeiro plano com a notificação,
  /// usando [operacaoCallback] como entry-point do TaskHandler.
  static Future<void> iniciar({
    required String titulo,
    required String texto,
  }) async {
    await FlutterForegroundTask.startService(
      callback: operacaoCallback,
      notificationTitle: titulo,
      notificationText: texto,
      notificationButtons: const [
        NotificationButton(
          id: kBotaoCancelarNotificacao,
          text: 'Cancelar',
        ),
      ],
    );
  }

  /// Envia o JSON com os parâmetros da operação para o TaskHandler.
  static Future<void> enviarOperacao(Map<String, dynamic> parametros) async {
    FlutterForegroundTask.sendDataToTask(jsonEncode(parametros));
  }

  /// Solicita o cancelamento da operação ao TaskHandler (botão da notificação
  /// ou chamado pela interface).
  static Future<void> cancelarOperacao() async {
    FlutterForegroundTask.sendDataToTask(ComandosOperacao.cancelar);
  }

  /// Atualiza o progresso na notificação.
  static Future<void> atualizar({
    required String titulo,
    required String texto,
  }) async {
    await FlutterForegroundTask.updateService(
      notificationTitle: titulo,
      notificationText: texto,
    );
  }

  /// Encerra o serviço e remove a notificação.
  static Future<void> parar() async {
    await FlutterForegroundTask.stopService();
  }
}