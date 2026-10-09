import 'package:appcraft_utils_flutter/appcraft_utils_flutter.dart';
import 'package:test/test.dart';

/// Creates a notifier that is disposed after the test.
_StringNotifier _notifier({bool resendLastEvent = false}) {
  final notifier = _StringNotifier(resendLastEvent: resendLastEvent);
  addTearDown(notifier.dispose);
  return notifier;
}

/// Subscribes to [notifier] collecting events; cancelled after the test.
List<String> _collect(_StringNotifier notifier) {
  final events = <String>[];
  addTearDown(notifier.listen(events.add).cancel);
  return events;
}

void main() {
  group('ACNotifier', () {
    test('does not resend the last event by default', () {
      final notifier = _StringNotifier();
      addTearDown(notifier.dispose);

      expect(notifier.resendLastEvent, isFalse);
    });

    test('delivers events in order to every subscriber', () async {
      final notifier = _notifier();
      final first = _collect(notifier);
      final second = _collect(notifier);

      notifier
        ..send('a')
        ..send('b');
      await pumpEventQueue();

      expect(first, ['a', 'b']);
      expect(second, ['a', 'b']);
    });

    test('listenAny is called once per event', () async {
      final notifier = _notifier();
      var calls = 0;
      addTearDown(notifier.listenAny(() => calls++).cancel);

      notifier
        ..send('a')
        ..send('b');
      await pumpEventQueue();

      expect(calls, 2);
    });

    test('accepts null callbacks', () async {
      final notifier = _notifier();
      addTearDown(notifier.listen(null).cancel);
      addTearDown(notifier.listenAny(null).cancel);
      final events = _collect(notifier);

      notifier.send('a');
      await pumpEventQueue();

      expect(events, ['a']);
    });

    test('drops an event sent without subscribers', () async {
      final notifier = _notifier()..send('lost');
      final events = _collect(notifier);

      notifier.send('b');
      await pumpEventQueue();

      expect(events, ['b']);
    });

    test('resends only the last stored event to the first subscriber',
        () async {
      final notifier = _notifier(resendLastEvent: true)
        ..send('a')
        ..send('b');

      final first = _collect(notifier);
      await pumpEventQueue();
      final second = _collect(notifier);
      await pumpEventQueue();

      expect(first, ['b']);
      expect(second, isEmpty);
    });

    test('stops delivering events after cancel', () async {
      final notifier = _notifier();
      final events = <String>[];
      final subscription = notifier.listen(events.add);

      await subscription.cancel();
      notifier.send('a');
      await pumpEventQueue();

      expect(events, isEmpty);
    });

    test('dispose completes current and new subscriptions', () async {
      final notifier = _notifier();
      var currentDone = false;
      var newDone = false;
      final current = notifier.listen(null)..onDone(() => currentDone = true);
      addTearDown(current.cancel);

      await notifier.dispose();
      final afterDispose = notifier.listen(null)..onDone(() => newDone = true);
      addTearDown(afterDispose.cancel);
      await pumpEventQueue();

      expect(currentDone, isTrue);
      expect(newDone, isTrue);
    });

    // NOTE: possible bug, see report
    test('listen throws after dispose when an event is stored', () async {
      final notifier = _notifier(resendLastEvent: true)..send('stored');

      await notifier.dispose();

      expect(() => notifier.listen(null), throwsStateError);
    });
  });
}

class _StringNotifier extends ACNotifier<String> {
  _StringNotifier({super.resendLastEvent});
}
