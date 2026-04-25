import 'dart:async';

/// Базовый нотификатор событий типа [T].
///
/// Оборачивает [StreamController] в режиме broadcast и предоставляет
/// удобные методы для подписки и отправки событий.
abstract class ACNotifier<T> {
  /// Создаёт нотификатор.
  ///
  /// Если [resendLastEvent] равен `true`, то при отсутствии подписчиков
  /// последнее событие будет сохранено и переотправлено первому
  /// появившемуся подписчику.
  ACNotifier({
    this.resendLastEvent = false
  });

  /// Если `true`,
  /// то при попытке отправить событие и при отстуствии подсписчиков, событие будет сохраненою.
  /// А при подписке будет отправлено последнее сохранённое событие.
  final bool resendLastEvent;
  T? _lastEvent;

  final _streamController = StreamController<T>.broadcast();

  /// Подписывается на события и вызывает [onData] для каждого события.
  ///
  /// Возвращает [ACNotifierSub], управляющий жизненным циклом подписки.
  ACNotifierSub<T> listen(void onData(T event)?) {
    final subscription = _streamController
      .stream
      .listen(onData);
    _trySendLastEvent();
    return subscription;
  }

  /// Подписывается на события и вызывает [onData] без передачи значения.
  ///
  /// Удобно, когда содержимое события не важно — важен только факт его получения.
  ACNotifierSub<T> listenAny(void onData()?) {
    final subscription = _streamController
      .stream
      .listen((_) {
        onData?.call();
      });
    _trySendLastEvent();
    return subscription;
  }

  /// Отправляет [event] подписчикам.
  ///
  /// Если подписчиков нет и [resendLastEvent] равен `true`,
  /// событие сохраняется и будет отправлено первому подписчику.
  void send(T event) {
    if (_streamController.hasListener) {
      _streamController.add(event);
    } else if (resendLastEvent) {
      _lastEvent = event;
    }
  }

  void _trySendLastEvent() {
    if (!resendLastEvent) return;

    final lastEvent = _lastEvent;
    if (lastEvent == null) return;
    _streamController.add(lastEvent);
    _lastEvent = null;
  }

  /// Закрывает внутренний поток и освобождает ресурсы нотификатора.
  Future<void> dispose() async =>
    _streamController.close();

}

/// Подписка на события [ACNotifier].
typedef ACNotifierSub<T> = StreamSubscription<T>;