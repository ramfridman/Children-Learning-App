import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/alerts_provider.dart';
import '../app/progress_provider.dart';
import '../app/push_providers.dart';
import '../app/providers.dart';
import '../app/reward_providers.dart';
import '../app/state.dart';
import '../app/tutor_log_provider.dart';
import '../app/sync_providers.dart';
import '../sync/sync_engine.dart';
import '../app/voice_input.dart';
import '../core/config.dart' show appVersion;
import '../core/errors.dart';
import '../data/app_database.dart';
import '../data/child_name.dart';
import '../design/app_text.dart';
import '../design/components.dart';
import '../design/tokens.g.dart';
import '../security/parent_session.dart';
import '../strings/he.dart';
import '../ui/dev/dev_home_page.dart';
import 'age_cards.dart';
import 'alerts_screen.dart';
import 'backends.dart';
import 'child_form.dart';
import 'pin_screens.dart';
import 'prizes_screen.dart';
import 'progress_screen.dart';
import 'language_pages.dart';
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
  String? _pushNote;

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

  /// The licence of the English and Russian speech models, in full (Apache-2.0 section 4: a copy goes with the files).
  Future<void> _showApacheLicence() async {
    final String text = await rootBundle.loadString('assets/licenses/apache-2.0.txt');
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (BuildContext c) => AlertDialog(
        key: const Key('voice-licence-text'),
        title: Text(He.areaVoiceLicence.text),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Text(text, style: AppText.parent(TokenType.parentSmall)),
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(c).pop(), child: Text(He.areaVoiceLicenceClose.text)),
        ],
      ),
    );
  }

  Future<void> _setPush(bool on) async {
    final PushSwitch r = await ref.read(pushEnabledProvider.notifier).set(on);
    if (!mounted) return;
    setState(
      () => _pushNote = switch (r) {
        PushSwitch.denied => He.areaPushDenied.text,
        PushSwitch.unavailable => He.areaPushUnavailable.text,
        PushSwitch.failed => He.areaPushFailed.text,
        _ => null,
      },
    );
  }

  /// Ceremonies on or off. It is one of the family's rules, so every phone follows.
  Future<void> _setCeremonies(bool on) async {
    final AppDatabase db = await ref.read(databaseProvider.future);
    await db.putSetting(ceremoniesKey, on ? 'on' : 'off');
    ref.invalidate(ceremoniesOnProvider);
    unawaited(ref.read(syncRunnerProvider).now(force: true));
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
    final String question = He.areaConfirmRemove.fill(<String, String>{'child': displayChildName(p.name)});
    if (!await _confirm(question)) return;
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
              AgeCardsColumn(profiles: app?.profiles ?? const <Profile>[]),
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
                    child: _ChildRow(
                      name: displayChildName(p.name),
                      // Saved before B-28 with more than the server takes: the family account has it cut. Its own row
                      // under the name, the width of the card, so no word is cut by the buttons (QA-B28-3).
                      note: p.name.length > childNameMaxLength
                          ? Text(
                              He.setupNameLegacyShortened.text,
                              key: Key('legacy-name-${p.id}'),
                              style: AppText.parent(TokenType.parentSmall, color: TokenColors.inkSoft),
                            )
                          : null,
                      // The settings of this child (age, screens, languages, time): its own row under the name, so the two buttons beside
                      // the name keep the room they have (a long name still stacks them under it).
                      extra: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: ParentButton(
                          key: Key('languages-${p.id}'),
                          label: He.areaChildSettings.text,
                          quiet: true,
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (BuildContext c) =>
                                  ChildSettingsScreen(profile: p, onClose: () => Navigator.pop(c)),
                            ),
                          ),
                        ),
                      ),
                      buttons: <Widget>[
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
                          key: Key('remove-${p.id}'),
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
              _card(He.areaPrizes.text, <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(He.areaCeremoniesHelp.text, style: AppText.parent(TokenType.parentSmall)),
                    ),
                    Switch(
                      key: const Key('ceremonies-switch'),
                      value: ref.watch(ceremoniesOnProvider).value ?? true,
                      onChanged: _setCeremonies,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ParentButton(
                  key: const Key('open-prizes'),
                  label: He.areaPromisesOpen.text,
                  quiet: true,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (BuildContext c) => PrizesScreen(onClose: () => Navigator.pop(c)),
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
                for (final Str credit in <Str>[
                  He.areaVoiceCredit,
                  He.areaVoiceCreditEng,
                  He.areaVoiceCreditRus,
                ])
                  Text(credit.text, style: AppText.parent(TokenType.parentSmall, color: TokenColors.inkSoft)),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    key: const Key('voice-licence'),
                    onPressed: _showApacheLicence,
                    child: Text(He.areaVoiceLicence.text),
                  ),
                ),
              ]),
              if (ref.watch(isParentDeviceProvider).value ?? true)
                _card(He.areaPush.text, <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(He.areaPushHelp.text, style: AppText.parent(TokenType.parentSmall)),
                      ),
                      Switch(
                        key: const Key('push-switch'),
                        value: ref.watch(pushEnabledProvider).value ?? false,
                        onChanged: _setPush,
                      ),
                    ],
                  ),
                  if (_pushNote != null) Text(_pushNote!, style: AppText.parent(TokenType.parentSmall)),
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

/// One child in the parent area's list: the name with the progress and remove buttons beside it, or, when the name would
/// not fit beside them (it would wrap in the middle of a word), the buttons in their own row under it. The note, if any,
/// has the row under both, the width of the card.
class _ChildRow extends StatelessWidget {
  const _ChildRow({required this.name, required this.buttons, this.note, this.extra});

  final String name;
  final List<Widget> buttons;
  final Widget? note;

  /// A row of its own under everything else (the languages button).
  final Widget? extra;

  /// What the two buttons and the gap need, at a text scale of 1.
  static const double _buttonsWidth = 190;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints box) {
      final TextStyle style = AppText.parent(TokenType.parentBody);
      final TextScaler scaler = MediaQuery.textScalerOf(context);
      final double nameWidth = (TextPainter(
        text: TextSpan(text: name, style: style),
        textDirection: TextDirection.rtl,
        textScaler: scaler,
      )..layout()).width;
      final bool stacked = nameWidth > box.maxWidth - scaler.scale(_buttonsWidth) - 8;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (stacked) ...<Widget>[
            Text(name, style: style),
            const SizedBox(height: 4),
            Row(children: buttons),
          ] else
            Row(
              children: <Widget>[
                Expanded(child: Text(name, style: style)),
                ...buttons,
              ],
            ),
          ?note,
          if (extra != null) ...<Widget>[const SizedBox(height: 4), extra!],
        ],
      );
    },
  );
}
