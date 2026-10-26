import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/companion.dart';
import '../characters/character.dart';
import '../characters/character_view.dart';
import '../characters/resolver.dart';
import '../design/board.dart';
import '../design/components.dart';
import '../design/layout.dart';
import '../design/tokens.g.dart';
import '../strings/he.dart';
import '../voice/voice_director.dart';

/// Friends' Beach: the child chooses the character who walks beside them everywhere. Big pictures, no reading:
/// a touch makes the friend wave and say hello in its own voice, and the one with the glowing frame is the
/// companion. The choice is saved at once and changes the guide on every screen.
class FriendsBeach extends ConsumerStatefulWidget {
  const FriendsBeach({super.key, this.greetingVoice = 'vo:core.greeting.hello'});

  final String greetingVoice;

  @override
  ConsumerState<FriendsBeach> createState() => _FriendsBeachState();
}

class _FriendsBeachState extends ConsumerState<FriendsBeach> {
  static const List<Color> _tints = <Color>[
    TokenColors.domainNumbersTint,
    TokenColors.domainColorsTint,
    TokenColors.domainShapesTint,
    TokenColors.domainLogicTint,
    TokenColors.domainCsTint,
    TokenColors.domainMathTint,
    TokenColors.sparkTint,
    TokenColors.skyTint,
    TokenColors.seaTint,
  ];

  late final VoiceDirector _director;
  int _waveId = 0;
  String? _waving;

  @override
  void initState() {
    super.initState();
    _director = ref.read(voiceDirectorProvider);
  }

  @override
  void dispose() {
    unawaited(_director.stop());
    super.dispose();
  }

  Future<void> _choose(Character c) async {
    final int id = ++_waveId;
    setState(() => _waving = c.id);
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 1800)).then((_) {
        if (mounted && id == _waveId) setState(() => _waving = null);
      }),
    );
    await ref.read(companionProvider.notifier).choose(c.id);
    final Guide guide = await ref.read(guideProvider.future);
    _director.useBank(guide.bank);
    if (mounted) await _director.say(widget.greetingVoice);
  }

  @override
  Widget build(BuildContext context) {
    final BoardClass board = AppLayout.of(context).board;
    final AsyncValue<CharacterResolver> resolver = ref.watch(resolverProvider);
    final String? chosen = ref.watch(companionProvider).value;
    final List<Character> friends = resolver.value?.companions() ?? const <Character>[];
    final String selected = friends.any((Character c) => c.id == chosen)
        ? chosen!
        : (resolver.value?.house.id ?? '');
    final bool tablet = board.isTablet;
    final Rect area = tablet
        ? Rect.fromLTWH(40, 190, board.size.width - 80, board.size.height - 260)
        : Rect.fromLTWH(24, 112, board.size.width - 48, board.size.height - 136);
    final double cardW = tablet ? 220 : 168;
    final double cardH = tablet ? 280 : 232;
    final List<Widget> cards = <Widget>[
      for (int i = 0; i < friends.length; i++)
        _FriendCard(
          key: Key('friend-${friends[i].id}'),
          character: friends[i],
          tint: _tints[i % _tints.length],
          width: cardW,
          height: cardH,
          selected: friends[i].id == selected,
          waving: _waving == friends[i].id,
          onTap: () => _choose(friends[i]),
        ),
    ];
    return Scaffold(
      body: BoardCanvas(
        background: TokenColors.cream,
        board: board,
        children: <Widget>[
          Positioned(
            left: 24,
            right: 120,
            top: tablet ? 56 : 20,
            child: Align(
              alignment: Alignment.centerRight,
              child: BoardBubble(
                key: const Key('friends-title'),
                text: He.friendsTitle.text,
                fontSize: tablet ? 30 : 22,
                maxWidth: board.size.width - 160,
              ),
            ),
          ),
          boardAt(
            right: tablet ? 24 : 24,
            top: tablet ? 40 : 12,
            child: PebbleButton(
              key: const Key('friends-home'),
              semanticLabel: He.homeSemantics.text,
              onPressed: () => Navigator.of(context).pop(),
              child: const BoardSvg('assets/art/ui/home_palm.svg', width: 32, height: 32),
            ),
          ),
          Positioned.fromRect(
            rect: area,
            child: tablet
                ? SingleChildScrollView(
                    child: Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      alignment: WrapAlignment.center,
                      children: cards,
                    ),
                  )
                : ListView(
                    key: const Key('friends-list'),
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    children: <Widget>[
                      for (final Widget c in cards)
                        Padding(padding: const EdgeInsets.only(left: 16), child: c),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _FriendCard extends StatelessWidget {
  const _FriendCard({
    super.key,
    required this.character,
    required this.tint,
    required this.width,
    required this.height,
    required this.selected,
    required this.waving,
    required this.onTap,
  });

  final Character character;
  final Color tint;
  final double width;
  final double height;
  final bool selected;
  final bool waving;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: character.displayName('').isEmpty ? He.friendsSemantics.text : character.displayName(''),
    hint: selected ? He.friendChosenSemantics.text : null,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ExcludeSemantics(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: width,
          height: height,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(TokenRadius.xl),
            border: Border.all(color: selected ? TokenColors.spark : tint, width: selected ? 6 : 6),
            boxShadow: selected
                ? clayShadows(TokenColors.sparkDeep, soft16: true)
                : clayShadows(TokenColors.cardLip, soft16: true),
          ),
          child: CharacterView(
            character: character,
            state: waving ? CharacterState.wave : CharacterState.idle,
            semanticLabel: '',
          ),
        ),
      ),
    ),
  );
}
