import '../design/target_text.dart' show TargetLanguage;

/// The greeting word of the two foreign-language course hosts, in the course's own language (the editor's `docs/agents/hebrew-notes.md`
/// section 16.2): said once at the host's greeting, before the Hebrew line, by the course's teaching voice (clip `vo:host.<host>.hello`,
/// pack content that is in no pack yet, so the greeting plays without it), and written in its chip only where the letters rule allows. The
/// Hebrew course has none: its whole greeting is already Hebrew.
const Map<String, ({String text, TargetLanguage language})> hostHello =
    <String, ({String text, TargetLanguage language})>{
      'host_eng': (text: 'Hello!', language: TargetLanguage.english),
      'host_rus': (text: 'Привет!', language: TargetLanguage.russian),
    };
