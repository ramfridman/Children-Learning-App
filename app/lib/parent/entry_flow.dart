import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/state.dart';
import '../security/parent_session.dart';
import 'gate_screen.dart';
import 'parent_area.dart';
import 'pin_screens.dart';

/// The way into the parent area from the child space: the gate, then the PIN, then the area. Each
/// step replaces the one before, so "back" never leads from the area to a step already passed. The
/// area closes itself (and returns to the child space) when the session locks.
Future<void> openParentArea(BuildContext context, WidgetRef ref) {
  final NavigatorState nav = Navigator.of(context);
  final ParentSession session = ref.read(parentSessionProvider);

  Route<void> area() => MaterialPageRoute<void>(builder: (BuildContext c) => _AreaHost(session: session));
  Route<void> pin() => MaterialPageRoute<void>(
    builder: (BuildContext c) => PinEntryScreen(
      onCancel: nav.pop,
      onUnlocked: () async {
        await session.unlock();
        nav.pushReplacement(area());
      },
    ),
  );
  return nav.push(
    MaterialPageRoute<void>(
      builder: (BuildContext c) => GateScreen(onCancel: nav.pop, onPassed: () => nav.pushReplacement(pin())),
    ),
  );
}

/// Shows the parent area while the session is open, and leaves it as soon as the session locks.
class _AreaHost extends StatefulWidget {
  const _AreaHost({required this.session});

  final ParentSession session;

  @override
  State<_AreaHost> createState() => _AreaHostState();
}

class _AreaHostState extends State<_AreaHost> {
  @override
  void initState() {
    super.initState();
    widget.session.unlocked.addListener(_onChange);
  }

  @override
  void dispose() {
    widget.session.unlocked.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (!widget.session.unlocked.value && mounted) {
      Navigator.of(context).popUntil((Route<dynamic> r) => r.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    // The system back button locks the area: leaving it always means locking it.
    onPopInvokedWithResult: (bool didPop, Object? result) => widget.session.lock(),
    child: ParentArea(onClose: widget.session.lock),
  );
}
