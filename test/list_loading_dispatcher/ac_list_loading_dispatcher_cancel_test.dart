import 'dart:async';

import 'package:appcraft_utils_flutter/src/list_loading_dispatcher/src/ac_cancel_strategy.dart';
import 'package:appcraft_utils_flutter/src/list_loading_dispatcher/src/ac_list_loading_dispatcher.dart';
import 'package:appcraft_utils_flutter/src/list_loading_dispatcher/src/ac_list_loading_params.dart';
import 'package:appcraft_utils_flutter/src/list_loading_dispatcher/src/ac_list_loading_parser.dart';
import 'package:test/test.dart';

import 'helpers/fake_loader.dart';

/// Minimal implementation of [ACListLoadingParamsMixin] used only in tests.
final class _TestParams with ACListLoadingParamsMixin {
  const _TestParams({this.limit, this.offset, this.query});

  @override
  final int? limit;
  @override
  final int? offset;
  @override
  final String? query;
}

/// Default parser: items pass through verbatim, `hasMore` derived from length.
ACParseResult<int> _listParser(List<int> response) => ACParseResult<int>(
  items: response,
  hasMore: response.length >= 2,
);

/// Spy implementation of [ACCancelStrategy] used to verify which strategy the
/// dispatcher actually picks per call.
///
/// The spy delegates its actual cancellation semantics to an internal
/// [ACOperationCancelStrategy] so that the dispatcher's interaction with
/// `run`/`cancel` remains realistic (awaited futures still complete through
/// `valueOrCancellation`). It simply counts calls to the two methods.
final class _SpyCancelStrategy implements ACCancelStrategy {
  _SpyCancelStrategy();

  int runCalls = 0;
  int cancelCalls = 0;
  final ACOperationCancelStrategy _inner = ACOperationCancelStrategy();

  @override
  Future<T?> run<T>(Future<T> future) {
    runCalls++;
    return _inner.run<T>(future);
  }

  @override
  Future<void> cancel() async {
    cancelCalls++;
    await _inner.cancel();
  }

  @override
  bool get isActive => _inner.isActive;
}

ACListLoadingDispatcher<int, List<int>> _buildDispatcher({
  ACCancelStrategy? defaultCancelStrategy,
}) =>
    ACListLoadingDispatcher<int, List<int>>(
      parser: _listParser,
      defaultCancelStrategy: defaultCancelStrategy,
    );

void main() {
  group('ACListLoadingDispatcher — cancel strategy override (US3)', () {
    test('reload with per-call cancelStrategy uses the supplied strategy',
        () async {
      // Arrange
      final dispatcher = _buildDispatcher();
      final spy = _SpyCancelStrategy();
      final loader = FakeLoader<List<int>>();
      loader.enqueueValue(<int>[1, 2, 3]);

      // Act
      await dispatcher.reload<_TestParams>(
        params: const _TestParams(),
        load: loader.call,
        cancelStrategy: spy,
      );

      // Assert — the override was consulted and the load completed through it.
      expect(spy.runCalls, equals(1),
          reason: 'override strategy must wrap the loader Future once');
      expect(loader.callCount, equals(1));
      expect(dispatcher.items, equals(<int>[1, 2, 3]));
      expect(dispatcher.isLoading, isFalse);
      expect(dispatcher.error, isNull);

      await dispatcher.dispose();
    });

    test('after an override reload, a subsequent reload without override '
        'falls back to the constructor default', () async {
      // Arrange
      final spyDefault = _SpyCancelStrategy();
      final spyOverride = _SpyCancelStrategy();
      final dispatcher = _buildDispatcher(defaultCancelStrategy: spyDefault);
      final loader = FakeLoader<List<int>>();
      loader.enqueueValue(<int>[1, 2]);
      loader.enqueueValue(<int>[3, 4]);

      // Act — first call with override, second call without.
      await dispatcher.reload<_TestParams>(
        params: const _TestParams(),
        load: loader.call,
        cancelStrategy: spyOverride,
      );
      await dispatcher.reload<_TestParams>(
        params: const _TestParams(),
        load: loader.call,
      );

      // Assert — each spy saw exactly one run.
      expect(spyOverride.runCalls, equals(1),
          reason: 'override strategy handled only the first reload');
      expect(spyDefault.runCalls, equals(1),
          reason: 'default strategy handled the second reload');
      expect(loader.callCount, equals(2));
      expect(dispatcher.items, equals(<int>[3, 4]));

      await dispatcher.dispose();
    });

    test('reload with override while another override-reload is in flight '
        'cancels the previous override and runs the new one', () async {
      // Arrange
      final dispatcher = _buildDispatcher();
      final firstSpy = _SpyCancelStrategy();
      final secondSpy = _SpyCancelStrategy();

      final firstGate = Completer<List<int>>();
      Future<List<int>> firstLoad(_TestParams _) => firstGate.future;
      final secondLoader = FakeLoader<List<int>>();
      secondLoader.enqueueValue(<int>[9, 8, 7]);

      // Act — start a slow reload with the first override, then kick off a
      // second reload with a different override while the first is pending.
      final firstFuture = dispatcher.reload<_TestParams>(
        params: const _TestParams(),
        load: firstLoad,
        cancelStrategy: firstSpy,
      );
      final secondFuture = dispatcher.reload<_TestParams>(
        params: const _TestParams(),
        load: secondLoader.call,
        cancelStrategy: secondSpy,
      );
      // Release the first loader so its Future can resolve; its result must be
      // discarded because the strategy has been cancelled.
      firstGate.complete(<int>[1, 1, 1]);
      await Future.wait(<Future<void>>[firstFuture, secondFuture]);

      // Assert
      expect(firstSpy.runCalls, equals(1),
          reason: 'first override started the load');
      expect(firstSpy.cancelCalls, greaterThanOrEqualTo(1),
          reason: 'the superseded override must be cancelled');
      expect(secondSpy.runCalls, equals(1),
          reason: 'second override runs the new load');
      expect(dispatcher.items, equals(<int>[9, 8, 7]),
          reason: 'only the second result may land in items');
      expect(dispatcher.isLoading, isFalse);

      await dispatcher.dispose();
    });

    test('loadMore with per-call cancelStrategy uses the supplied strategy',
        () async {
      // Arrange — seed the dispatcher so hasMore stays true.
      final dispatcher = _buildDispatcher();
      final seedLoader = FakeLoader<List<int>>();
      seedLoader.enqueueValue(<int>[1, 2]);
      await dispatcher.reload<_TestParams>(
        params: const _TestParams(),
        load: seedLoader.call,
      );
      expect(dispatcher.hasMore, isTrue);

      final spy = _SpyCancelStrategy();
      final loadMoreLoader = FakeLoader<List<int>>();
      loadMoreLoader.enqueueValue(<int>[3, 4]);

      // Act
      await dispatcher.loadMore<_TestParams>(
        params: const _TestParams(offset: 2),
        load: loadMoreLoader.call,
        cancelStrategy: spy,
      );

      // Assert
      expect(spy.runCalls, equals(1),
          reason: 'loadMore must honour the per-call override');
      expect(dispatcher.items, equals(<int>[1, 2, 3, 4]));
      expect(dispatcher.isLoading, isFalse);

      await dispatcher.dispose();
    });

    test('no default, no override: a reload can still cancel a prior reload '
        '(fresh ACOperationCancelStrategy is used each call)', () async {
      // Arrange — dispatcher has neither a default strategy nor overrides.
      final dispatcher = _buildDispatcher();
      final firstGate = Completer<List<int>>();
      Future<List<int>> firstLoad(_TestParams _) => firstGate.future;
      final secondLoader = FakeLoader<List<int>>();
      secondLoader.enqueueValue(<int>[5, 6]);

      // Act — two back-to-back reloads; the first one blocks on a completer.
      final firstFuture = dispatcher.reload<_TestParams>(
        params: const _TestParams(),
        load: firstLoad,
      );
      final secondFuture = dispatcher.reload<_TestParams>(
        params: const _TestParams(),
        load: secondLoader.call,
      );
      firstGate.complete(<int>[1, 1, 1]);
      await Future.wait(<Future<void>>[firstFuture, secondFuture]);

      // Assert — second result wins, demonstrating that the fallback strategy
      // correctly cancelled the first one even without a shared spy.
      expect(dispatcher.items, equals(<int>[5, 6]));
      expect(dispatcher.isLoading, isFalse);

      await dispatcher.dispose();
    });

    test('defaultCancelStrategy is accessible via getter and reflects the '
        'constructor argument', () async {
      // Arrange — dispatcher with explicit default.
      final spyDefault = _SpyCancelStrategy();
      final dispatcherWithDefault =
          _buildDispatcher(defaultCancelStrategy: spyDefault);
      // Dispatcher without default.
      final dispatcherWithoutDefault = _buildDispatcher();

      // Act & Assert
      expect(dispatcherWithDefault.defaultCancelStrategy, same(spyDefault));
      expect(dispatcherWithoutDefault.defaultCancelStrategy, isNull);

      await dispatcherWithDefault.dispose();
      await dispatcherWithoutDefault.dispose();
    });

    test('per-call override wins over defaultCancelStrategy', () async {
      // Arrange
      final spyDefault = _SpyCancelStrategy();
      final spyOverride = _SpyCancelStrategy();
      final dispatcher = _buildDispatcher(defaultCancelStrategy: spyDefault);
      final loader = FakeLoader<List<int>>();
      loader.enqueueValue(<int>[1, 2]);

      // Act — single reload with an explicit override.
      await dispatcher.reload<_TestParams>(
        params: const _TestParams(),
        load: loader.call,
        cancelStrategy: spyOverride,
      );

      // Assert — only the override's `run` was consulted; the default stays
      // untouched despite being registered on the dispatcher.
      expect(spyOverride.runCalls, equals(1));
      expect(spyDefault.runCalls, equals(0),
          reason: 'per-call override must take precedence over the default');
      expect(dispatcher.items, equals(<int>[1, 2]));

      await dispatcher.dispose();
    });
  });
}
