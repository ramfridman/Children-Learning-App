import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/alerts_provider.dart';
import '../app/progress_provider.dart';
import '../app/providers.dart';
import '../app/state.dart';
import '../app/tutor_log_provider.dart';
import '../app/sync_providers.dart';
import '../sync/sync_engine.dart';
import '../app/voice_input.dart';
import '../core/config.dart' show appVersion;
import '../core/errors.dart';
import '../data/app_database.dart';
import '../design/app_text.dart';
import '../design/components.dart';
import '../design/tokens.g.dart';
import '../security/parent_session.dart';
import '../strings/he.dart';
import '../ui/dev/dev_home_page.dart';
import 'alerts_screen.dart';
import 'backends.dart';
import 'child_form.dart';
import 'pin_screens.dart';
import 'progress_screen.dart';
import 'rules_screen.dart';
import 'tutor_log_screen.dart';

/// The parent area (adult UI, calm). In M1 it holds only what the shell needs: the family's devices
/// with revoke, the child profiles, the PIN and the lock. Every tap restarts the idle clock, and the
/// area closes by itself after 5 idle minutes or when the app goes to the background.
class ParentArea extends ConsumerStatefulWidget {
  const ParentArea({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  ConsumerState<ParentArea> createState() => _ParentAreaState();
}

class _ParentAreaState extends ConsumerState<ParentArea> {
  List<DeviceInfo>? _devices;
  bool _offline = false;
  String? _voiceNote;

  @override
  void initState() {
    super.initState();
    unawaited(_loadDevices());
    // Look for alerts now, so that the parent sees today's before reading anything else.
    unawaited(
      scanForAlerts(ref).catchError((Object _) {}).then((_) => ref.read(syncRunnerProvider).now(force: true)),
    );
  }

  Future<void> _loadDevices() async {
    try {
      final List<DeviceInfo> d = await ref.read(devicesBackendProvider).list();
      if (mounted) {
        setState(() {
          _devices = d;
          _offline = false;
        });
      }
    } on Object {
      if (mounted) setState(() => _offline = true);
    }
  }

  Future<void> _setVoice(bool on) async {
    final VoiceSwitch r = await ref.read(voiceEnabledProvider.notifier).set(on);
    if (!mounted) return;
    setState(
      () => _voiceNote = switch (r) {
        VoiceSwitch.modelMissing => He.areaVoiceNoModel.text,
        VoiceSwitch.permissionDenied => He.areaVoiceNoPermission.text,
        _ => null,
      },
    );
  }

  Future<bool> _confirm(String text) async =>
      await showDialog<bool>(
        context: context,
        builder: (BuildContext c) => AlertDialog(
          content: Text(text, style: AppText.parent(TokenType.parentBody)),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.pop(c, false), child: Text(He.confirmNo.text)),
            TextButton(onPressed: () => Navigator.pop(c, true), child: Text(He.confirmYes.text)),
          ],
        ),
      ) ??
      false;

  Future<void> _revoke(DeviceInfo d) async {
    if (!await _confirm('${He.areaRevoke.text}?')) return;
    try {
      await ref.read(devicesBackendProvider).revoke(d.id);
    } on GatewayException {
      // The list below is reloaded either way, so what is shown is what the server says.
    }
    await _loadDevices();
  }

  Future<void> _remove(Profile p) async {
    if (!await _confirm(He.areaConfirmRemove.fill(<String, String>{'child': p.name}))) return;
    // Gone from this phone at once; on the server (and so from every phone) as soon as it can be reached.
    final SyncEngine? engine = await ref.read(syncEngineProvider.future);
    if (engine != null) {
      await engine.deleteChild(p.id);
    } else {
      await (await ref.read(databaseProvider.future)).deleteChildData(p.id);
    }
    await ref.read(appStateProvider.notifier).reload();
  }

  Widget _card(String title, List<Widget> children) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: TokenColors.paper,
      borderRadius: BorderRadius.circular(TokenRadius.md),
      border: Border.all(color: TokenColors.hairline, width: TokenBorder.thin),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: AppText.parent(TokenType.parentH2)),
        const SizedBox(height: 8),
        ...children,
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final AppState? app = ref.watch(appStateProvider).value;
    final ParentSession session = ref.watch(parentSessionProvider);
    final bool dev = ref.watch(configProvider).isDev;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => session.touch(),
      child: Scaffold(
        backgroundColor: TokenColors.parentBg,
        appBar: AppBar(
          backgroundColor: TokenColors.night,
          foregroundColor: Colors.white,
          title: Text(He.areaTitle.text, style: AppText.parent(TokenType.parentH2, color: Colors.white)),
          leading: IconButton(
            icon: const Icon(Icons.lock_rounded),
            tooltip: He.areaLockNow.text,
            onPressed: widget.onClose,
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _card(He.alertsTitle.text, <Widget>[
                ParentButton(
                  key: const Key('open-alerts'),
                  label: (ref.watch(unreadAlertsProvider).value ?? 0) > 0
                      ? He.alertsOpenUnread.fill(<String, String>{
                          'n': '${ref.watch(unreadAlertsProvider).value}',
                        })
                      : He.alertsOpen.text,
                  quiet: true,
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (BuildContext c) => AlertsScreen(onClose: () => Navigator.pop(c)),
                      ),
                    );
                    ref.invalidate(unreadAlertsProvider);
                  },
                ),
              ]),
              _card(He.tutorLogOpen.text, <Widget>[
                ParentButton(
                  key: const Key('open-tutor-log'),
                  label: He.tutorLogOpen.text,
                  quiet: true,
                  onPressed: () {
                    ref.invalidate(tutorLogProvider);
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (BuildContext c) => TutorLogScreen(onClose: () => Navigator.pop(c)),
                      ),
                    );
                  },
                ),
              ]),
              _card(He.areaDevices.text, <Widget>[
                if (_offline) Text(He.areaOffline.text, style: AppText.parent(TokenType.parentSmall)),
                if (_devices == null && !_offline) const LinearProgressIndicator(),
                for (final DeviceInfo d in _devices ?? const <DeviceInfo>[])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            '${d.role == 'parent' ? He.roleParent.text : He.roleChild.text}'
                            '${d.thisDevice ? ' · ${He.areaThisDevice.text}' : ''}',
                            style: AppText.parent(TokenType.parentBody),
                          ),
                        ),
                        if (!d.thisDevice)
                          ParentButton(
                            label: He.areaRevoke.text,
                            destructive: true,
                            onPressed: () => _revoke(d),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                ParentButton(label: He.areaRefresh.text, quiet: true, onPressed: _loadDevices),
              ]),
              _card(He.areaProfiles.text, <Widget>[
                for (final Profile p in app?.profiles ?? const <Profile>[])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: <Widget>[
                        Expanded(child: Text(p.name, style: AppText.parent(TokenType.parentBody))),
                        ParentButton(
                          key: Key('progress-${p.id}'),
                          label: He.areaProgress.text,
                          quiet: true,
                          onPressed: () {
                            ref.invalidate(progressProvider(p.id));
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (BuildContext c) =>
                                    ProgressScreen(profile: p, onClose: () => Navigator.pop(c)),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        ParentButton(
                          label: He.areaRemove.text,
                          destructive: true,
                          onPressed: () => _remove(p),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                ParentButton(
                  label: He.areaAddChild.text,
                  quiet: true,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (BuildContext c) => ChildFormScreen(
                        onSaved: () {
                          Navigator.pop(c);
                          unawaited(ref.read(syncRunnerProvider).now(force: true));
                        },
                        onCancel: () => Navigator.pop(c),
                      ),
                    ),
                  ),
                ),
              ]),
              _card(He.pinTitle.text, <Widget>[
                ParentButton(
                  label: He.areaChangePin.text,
                  quiet: true,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (BuildContext c) =>
                          PinSetupScreen(onDone: () => Navigator.pop(c), onCancel: () => Navigator.pop(c)),
                    ),
                  ),
                ),
              ]),
              _card(He.timeTitle.text, <Widget>[
                ParentButton(
                  key: const Key('open-time-rules'),
                  label: He.areaTimeOpen.text,
                  quiet: true,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (BuildContext c) => RulesScreen(onClose: () => Navigator.pop(c)),
                    ),
                  ),
                ),
              ]),
              _card(He.areaVoice.text, <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(He.areaVoiceHelp.text, style: AppText.parent(TokenType.parentSmall)),
                    ),
                    Switch(
                      key: const Key('voice-switch'),
                      value: ref.watch(voiceEnabledProvider).value ?? false,
                      onChanged: _setVoice,
                    ),
                  ],
                ),
                if (_voiceNote != null) Text(_voiceNote!, style: AppText.parent(TokenType.parentSmall)),
                const SizedBox(height: 4),
                Text(
                  He.areaVoiceCredit.text,
                  style: AppText.parent(TokenType.parentSmall, color: TokenColors.inkSoft),
                ),
              ]),
              ParentButton(label: He.areaLockNow.text, onPressed: widget.onClose),
              const SizedBox(height: 24),
              // Long press on the version opens the device-chain test page in the dev flavour only.
              GestureDetector(
                onLongPress: dev
                    ? () =>
                          Navigator.of(context)
                              .push(MaterialPageRoute<void>(builder: (BuildContext c) => const DevHomePage()))
                    : null,
                child: Text(
                  '${He.areaVersion.text} $appVersion',
                  style: AppText.parent(TokenType.parentSmall, color: TokenColors.inkSoft),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
