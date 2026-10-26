import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/state.dart';
import '../../auth/auth_client.dart';
import '../../content/engine_adapter.dart';
import '../../content/models.dart';
import '../../content/pack_installer.dart';
import '../../content/pack_verify.dart';
import '../../data/app_database.dart';
import '../../engine/engine.dart';
import '../../core/errors.dart';
import '../../core/log.dart';
import '../../device/device_key_service.dart';
import '../../device/enrolment_service.dart';
import '../../device/secure_store.dart';
import 'dev_strings.dart';

/// Plain screens for testing the device chain on a real phone: sign in, enrol, pair, signed calls.
class DevHomePage extends ConsumerStatefulWidget {
  const DevHomePage({super.key});

  @override
  ConsumerState<DevHomePage> createState() => _DevHomePageState();
}

class _DevHomePageState extends ConsumerState<DevHomePage> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _emailCode = TextEditingController();
  final TextEditingController _devSecret = TextEditingController();
  final TextEditingController _pairCode = TextEditingController();
  final TextEditingController _revokeId = TextEditingController();
  final List<String> _lines = <String>[];
  String? _deviceId;
  String? _shownCode;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refreshDeviceId();
  }

  @override
  void dispose() {
    _email.dispose();
    _emailCode.dispose();
    _devSecret.dispose();
    _pairCode.dispose();
    _revokeId.dispose();
    super.dispose();
  }

  Future<void> _refreshDeviceId() async {
    final String? id = await ref.read(secureStoreProvider).read(StoreKeys.deviceId);
    if (mounted) setState(() => _deviceId = id);
  }

  /// Runs one action, shows what happened (scrubbed), and never lets an error escape.
  Future<void> _run(String label, Future<String> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    String result;
    try {
      result = await action();
    } on GatewayException catch (e) {
      result = 'refused: ${e.code}${e.status == null ? '' : ' (${e.status})'}';
    } on KeystoreException catch (e) {
      result = 'key error: ${e.code}';
    } on StateError catch (e) {
      result = 'not done: ${e.message}';
    }
    final String line = Log.scrub('$label: $result');
    Log.d(line);
    if (!mounted) return;
    setState(() {
      _lines.insert(0, line);
      _busy = false;
    });
    await _refreshDeviceId();
  }

  Future<String> _accessToken() async {
    final String? token = await ref.read(sessionManagerProvider).accessToken();
    if (token == null) throw const GatewayException('unauthorized');
    return token;
  }

  Future<String> _call(String function, {Map<String, Object?> body = const <String, Object?>{}}) async {
    final String? id = _deviceId;
    if (id == null) throw StateError('this phone is not enrolled');
    final Map<String, Object?> json = await ref
        .read(gatewayProvider)
        .call(function, body, deviceId: id, accessToken: await _accessToken());
    return json.toString();
  }

  void _signIn() => _run('sign in', () async {
    final AuthSession session = await ref
        .read(authClientProvider)
        .verifyEmailCode(_email.text.trim(), _emailCode.text.trim());
    await ref.read(sessionManagerProvider).setSession(session);
    return 'signed in';
  });

  void _enrol({required bool replace}) => _run('enrol', () async {
    final String secret = _devSecret.text.trim();
    final Enrolled e = await ref
        .read(enrolmentProvider)
        .enrolParent(replaceThisDevice: replace, devSecret: secret.isEmpty ? null : secret);
    return 'device ${e.deviceId} role ${e.role} level ${e.securityLevel}';
  });

  /// Installs every .nnpack file in the `incoming` folder of the no-backup area, one by one, and says what became of each.
  /// Put files there with `adb shell run-as` (dev build only); this is how a damaged pack is shown to be refused.
  void _installIncoming() => _run('install packs', () async {
    final String folder = await ref.read(platformProvider).noBackupDir();
    final Directory incoming = Directory('$folder${Platform.pathSeparator}incoming');
    if (!incoming.existsSync()) throw StateError('no folder ${incoming.path}');
    final PackInstaller installer = await ref.read(packInstallerProvider.future);
    final List<String> out = <String>[];
    final List<File> files =
        incoming.listSync().whereType<File>().where((File f) => f.path.endsWith('.nnpack')).toList()
          ..sort((File a, File b) => a.path.compareTo(b.path));
    for (final File f in files) {
      final String name = f.uri.pathSegments.last;
      try {
        final InstallResult r = await installer.install(await f.readAsBytes());
        out.add(
          '$name: ${r.outcome.name} ${r.pack.id} ${r.pack.version}${r.hidden ? ' (hidden: ${r.pack.hiddenReason})' : ''}',
        );
      } on PackRejected catch (e) {
        out.add('$name: REFUSED at ${e.stage}: ${e.reason}');
      }
    }
    return out.isEmpty ? 'no .nnpack files in the folder' : out.join('\n');
  });

  void _listPacks() => _run('packs', () async {
    final AppDatabase db = await ref.read(databaseProvider.future);
    final List<InstalledPack> rows = await db.allInstalledPacks();
    if (rows.isEmpty) return 'none installed';
    return rows
        .map(
          (InstalledPack p) =>
              '${p.id} ${p.version} ${p.manifestSha256.substring(0, 12)}${p.hidden ? ' hidden' : ''}',
        )
        .join('\n');
  });

  /// Replays every child's answers through the learning engine and prints what it concluded.
  void _engineState() => _run('engine', () async {
    final AppDatabase db = await ref.read(databaseProvider.future);
    final PackContent content = await ref.read(contentProvider.future);
    final List<Profile> children = await db.allProfiles();
    if (children.isEmpty) return 'no child profiles';
    final List<String> out = <String>[];
    for (final Profile p in children) {
      final Engine engine = Engine(catalog: engineCatalog(content))
        ..replay((await db.attemptsOf(p.id)).map(eventOf));
      final String text = engineSummary(engine, DateTime.now().toUtc());
      out.add('Child ${p.name}:${String.fromCharCode(10)}$text');
    }
    return out.join(String.fromCharCode(10) + String.fromCharCode(10));
  });

  void _pair() => _run('pair', () async {
    final String secret = _devSecret.text.trim();
    final Enrolled e = await ref
        .read(enrolmentProvider)
        .pairChild(_pairCode.text.trim(), devSecret: secret.isEmpty ? null : secret);
    return 'device ${e.deviceId} role ${e.role} level ${e.securityLevel}';
  });

  void _makeCode() => _run('pairing code', () async {
    final String? id = _deviceId;
    if (id == null) throw StateError('this phone is not enrolled');
    final Map<String, Object?> json = await ref
        .read(gatewayProvider)
        .call(
          'pairing-code-create',
          const <String, Object?>{},
          deviceId: id,
          accessToken: await _accessToken(),
        );
    final Object? code = json['code'];
    if (mounted) setState(() => _shownCode = code is String ? code : null);
    return 'created (shown below)';
  });

  @override
  Widget build(BuildContext context) {
    final bool isDev = ref.watch(configProvider).isDev;
    return Scaffold(
      appBar: AppBar(title: const Text(DevStrings.title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Text('Enrolled device: ${_deviceId ?? 'none'}'),
            const SizedBox(height: 16),
            _heading(DevStrings.signIn),
            _field(_email, DevStrings.email, keyboard: TextInputType.emailAddress),
            _button(
              DevStrings.sendCode,
              () => _run('send code', () async {
                await ref.read(authClientProvider).sendEmailCode(_email.text.trim());
                return 'requested';
              }),
            ),
            _field(_emailCode, DevStrings.code, keyboard: TextInputType.number),
            _button(DevStrings.verify, _signIn),
            _heading(DevStrings.enrol),
            if (isDev) _field(_devSecret, DevStrings.devSecret),
            _button(DevStrings.enrolButton, () => _enrol(replace: false)),
            _button(DevStrings.replaceButton, () => _enrol(replace: true)),
            _heading(DevStrings.pair),
            _field(_pairCode, DevStrings.pairCode, keyboard: TextInputType.number),
            _button(DevStrings.pairButton, _pair),
            _heading(DevStrings.calls),
            _button(DevStrings.ping, () => _run('ping', () => _call('signed-ping'))),
            _button(DevStrings.appConfig, () => _run('app config', () => _call('app-config'))),
            _button(DevStrings.makeCode, _makeCode),
            if (_shownCode != null)
              SelectableText('Code: $_shownCode', style: Theme.of(context).textTheme.headlineSmall),
            _button(DevStrings.listDevices, () => _run('devices', () => _call('device-list'))),
            _field(_revokeId, DevStrings.revokeId),
            _button(
              DevStrings.revoke,
              () => _run(
                'revoke',
                () => _call('device-revoke', body: <String, Object?>{'device_id': _revokeId.text.trim()}),
              ),
            ),
            _button(
              DevStrings.forget,
              () => _run('forget', () async {
                await ref.read(enrolmentProvider).forgetThisDevice();
                if (mounted) setState(() => _shownCode = null);
                return 'done';
              }),
            ),
            _heading(DevStrings.packs),
            _button(DevStrings.installIncoming, _installIncoming),
            _button(DevStrings.listPacks, _listPacks),
            _heading(DevStrings.engine),
            _button(DevStrings.engineState, _engineState),
            _heading(DevStrings.output),
            for (final String line in _lines)
              Padding(padding: const EdgeInsets.only(bottom: 8), child: SelectableText(line)),
          ],
        ),
      ),
    );
  }

  Widget _heading(String text) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 8),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );

  Widget _field(TextEditingController controller, String label, {TextInputType? keyboard}) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: TextField(
      controller: controller,
      keyboardType: keyboard,
      autocorrect: false,
      enableSuggestions: false,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
    ),
  );

  Widget _button(String label, VoidCallback onPressed) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: FilledButton(onPressed: _busy ? null : onPressed, child: Text(label)),
  );
}
