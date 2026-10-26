import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../app/state.dart';
import '../child/art.dart';
import '../data/app_database.dart';
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
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _valid => _name.text.trim().isNotEmpty && _name.text.trim().length <= 40;

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
                  maxLength: 40,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: TokenColors.paper,
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
                          child: AvatarBadge(avatarId: id, size: 64),
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
