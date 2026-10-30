import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../app/state.dart';
import '../child/art.dart';
import '../data/app_database.dart';
import '../data/child_name.dart';
import '../design/app_text.dart';
import '../design/components.dart';
import '../design/tokens.g.dart';
import '../strings/he.dart';

/// Adds a child profile: first name, age, avatar and how the app addresses the child. Adult UI.
/// Only reachable behind the gate and the PIN, or during the first setup.
class ChildFormScreen extends ConsumerStatefulWidget {
  const ChildFormScreen({super.key, required this.onSaved, this.onCancel});

  final VoidCallback onSaved;
  final VoidCallback? onCancel;

  @override
  ConsumerState<ChildFormScreen> createState() => _ChildFormScreenState();
}

class _ChildFormScreenState extends ConsumerState<ChildFormScreen> {
  final TextEditingController _name = TextEditingController();
  int _age = 5;
  String _avatar = avatarIds.first;
  String _address = 'n';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Every change of the field, the formatter's cuts included, redraws the counter, the note and the Save button.
    _name.addListener(_changed);
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  ChildNameProblem get _problem => validateChildName(_name.text);

  bool get _valid => _problem == ChildNameProblem.ok;

  /// What is said under the field: nothing while it is empty; why the name cannot be saved (an error); the limit, as a
  /// plain note, once a name that can be saved reaches it (the formatter takes no more, so the parent learns why here).
  ({Str text, bool error})? get _note => switch (_problem) {
    ChildNameProblem.empty => null,
    ChildNameProblem.badChars => (text: He.setupNameBadChars, error: true),
    ChildNameProblem.tooLong => (text: He.setupNameTooLong, error: true),
    ChildNameProblem.ok =>
      _name.text.length >= childNameMaxLength ? (text: He.setupNameTooLong, error: false) : null,
  };

  /// Flutter's own counter counts graphemes; this one counts UTF-16 units, as the limit and the server do.
  Widget _counter(
    BuildContext context, {
    required int currentLength,
    required bool isFocused,
    required int? maxLength,
  }) => Text(
    '${_name.text.length}/$childNameMaxLength',
    textDirection: TextDirection.ltr,
    style: AppText.parent(TokenType.parentSmall, color: TokenColors.inkSoft),
  );

  Future<void> _save() async {
    if (!_valid || _saving) return;
    setState(() => _saving = true);
    final AppDatabase db = await ref.read(databaseProvider.future);
    await db.addProfile(
      ProfilesCompanion(
        id: Value<String>(const Uuid().v4()),
        name: Value<String>(_name.text.trim()),
        avatar: Value<String>(_avatar),
        addressForm: Value<String>(_address),
        ageBand: Value<int>(bandForAge(_age).index),
        createdAt: Value<DateTime>(DateTime.now().toUtc()),
      ),
    );
    await ref.read(appStateProvider.notifier).reload();
    if (!mounted) return;
    widget.onSaved();
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 8),
    child: Text(text, style: AppText.parent(TokenType.parentH3)),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: TokenColors.parentBg,
    bottomNavigationBar: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (widget.onCancel != null) ...<Widget>[
              ParentButton(label: He.setupBack.text, quiet: true, onPressed: widget.onCancel),
              const SizedBox(width: 12),
            ],
            ParentButton(label: He.setupSave.text, onPressed: _valid && !_saving ? _save : null),
          ],
        ),
      ),
    ),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(He.setupChildTitle.text, style: AppText.parent(TokenType.parentH1)),
                _label(He.setupName.text),
                TextField(
                  controller: _name,
                  inputFormatters: const <TextInputFormatter>[ChildNameLengthFormatter()],
                  buildCounter: _counter,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: TokenColors.paper,
                  ),
                ),
                if (_note case (:final Str text, :final bool error))
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      text.text,
                      style: AppText.parent(
                        TokenType.parentSmall,
                        color: error ? TokenColors.domainNumbersDeep : TokenColors.inkSoft,
                      ),
                    ),
                  ),
                _label(He.setupAge.text),
                Wrap(
                  spacing: 8,
                  children: <Widget>[
                    for (final int a in <int>[3, 4, 5, 6, 7, 8])
                      ChoiceChip(
                        label: Text('$a'),
                        selected: _age == a,
                        onSelected: (_) => setState(() => _age = a),
                      ),
                  ],
                ),
                _label(He.setupAvatar.text),
                Wrap(
                  spacing: 12,
                  children: <Widget>[
                    for (final String id in avatarIds)
                      GestureDetector(
                        onTap: () => setState(() => _avatar = id),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _avatar == id ? TokenColors.night : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: AvatarPicture(avatarId: id, size: 64),
                        ),
                      ),
                  ],
                ),
                _label(He.setupAddress.text),
                Wrap(
                  spacing: 8,
                  children: <Widget>[
                    for (final (String code, Str label) in <(String, Str)>[
                      ('f', He.addressFemale),
                      ('m', He.addressMale),
                      ('n', He.addressNeutral),
                    ])
                      ChoiceChip(
                        label: Text(label.text),
                        selected: _address == code,
                        onSelected: (_) => setState(() => _address = code),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Lets at most [childNameMaxLength] UTF-16 units into the name field, never half of a surrogate pair. Flutter's
/// `maxLength` counts graphemes, so a name with nikud or an emoji could pass it and still be refused by the server.
class ChildNameLengthFormatter extends TextInputFormatter {
  const ChildNameLengthFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.length <= childNameMaxLength) return newValue;
    // Already full: what was typed at the cursor is not taken, rather than cutting letters off the end.
    if (oldValue.text.length >= childNameMaxLength && oldValue.selection.isCollapsed) return oldValue;
    final String text = cutToUtf16Units(newValue.text, childNameMaxLength);
    final TextSelection s = newValue.selection;
    final TextRange c = newValue.composing;
    return TextEditingValue(
      text: text,
      selection: s.copyWith(
        baseOffset: s.baseOffset.clamp(-1, text.length),
        extentOffset: s.extentOffset.clamp(-1, text.length),
      ),
      composing: !c.isCollapsed && c.start < text.length
          ? TextRange(start: c.start, end: c.end.clamp(c.start, text.length))
          : TextRange.empty,
    );
  }
}
