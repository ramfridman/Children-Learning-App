/// How many sticker drawings there are (assets/art/stickers/sticker_01.svg and on).
const int stickerDesigns = 12;

/// Which drawing a sticker has. Fixed by the sticker's key and not random: the same sticker is the same drawing on every
/// phone and every time, and the stickers of one lesson follow each other round the set.
int stickerDesign(String key) {
  final List<String> p = key.split(':');
  if (p.length != 3 || p[0] != 'sticker') return 1;
  final int n = int.tryParse(p[2]) ?? 1;
  int offset = 0;
  for (final int c in p[1].codeUnits) {
    offset += c;
  }
  return (offset + n - 1) % stickerDesigns + 1;
}

String stickerAsset(String key) =>
    'assets/art/stickers/sticker_${stickerDesign(key).toString().padLeft(2, '0')}.svg';
