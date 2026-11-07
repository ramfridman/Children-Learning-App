import 'dart:math' as math;

import '../content/models.dart';
import '../content/own_name_docs.dart';

export '../content/own_name_docs.dart' show houseName, printName;

// The own-name items of Hebrew Band A (HEB-A-11, `tap_answer` 1.5, `answer.type` `name`): the options are made on the device, when a
// lesson opens, from the first name of the child who plays it. A pack holds only the rules and a closed list of names (never a name), so
// there is nothing to send. What this file does with a name is to put it on a tile: it is never logged, written, stored, sent, shown to a
// tutor or voiced, and an answer is recorded as the id of the option (`o1`), as for any other tap. Decision 25 of 2026-11-03.

/// Makes the options of the own-name items of a lesson. [childName] is the profile's first name as the parent typed it, [companionName]
/// the name of the child's companion; both may be null. A name that cannot be used (see [printName]) is passed over for the next:
/// the child's, the companion's, the house character's. [random] chooses among the names of the closed list that fit the rule.
class OwnName {
  OwnName({String? childName, String? companionName, math.Random? random})
    : _docs = OwnNameDocs(childName: childName, companionName: companionName, random: random);

  final OwnNameDocs _docs;

  /// [a] with its options made, or [a] itself when it is not an own-name item. It never throws: an item whose options cannot be made even
  /// from the house name (the validator refuses such a pack) comes back as it was, and [stillToMake] tells the lesson to pass it over.
  Activity apply(Activity a) {
    if (a is! TapAnswerActivity || !a.ownName) return a;
    try {
      final Map<String, Object?>? doc = _docs.madeDoc(a.json);
      return doc == null ? a : Activity.fromJson(doc, a.assets);
    } on Object {
      return a; // a malformed item: nothing is logged, because a log must not carry a name
    }
  }

  /// An item that [apply] could not make: it has no faces to draw.
  static bool stillToMake(Activity a) => a is TapAnswerActivity && a.ownName;
}
