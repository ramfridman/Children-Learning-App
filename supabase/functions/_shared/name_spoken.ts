// How a child's name is said (B-42, docs/milestones/B42.md section 3.2): the spelling a parent checked, with nikud where the
// name needs it. It is the one text the gateway turns into the child's own name clip, so the rule is narrow: Hebrew
// letters, their nikud, a space, a hyphen and a geresh, 1 to 24 characters, and nothing the voice would read wrongly or
// that could hide in a name (the same refusals as the app's `safeChildName`, B-32; the app is tested against the same
// vectors, testvectors/name-spoken.json).
//
// A mark may stand only on a letter, at most three in a row (a shin with a dagesh, a dot and a vowel). U+05B3 (hataf
// qamats) and U+05C7 (qamats qatan) are never sent to the voice (`voice_text_lib.dart`), so they are not allowed here.
// The pattern has no `u` flag: it counts UTF-16 units, as the app and the database do (every allowed character is in the
// basic plane).

const LETTER = "\\u05D0-\\u05EA";
const MARK = "\\u05B0-\\u05B2\\u05B4-\\u05BC\\u05C1\\u05C2";
const JOINER = " '\\-\\u05BE\\u05F3";

/** The longest spelling, in UTF-16 units. */
export const NAME_SPOKEN_MAX = 24;

export const NAME_SPOKEN = new RegExp(
  `^(?=.*[${LETTER}])(?! )(?!.* $)(?!.* {2})(?:[${LETTER}][${MARK}]{0,3}|[${JOINER}])+$`,
);

/** Whether [value] is a spelling the gateway will voice. */
export function isSpokenName(value: unknown): value is string {
  return typeof value === "string" && value.length >= 1 && value.length <= NAME_SPOKEN_MAX &&
    NAME_SPOKEN.test(value);
}
