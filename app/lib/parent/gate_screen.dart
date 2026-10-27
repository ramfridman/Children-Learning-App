import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/state.dart';
import '../design/app_text.dart';
import '../design/components.dart';
import '../design/tokens.g.dart';
import '../security/parent_gate.dart';
import '../strings/he.dart';
import '../design/layout.dart';
import 'entry_layout.dart';
import 'keypad.dart';

/// The parent gate: a small sum in digits on a shuffled keypad. It is the first
/// of two steps (the PIN is the second) and a speed bump against children, not security by itself.
class GateScreen extends ConsumerStatefulWidget {
  const GateScreen({super.key, required this.onPassed, required this.onCancel});

  final VoidCallback onPassed;
  final VoidCallback onCancel;

  @override
  ConsumerState<GateScreen> createState() => _GateScreenState();
}

class _GateScreenState extends ConsumerState<GateScreen> {
  late GateQuestion _question = ref.read(parentGateProvider).newQuestion();
  String _entered = '';
  String? _message;
  Duration? _waiting;
  bool _longWait = false;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    unawaited(_checkWaiting());
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _checkWaiting() async {
    final GateWait? w = await ref.read(parentGateProvider).waiting();
    if (!mounted) return;
    _setWaiting(w);
  }

  void _setWaiting(GateWait? w) {
    _tick?.cancel();
    setState(() {
      _waiting = w?.remaining;
      _longWait = w?.long ?? false;
    });
    if (w == null) return;
    _tick = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      final Duration left = (_waiting ?? Duration.zero) - const Duration(seconds: 1);
      if (left <= Duration.zero) {
        t.cancel();
        setState(() {
          _waiting = null;
          _message = null;
          _question = ref.read(parentGateProvider).newQuestion();
        });
      } else {
        setState(() => _waiting = left);
      }
    });
  }

  Future<void> _submit() async {
    final GateOutcome o = await ref.read(parentGateProvider).submit(_question, _entered);
    if (!mounted) return;
    switch (o) {
      case GateOk():
        widget.onPassed();
      case GateWrong():
        setState(() {
          _entered = '';
          _message = He.gateWrong.text;
          _question = ref.read(parentGateProvider).newQuestion();
        });
      case GateWait():
        _entered = '';
        _setWaiting(o);
    }
  }

  String? get _waitText {
    final Duration? w = _waiting;
    if (w == null) return null;
    return _longWait
        ? He.gateLong.fill(<String, String>{'m': '${(w.inSeconds / 60).ceil()}'})
        : He.gateCoolDown.fill(<String, String>{'s': '${w.inSeconds}'});
  }

  @override
  Widget build(BuildContext context) {
    final bool waiting = _waiting != null;
    return EntryLayout(
      title: He.gateTitle.text,
      hint: waiting ? _waitText! : He.gateHint.text,
      error: waiting ? null : _message,
      display: waiting
          ? const SizedBox(height: 56)
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  He.gateQuestion.text,
                  style: AppText.parent(TokenType.parentH2),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                MathIsolate(
                  child: Text(
                    _question.expression,
                    key: const Key('gate-sum'),
                    style: AppText.parent(TokenType.parentStat, color: TokenColors.night),
                  ),
                ),
                const SizedBox(height: 8),
                // The answer being typed is shown as digits (it is a number, not a secret).
                MathIsolate(
                  child: Text(
                    _entered.isEmpty ? ' ' : _entered,
                    style: AppText.parent(TokenType.parentStat, color: TokenColors.night),
                  ),
                ),
              ],
            ),
      keypad: ParentKeypad(
        order: _question.keypad,
        enabled: !waiting,
        onDigit: (int d) {
          if (_entered.length < 3) setState(() => _entered += '$d');
        },
        onDelete: () {
          if (_entered.isNotEmpty) {
            setState(() => _entered = _entered.substring(0, _entered.length - 1));
          }
        },
      ),
      actions: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          ParentButton(label: He.gateBack.text, quiet: true, onPressed: widget.onCancel),
          const SizedBox(width: 12),
          ParentButton(label: He.pinOk.text, onPressed: waiting || _entered.isEmpty ? null : _submit),
        ],
      ),
    );
  }
}
