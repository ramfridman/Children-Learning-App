/// What a child can be given (PLAN: Awards, prizes & the Trophy Hall). Every award has a key that is the same on every
/// device, so an award is given once however many phones work it out, and the key says what it is for.
enum AwardKind { sticker, star, trophy, medal, decoration }

enum TrophyTier { bronze, silver, gold }

/// The lands that can hold trophies, in the order of the Trophy Hall. Nitzi's own island has none.
enum TrophyLand {
  counting('numbers'),
  colors('colors'),
  shapes('shapes'),
  logic('logic'),
  robots('cs'),
  market('math');

  const TrophyLand(this.domain);

  /// The skill domain whose skills this land grows.
  final String domain;

  static TrophyLand? ofDomain(String domain) {
    for (final TrophyLand l in values) {
      if (l.domain == domain) return l;
    }
    return null;
  }
}

/// An award that is due, and when it was earned (the moment of the answer that made it true, never "now").
class AwardDue {
  const AwardDue({required this.key, required this.kind, required this.at});

  final String key;
  final AwardKind kind;
  final DateTime at;
}

/// Builds and reads award keys. The keys are the only thing about an award that leaves the phone.
abstract final class Awards {
  static String sticker(String lessonId, int n) => 'sticker:$lessonId:$n';

  static String star(String skillId) => 'star:$skillId';

  static String trophy(TrophyLand land, TrophyTier tier) => 'trophy:${land.name}:${tier.name}';

  static AwardKind? kindOf(String key) {
    final String head = key.split(':').first;
    for (final AwardKind k in AwardKind.values) {
      if (k == AwardKind.decoration ? head == 'deco' : k.name == head) return k;
    }
    return null;
  }

  /// `trophy:counting:silver` as a land and a tier, or null for any other key.
  static ({TrophyLand land, TrophyTier tier})? trophyOf(String key) {
    final List<String> p = key.split(':');
    if (p.length != 3 || p[0] != 'trophy') return null;
    final TrophyLand? land = TrophyLand.values.where((TrophyLand l) => l.name == p[1]).firstOrNull;
    final TrophyTier? tier = TrophyTier.values.where((TrophyTier t) => t.name == p[2]).firstOrNull;
    return land == null || tier == null ? null : (land: land, tier: tier);
  }

  /// `star:NUM-A-01` as a skill id, or null.
  static String? starOf(String key) => key.startsWith('star:') ? key.substring(5) : null;

  /// `sticker:butterflies:3` as a lesson id and the number of the finished visit, or null.
  static ({String lessonId, int n})? stickerOf(String key) {
    final List<String> p = key.split(':');
    if (p.length != 3 || p[0] != 'sticker') return null;
    final int? n = int.tryParse(p[2]);
    return n == null ? null : (lessonId: p[1], n: n);
  }
}
