import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/companion.dart';
import '../app/providers.dart' show clockProvider;
import '../app/state.dart';
import '../app/sync_providers.dart';
import '../app/welcome_providers.dart';
import '../characters/character.dart';
import '../characters/resolver.dart';
import '../data/app_database.dart';
import '../data/child_name.dart';
import '../design/app_text.dart';
import '../design/components.dart';
import '../design/tokens.g.dart';
import '../strings/he.dart';
import '../voice/name_clips.dart';

/// How a child's name is said (B-42, docs/milestones/B42.md section 3.2). The parent writes the spelling the voice should
/// read, with nikud where the name needs it, and taps "listen": the spelling is saved with the child (and goes to the
/// family like the nickname), the gateway makes the sound of it in the voice of the friend the child chose, and the sound is
/// kept on this device only and played so the parent hears it before the child does. Nothing is made until the parent taps.
class NameSpokenScreen extends ConsumerStatefulWidget {
  const NameSpokenScreen({super.key, required this.profile, required this.onClose});

  final Profile profile;
  final VoidCallback onClose;

  @override
  ConsumerState<NameSpokenScreen> createState() => _NameSpokenScreenState();
}

class _NameSpokenScreenState extends ConsumerState<NameSpokenScreen> {
  late final TextEditingController _spelling = TextEditingController(text: widget.profile.nameSpoken ?? '');
  bool _busy = false;
  Str? _note;
  bool _noteIsError = false;

  @override
  void initState() {
    super.initState();
    _spelling.addListener(() => setState(() => _note = null));
  }

  @override
  void dispose() {
    _spelling.dispose();
    super.dispose();
  }

  SpokenNameProblem get _problem => validateSpokenName(_spelling.text);

  bool get _canListen => !_busy && _spelling.text.trim().isNotEmpty && _problem == SpokenNameProblem.ok;

  Str? get _problemNote => switch (_problem) {
    SpokenNameProblem.ok => null,
    SpokenNameProblem.tooLong => He.nameSpokenTooLong,
    SpokenNameProblem.badChars => He.nameSpokenBadChars,
  };

  /// Keeps the spelling with the child (cleared when the field is empty). A different spelling deletes the old clip.
  Future<AppDatabase> _save() async {
    final AppDatabase db = await ref.read(databaseProvider.future);
    final String text = _spelling.text.trim();
    await db.setNameSpoken(widget.profile.id, text.isEmpty ? null : text);
    ref.invalidate(nameClipProvider(widget.profile.id));
    return db;
  }

  Future<void> _saveOnly() async {
    if (_problem != SpokenNameProblem.ok || _busy) return;
    await _save();
    unawaited(ref.read(syncRunnerProvider).now(force: true));
    if (mounted) {
      setState(() {
        _note = He.nameSpokenSaved;
        _noteIsError = false;
      });
    }
  }

  Future<void> _listen() async {
    if (!_canListen) return;
    setState(() {
      _busy = true;
      _note = He.nameSpokenWorking;
      _noteIsError = false;
    });
    Str done;
    bool error = false;
    try {
      final AppDatabase db = await _save();
      // The server reads the spelling, so it has to be there before the gateway is asked.
      await ref.read(syncRunnerProvider).now(force: true);
      final CharacterResolver resolver = await ref.read(resolverProvider.future);
      final String characterId = resolver
          .resolve(CharacterRole.guideTutor, companionId: await db.companionOf(widget.profile.id))
          .id;
      final MadeNameClip made = await ref
          .read(nameVoiceProvider)
          .make(childId: widget.profile.id, characterId: characterId);
      final String mine = spellingHash(_spelling.text.trim());
      if (made.spellingHash != mine) {
        // The server voiced an older spelling (the new one has not reached it yet): that clip is not this name's.
        error = true;
        done = He.nameSpokenNotYet;
      } else {
        await db.putNameClip(
          profileId: widget.profile.id,
          characterId: characterId,
          spellingHash: mine,
          sound: made.sound,
          at: DateTime.fromMillisecondsSinceEpoch(ref.read(clockProvider).nowMs(), isUtc: true),
        );
        ref.invalidate(nameClipProvider(widget.profile.id));
        unawaited(ref.read(voiceDirectorProvider).sayBytes(made.sound));
        done = He.nameSpokenHeard;
      }
    } on NameVoiceException catch (e) {
      error = true;
      done = switch (e.failure) {
        NameVoiceFailure.off => He.nameSpokenOff,
        NameVoiceFailure.cap => He.nameSpokenCap,
        NameVoiceFailure.notThere || NameVoiceFailure.unreachable => He.nameSpokenOffline,
      };
    } on Object {
      error = true;
      done = He.nameSpokenOffline;
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _note = done;
      _noteIsError = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Str? note = _problemNote ?? _note;
    final bool error = _problemNote != null || _noteIsError;
    return Scaffold(
      backgroundColor: TokenColors.parentBg,
      appBar: AppBar(
        backgroundColor: TokenColors.night,
        foregroundColor: Colors.white,
        title: Text(
          He.nameSpokenTitle.fill(<String, String>{'child': displayChildName(widget.profile.name)}),
          style: AppText.parent(TokenType.parentH2, color: Colors.white),
        ),
        leading: IconButton(
          key: const Key('name-spoken-back'),
          icon: const Icon(Icons.arrow_forward_rounded),
          onPressed: widget.onClose,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(He.nameSpokenHelp.text, style: AppText.parent(TokenType.parentBody)),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('name-spoken-field'),
                  controller: _spelling,
                  buildCounter:
                      (
                        BuildContext c, {
                        required int currentLength,
                        required bool isFocused,
                        required int? maxLength,
                      }) => Text(
                        '${_spelling.text.length}/$spokenNameMaxLength',
                        textDirection: TextDirection.ltr,
                        style: AppText.parent(TokenType.parentSmall, color: TokenColors.inkSoft),
                      ),
                  decoration: InputDecoration(
                    labelText: He.nameSpokenField.text,
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: TokenColors.paper,
                  ),
                ),
                if (note != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      note.text,
                      key: const Key('name-spoken-note'),
                      style: AppText.parent(
                        TokenType.parentSmall,
                        color: error ? TokenColors.domainNumbersDeep : TokenColors.inkSoft,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    ParentButton(
                      key: const Key('name-spoken-listen'),
                      label: He.nameSpokenListen.text,
                      onPressed: _canListen ? _listen : null,
                    ),
                    const SizedBox(width: 12),
                    ParentButton(
                      key: const Key('name-spoken-save'),
                      label: He.setupSave.text,
                      quiet: true,
                      onPressed: !_busy && _problem == SpokenNameProblem.ok ? _saveOnly : null,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  He.nameSpokenPrivacy.text,
                  style: AppText.parent(TokenType.parentSmall, color: TokenColors.inkSoft),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
