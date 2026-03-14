import 'package:flutter/material.dart';
import 'package:aurora/features/chat/presentation/widgets/viewport_preserving_sliver_list.dart';
import 'package:flutter_test/flutter_test.dart';

class _HarnessHost extends StatefulWidget {
  const _HarnessHost({super.key});

  @override
  State<_HarnessHost> createState() => _HarnessHostState();
}

class _HarnessHostState extends State<_HarnessHost> {
  final ScrollController _scrollController = ScrollController();
  final bool _keepScrollPosition = true;
  bool _isStreaming = true;
  bool _autoScrollEnabled = false;
  bool _activeInteraction = false;
  bool _preserveScrollLock = false;
  bool _pendingPreserveLockRelease = false;
  bool _releaseCheckScheduled = false;
  bool _observedSizeChangeSinceReleaseCheck = false;
  double _trackedHeight = 120;
  int _trackedChangeCount = 0;

  bool get lockActive => _preserveScrollLock || _pendingPreserveLockRelease;

  void jumpTo(double offset) {
    _scrollController.jumpTo(offset);
  }

  void setTrackedHeight(double height) {
    setState(() {
      _trackedHeight = height;
    });
  }

  void setStreaming(bool value) {
    setState(() {
      _isStreaming = value;
    });
  }

  void setAutoScrollEnabled(bool value) {
    setState(() {
      _autoScrollEnabled = value;
    });
  }

  void setActiveInteraction(bool value) {
    setState(() {
      _activeInteraction = value;
    });
  }

  void _engageLock() {
    _preserveScrollLock = true;
    _pendingPreserveLockRelease = false;
    _observedSizeChangeSinceReleaseCheck = false;
  }

  void _releaseLock() {
    _preserveScrollLock = false;
    _pendingPreserveLockRelease = false;
    _releaseCheckScheduled = false;
    _observedSizeChangeSinceReleaseCheck = false;
  }

  void _beginReleaseWindow() {
    if (!_preserveScrollLock || _pendingPreserveLockRelease) return;
    _pendingPreserveLockRelease = true;
    _observedSizeChangeSinceReleaseCheck = false;
    _scheduleReleaseCheck();
  }

  void _scheduleReleaseCheck() {
    if (_releaseCheckScheduled) return;
    _releaseCheckScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _releaseCheckScheduled = false;
      if (!mounted || !_pendingPreserveLockRelease) return;
      if (_observedSizeChangeSinceReleaseCheck) {
        _observedSizeChangeSinceReleaseCheck = false;
        _scheduleReleaseCheck();
        return;
      }
      setState(_releaseLock);
    });
  }

  void _handleTrackedSizeChange() {
    _trackedChangeCount++;
    if (!lockActive) return;
    if (_pendingPreserveLockRelease) {
      _observedSizeChangeSinceReleaseCheck = true;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preserveEligible = _keepScrollPosition && !_autoScrollEnabled;
    if (_isStreaming && preserveEligible) {
      _engageLock();
    } else if (!preserveEligible) {
      _releaseLock();
    } else {
      _beginReleaseWindow();
    }

    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            Text('lock:${lockActive ? 'on' : 'off'}'),
            Expanded(
              child: CustomScrollView(
                cacheExtent: 5000,
                controller: _scrollController,
                reverse: true,
                slivers: [
                  ViewportPreservingSliverList(
                    preserveScrollOffset: lockActive &&
                        !_activeInteraction &&
                        !_autoScrollEnabled,
                    onTrackedChildExtentChanged: _handleTrackedSizeChange,
                    delegate: SliverChildListDelegate.fixed([
                      ViewportPreservingTrackedItem(
                        itemId: 'tracked',
                        child: Container(
                          key: const ValueKey<String>('tracked-item'),
                          height: _trackedHeight,
                          alignment: Alignment.center,
                          color: Colors.blue.shade100,
                          child: const Text('tracked'),
                        ),
                      ),
                      for (var i = 0; i < 20; i++)
                        ViewportPreservingTrackedItem(
                          itemId: 'old-$i',
                          child: Container(
                            key: ValueKey<String>('old-$i'),
                            height: 80,
                            alignment: Alignment.center,
                            color:
                                i.isEven ? Colors.grey.shade200 : Colors.white,
                            child: Text('old $i'),
                          ),
                        ),
                    ],
                        addAutomaticKeepAlives: false,
                        addRepaintBoundaries: false,
                        addSemanticIndexes: false),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  testWidgets('synchronous correction keeps old content fixed in the same pump',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 820));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final key = GlobalKey<_HarnessHostState>();
    await tester.pumpWidget(_HarnessHost(key: key));
    await tester.pump();

    final state = key.currentState!;
    state.jumpTo(280);
    await tester.pump();

    final beforeY =
        tester.getTopLeft(find.byKey(const ValueKey<String>('old-5'))).dy;

    state.setTrackedHeight(300);
    await tester.pump();

    expect(state._trackedChangeCount, greaterThan(0));

    final afterY =
        tester.getTopLeft(find.byKey(const ValueKey<String>('old-5'))).dy;
    expect(afterY, closeTo(beforeY, 0.1));
  });

  testWidgets('auto-scroll mode stays pinned to bottom without correction',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 820));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final key = GlobalKey<_HarnessHostState>();
    await tester.pumpWidget(_HarnessHost(key: key));
    await tester.pump();

    final state = key.currentState!;
    state.setAutoScrollEnabled(true);
    await tester.pump();

    state.setTrackedHeight(320);
    await tester.pump();

    expect(state._scrollController.position.pixels, closeTo(0, 0.1));
  });

  testWidgets('active interaction suppresses synchronous correction',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 820));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final key = GlobalKey<_HarnessHostState>();
    await tester.pumpWidget(_HarnessHost(key: key));
    await tester.pump();

    final state = key.currentState!;
    state.jumpTo(280);
    await tester.pump();
    state.setActiveInteraction(true);
    await tester.pump();

    final beforeY =
        tester.getTopLeft(find.byKey(const ValueKey<String>('old-5'))).dy;

    state.setTrackedHeight(320);
    await tester.pump();

    final afterY =
        tester.getTopLeft(find.byKey(const ValueKey<String>('old-5'))).dy;
    expect((afterY - beforeY).abs(), greaterThan(20));
  });

  testWidgets('lock releases only after one stable post-stream frame',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 820));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final key = GlobalKey<_HarnessHostState>();
    await tester.pumpWidget(_HarnessHost(key: key));
    await tester.pump();

    final state = key.currentState!;
    expect(find.text('lock:on'), findsOneWidget);

    state.setTrackedHeight(280);
    await tester.pump();
    state.setStreaming(false);
    state.setTrackedHeight(320);
    await tester.pump();

    expect(find.text('lock:on'), findsOneWidget);

    await tester.pump();
    expect(find.text('lock:on'), findsOneWidget);

    await tester.pump();
    expect(find.text('lock:off'), findsOneWidget);
  });
}
