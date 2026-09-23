import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Gerencia a notificação de progresso na barra de status
/// (serviço em primeiro plano).
class ServicoNotificacao {
  ServicoNotificacao._();

  static bool _inicializado = false;

  /// Inicializa as opções do serviço (chamar uma vez no app).
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
      ),
    );
    _inicializado = true;
  }

  /// Solicita a permissão de notificação (Android 13+).
  static Future<NotificationPermission> pedirPermissao() {
    return FlutterForegroundTask.requestNotificationPermission();
  }

  /// Inicia o serviço com uma notificação de progresso.
  static Future<void> iniciar({
    required String titulo,
    required String texto,
  }) async {
    await FlutterForegroundTask.startService(
      notificationTitle: titulo,
      notificationText: texto,
    );
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