import 'character.dart';

/// Fills a role with a character. Screens ask for a role; the resolver decides who plays it.
///
/// Priority: the companion the child chose (if it may play the role), the friend of the current domain,
/// the activity's suggestion, and last the house character, who is always available. A character that is
/// not installed, not enabled or not allowed in this build is not in [available] and so never chosen: a
/// removed pack quietly gives way to the next in line.
class CharacterResolver {
  CharacterResolver({required Iterable<Character> available, required this.house})
    : _available = <String, Character>{for (final Character c in available) c.id: c};

  final Map<String, Character> _available;

  /// The character that is always bundled (Nitzi).
  final Character house;

  Iterable<Character> get all => _available.values;

  Character? byId(String id) => _available[id];

  Character resolve(
    CharacterRole role, {
    String? companionId,
    String? domainFriendId,
    String? activityDefaultId,
  }) {
    for (final String? id in <String?>[companionId, domainFriendId, activityDefaultId]) {
      final Character? c = id == null ? null : _available[id];
      if (c != null && c.allows(role)) return c;
    }
    return house;
  }

  /// The characters a child may pick as a companion (they can play the guide).
  List<Character> companions() => <Character>[
    house,
    for (final Character c in _available.values)
      if (c.id != house.id && c.allows(CharacterRole.guideTutor)) c,
  ];
}
