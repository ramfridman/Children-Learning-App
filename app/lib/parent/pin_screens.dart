import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/state.dart';
import '../design/components.dart';
import '../security/pin_service.dart';
import '../strings/he.dart';
import 'entry_layout.dart';
import 'keypad.dart';

String _formatWait(Duration d) => d.inMinutes >= 1
    ? He.pinMinutes.fill(<String, String>{'n': '${(d.inSeconds / 60).ceil()}'})
    : He.pinSeconds.fill(<String, String>{'n': '${d.inSeconds}'});

/// Asks for the parent PIN, the second step into the parent area.
class PinEntryScreen extends ConsumerStatefulWidget {
  const PinEntryScreen({super.key, required this.onUnlocked, required this.onCancel});

  final VoidCallback onUnlocked;
  final VoidCallback onCancel;

  @override
  ConsumerState<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends ConsumerState<PinEntryScreen> {
  String _pin = '';
  String? _error;
  Duration? _locked;
  bool _checking = false;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    unawaited(_refreshLock());
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _refreshLock() async {
    final Duration? left = await ref.read(pinServiceProvider).lockRemaining();
    if (!mounted) return;
    _showLock(left);
  }

  void _showLock(Duration? left) {
    _tick?.cancel();
    setState(() => _locked = left);
    if (left == null) return;
    _tick = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      final Duration next = (_locked ?? Duration.zero) - const Duration(seconds: 1);
      if (next <= Duration.zero) {
        t.cancel();
        setState(() {
          _locked = null;
          _error = null;
        });
      } else {
        setState(() => _locked = next);
      }
    });
  }

  Future<void> _submit() async {
    if (_checking || _pin.length < PinService.minLength) return;
    setState(() => _checking = true);
    final PinResult r = await ref.read(pinServiceProvider).verify(_pin);
    if (!mounted) return;
    // A correct PIN keeps the screen busy until the area replaces it, so the keypad never comes back to life in between.
    if (r is PinOk) {
      widget.onUnlocked();
      return;
    }
    setState(() {
      _checking = false;
      _pin = '';
    });
    switch (r) {
      case PinOk():
        widget.onUnlocked();
      case PinWrong():
        setState(() => _error = He.pinWrong.text);
        if (r.lockedFor != null) _showLock(r.lockedFor);
      case PinLocked():
        _showLock(r.remaining);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool locked = _locked != null;
    return EntryLayout(
      title: He.pinTitle.text,
      hint: locked ? He.pinLocked.fill(<String, String>{'t': _formatWait(_locked!)}) : He.pinEnter.text,
      error: locked ? null : _error,
      display: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Opacity(
            opacity: _checking ? 0.3 : 1,
            child: EntryDots(filled: _pin.length),
          ),
          if (_checking)
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(key: Key('pin-checking'), strokeWidth: 3),
            ),
        ],
      ),
      keypad: ParentKeypad(
        order: ParentKeypad.plain,
        enabled: !locked && !_checking,
        onDigit: (int d) {
          if (_pin.length < PinService.maxLength) setState(() => _pin += '$d');
        },
        onDelete: () {
          if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1));
        },
      ),
      actions: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          ParentButton(label: He.gateBack.text, quiet: true, onPressed: widget.onCancel),
          const SizedBox(width: 12),
          ParentButton(
            label: He.pinOk.text,
            onPressed: locked || _checking || _pin.length < PinService.minLength ? null : _submit,
          ),
        ],
      ),
    );
  }
}

/// Choosing the PIN: type it, then type it again.
class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key, required this.onDone, this.onCancel});

  final VoidCallback onDone;
  final VoidCallback? onCancel;

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  String _first = '';
  String _pin = '';
  bool _confirming = false;
  String? _error;
  bool _saving = false;

  Future<void> _submit() async {
    if (_pin.length < PinService.minLength || _saving) return;
    if (!_confirming) {
      setState(() {
        _first = _pin;
        _pin = '';
        _confirming = true;
        _error = null;
      });
      return;
    }
    if (_pin != _first) {
      setState(() {
        _pin = '';
        _first = '';
        _confirming = false;
        _error = He.pinMismatch.text;
      });
      return;
    }
    setState(() => _saving = true);
    await ref.read(pinServiceProvider).setPin(_pin);
    if (!mounted) return;
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) => EntryLayout(
    title: He.pinSetTitle.text,
    hint: _confirming ? He.pinConfirm.text : He.pinSetHint.text,
    error: _error,
    display: EntryDots(filled: _pin.length),
    keypad: ParentKeypad(
      order: ParentKeypad.plain,
      enabled: !_saving,
      onDigit: (int d) {
        if (_pin.length < PinService.maxLength) setState(() => _pin += '$d');
      },
      onDelete: () {
        if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1));
      },
    ),
    actions: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (widget.onCancel != null) ...<Widget>[
          ParentButton(label: He.gateBack.text, quiet: true, onPressed: widget.onCancel),
          const SizedBox(width: 12),
        ],
        ParentButton(
          label: He.pinOk.text,
          onPressed: _pin.length < PinService.minLength || _saving ? null : _submit,
        ),
      ],
    ),
  );
}
