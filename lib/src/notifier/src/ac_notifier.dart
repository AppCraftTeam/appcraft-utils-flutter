import 'dart:async';

/// Base notifier of events of type [T].
///
/// Wraps a broadcast [StreamController] and provides convenient methods
/// for subscribing to and sending events.
abstract class ACNotifier<T> {
  /// Creates a notifier.
  ///
  /// If [resendLastEvent] is `true`, then while there are no subscribers
  /// the last event is stored and resent to the first subscriber
  /// that appears.
  ACNotifier({this.resendLastEvent = false});

  /// Whether the last event is stored and resent.
  ///
  /// If `true`, an event sent while there are no subscribers is stored,
  /// and the last stored event is sent upon subscription.
  final bool resendLastEvent;
  T? _lastEvent;

  final _streamController = StreamController<T>.broadcast();

  /// Subscribes to events and calls [onData] for each event.
  ///
  /// Returns an [ACNotifierSub] that manages the subscription lifecycle.
  ACNotifierSub<T> listen(void onData(T event)?) {
    final subscription = _streamController.stream.listen(onData);
    _trySendLastEvent();
    return subscription;
  }

  /// Subscribes to events and calls [onData] without passing the value.
  ///
  /// Handy when the event content does not matter — only the fact that it
  /// was received.
  ACNotifierSub<T> listenAny(void onData()?) {
    final subscription = _streamController.stream.listen((_) {
      onData?.call();
    });
    _trySendLastEvent();
    return subscription;
  }

  /// Sends [event] to the subscribers.
  ///
  /// If there are no subscribers and [resendLastEvent] is `true`,
  /// the event is stored and will be sent to the first subscriber.
  /// After [dispose] the event is discarded.
  void send(T event) {
    if (_streamController.isClosed) return;

    if (_streamController.hasListener) {
      _streamController.add(event);
    } else if (resendLastEvent) {
      _lastEvent = event;
    }
  }

  void _trySendLastEvent() {
    if (!resendLastEvent || _streamController.isClosed) return;

    final lastEvent = _lastEvent;
    if (lastEvent == null) return;
    _streamController.add(lastEvent);
    _lastEvent = null;
  }

  /// Closes the internal stream and releases the notifier resources.
  ///
  /// The stored event is cleared. After the call [send] does nothing,
  /// and new subscriptions complete immediately without events. Calling it
  /// again is safe.
  Future<void> dispose() async {
    _lastEvent = null;
    await _streamController.close();
  }
}

/// Subscription to [ACNotifier] events.
typedef ACNotifierSub<T> = StreamSubscription<T>;
