# B-26: the child's home island and Nitzi's home, the Hebrew

Owner of this doc: hebrew-text-editor. Board item: B-26 (plan step, wording only; no app code, no master-table rows yet).
Written 2026-10-29 from `main` 48d7df0. Binding owner decisions (2026-10-29): the home island is named after the child,
"האי של <name>", per profile, on screen only, never sent to any vendor (not Anthropic, not ElevenLabs for this label), no
nikud on the name unless the parent set a reviewed spelling. The same words are the map sign and the title of the new
small screen "Nitzi's home" (Nitzi greets the child; the Trophy Hall, the stickers and today's adventure live there).

Today the sign is `He.landNitzi = Str('הָאִי שֶׁל נִיצִי', nikud: true)` (`app/lib/strings/he.dart:49`), drawn by
`_LandSign` in `app/lib/child/home_screen.dart:721` (Heebo 18, weight 700, one line, `softWrap: false`, a 20-point icon,
8 + 8 padding, a 3-point border), and `HomeScreen.homeLabel` already lets the caller pass another `Str` (line 337).

## 1. The pattern

### 1.1 The words

| Where | Pattern | Nikud |
|---|---|---|
| Map sign | `הָאִי שֶׁל {child}` | the frame `הָאִי שֶׁל` pointed (child text); the name as the parent wrote it |
| Screen title | `הָאִי שֶׁל {child}` (same words, never shortened, see 1.4) | same |
| Screen reader (sign, tap area, screen) | `האי של {child}` (full name, never shortened) | none (semantics strings are unpointed, as all `*Semantics` in `he.dart`) |

### 1.2 Grammar, worked out

1. **`הָאִי שֶׁל דנה`, not the construct `אִי דנה`.** With a person, the analytic possessive with `שֶׁל` is the spoken,
   warm form a child hears at gan ("הַכִּסֵּא שֶׁל דָּנָה"); `אִי דנה` sounds like a place name on a map (like `אִיֵּי יָוָן`),
   is formal, and in writing `אי` + word can be read as the negation prefix (`אִי־סֵדֶר`, `אִי־ודאות`). The old sign
   `הָאִי שֶׁל נִיצִי` already used `שֶׁל`, so the sign keeps its shape and only the name changes. The other signs are
   constructs with a common noun (`גִּבְעוֹת הַסְּפִירָה`); that is right for them and does not apply to a name.
2. **`שֶׁל` is a separate word, so nothing touches the name.** This is the main reason for the pattern: a prefix
   (`לְ`, `בְּ`, `וְ`, `שֶׁ`, `מִ`, `כְּ`, `הַ`) would change its vowel by the name's first letter (`לְדָנָה`, `לַאֲבִיגַיִל`,
   `לִיהוֹנָתָן`, `וּמִיכָאֵל`) and we cannot point a name we did not write. With `שֶׁל` a name that starts with
   ה ו ב כ ל מ ש (`הדס`, `ורד`, `ברק`, `כרמל`, `לביא`, `מיכאל`, `שירה`) or with a vowel, aleph or ayin (`אורי`, `עדי`) reads
   exactly as written. **Rule for every line in the app: `{child}` never gets a prefix letter.** Use a separate word
   (`שֶׁל {child}`, `עִם {child}`, `בִּשְׁבִיל {child}`) or the name alone as a vocative (`שָׁלוֹם, {child}!`).
   `שֶׁל` is never fused (`שֶׁלְּדָנָה` is wrong).
3. **Gender.** `אִי` is masculine; `שֶׁל` does not inflect. The sign is the same words for a girl, a boy and a unisex name
   (`נועם`, `עדי`, `טל`, `שחר`, `אורי`, `כרמל`): no address form is needed, and the app never guesses a gender from a
   name. Anything said about the island agrees with `אִי` (`הָאִי שֶׁל דָּנָה גָּדֵל`, masculine, also for a girl). Words
   addressed to the child follow the team rule (plural, or no second person at all; section 3).
4. **The definite article stays on `הָאִי`** (qamats under ה before the guttural א). It is "the island of", one island.
5. **Mixed pointing is intended.** A pointed frame with an unpointed name (`הָאִי שֶׁל דנה`) is fine for a reader of any
   age: children recognise their own name as a whole word from the gan name cards. The app never adds nikud to a name
   (CLAUDE.md: nikud is never generated at runtime).

### 1.3 Names as parents type them

| Case | What the app does | Why |
|---|---|---|
| Spaces around or inside | trim; any run of white space becomes one space | `"  טל "` → `טל` |
| Control or direction characters (U+0000–001F, U+007F–009F, U+200B–200F, U+202A–202E, U+2066–2069, U+FEFF) | removed | they can reorder the sign or hide text (also a spoofing risk; security-engineer to confirm) |
| Geresh, typed as `'` (U+0027) or `׳` (U+05F3): `ג'וליה`, `צ׳רלי`, `ז'אן` | kept exactly as typed; never converted | it is the parent's spelling; Heebo has both glyphs |
| Hyphen `-` or maqaf `־` (U+05BE): `בת-אל`, `שירה-לי` | kept as typed; the whole hyphenated name is one name | `בת-אל` must never become `בת` |
| Two parts with a space: `נועה מאיה` | shown whole when it fits (1.4) | we do not know which part the child goes by |
| Latin letters: `Emma`, `Alexander` | shown as typed, inside a first-strong isolate: `U+2068 name U+2069` | keeps a Latin name and its `…` in left-to-right order inside the right-to-left sign; never transliterated |
| Parent-typed nikud (`אֲבִיגַיִל`) | shown as typed | it is the parent's reviewed spelling (section 4) |
| Nothing left after the steps above, or no letter at all | the fallback (section 2) | |

The name is always wrapped in U+2068 … U+2069 on the sign and the title (Hebrew and Latin alike, so there is one code
path); the semantics string carries the plain name without the marks.

### 1.4 How long, and how it is cut

Counting unit: a **grapheme cluster** (`String.characters`; a letter with its nikud is one, a space, a hyphen, a geresh
and `…` are one each). So nikud never changes whether a name is cut.

**Sign: the name part is at most 10 clusters.** (Recommended; the design-director confirms the number, section 6 and
the hand-off.) Over 10:

1. **Whole parts first.** Split at a space, `-` or `־`, keeping the separators. Take the longest run of whole parts from
   the start whose length is at most 9 and that holds at least 2 letters; drop a trailing separator; add `…` (U+2026).
   `Marie-Antoinette` → `Marie…`; `אביגיל-רחל שושנה` → `אביגיל…`.
2. **Otherwise letters.** Take the first 9 clusters and add `…`. If the next cluster (the first one dropped) is a geresh
   or an apostrophe, drop one more letter, so a letter is never shown without its geresh (`צ'` is one sound). Drop a
   trailing space or hyphen before the `…`.
3. **Never** cut without `…`; never convert a cut letter to a final form (`…` says the word goes on); never cut the
   screen-reader text.
4. The `…` is inside the isolate, at the logical end of the name, so in a Latin name it sits to the right of the letters
   and in a Hebrew name to the left (the end of the word in each script).

**Title: never cut in practice.** The title shows the whole name and may wrap to two lines. Join `הָאִי` and `שֶׁל` with a
no-break space (U+00A0) so a wrap only falls before the name. As a guard for the 40-character field only: over 24
clusters, the same rule with 24 (23 + `…`).

Why 10: almost every Israeli first name is at most 7 letters, the long ones are 8 to 10 (`אלכסנדרה`, `מקסימיליאן`,
`Alexander`), and 10 of the widest letter (`מ`) still gives a sign of about 232 points (section 6). A count, not a
measured width, so the same name looks the same on every phone and a test can pin it.

### 1.5 Examples

Sign and title as shown (the U+2068/U+2069 marks are not written here). Widths: Heebo advance widths at 18 points,
regular weight from the font file times 1.07 for weight 700, plus 46 points of icon, padding and border: an estimate,
not a rendered measurement (section 6).

| # | Name as typed | Kind | Clusters | Sign | Screen title | Sign width (est.) |
|---|---|---|---|---|---|---|
| 1 | דנה | girl, short | 3 | הָאִי שֶׁל דנה | הָאִי שֶׁל דנה | 139 |
| 2 | בן | boy, shortest | 2 | הָאִי שֶׁל בן | הָאִי שֶׁל בן | 126 |
| 3 | נועה | girl | 4 | הָאִי שֶׁל נועה | הָאִי שֶׁל נועה | 145 |
| 4 | יהונתן | boy | 6 | הָאִי שֶׁל יהונתן | הָאִי שֶׁל יהונתן | 158 |
| 5 | הדס | girl, starts with ה | 3 | הָאִי שֶׁל הדס | הָאִי שֶׁל הדס | 144 |
| 6 | ורד | girl, starts with ו | 3 | הָאִי שֶׁל ורד | הָאִי שֶׁל ורד | 135 |
| 7 | שירה | girl, starts with ש | 4 | הָאִי שֶׁל שירה | הָאִי שֶׁל שירה | 152 |
| 8 | מיכאל | boy, starts with מ | 5 | הָאִי שֶׁל מיכאל | הָאִי שֶׁל מיכאל | 161 |
| 9 | לביא | boy, starts with ל | 4 | הָאִי שֶׁל לביא | הָאִי שֶׁל לביא | 148 |
| 10 | כרמל | unisex, starts with כ | 4 | הָאִי שֶׁל כרמל | הָאִי שֶׁל כרמל | 152 |
| 11 | אורי | unisex, aleph | 4 | הָאִי שֶׁל אורי | הָאִי שֶׁל אורי | 144 |
| 12 | עדי | unisex, ayin | 3 | הָאִי שֶׁל עדי | הָאִי שֶׁל עדי | 137 |
| 13 | נועם | unisex | 4 | הָאִי שֶׁל נועם | הָאִי שֶׁל נועם | 146 |
| 14 | ג'וליה | girl, geresh as `'` | 6 | הָאִי שֶׁל ג'וליה | הָאִי שֶׁל ג'וליה | 154 |
| 15 | צ׳רלי | unisex, geresh U+05F3 | 5 | הָאִי שֶׁל צ׳רלי | הָאִי שֶׁל צ׳רלי | 149 |
| 16 | בת-אל | girl, hyphen | 5 | הָאִי שֶׁל בת-אל | הָאִי שֶׁל בת-אל | 160 |
| 17 | שירה-לי | girl, hyphen | 7 | הָאִי שֶׁל שירה-לי | הָאִי שֶׁל שירה-לי | 173 |
| 18 | נועה מאיה | girl, two parts | 9 | הָאִי שֶׁל נועה מאיה | הָאִי שֶׁל נועה מאיה | 192 |
| 19 | אֲבִיגַיִל | girl, parent-pointed | 6 | הָאִי שֶׁל אֲבִיגַיִל | הָאִי שֶׁל אֲבִיגַיִל | 162 |
| 20 | Emma | Latin | 4 | הָאִי שֶׁל Emma | הָאִי שֶׁל Emma | 165 |
| 21 | Alexander | Latin, boy | 9 | הָאִי שֶׁל Alexander | הָאִי שֶׁל Alexander | 196 |
| 22 | אלכסנדרה | girl, long | 8 | הָאִי שֶׁל אלכסנדרה | הָאִי שֶׁל אלכסנדרה | 193 |
| 23 | מקסימיליאן | boy, long (at the limit) | 10 | הָאִי שֶׁל מקסימיליאן | הָאִי שֶׁל מקסימיליאן | 204 |
| 24 | Massimiliano | Latin, one long word | 12 | הָאִי שֶׁל Massimili… | הָאִי שֶׁל Massimiliano | 206 |
| 25 | Marie-Antoinette | Latin, hyphen | 16 | הָאִי שֶׁל Marie… | הָאִי שֶׁל Marie-Antoinette | 172 |
| 26 | אביגיל-רחל שושנה | three parts | 16 | הָאִי שֶׁל אביגיל… | הָאִי שֶׁל אביגיל-רחל שושנה | 175 |
| 27 | אנהמריהלואיזה | typed without spaces (made up) | 13 | הָאִי שֶׁל אנהמריהלו… | הָאִי שֶׁל אנהמריהלואיזה | 208 |
| 28 | `"  טל  "` | spaces around | 2 | הָאִי שֶׁל טל | הָאִי שֶׁל טל | 132 |
| 29 | (empty, or only spaces and control marks) | no name | 0 | הָאִי שֶׁלִּי | הָאִי שֶׁלִּי | 111 |
| — | (today) | | | הָאִי שֶׁל נִיצִי | | 139 |
| — | widest name allowed: 10 × מ | worst case | 10 | | | about 232 |

## 2. When there is no name

Today every profile has a name (the form needs 1 to 40 characters; a synced profile carries a 1 to 24 nickname), so the
fallback is a guard for an empty or unusable name after the steps of 1.3.

| Use | Text | Why |
|---|---|---|
| Sign and title | `הָאִי שֶׁלִּי` | "my island", in the child's own voice, like the existing `הַמַּדְבֵּקוֹת שֶׁלִּי` (`stickersTitle`); calm, nothing is missing, no gender |
| Screen reader | `האי שלי` | |
| Greeting | `שָׁלוֹם! בְּרוּכִים הַבָּאִים הַבַּיְתָה.` | the greeting of 3.1 without the name |

Not recommended: `הָאִי שֶׁלָּנוּ` (warm, but with siblings on one phone "ours" blurs whose island it is), or going back to
`הָאִי שֶׁל נִיצִי` (undoes the owner's decision that the island is the child's), or anything with "name" in it.

## 3. Nitzi's home: the texts

Update 2026-10-29 (owner decision 4): the friend the child chose says these lines, not only Nitzi, so no line names Nitzi
or has a first person with a gender (friends are girls and boys, and a family character can be either). The child is addressed in the
plural or not addressed with a verb at all, so no gender is guessed. Nothing is timed, nothing asks a personal
question, nothing counts what is missing. `{companion}` is not used: its gender would have to agree with the verbs.

Every string below is new and is `"review": "needs-editor"` (`Str.review` returns it for all strings in `he.dart`).
"Voice later" means a candidate for a voiced line after the owner approves the text; nothing is voiced in B-26.

### 3.1 Strings for `app/lib/strings/he.dart` (proposed names)

| Name | Screen text | Nikud | Where | Voice later | Voice text (draft, for the voice director) |
|---|---|---|---|---|---|
| `homeIsland` | `הָאִי שֶׁל {child}` | yes (frame) | the sign and the screen title | **never** (owner: this label is not sent to any vendor) | — |
| `homeIslandMine` | `הָאִי שֶׁלִּי` | yes | fallback sign and title | no | — |
| `homeIslandSemantics` | `האי של {child}` | no | screen reader: the sign, its tap area, the screen | no | — |
| `homeIslandMineSemantics` | `האי שלי` | no | screen reader, fallback | no | — |
| `nitziHomeWelcome` | `שָׁלוֹם, {child}! בְּרוּכִים הַבָּאִים הַבַּיְתָה.` | yes; the name as typed | Nitzi's bubble when the screen opens | yes, **without the name** (one clip for every child) | `שלום, ברוכים הבאים הביתה.` |
| `nitziHomeWelcomeNoName` | `שָׁלוֹם! בְּרוּכִים הַבָּאִים הַבַּיְתָה.` | yes | the same, when there is no name | yes (the same clip) | `שלום, ברוכים הבאים הביתה.` |
| `nitziHomeHi` (optional) | `זֶה הַבַּיִת שֶׁלִּי.` (2026-10-29; was `אֲנִי נִיצִי. אֲנִי גָּרָה פֹּה.`, which fits Nitzi only) | yes | when the child taps the friend at its house door | yes | `זה הבית שלי.` |
| `nitziHomeTreasures` | `פֹּה גָּרִים הַגְּבִיעִים, הַמֵּדַלְיוֹת וְהַמַּדְבֵּקוֹת.` | yes | Nitzi's second bubble, or when the hall or the stickers are tapped for the first time | yes | `פֹּה גָּרִים הגביעים, המדליות והמדבקות.` |
| `nitziHomeBottle` | `בַּבַּקְבּוּק יֵשׁ הַרְפַּתְקָה. בּוֹאוּ נִפְתַּח אוֹתוֹ.` (2026-10-29; was `הַבַּקְבּוּק הֵבִיא הַרְפַּתְקָה חֲדָשָׁה.`: a revisit is not new) | yes | beside the bottle | yes | `בבקבוק יש הרפתקה. בואו נִפְתַּח אותו.` |
| `nitziHomeBottleDone` (only if the app knows the day's adventure was finished) | `כְּבָר סִיַּמְנוּ אֶת הַהַרְפַּתְקָה שֶׁל הַיּוֹם. אֶפְשָׁר לְשַׂחֵק בָּאִיִּים.` | yes | the same place, after it was finished | yes | `כבר סיימנו את ההרפתקה של היום. אפשר לשחק בָּאִיִּים.` |
| `nitziHomeBack` | `לַמַּפָּה` | yes | the visible label of the back button | no | — |

Reused, unchanged: `He.hallTitle` `הֵיכַל הַגְּבִיעִים`, `He.stickersTitle` `הַמַּדְבֵּקוֹת שֶׁלִּי` (or the shorter
`He.homeStickersLabel` `מַדְבֵּקוֹת` under a small button), `He.homeDaily` `הַהַרְפַּתְקָה שֶׁל הַיּוֹם`, and
`He.landBackSemantics` `חזרה למפה` for the back button's screen reader. No new semantics string is needed for them.

### 3.2 Notes on the wording

- `בְּרוּכִים הַבָּאִים` is the fixed welcome said to anyone (a sign at the gan door says it), so the plural is natural even
  before one name. The per-gender forms are a question for the owner (section 5, Q5).
- `פֹּה גָּרִים הַגְּבִיעִים, הַמֵּדַלְיוֹת וְהַמַּדְבֵּקוֹת`: a mixed group (masculine `גְּבִיעִים` and feminine nouns) takes
  the masculine plural `גָּרִים`. "Live here" keeps the screen a home, and says nothing about how many there are, so
  an empty shelf is not pointed at. If the design splits it: `פֹּה גָּרִים הַגְּבִיעִים וְהַמֵּדַלְיוֹת.` and
  `גַּם הַמַּדְבֵּקוֹת גָּרוֹת פֹּה.` (feminine plural for the stickers).
- Spoken lines avoid a conjunctive `וְ` before ב ג ד כ פ ת (`וְכָאן`, `וּפֹה`): the normative spirant (`vechan`, `ufo`)
  differs from everyday speech (`vekan`, `upo`) and a voice would say one of them wrongly for someone. Hence `פֹּה` and
  `גַּם`.
- `כְּבָר סִיַּמְנוּ` is "we", Nitzi and the child together: no gender, no "you did / did not". There is no "come back
  tomorrow": a promise of the next bottle is a pull to return (a streak by another name); the line points to the
  islands, which are always open.
- `לַמַּפָּה` ("to the map") is the shortest clear label; an arrow next to it is the design-director's call (the arrow
  of a back button in right-to-left points right).
- Partial nikud in the voice texts: `פֹּה` (else `פֶּה`, mouth), `גָּרִים`, `גָּרָה` (else `גֵּרִים`), `בָּאִיִּים`; the rest is
  plain full spelling. No `!` in a voice text; the comma after `שלום` is the small breath.
- The name is shown in the bubble but never said: the welcome clip is the same for every child. A voiced name would make
  the welcome a PER-NAME line like `homeBubble` (hebrew-notes, question 6), which needs the owner (Q6).

## 4. Where the name lives today (read only, nothing changed)

| What | Where | Today |
|---|---|---|
| The name | `Profiles.name`, `app/lib/data/tables.dart:8`; documented as "the parent-reviewed spelling" (line 4) | free text, 1 to 40 characters, on the device |
| Where the parent types it | `ChildFormScreen`, `app/lib/parent/child_form.dart:94`, label `He.setupName` `שם פרטי` | trim and length only |
| Server copy | `child-put` sends it as `nickname` (`app/lib/sync/sync_engine.dart:226`); the server takes 1 to 24 characters, no control characters, no `<>` (`supabase/functions/child-put/handler.ts:10`) | |
| Address form | `Profiles.addressForm` (`f`, `m`, `n`) | not needed for the sign |

**Which spelling the sign uses:** `Profiles.name` exactly as stored (after the clean-up of 1.3). It is the only spelling
there is, and it is the one the parent chose. If a separate reviewed pointed spelling is added later, the sign and title
use it when it is set and `Profiles.name` otherwise (the owner's own words: "no nikud unless the parent set a reviewed
spelling"); the screen-reader text keeps the plain name.

**Gaps (for later items, not B-26 code):**

1. **No field for a pointed ("how to say it") spelling.** PLAN.md (privacy rule 2 and decision 3) says the voice may get
   a first name "spelled and vocalised by a parent"; there is no such field. A parent can only type nikud into the
   name itself, on a phone keyboard that rarely offers it, and that nikud then also counts toward the length limits.
2. **No way to edit a name.** The parent area adds and removes profiles only (`addProfile`, `removeProfile`); a typo now
   lives on the child's island sign until the profile is deleted (and deleting takes the child's rewards).
3. **40 here, 24 on the server.** A name of 25 to 40 characters never syncs: `_pushProfiles` skips the failed call
   silently (`sync_engine.dart:233`). Nikud counts as characters on both sides.
4. **No clean-up of direction and invisible characters** (1.3) in the form or the sync.
5. **The parent is not told the name appears on the map.** A one-line hint under the field would help (adult text, no
   nikud), for example `השם יופיע על האי של הילד או הילדה במפה.` — needs the owner's OK like any new string.

## 5. Questions for the owner (with my recommendation)

1. **Sign limit.** Recommended: the name part shows up to 10 characters, longer names are shortened with `…` (whole
   parts first). If the design-director finds 10 too wide on the iPhone SE, the alternatives are 8 or a two-line sign
   (`הָאִי שֶׁל` small on top, the name below), which keeps a 10-letter name at about 168 points (today: 139).
2. **Shorten with `…` always**, also when a whole first part is kept (`Marie…`, `אביגיל…`)? Recommended yes: it is
   honest and tells the parent the sign is shortened; the title and the screen reader keep the whole name.
3. **Fallback** `הָאִי שֶׁלִּי`? Recommended yes (over `הָאִי שֶׁלָּנוּ` or `הָאִי שֶׁל נִיצִי`).
4. **Reviewed pointed spelling on the sign.** When a pointed spelling exists (it does not yet), show it on the sign and
   the title? Recommended yes, as you said; today the sign shows the name as typed.
5. **Welcome per address form** (`בָּרוּךְ הַבָּא` / `בְּרוּכָה הַבָּאָה` / `בְּרוּכִים הַבָּאִים`) or `בְּרוּכִים הַבָּאִים` for
   everyone? Recommended: the plural for everyone (a fixed formula; one voice clip; no gender decision).
6. **Is the welcome voiced with the name?** Recommended no: the name is shown in the bubble, the clip is the same for
   every child, and no name goes to ElevenLabs for this screen. (A voiced name would be a per-name line, your call.)
7. **"Done for today" line** (`nitziHomeBottleDone`): include it (no "come back tomorrow"), or show nothing once the
   adventure is finished? Recommended include, only if the app already knows the adventure was finished.
8. **Is "Nitzi's home" (`הַבַּיִת שֶׁל נִיצִי`) written anywhere on screen?** Recommended no: the screen's title is the
   child's island, and Nitzi says she lives there (`אֲנִי נִיצִי. אֲנִי גָּרָה פֹּה.`). "Nitzi's home" stays the name of
   the screen in the code and the plan.
9. **Gaps 1 to 5 of section 4** as later board items (edit a name, a pointed-spelling field, one length limit for the
   app and the server, the clean-up, the parent hint)? Recommended yes; gap 3 (silent sync skip) first.

## 6. Width risks (for the design-director)

- The sign grows from 139 points (today) to about 126–204 for real names and up to about 232 for 10 wide letters
  (estimates from the font's advance widths; Heebo 700 was approximated as regular × 1.07; nikud adds no width;
  the 1.7 line height of `AppText.fixed` sets the sign's height, not its width). Please measure in Chrome or a golden.
- **iPhone SE**: the "+" pebble is 19 points from the Nitzi sign horizontally and 10 above it
  (`docs/design/phone-map-7-lands.md`), and the sign is 147 from the world's right edge. A centred sign wider than
  about 175 (139 + 2 × 19) meets the "+". Options: anchor the Nitzi sign at its right edge and let it grow toward Counting Hills
  (252 apart; room for about 225), move the "+", lower the limit to 8, or the two-line sign.
- **Phone**: the "+" is 25 points from the sign; the same question at about 190 and up.
- **Tablets**: signs are 252 (landscape) and about 310 (portrait) apart; a 232 sign keeps about 40 points to Counting
  Hills' sign. Probably fine; please confirm.
- **Latin names**: check that `Massimili…` shows the `…` on the right of the letters (the isolate), and `Emma` reads
  left to right inside the sign.
- **Title**: two lines must fit on the SE at the title size; a wrap falls only before the name (no-break space).

## 7. Step 3 hand-off (2026-10-29): the map bubble without a name, and a last read

From `docs/qa/b26-step3-verification.md` (notes): with no usable name the map bubble says only `מַה בַּבַּקְבּוּק?`,
built in code from `homeBubble` (`_withoutName`, `home_screen.dart:740`, `replaceFirst('{child}, ', '')`), so it was
never a row of the review tables.

### 7.1 Decision: keep the bare question, as its own entry

**The words stay `מַה בַּבַּקְבּוּק?`.** It is a whole question in spoken Hebrew ("what's in the bottle?", as a child
says it), the same invitation as the named line without the call. It has no verb, so no gender is guessed and it fits
every friend; it says nothing about a missing name; it is true for a revisit and for a new lesson; and its fixed width
is the one already measured for the named line (123 at Heebo 500, 24; tablet limit 140), so it is one line on every
board. Weighed and not taken: `שָׁלוֹם! מַה בַּבַּקְבּוּק?` (a greeting the named line does not have, about 60 wider,
over the tablet limit; the welcome belongs to the home, `nitziHomeWelcomeNoName`), `מַה יֵּשׁ בַּבַּקְבּוּק?` (156, too
wide, as in step 2), `הֵי, מַה בַּבַּקְבּוּק?` (a call to no one, and slangy).

**Own entry: yes.** `He.homeBubbleNoName = Str('מַה בַּבַּקְבּוּק?', nikud: true)` (added to `app/lib/strings/he.dart`
under `homeBubble`; `review` is `needs-editor` like every `Str`). Code point for code point the text the code builds
today (checked, NFC). Why:
1. Every line a child sees is read by the editor and the owner in the tables; a derived line escapes them.
2. The derivation is fragile: if `homeBubble` is ever reworded (another punctuation after the name, a word before it),
   `replaceFirst('{child}, ', '')` matches nothing and a child with no name sees the raw `{child}` on the map.
3. It is the pattern of `nitziHomeWelcome` / `nitziHomeWelcomeNoName`.

**For the app-developer** (not done here): `_withoutName` → `He.homeBubbleNoName`. `_breakAfterName` may stay derived
(it only adds a line break to the same words), but it has the same fragility: a test or an `assert` that
`He.homeBubble.text` contains `'{child}, '` would catch a rewording. A test that the nameless bubble shows exactly
`He.homeBubbleNoName.text`.

**Voice:** spoken, voice text `מה בבקבוק?`: the same voice text as `homeBubble`, so one clip serves both and this line
is never per-name. Nothing is voiced in B-26 (decision 6).

**Tables:** `tools/hebrew_voice_review.py`: `homeBubbleNoName` added to `VOICED_UI` and to `PENDING` (stays `proposed`
for the owner). Regenerated with `tools/export-hebrew-review.py` and `tools/hebrew_voice_review.py`: 9,522 rows
(screens 332), master text-ready 9,455, proposed 44, unchanged 23. Against the step-3 tables the only change is the
new row in each of the five files (plus the counts in the two `.md` summaries).

### 7.2 A last read against the final flow

Every B-26 line read again for gender (the child's is unknown), nikud and voice. All child lines are fully pointed and
checked: `הָאִי` (qamats under the article before א), `שֶׁלִּי` (dagesh in ל), `בַּבַּקְבּוּק` (article merged into בַּ, dagesh
forte in the second ב, dagesh lene in בּוּק after the shva), `מַה` with patah before the dagesh, `הַבָּאִים`, `הַבַּיְתָה`,
`פֹּה` (holam, not `פֶּה`), `וְהַמַּדְבֵּקוֹת` (וְ before ה), `נִפְתַּח` (qal future, first person plural), `סִיַּמְנוּ`, `בָּאִיִּים`.
No line has a singular "you", a gendered first person, a gendered verb about the child, or a prefix on `{child}`.

| Where in the flow | String | Verdict |
|---|---|---|
| Map sign | `homeIsland` `הָאִי שֶׁל {child}`; `homeIslandMine` `הָאִי שֶׁלִּי` | final. `אִי` is masculine, `שֶׁל` does not inflect: the same for a girl, a boy and a unisex name. Never voiced. |
| Sign and title, screen reader | `homeIslandSemantics`, `homeIslandMineSemantics` | final, unpointed. When the Hall's glow moves to the sign, join the two labels with a comma: `האי של דנה, גביע חדש מחכה`. |
| Map bubble | `homeBubble` `{child}, מַה בַּבַּקְבּוּק?`; `homeBubbleNoName` `מַה בַּבַּקְבּוּק?` | final text; per-name voicing of `homeBubble` is Q6 (not in B-26). |
| Today's Adventure pill | `homeDaily` `הַהַרְפַּתְקָה שֶׁל הַיּוֹם` | unchanged and still true: with one stop (decision 3) it is the adventure offered today; it promises no count. |
| Home title | `island.title` = `homeIsland` / `homeIslandMine` with no-break spaces in the frame | final (same words as the sign, never shortened under 24). |
| Home bubble on entry | `nitziHomeWelcome` / `nitziHomeWelcomeNoName` | text final; the fixed plural `בְּרוּכִים הַבָּאִים` for every child is Q5 (open). |
| Friend at the door | `nitziHomeHi` `זֶה הַבַּיִת שֶׁלִּי.` | correct and gender-free, but the design has no line here (a tap waves). If it is used: the house stands on **the child's** island and any friend may say it, so `זֶה הַבַּיִת שֶׁלָּנוּ.` ("our house": this friend and this child) fits the flow better. Owner question 3 below; not changed in `he.dart`. |
| Bottle, its line | `nitziHomeBottle` `בַּבַּקְבּוּק יֵשׁ הַרְפַּתְקָה. בּוֹאוּ נִפְתַּח אוֹתוֹ.` | final; it answers the map's question; `אוֹתוֹ` agrees with `בַּקְבּוּק`. |
| Bottle, done | `nitziHomeBottleDone` | waits for the three-stop plan (Q7). |
| Hall and stickers line | `nitziHomeTreasures` | final; true once the lighthouse and the book are in the home (step 4). |
| Bottle label | none yet | **reuse `homeDaily`**: the pill on the map is the same thing (its icon is the bottle), so the same name ties them. If it is too wide under the SE bottle (136 wide; the design-director measures at 14 bold), a new one-word label `הַרְפַּתְקָה` (I write it on request). |
| Book label | `homeStickersLabel` `מַדְבֵּקוֹת` | reuse (the child knows it from the map pebble). |
| Lighthouse label | `homeHallLabel` `גְּבִיעִים` | reuse; `הֵיכַל הַגְּבִיעִים` (`hallTitle`) stays the Hall's own title, too long and too formal for a label. |
| Back | the pebble, `landBackSemantics` `חזרה למפה` | final. My draft visible label `nitziHomeBack` `לַמַּפָּה` (3.1) is **withdrawn**: the back pebbles of the Land, Hall and Sticker screens have no visible word, and the design gives this one none. Not in `he.dart`. |
| Old sign | `landNitzi` `הָאִי שֶׁל נִיצִי` | now only the screen-reader fallback when no `HomeIslandName` is passed (tests, old callers); a child never sees it. Keep. |

**Voice-ready.** Nothing of B-26 is voiced (decision 6). In the master table only `homeBubble` and `homeBubbleNoName`
are spoken (`מה בבקבוק?`). The draft voice texts of 3.1 (`שלום, ברוכים הבאים הביתה.`, `זה הבית שלי.`, `פֹּה גָּרִים
הגביעים, המדליות והמדבקות.`, `בבקבוק יש הרפתקה. בואו נִפְתַּח אותו.`) are ready for the voicing step: no name, no
`!`, partial nikud where a TTS could misread. When that step comes, their ids go into `VOICED_UI`.

**Found while reading (app-developer, QA to verify): a shortened Latin name in the bubble shows its `…` on the wrong
side.** The sign puts the name in U+2068 … U+2069 (1.3); the bubble fills `{child}` with the bare cleaned name. In
`Massimili…, מַה בַּבַּקְבּוּק?` the `…` and the comma stand between a Latin and a Hebrew run, so they take the line's
right-to-left direction and the `…` is drawn to the **left** of the Latin letters, where a Latin word begins (rule 4 of
1.4 wants it on the right). Only long Latin names that are shortened (SE, tablets) show it; Hebrew names and whole Latin
names are right. Fix: fill `{child}` with `'⁨$name⁩'` in the bubble too (as `_withName` does), and later in
`nitziHomeWelcome`; the marks have no width, so the fit does not change.

**Name pronunciation.** Nothing to decide in B-26: no name is voiced. Q6 (how a voiced name is joined to `מה בבקבוק?`)
and the missing "how to say it" field (gap 1 of section 4) stay for the voicing step. One look-alike, for information:
the name `שלי` (Shelly) gives `הָאִי שֶׁל שלי`, which reads like "my island" twice over; the pointed frame and the gan
name card make it clear on screen, and a screen reader says it the way the family says the name. No change.

### 7.3 Still for the owner

1. Q5: `בְּרוּכִים הַבָּאִים` for every child (recommended) or by address form.
2. Q6 (later, voicing): the per-name `homeBubble`: one clip per child with the name, or a name clip joined to `מה בבקבוק?`.
3. `nitziHomeHi`, if the design uses it: `זֶה הַבַּיִת שֶׁלִּי.` (the friend's house) or `זֶה הַבַּיִת שֶׁלָּנוּ.` (recommended:
   the house of this friend and this child, on the child's island).
4. Q7: show `nitziHomeBottleDone` once the three-stop plan exists (recommended), or nothing.
5. `homeBubbleNoName` `מַה בַּבַּקְבּוּק?` (new row, `proposed`): approve with the other B-26 rows.
