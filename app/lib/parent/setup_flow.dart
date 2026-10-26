import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/state.dart';
import '../core/errors.dart';
import '../design/app_text.dart';
import '../design/components.dart';
import '../design/tokens.g.dart';
import '../strings/he.dart';
import 'backends.dart';
import 'child_form.dart';
import 'pin_screens.dart';

enum SetupStep { welcome, signIn, enrol, pin, child }

/// First launch, adult UI: sign in with the emailed code, register this device as a parent device,
/// choose the parent PIN, and add the first child. The PIN always comes before the first profile,
/// because on a shared device it is the only thing between a child and the parent area.
class SetupFlow extends ConsumerStatefulWidget {
  const SetupFlow({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  ConsumerState<SetupFlow> createState() => _SetupFlowState();
}

class _SetupFlowState extends ConsumerState<SetupFlow> {
  SetupStep? _step;
  final TextEditingController _email = TextEditingController();
  final TextEditingController _code = TextEditingController();
  bool _codeSent = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _decideStart();
  }

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  /// Picks up where an interrupted setup stopped.
  Future<void> _decideStart() async {
    final SetupBackend backend = ref.read(setupBackendProvider);
    final AppState state = await ref.read(appStateProvider.future);
    SetupStep step = SetupStep.welcome;
    if (state.enrolled) {
      step = state.pinSet ? SetupStep.child : SetupStep.pin;
    } else if (await backend.hasSession()) {
      step = SetupStep.enrol;
    }
    if (mounted) setState(() => _step = step);
  }

  Future<void> _run(Future<void> Function() action, {String? onError}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on GatewayException catch (e) {
      _error = e.code == 'auth_failed' ? (onError ?? He.setupError.text) : He.setupError.text;
    } on Object {
      _error = He.setupError.text;
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _sendCode() => _run(() async {
    await ref.read(setupBackendProvider).sendCode(_email.text.trim());
    _codeSent = true;
  });

  Future<void> _verify() => _run(() async {
    await ref.read(setupBackendProvider).verifyCode(_email.text.trim(), _code.text.trim());
    _step = SetupStep.enrol;
  }, onError: He.setupWrongCode.text);

  Future<void> _enrol() => _run(() async {
    await ref.read(setupBackendProvider).enrol();
    await ref.read(appStateProvider.notifier).reload();
    _step = SetupStep.pin;
  });

  Widget _page(String title, List<Widget> children) => Scaffold(
    backgroundColor: TokenColors.parentBg,
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: AppText.parent(TokenType.parentH1)),
                const SizedBox(height: 12),
                ...children,
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _error!,
                      style: AppText.parent(TokenType.parentSmall, color: TokenColors.domainNumbersDeep),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _body(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Text(text, style: AppText.parent(TokenType.parentBody)),
  );

  @override
  Widget build(BuildContext context) {
    switch (_step) {
      case null:
        return const Scaffold(
          backgroundColor: TokenColors.parentBg,
          body: Center(child: CircularProgressIndicator()),
        );
      case SetupStep.welcome:
        return _page(He.setupWelcomeTitle.text, <Widget>[
          _body(He.setupWelcomeBody.text),
          ParentButton(label: He.setupStart.text, onPressed: () => setState(() => _step = SetupStep.signIn)),
        ]);
      case SetupStep.signIn:
        return _page(He.setupWelcomeTitle.text, <Widget>[
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(labelText: He.setupEmail.text, border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          ParentButton(label: He.setupSendCode.text, onPressed: _busy ? null : _sendCode),
          if (_codeSent) ...<Widget>[
            const SizedBox(height: 16),
            _body(He.setupCodeSent.text),
            TextField(
              controller: _code,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(labelText: He.setupCode.text, border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            ParentButton(label: He.setupVerify.text, onPressed: _busy ? null : _verify),
          ],
        ]);
      case SetupStep.enrol:
        return _page(He.setupEnrolTitle.text, <Widget>[
          _body(He.setupEnrolBody.text),
          ParentButton(label: He.setupEnrolButton.text, onPressed: _busy ? null : _enrol),
        ]);
      case SetupStep.pin:
        return PinSetupScreen(
          onDone: () async {
            await ref.read(appStateProvider.notifier).reload();
            if (mounted) setState(() => _step = SetupStep.child);
          },
        );
      case SetupStep.child:
        return ChildFormScreen(onSaved: widget.onFinished);
    }
  }
}
