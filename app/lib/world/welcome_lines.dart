import '../rewards/award.dart';
import 'todays_adventure.dart';
import 'welcome_table.dart';

// What the friend says in the daily welcome, in order (B-42, `docs/milestones/B42.md` section 2.2). A pure function of its
// arguments: no clock, no random source, no database. The day number and everything else come in as parameters, so the
// same input always gives the same welcome and every case can be tested.
//
// The ids it returns are `vo:` ids of the welcome lines, with [welcomeNameClip] first when the child has a name clip. No
// line says the child's name or anything about the child; the name is its own clip, and only a greeting may follow it.

/// The place of the name clip in a welcome. It is not a `vo:` id: the clip is the child's own, made from a spelling the
/// parent checked, and kept on the device (the encrypted store, never synced).
const String welcomeNameClip = 'name';

/// The three greetings that turn with the day: the day number mod 3, 0 to 2.
const List<String> welcomeHellos = <String>['vo:welcome.hello.1', 'vo:welcome.hello.2', 'vo:welcome.hello.3'];

/// The greeting of a child's very first adventure.
const String welcomeHelloFirst = 'vo:welcome.hello.first';

/// The closing line, which points at the bottle.
const String welcomeClose = 'vo:welcome.close';

/// The lines of the welcome for [stop], the stop Today's Adventure picked when the map was built.
///
/// - [today] is `Engine.dayKey` of the day; the greeting turns with it (a new child's first adventure has its own).
/// - [hasNameClip] puts the name clip first.
/// - [warmUpDue] says whether the warm-up game will run before this land's lesson. It decides where the child starts, so the
///   topic would guess and the land line is said instead.
/// - [skillOfLesson] is the first skill of a lesson that belongs to a land's domain (the B-39 land rule: the lesson
///   `butterflies` is on two paths and counts for each of them by its own skills); null when it has none.
/// - [table] says which topic line goes with a skill. A skill with no topic gets its land line.
///
/// With nothing to play ([AdventureKind.none]) there is only the greeting: no topic, no closing line.
List<String> welcomeLines({
  required TodaysAdventure stop,
  required int today,
  required bool hasNameClip,
  required bool Function(TrophyLand land) warmUpDue,
  required String? Function(String lessonId, TrophyLand land) skillOfLesson,
  required WelcomeTable table,
}) {
  final String greeting = stop.reason == AdventureReason.welcome
      ? welcomeHelloFirst
      : welcomeHellos[today % welcomeHellos.length];
  final List<String> lines = <String>[if (hasNameClip) welcomeNameClip, greeting];
  final TrophyLand? land = stop.land;
  if (stop.kind == AdventureKind.none || land == null) return List<String>.unmodifiable(lines);

  final String? lessonId = stop.lessonId;
  final String? skill = stop.kind == AdventureKind.revisit
      ? stop.skillId
      : (lessonId == null ? null : skillOfLesson(lessonId, land));
  final bool placementFirst = stop.kind == AdventureKind.lesson && warmUpDue(land);
  final String? topic = placementFirst || skill == null ? null : table.topicOf(skill);
  lines
    ..add(topic ?? table.landLine(land))
    ..add(welcomeClose);
  return List<String>.unmodifiable(lines);
}

/// Whether [voId] may be said right after the name clip: a greeting of the welcome, or the shared clip of the map bubble
/// ([homeBubbleVoice]). A topic, a land line or the closing line never follows a name, so the name is heard once, as a call.
bool mayFollowNameClip(String voId) =>
    voId == welcomeHelloFirst || welcomeHellos.contains(voId) || voId == homeBubbleVoice;

/// The shared clip of the map bubble ("מה בבקבוק?"): the same words with a name before them and without.
const String homeBubbleVoice = 'vo:core.home.bubble';
