// ignore_for_file: cascade_invocations, unused_element_parameter, prefer_const_constructors
import 'dart:async';

import 'package:appcraft_utils_flutter/src/list_loading_dispatcher/src/ac_cancel_strategy.dart';
import 'package:appcraft_utils_flutter/src/list_loading_dispatcher/src/ac_list_loading_dispatcher.dart';
import 'package:appcraft_utils_flutter/src/list_loading_dispatcher/src/ac_list_loading_params.dart';
import 'package:appcraft_utils_flutter/src/list_loading_dispatcher/src/ac_list_loading_result.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_loader.dart';

/// Minimal implementation of [ACListLoadingParamsMixin] used only in tests.
final class _TestParams with ACListLoadingParamsMixin, ACOffsetListLoadingParamsMixin {
  const _TestParams({this.limit, this.offset, this.query});

  @override
  final int? limit;
  @override
  final int? offset;
  @override
  final String? query;
}

/// DTO that mixes in [ACListLoadingResult].
final class _TestPage<T> with ACListLoadingResult<T> {
  const _TestPage(this.items, {this.hasMore = true});

  @override
  final List<T> items;
  @override
  final bool hasMore;
}

/// Spy [ACCancelStrategy] used to verify which strategy the dispatcher picks
/// per call.
///
/// Delegates the actual cancellation semantics to an internal
/// [ACOperationCancelStrategy] so dispatcher interactions stay realistic
/// (awaited futures still resolve through `valueOrCancellation`). Tracks the
/// number of `run`/`cancel` invocations.
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

ACListLoadingDispatcher<int> _buildDispatcher() =>
    ACListLoadingDispatcher<int>();

void main() {
  group('ACListLoadingDispatcher — cancel strategy (US3, post-T047)', () {
    test('reload with per-call cancelStrategy uses the supplied strategy',
        () async {
      // Arrange
      final dispatcher = _buildDispatcher();
      final spy = _SpyCancelStrategy();
      final loader = FakeLoader<ACListLoadingResult<int>>();
      loader.enqueueValue(_TestPage<int>(<int>[1, 2, 3], hasMore: true));

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

      dispatcher.dispose();
    });

    test('loadMore with per-call cancelStrategy uses the supplied strategy',
        () async {
      // Arrange — seed the dispatcher so hasMore stays true.
      final dispatcher = _buildDispatcher();
      final seedLoader = FakeLoader<ACListLoadingResult<int>>();
      seedLoader.enqueueValue(_TestPage<int>(<int>[1, 2], hasMore: true));
      await dispatcher.reload<_TestParams>(
        params: const _TestParams(),
        load: seedLoader.call,
      );
      expect(dispatcher.hasMore, isTrue);

      final spy = _SpyCancelStrategy();
      final loadMoreLoader = FakeLoader<ACListLoadingResult<int>>();
      loadMoreLoader.enqueueValue(_TestPage<int>(<int>[3, 4], hasMore: true));

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

      dispatcher.dispose();
    });

    test('reload with override while another override-reload is in flight '
        'cancels the previous override and runs the new one', () async {
      // Arrange
      final dispatcher = _buildDispatcher();
      final firstSpy = _SpyCancelStrategy();
      final secondSpy = _SpyCancelStrategy();

      final firstGate = Completer<ACListLoadingResult<int>>();
      Future<ACListLoadingResult<int>> firstLoad(_TestParams _) =>
          firstGate.future;
      final secondLoader = FakeLoader<ACListLoadingResult<int>>();
      secondLoader.enqueueValue(_TestPage<int>(<int>[9, 8, 7], hasMore: true));

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
      // Release the first loader so its Future can resolve; its result must
      // be discarded because the strategy was cancelled.
      firstGate.complete(_TestPage<int>(<int>[1, 1, 1], hasMore: true));
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

      dispatcher.dispose();
    });

    test('consecutive reloads without override: each call uses a fresh '
        'strategy; second cancels the first', () async {
      // Arrange — no default, no override. Dispatcher must internally spin
      // up a new ACOperationCancelStrategy per call.
      final dispatcher = _buildDispatcher();
      final firstGate = Completer<ACListLoadingResult<int>>();
      Future<ACListLoadingResult<int>> firstLoad(_TestParams _) =>
          firstGate.future;
      final secondLoader = FakeLoader<ACListLoadingResult<int>>();
      secondLoader.enqueueValue(_TestPage<int>(<int>[5, 6], hasMore: true));

      // Act — two back-to-back reloads; the first one blocks on a completer.
      final firstFuture = dispatcher.reload<_TestParams>(
        params: const _TestParams(),
        load: firstLoad,
      );
      final secondFuture = dispatcher.reload<_TestParams>(
        params: const _TestParams(),
        load: secondLoader.call,
      );
      firstGate.complete(_TestPage<int>(<int>[1, 1, 1], hasMore: true));
      await Future.wait(<Future<void>>[firstFuture, secondFuture]);

      // Assert — only the second result lands, confirming the first was
      // cancelled by a fresh per-call strategy.
      expect(dispatcher.items, equals(<int>[5, 6]));
      expect(dispatcher.isLoading, isFalse);

      dispatcher.dispose();
    });

    test('per-call override on first reload does NOT leak into the second '
        'reload (no shared state between calls)', () async {
      // Arrange
      final dispatcher = _buildDispatcher();
      final firstSpy = _SpyCancelStrategy();
      final loader = FakeLoader<ACListLoadingResult<int>>()
        ..enqueueValue(_TestPage<int>(<int>[1, 2], hasMore: true))
        ..enqueueValue(_TestPage<int>(<int>[3, 4], hasMore: true));

      // Act — first reload with override; second reload without.
      await dispatcher.reload<_TestParams>(
        params: const _TestParams(),
        load: loader.call,
        cancelStrategy: firstSpy,
      );
      await dispatcher.reload<_TestParams>(
        params: const _TestParams(),
        load: loader.call,
      );

      // Assert — override was used only once; subsequent run did NOT touch it.
      expect(firstSpy.runCalls, equals(1),
          reason: 'override is per-call, not persistent');
      expect(loader.callCount, equals(2));
      expect(dispatcher.items, equals(<int>[3, 4]));

      dispatcher.dispose();
    });
  });
}
