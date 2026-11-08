import '../data/app_database.dart';
import '../engine/age.dart' show CaptionSetting, SchoolStage, schoolYearOf;

// What the parent area keeps on this device about a child's age settings (B-29, docs/design/b29-steps5-6.md sections 3 and 4). Three small
// settings, each by the child's id, and none of them is synced: the school year the stage was last confirmed for (so the September card
// knows when to ask), the captions setting, and the day the "add the age" card was put away. They go with the child.

/// The school year (the year it started in) the stage was last confirmed for.
String stageYearKey(String childId) => 'stage_year_$childId';

/// The captions setting: `auto`, `on` or `off`.
String readingKey(String childId) => 'reading_$childId';

/// The school year in which the parent said "not now" to the "add the age" card.
String ageCardHiddenKey(String childId) => 'age_card_hidden_$childId';

/// Every key above, for deleting a child.
List<String> ageSettingKeys(String childId) => <String>[
  stageYearKey(childId),
  readingKey(childId),
  ageCardHiddenKey(childId),
];

/// The reads and writes of those settings.
extension AgeSettings on AppDatabase {
  Future<int?> stageYearOf(String childId) async => int.tryParse(await setting(stageYearKey(childId)) ?? '');

  /// Records that the stage was confirmed in the school year of [now].
  Future<void> markStageConfirmed(String childId, DateTime now) =>
      putSetting(stageYearKey(childId), '${schoolYearOf(now)}');

  Future<CaptionSetting> captionSettingOf(String childId) async =>
      CaptionSetting.fromWord(await setting(readingKey(childId)));

  Future<void> setCaptionSetting(String childId, CaptionSetting value) =>
      putSetting(readingKey(childId), value.word);

  Future<int?> ageCardHiddenYear(String childId) async =>
      int.tryParse(await setting(ageCardHiddenKey(childId)) ?? '');

  Future<void> hideAgeCard(String childId, DateTime now) =>
      putSetting(ageCardHiddenKey(childId), '${schoolYearOf(now)}');

  /// Confirms [stage] for [childId] now: the stage and its band, and the school year it was confirmed for. The month and year of birth
  /// are written apart, by the page that asks for them.
  Future<void> confirmStage(String childId, SchoolStage stage, DateTime now) async {
    await setSchoolStage(childId, stage);
    await markStageConfirmed(childId, now);
  }
}
