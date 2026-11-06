// The size limits of a pack, in one place. They are a security control against a hostile pack: the zip reader, the schemas
// of the manifest and the pack source all take their caps from here, so no cap can grow without the others. Every cap is
// finite. Each is sized for the end of M10 (Band C: about 2,500 activities, about 7,500 voice lines) with room to spare;
// raise one only with the reasons in docs/PLAN.md (Pack limits).

abstract final class PackLimits {
  /// Voice lines of one pack: the recorded ones (`vo`), the ones that wait for their voice (`voPending`) and mouth cues.
  /// Now about 4,000 in the starter pack; Band C brings about 7,500 in all.
  static const int voiceLines = 12000;

  /// Files listed in a manifest. A line is two files (its sound and its mouth cues), so a pack of one friend's voice at
  /// the most lines is twice [voiceLines]; a pack of lessons is far under it (1,700 files now, about 3,300 with Band C).
  static const int files = 2 * voiceLines;

  /// Pictures in a pack.
  static const int assets = 2000;

  /// Entries of a pack by kind. Now 1,135 activities, 193 lessons, 112 skills and 50 misconceptions; Band C adds about 1,200
  /// activities, 130 lessons and 100 skills.
  static const int activities = 3000;
  static const int lessons = 600;
  static const int skills = 600;
  static const int misconceptions = 400;
}
