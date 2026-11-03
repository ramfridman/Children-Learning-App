/// The sentence of the daily welcome that the map's bubble shows now (B-42): one sentence at a time, the one being said.
/// [text] is the sentence with its niqqud; [withName] puts the child's name before it, as a call on its own line (the first
/// sentence: the name, a comma, and the greeting under it).
class WelcomeShown {
  const WelcomeShown({required this.text, required this.withName});

  final String text;
  final bool withName;

  @override
  bool operator ==(Object other) => other is WelcomeShown && other.text == text && other.withName == withName;

  @override
  int get hashCode => Object.hash(text, withName);
}
