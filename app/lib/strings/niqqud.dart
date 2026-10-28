/// A Hebrew text without its niqqud (points and cantillation, code points 0x0591 to 0x05C7), for the adult screens, which
/// read plain text. The child's strings are the ones written with niqqud; a name that both use (a land's) is stripped
/// here, never written twice.
String withoutNiqqud(String text) =>
    String.fromCharCodes(text.runes.where((int c) => c < 0x0591 || c > 0x05C7));
