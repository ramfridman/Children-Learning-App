// Every Hebrew string the app shows, in one place. Nothing is generated at runtime.
//
// Every entry is `review: needs-editor` until the owner or an editor approves it. Child-facing
// strings carry full niqqud ([Str.nikud] true); adult strings (setup, gate, parent area) have none.
// `test/strings_test.dart` checks both rules and that no screen holds a Hebrew literal of its own.

/// One string of the catalogue.
class Str {
  const Str(this.text, {this.nikud = false});

  final String text;

  /// True for text that children see or hear, which is written with full niqqud.
  final bool nikud;

  /// All strings are drafts until a person approves them; nothing here is approved yet.
  String get review => 'needs-editor';

  /// Replaces placeholders such as the child's first name (`{child}`), after validation. One pass over the text: a
  /// value that holds braces (the child's words) is put in as it is, never filled again.
  String fill(Map<String, String> values) =>
      text.replaceAllMapped(_placeholder, (Match m) => values[m[1]] ?? m[0]!);

  static final RegExp _placeholder = RegExp(r'\{(\w+)\}');

  @override
  String toString() => text;
}

abstract final class He {
  // ---- child space ----
  static const Str pickerTitle = Str('עִם מִי נְשַׂחֵק הַיּוֹם?', nikud: true);
  static const Str pickerAddSemantics = Str('הוספת ילד, להורים בלבד');
  static const Str friendsSemantics = Str('לבחור חבר');
  static const Str friendsTitle = Str('מִי יִהְיֶה הֶחָבֵר שֶׁלִּי?', nikud: true);
  static const Str friendChosenSemantics = Str('החבר שנבחר');
  static const Str homeParents = Str('הורים');
  static const Str restScene = Str('עַכְשָׁו נָחִים קְצָת. נִפָּגֵשׁ שׁוּב אַחַר כָּךְ!', nikud: true);
  static const Str restBackSemantics = Str('חזרה');
  static const Str restGoodbye = Str(
    'הָיָה כֵּיף! עַכְשָׁו נָחִים קְצָת, וְנִשְׁחַק שׁוּב אַחַר כָּךְ.',
    nikud: true,
  );
  static const Str placementDone = Str('יָפֶה מְאֹד! עַכְשָׁו נֵדַע מֵאֵיפֹה לְהַתְחִיל.', nikud: true);
  static const Str homeDaily = Str('הַהַרְפַּתְקָה שֶׁל הַיּוֹם', nikud: true);
  static const Str homeBubble = Str('{child}, הַבַּקְבּוּק הִגִּיעַ!', nikud: true);
  static const Str landColors = Str('מִפְרַץ הַצְּבָעִים', nikud: true);
  static const Str landCounting = Str('גִּבְעוֹת הַסְּפִירָה', nikud: true);
  static const Str landNitzi = Str('הָאִי שֶׁל נִיצִי', nikud: true);
  static const Str landShapes = Str('יַעַר הַצּוּרוֹת', nikud: true);
  static const Str landLogic = Str('מְעָרַת הַחִידוֹת', nikud: true);
  static const Str landRobots = Str('נְמַל הָרוֹבּוֹטִים', nikud: true);
  static const Str landMarket = Str('כְּפַר הַשּׁוּק', nikud: true);
  static const Str homeMapSemantics = Str('מפת האיים');
  static const Str switchChildSemantics = Str('החלפת ילד');
  static const Str bookSemantics = Str('הספר');
  static const Str activityQuestion = Str('כַּמָּה פְּרָחִים יֵשׁ?', nikud: true);
  static const Str replaySemantics = Str('שמיעה חוזרת של השאלה');
  static const Str coinA10Semantics = Str('10 אגורות');
  static const Str coinH50Semantics = Str('חצי שקל');
  static const Str coinS1Semantics = Str('שקל');
  static const Str coinS2Semantics = Str('שני שקלים');
  static const Str coinS5Semantics = Str('חמישה שקלים');
  static const Str coinS10Semantics = Str('עשרה שקלים');
  static const Str noteN20Semantics = Str('שטר של עשרים');
  static const Str noteN50Semantics = Str('שטר של חמישים');
  static const Str noteN100Semantics = Str('שטר של מאה');
  static const Str noteN200Semantics = Str('שטר של מאתיים');
  static const Str agorot = Str('אֲגוֹרוֹת', nikud: true);
  static const Str giveDoneSemantics = Str('סיימתי');
  static const Str lessonDoneSemantics = Str('חזרה למפה');
  static const Str lessonUnavailable = Str('הַשִּׁעוּר לֹא מוּכָן עַכְשָׁו', nikud: true);
  static const Str counterSemantics = Str('כמה כבר נספרו');
  static const Str showMeSemantics = Str('תראו לי');
  static const Str hintSemantics = Str('רמז');
  static const Str homeSemantics = Str('הביתה');
  static const Str micSemantics = Str('מיקרופון');
  static const Str micListeningSemantics = Str('מקשיבים');
  static const Str micThinkingSemantics = Str('חושבים');
  static const Str micUnderstoodSemantics = Str('הבנו');
  static const Str micNotUnderstoodSemantics = Str('לא הבנו, אפשר לנסות שוב');
  static const Str micFadedSemantics = Str('אפשר ללחוץ על התשובה');
  static const Str confirmYesSemantics = Str('כן, זה מה שאמרתי');
  static const Str confirmAgainSemantics = Str('לומר שוב');
  static const Str thinkHmm = Str('הַמְּמ… בּוֹאוּ נַחְשֹׁב.', nikud: true);
  static const Str listenMixed = Str(
    'אוֹפְּס, הָאָזְנַיִם שֶׁלִּי הִתְבַּלְבְּלוּ! אֶפְשָׁר לְהַגִּיד שׁוּב?',
    nikud: true,
  );
  static const Str listenConfirm = Str('שָׁמַעְתִּי… נָכוֹן?', nikud: true);
  static const Str listenTap = Str('אֶפְשָׁר גַּם לִלְחֹץ עַל הַתְּשׁוּבָה.', nikud: true);

  // ---- the Trophy Hall, the ceremony, medals and prizes (M8) ----
  static const Str homeStickersLabel = Str('מַדְבֵּקוֹת', nikud: true);
  static const Str homeHallLabel = Str('גְּבִיעִים', nikud: true);
  static const Str stickersTitle = Str('הַמַּדְבֵּקוֹת שֶׁלִּי', nikud: true);
  static const Str stickersHow = Str('מַדְבֵּקָה אַחַת עַל כָּל שִׁעוּר שֶׁמְּסַיְּמִים', nikud: true);
  static const Str stageSketch = Str('עוֹד מְתַרְגְּלִים', nikud: true);
  static const Str stageColour = Str('יוֹדְעִים!', nikud: true);
  static const Str stageFruit = Str('יוֹדְעִים וְגַם זוֹכְרִים!', nikud: true);
  static const Str landPlayLabel = Str('לְשַׂחֵק', nikud: true);
  static const Str legendSketch = Str('מְתַרְגְּלִים', nikud: true);
  static const Str legendColour = Str('יוֹדְעִים', nikud: true);
  static const Str legendStar = Str('וְגַם זוֹכְרִים', nikud: true);
  static const Str legendSemantics = Str('מה אומרים הציורים: מתרגלים, יודעים, זוכרים');
  static const Str hallTitle = Str('הֵיכַל הַגְּבִיעִים', nikud: true);
  static const Str hallSemantics = Str('היכל הגביעים');
  static const Str hallTabTrophies = Str('גְּבִיעִים', nikud: true);
  static const Str hallTabMedals = Str('מֵדַלְיוֹת', nikud: true);
  static const Str hallTabFriend = Str('לֶחָבֵר', nikud: true);
  static const Str trophyBronze = Str('גְּבִיעַ הַבְּרוֹנְזָה', nikud: true);
  static const Str trophySilver = Str('גְּבִיעַ הַכֶּסֶף', nikud: true);
  static const Str trophyGold = Str('גְּבִיעַ הַזָּהָב', nikud: true);
  static const Str trophyHow = Str('מְבִינִים {n} דְּבָרִים וְזוֹכְרִים גַּם אַחֲרֵי שָׁבוּעַ', nikud: true);
  static const Str trophyComing = Str(
    'הַגְּבִיעִים יָבוֹאוּ כְּשֶׁיִּהְיֶה עוֹד מָה לִלְמֹד כָּאן',
    nikud: true,
  );
  static const Str trophyNewSemantics = Str('גביע חדש מחכה');
  static const Str trophyReplaySemantics = Str('לראות שוב את הטקס');
  static const Str trophyLockedSemantics = Str('גביע שעוד לא הרווחנו');
  static const Str ceremonyBronze = Str('הִנֵּה גְּבִיעַ בְּרוֹנְזָה בִּשְׁבִילְכֶם!', nikud: true);
  static const Str ceremonySilver = Str('הִנֵּה גְּבִיעַ כֶּסֶף בִּשְׁבִילְכֶם!', nikud: true);
  static const Str ceremonyGold = Str('הִנֵּה גְּבִיעַ זָהָב בִּשְׁבִילְכֶם!', nikud: true);
  static const Str ceremonyMedal = Str('הִנֵּה מֵדַלְיָה בִּשְׁבִילְכֶם!', nikud: true);
  static const Str ceremonyAlso = Str('וְגַם לֶחָבֵר:', nikud: true);
  static const Str ceremonyContinueSemantics = Str('להמשיך');
  static const Str medalBraveAsker = Str('אֹמֶץ לִשְׁאֹל', nikud: true);
  static const Str medalTryAgain = Str('מְנַסִּים שׁוּב', nikud: true);
  static const Str medalExplainer = Str('אֵיךְ יָדַעְתִּי', nikud: true);
  static const Str medalBugFixer = Str('מְתַקְּנֵי בָּאגִים', nikud: true);
  static const Str medalBraveAskerHow = Str(
    'אוֹמְרִים "לֹא בָּטוּחַ" אוֹ "תַּרְאוּ לִי" חָמֵשׁ פְּעָמִים',
    nikud: true,
  );
  static const Str medalTryAgainHow = Str('מְנַסִּים שׁוּב וּמַצְלִיחִים שָׁלוֹשׁ פְּעָמִים', nikud: true);
  static const Str medalExplainerHow = Str('אֶפְשָׁר יִהְיֶה לְהַרְוִיחַ אוֹתָהּ בְּקָרוֹב', nikud: true);
  static const Str medalBugFixerHow = Str('אֶפְשָׁר יִהְיֶה לְהַרְוִיחַ אוֹתָהּ בְּקָרוֹב', nikud: true);
  static const Str medalLockedSemantics = Str('מדליה שעוד לא הרווחנו');
  static const Str outfitHoney = Str('צָעִיף דְּבַשׁ', nikud: true);
  static const Str outfitSky = Str('צָעִיף שָׁמַיִם', nikud: true);
  static const Str outfitRose = Str('צָעִיף וֶרֶד', nikud: true);
  static const Str outfitNone = Str('בְּלִי צָעִיף', nikud: true);
  static const Str outfitHowBronze = Str('מְגִיעַ עִם גְּבִיעַ בְּרוֹנְזָה', nikud: true);
  static const Str outfitHowSilver = Str('מְגִיעַ עִם גְּבִיעַ כֶּסֶף', nikud: true);
  static const Str outfitHowGold = Str('מְגִיעַ עִם גְּבִיעַ זָהָב', nikud: true);
  static const Str outfitWearSemantics = Str('ללבוש');
  static const Str decorationLantern = Str('פָּנָס', nikud: true);
  static const Str decorationFlag = Str('דֶּגֶל', nikud: true);
  static const Str decorationFountain = Str('מַזְרֵקָה', nikud: true);
  static const Str stickersEmptyChild = Str(
    'אַחֲרֵי הַשִּׁעוּר הָרִאשׁוֹן תִּהְיֶה כָּאן מַדְבֵּקָה.',
    nikud: true,
  );

  // ---- parent gate and PIN (adult) ----
  static const Str gateTitle = Str('לפני שנמשיך');
  static const Str gateHint = Str('השאלה הזו מיועדת להורים. ענו עליה כדי להיכנס.');
  static const Str gateQuestion = Str('כמה זה?');
  static const Str gateBack = Str('חזרה');
  static const Str gateWrong = Str('התשובה לא נכונה, נסו שוב.');
  static const Str gateCoolDown = Str('נחכה רגע ואז ננסה שוב, בעוד {s} שניות.');
  static const Str gateLong = Str('יותר מדי נסיונות. אפשר לנסות שוב בעוד {m} דקות.');
  static const Str pinTitle = Str('קוד הורים');
  static const Str pinEnter = Str('הקלידו את קוד ההורים');
  static const Str pinWrong = Str('הקוד לא נכון.');
  static const Str pinLocked = Str('נסו שוב בעוד {t}.');
  static const Str pinSetTitle = Str('בחירת קוד הורים');
  static const Str pinSetHint = Str('4 עד 6 ספרות. הקוד שומר על אזור ההורים גם כשהילדים משתמשים במכשיר.');
  static const Str pinConfirm = Str('הקלידו את הקוד שוב לאישור');
  static const Str pinMismatch = Str('הקודים לא זהים, נסו שוב.');
  static const Str pinMinutes = Str('{n} דקות');
  static const Str pinSeconds = Str('{n} שניות');
  static const Str pinDelete = Str('מחיקת ספרה');
  static const Str pinOk = Str('אישור');

  // ---- parent setup (adult) ----
  static const Str setupWelcomeTitle = Str('ברוכים הבאים');
  static const Str setupWelcomeBody = Str(
    'נכין את המכשיר הזה למשחק של הילדים. זה לוקח כמה דקות: כניסה, רישום המכשיר, קוד הורים ופרופיל ראשון.',
  );
  static const Str setupStart = Str('מתחילים');
  static const Str setupEmail = Str('כתובת דוא"ל');
  static const Str setupSendCode = Str('שליחת קוד');
  static const Str setupCodeSent = Str('שלחנו קוד בן 6 ספרות לדוא"ל.');
  static const Str setupCode = Str('הקוד מהדוא"ל');
  static const Str setupVerify = Str('אימות');
  static const Str setupSignedIn = Str('נכנסתם בהצלחה.');
  static const Str setupEnrolTitle = Str('רישום המכשיר');
  static const Str setupEnrolBody = Str(
    'המכשיר הזה יהיה מכשיר הורים: רק מי שיודע את קוד ההורים יכול לנהל ממנו את המשפחה.',
  );
  static const Str setupEnrolButton = Str('רישום המכשיר');
  static const Str setupEnrolled = Str('המכשיר נרשם.');
  static const Str setupChildTitle = Str('הוספת ילד או ילדה');
  static const Str setupName = Str('שם פרטי');
  static const Str setupAge = Str('גיל');
  static const Str setupAvatar = Str('בחירת דמות');
  static const Str setupAddress = Str('פנייה בלשון');
  static const Str addressFemale = Str('נקבה');
  static const Str addressMale = Str('זכר');
  static const Str addressNeutral = Str('ניטרלי');
  static const Str setupSave = Str('שמירה');
  static const Str setupNext = Str('המשך');
  static const Str setupBack = Str('חזרה');
  static const Str setupFinish = Str('סיום');
  static const Str setupError = Str('משהו השתבש. בדקו את החיבור לאינטרנט ונסו שוב.');
  static const Str setupWrongCode = Str('הקוד לא נכון או שפג תוקפו.');

  // ---- parent area (adult) ----
  static const Str areaTitle = Str('אזור הורים');
  static const Str areaDevices = Str('מכשירים');
  static const Str areaThisDevice = Str('המכשיר הזה');
  static const Str areaRevoke = Str('ניתוק');
  static const Str areaRefresh = Str('רענון');
  static const Str areaProfiles = Str('ילדים');
  static const Str areaAddChild = Str('הוספת ילד');
  static const Str areaRemove = Str('הסרה');
  static const Str areaConfirmRemove = Str('להסיר את הפרופיל של {child}? כל ההתקדמות במכשיר הזה תימחק.');
  static const Str areaChangePin = Str('שינוי קוד הורים');
  static const Str areaLockNow = Str('נעילה וחזרה למשחק');
  static const Str areaTimeOpen = Str('זמן משחק ושעות מנוחה');

  // ---- parent area: what the helper said (M7b) ----
  static const Str tutorLogOpen = Str('מה העוזר אמר');
  static const Str tutorLogTitle = Str('מה העוזר אמר ב-30 הימים האחרונים');
  static const Str tutorLogHelp = Str(
    'כל משפט נבדק לפני שהילד שמע אותו. משפט שלא עבר את הבדיקות לא נשמע, ובמקומו נשמעה ההודעה הרגילה.',
  );
  static const Str tutorLogEmpty = Str('עוד לא נשמעו משפטים של העוזר.');
  static const Str tutorLogOffline = Str('אי אפשר להגיע לשרת כרגע. נסו שוב בעוד רגע.');
  static const Str tutorLogSpoken = Str('נשמע');
  static const Str tutorLogRule = Str('נשמעה ההודעה הרגילה');

  // ---- parent area: alerts (M7a) ----
  static const Str alertsTitle = Str('התראות');
  static const Str alertsOpen = Str('התראות');
  static const Str alertsOpenUnread = Str('התראות ({n} חדשות)');
  static const Str alertsNone = Str('אין התראות. כשיהיה משהו שכדאי לדעת עליו, הוא יופיע כאן.');
  static const Str alertsKeepWords = Str('לשמור בהתראה את המילים שנשמעו');
  static const Str alertsKeepWordsHelp = Str(
    'כשמופעל, המילים שנשמעו נשמרות עם ההתראה עד 30 יום. כשכבוי, המילים לא נשמרות. נשמרים רק סוג ההתראה, מספר הפעמים, והאם נשמע שזה אולי קורה הרבה.',
  );
  static const Str alertsNever = Str('ההתראות לא מוצגות בצד של הילדים, והאפליקציה אף פעם לא נוזפת בהם.');
  static const Str severityInfo = Str('לידיעה');
  static const Str severityAttention = Str('לתשומת לב');
  static const Str severityImportant = Str('חשוב');
  static const Str alertAbout = Str('{child}: {title}');
  static const Str alertPastLimitTitle = Str('שיחקו מעבר לזמן שנקבע');
  static const Str alertPastLimitDetail = Str('ב-{n} דקות יותר מהמותר.');
  static const Str alertPastLimitDo = Str('אפשר לשנות את הגבלת הזמן, או לדבר על סיום משחק.');
  static const Str alertRestTitle = Str('שיחקו בשעות המנוחה');
  static const Str alertRestDetail = Str('כ-{n} דקות.');
  static const Str alertRestDo = Str('אפשר להפעיל נעילה בשעות המנוחה או לשנות את השעות.');
  static const Str alertGateTitle = Str('ניסיון להיכנס לאזור ההורים');
  static const Str alertGateDetail = Str('נכשלו {n} ניסיונות ברצף.');
  static const Str alertGateDo = Str('אם עוד אין קוד הורים, כדאי לקבוע אחד.');
  static const Str alertGuessTitle = Str('נראה שיש ניחושים מהירים');
  static const Str alertGuessDo = Str('כדאי לשחק יחד כמה דקות ולעבור לפעילות רגועה.');
  static const Str alertUpsetTitle = Str('נראה שיש תסכול במשחק');
  static const Str alertUpsetDo = Str('אפשר לנסות פעילות רגועה בבית, או לשחק יחד.');
  // ---- parent area: word alerts (hebrew-validation.md 5.1, final-draft 2026-10-29) ----
  // {child} never has a prefix letter attached; the numbers are isolated left to right and only on screen.
  static const Str alertChildFallback = Str('הילדים');
  static const Str alertHeard = Str('במשחק של {child} נשמעו המילים: "{w}"');
  static const Str alertWordsNotKept = Str('המילים עצמן לא נשמרו, לפי ההגדרות שבחרתם.');
  static const Str alertActTitle = Str('נשמע משהו שחשוב לשים אליו לב');
  static const Str alertActUnsure = Str(
    'האפליקציה לא תמיד מבינה ילדים נכון. ייתכן שזה היה משחק או סיפור, וייתכן שהיא שמעה לא נכון. היא לא יודעת מה קרה, והיא לא מאבחנת דבר.',
  );
  static const Str alertActNow = Str('מה כדאי לעשות עכשיו');
  static const Str alertActStep1 = Str('למצוא זמן רגוע ומקום פרטי, ולשוחח עם {child} בלי ללחוץ.');
  static const Str alertActStep2 = Str(
    'להקשיב. אפשר לשאול שאלה פתוחה אחת, כמו "רוצה לספר לי עוד?" או "מה רצית לספר לי?". לא לחקור ולא להציע תשובות.',
  );
  static const Str alertActStep3 = Str(
    'לומר: "טוב שסיפרת לי. אני מאמין לך. זו לא אשמתך." (אפשר גם "מאמינה").',
  );
  static const Str alertActStep4 = Str('לא להבטיח לשמור סוד. אפשר לומר: "אעשה מה שצריך כדי לשמור עליך."');
  static const Str alertActStep5 = Str('אם החשש הוא מאדם מסוים, לא להתעמת איתו לפני שהתייעצתם.');
  static const Str alertActHelp = Str('אפשר להתייעץ עוד היום, גם בלי להגיש תלונה');
  static const Str alertHelp118 = Str(
    '\u2066118\u2069 – מוקד המידע והסיוע של משרד הרווחה והביטחון החברתי: חינם, 24 שעות ביממה, בעברית, בערבית, באמהרית וברוסית. אפשר גם לכתוב בוואטסאפ: \u2066050-2270118\u2069.',
  );
  static const Str alertHelp1201 = Str(
    '\u20661201\u2069 – ער״ן, עזרה ראשונה נפשית, אנונימית, בטלפון ובצ׳אט, גם להורים.',
  );
  // A lawyer confirms this sentence before the app is relied on.
  static const Str alertActDuty = Str(
    'במקרים רבים של פגיעה בילדים חלה בישראל חובת דיווח למשטרה או לעובד סוציאלי לפי חוק הנוער. במוקד \u2066118\u2069 אפשר לברר אם היא חלה במקרה שלכם.',
  );
  static const Str alertActNoReport = Str('האפליקציה לא מדווחת לאף גורם. ההחלטה מה לעשות היא שלכם.');
  static const Str alertAddPhys = Str(
    'אם נשמע שמישהו מרביץ: כדאי לשים לב אם יש סימנים על הגוף, ואם יש, לפנות לרופא הילדים. אם מדובר במבוגר שאחראי על {child}, להתייעץ לפני כל פנייה אליו.',
  );
  static const Str alertAddSex = Str(
    'אם נשמע משהו על נגיעה או על צילום: להקשיב בלי להראות בהלה, ולא לחקור לבד. כדאי להתייעץ מיד עם מוקד \u2066118\u2069 או עם מרכז הגנה לילדים ולנוער (בית לין); אפשר להתייעץ גם בלי למסור שם. אם יש חשש לפגיעה בימים האחרונים, המרכזים האקוטיים בבתי החולים פתוחים 24 שעות ביממה.',
  );
  static const Str alertAddSelf = Str(
    'ילדים צעירים לא תמיד מבינים מה זה מוות, ולפעמים אומרים דברים כאלה מתוך כעס. ובכל זאת, חשוב להתייחס לזה ברצינות: להישאר קרובים, גם ברגעים קשים, ולשאול בשקט מה עובר על {child}. בימים הקרובים כדאי להתייעץ עם יועצת הגן או בית הספר, עם פסיכולוג או עם רופא הילדים. אפשר לפנות גם לער״ן, \u20661201\u2069. בסכנה מיידית: חדר מיון.',
  );
  static const Str alertAddNegl = Str(
    'אם {child} לבד עכשיו, כדאי לדאוג מיד שמבוגר יהיה שם. ילדים בגיל הזה לא אמורים להישאר לבד בבית.',
  );
  static const Str alertAddEmerg = Str(
    'אם נשמע שמישהו נפל ולא זז: להתקשר מיד הביתה או לאדם שנמצא עם {child}, ואם צריך, לקרוא לעזרה רפואית. ייתכן שזה משחק, אבל כדאי לבדוק עכשיו.',
  );
  // The hours of 105 are not printed: they were not verified.
  static const Str alertAddOnline = Str(
    'אם מישהו פנה אל {child} בטלפון, במשחק או ברשת: לשמור צילומי מסך ולא למחוק, לא להגיב לפונה, ולדווח למוקד \u2066105\u2069 של המטה הלאומי להגנה על ילדים ברשת.',
  );
  static const Str alertAddSecret = Str(
    'ילדים שביקשו מהם לשמור סוד על משהו שמפחיד או כואב צריכים לשמוע שמותר לספר: "הפתעה אפשר לשמור בסוד. סוד שמפחיד או כואב תמיד מספרים, ומי שמספר לא נכנס לצרות."',
  );
  static const Str alertCheckTitle = Str('נשמע משהו שאולי כדאי לבדוק');
  static const Str alertCheckMaybe = Str(
    'זה יכול להיות משחק, סיפור או משהו שנאמר בלי כוונה. ייתכן גם שהאפליקציה שמעה לא נכון. אין צורך להיבהל.',
  );
  static const Str alertCheckAsk = Str(
    'בזמן רגוע, ובלי ללחוץ, אפשר לשאול: "איך היה היום? יש משהו שבא לך לספר לי?"',
  );
  static const Str alertCheckIf = Str(
    'אם זה חוזר, או אם משהו בהתנהגות של {child} השתנה (שינה, אכילה, פחד מאדם מסוים, חזרה להתנהגות של גיל צעיר יותר), כדאי להתייעץ עם היועצת בגן או בבית הספר, עם רופא הילדים או עם מוקד \u2066118\u2069.',
  );
  static const Str alertRepeatTitle = Str('נשמעו כמה דברים שכדאי לשים אליהם לב');
  static const Str alertRepeatHeard = Str('בשבוע האחרון נשמעו כמה פעמים דברים דומים: "{w}".');
  // The same sentence without the words, when the parent does not keep them (not in 5.1: for the editor).
  static const Str alertRepeatHeardNoWords = Str('בשבוע האחרון נשמעו כמה פעמים דברים דומים.');
  static const Str alertRepeatNext = Str(
    'כל אחד מהם לבד אולי לא מדאיג, אבל יחד כדאי לשוחח עם {child}. הצעדים ומספרי הסיוע מופיעים בהמשך.',
  );
  static const Str alertNoteTitle = Str('מילים לא הולמות השבוע');
  static const Str alertNoteMany = Str('השבוע נשמעו במשחק של {child} מילים לא הולמות, {n} פעמים.');
  static const Str alertNoteOnce = Str('נשמעה במשחק של {child} מילה לא הולמת, פעם אחת.');
  static const Str alertNoteCalm = Str(
    'ילדים בגיל הזה חוזרים על מילים ששמעו בבית, ברחוב או במסך, ולפעמים בודקים איך המבוגרים יגיבו. אין צורך להתרגש: אפשר להגיב בשקט, להסביר בקצרה שאת המילה הזאת לא אומרים, ולהציע מילה אחרת. ייתכן גם שהאפליקציה שמעה לא נכון.',
  );
  static const Str alertNoteHidden = Str('ההתראה לא מוצגת בצד של הילדים.');
  static const Str alertExposeTitle = Str('נשמעה מילה מעולם המבוגרים');
  static const Str alertExposeBody = Str(
    'במשחק של {child} נשמעה מילה שקשורה לתכנים למבוגרים. ייתכן שזה משהו שנשמע או נראה בבית, אצל חברים או במסך, וייתכן שהאפליקציה שמעה לא נכון. כדאי לשוחח בנחת, בלי לנזוף, ולבדוק אילו תכנים זמינים במכשירים בבית. אם זה קרה ברשת, אפשר לפנות למוקד \u2066105\u2069.',
  );
  // C-5, under an act or a check (owner approved the draft, 2026-10-30).
  static const Str alertOften = Str('נשמע גם שזה אולי קורה הרבה. כדאי לספר על כך כשמתייעצים.');
  // How many times an act or a check was heard in its half hour (new, for the editor: not in the drafts).
  static const Str alertHeardTimes = Str('זה נשמע {n} פעמים בתוך חצי שעה.');
  // W-47, the weekly note of a request to keep a secret (owner approved the draft, 2026-10-30).
  static const Str alertSecretAskTitle = Str('בקשה לשמור סוד');
  static const Str alertSecretAskMany = Str('השבוע נשמעה במשחק של {child} בקשה לא לספר משהו, {n} פעמים.');
  static const Str alertSecretAskOnce = Str('השבוע נשמעה במשחק של {child} בקשה לא לספר משהו, פעם אחת.');
  static const Str alertSecretAskCalm = Str(
    'לרוב זה משהו קטן, כמו כוס שנשברה. אפשר להזכיר בנחת שהפתעות שומרים בסוד, ודבר שמפחיד או כואב תמיד מספרים. ייתכן גם שהאפליקציה שמעה לא נכון.',
  );
  // W-37 in band A, the weekly note of a young child hitting themselves (owner approved the draft, 2026-10-30).
  static const Str alertSelfHitTitle = Str('מילים על מכות לעצמי');
  static const Str alertSelfHitMany = Str('השבוע נשמעו במשחק של {child} מילים על מכות לעצמי, {n} פעמים.');
  static const Str alertSelfHitOnce = Str('השבוע נשמעו במשחק של {child} מילים על מכות לעצמי, פעם אחת.');
  static const Str alertSelfHitCalm = Str(
    'אצל ילדים צעירים זה קורה לא פעם בזמן התפרצות של כעס או תסכול. כדאי לשים לב אם זה קורה הרבה או אם יש סימנים על הגוף, ולהתייעץ עם רופא הילדים אם משהו מדאיג. ייתכן גם שהאפליקציה שמעה לא נכון.',
  );
  static const Str alertsHonest = Str(
    'ההתראות הן עוד דרך לשים לב, ולא תחליף להשגחה ולשיחה עם הילדים. האפליקציה מקשיבה רק כשהילדים לוחצים על המיקרופון, והיא לא תמיד מבינה ילדים צעירים, ולכן היא תחמיץ הרבה. היא לא מאבחנת ולא מדווחת לאף גורם.',
  );
  // The parent card: a counsellor reviews the content (and the "doctor" sentence for a parent who washes a young child).
  static const Str alertCardTitle = Str('שיחה על סודות ועל המקומות הפרטיים');
  static const Str alertCard1 = Str(
    'הפתעה, כמו מתנה ליום הולדת, אפשר לשמור בסוד. סוד שמפחיד או כואב תמיד מספרים.',
  );
  static const Str alertCard2 = Str(
    'המקומות שבגד הים מכסה הם פרטיים. אף אחד לא נוגע בהם ולא מבקש מאיתנו לגעת בגוף שלו, חוץ מרופא, כשאמא או אבא איתנו.',
  );
  static const Str alertCard3 = Str(
    'תמיד אפשר לספר לאמא, לאבא או למבוגר אחר שסומכים עליו, ומי שמספר לא נכנס לצרות.',
  );
  static const Str alertCard4 = Str('כדאי לשאול מדי פעם שאלה פתוחה: "מה היה הכי כיף היום? ומה היה לא נעים?"');
  static const Str alertAbsenceTitle = Str('לא שיחקו זמן מה');
  static const Str alertAbsenceDetail = Str('לפני {n} ימים.');
  static const Str alertAbsenceDo = Str('אפשר להזמין להרפתקה קצרה.');
  static const Str alertRibbonTitle = Str('זכו בגביע שיש עליו הבטחה');
  static const Str alertRibbonDetail = Str('{t}: {w}');
  static const Str alertRibbonNoWords = Str('{t}');
  static const Str alertRibbonDo = Str('זה הזמן לקיים את ההבטחה.');
  static const Str areaPrizes = Str('גביעים והבטחות');
  static const Str areaCeremonies = Str('טקס כשמקבלים גביע');
  static const Str areaCeremoniesHelp = Str(
    'כשהילד מקבל גביע או מדליה, החבר מציג אותם בטקס קצר. כשהטקס כבוי, הם מחכים בהיכל הגביעים.',
  );
  static const Str areaPromisesOpen = Str('הבטחות לגביעים');
  static const Str prizesTitle = Str('הבטחות לגביעים');
  static const Str prizesHelp = Str(
    'אפשר לצרף הבטחה לגביע, למשל "בגביע הזהב הולכים לגלידה". כשהילד יזכה בו תקבלו התראה, וההבטחה תופיע ליד הגביע שלו בהיכל. עד 60 תווים, בלי קישורים.',
  );
  static const Str prizesBronze = Str('גביע ברונזה');
  static const Str prizesSilver = Str('גביע כסף');
  static const Str prizesGold = Str('גביע זהב');
  static const Str prizesEarned = Str('הושג');
  static const Str prizesNotYet = Str('בקרוב, כשיהיו באי מספיק מיומנויות');
  static const Str prizesHint = Str('ההבטחה');
  static const Str prizesBad = Str('עד 60 תווים, בלי קישורים ובלי תווים מיוחדים.');
  static const Str prizesTooMany = Str('אי אפשר להוסיף עוד הבטחות (עד 30).');
  static const Str prizesNoChildren = Str('עוד אין ילדים. אפשר להוסיף ילד באזור ההורים.');
  static const Str alertDropTitle = Str('המשחק השבוע ירד בהרבה');
  static const Str alertDropDo = Str('אפשר לשאול מה קרה, ולהציע הרפתקה אהובה.');

  // ---- parent area: the progress view (M7a) ----
  static const Str areaProgress = Str('התקדמות');
  static const Str progressTitle = Str('התקדמות של {child}');
  static const Str progressEmpty = Str('עוד לא שיחקו. כשיתחילו, כאן יופיע איך הלמידה מתקדמת.');
  static const Str progressTileMinutes = Str('דקות משחק השבוע');
  static const Str progressTileAdventures = Str('הרפתקאות הושלמו');
  static const Str progressTileUnderstood = Str('מיומנויות מובנות');
  static const Str progressDomainCount = Str('{a} מתוך {b} מובנות');
  static const Str progressCurveSoon = Str('הקו יתמלא ככל שיצטברו שבועות של משחק. כך נראה המצב עכשיו:');
  static const Str progressNotYetPlayed = Str('עוד לא התחילו');
  static const Str progressWeek = Str('השבוע');
  static const Str progressMinutesChart = Str('דקות משחק לפי יום');
  static const Str progressSessions = Str('{n} מפגשי משחק');
  static const Str progressAdventures = Str('{n} הרפתקאות הושלמו');
  static const Str progressUnderstanding = Str('הבנה לפי תחום');
  static const Str progressGrowth = Str('הבנה לאורך זמן');
  static const Str progressGrowthHelp = Str(
    'כל קו מראה תחום אחד, בסוף כל שבוע בשמונה השבועות האחרונים. תחום שעוד לא התחילו בו לא מופיע.',
  );
  static const Str progressNoPoints = Str('עוד אין מספיק נתונים לקו.');
  static const Str progressHelped = Str('מה עוזר לילד');
  static const Str progressHelpedLine = Str('{how}: הצליחו {a} מתוך {b}');
  static const Str progressMisconceptions = Str('מה כדאי לשים לב אליו');
  static const Str progressResolved = Str('נפתר');
  static const Str progressHomeActivity = Str('פעילות לבית: {w}');
  static const Str progressNothingToWatch = Str('לא נמצאו אי-הבנות.');
  static const Str progressHabits = Str('חוזקות בלמידה');
  static const Str habitAsked = Str('ביקשו עזרה כשלא היו בטוחים: {n} פעמים');
  static const Str habitHints = Str('השתמשו ברמזים: {n} פעמים');
  static const Str habitKept = Str('ניסו שוב והצליחו: {n} פעמים');
  static const Str statusUnderstood = Str('מובן');
  static const Str statusPractising = Str('בתרגול');
  static const Str statusRevisit = Str('כדאי לחזור');
  static const Str statusGap = Str('נמצא פער');
  static const Str statusNotStarted = Str('עוד לא התחילו');
  static const Str domainNumbers = Str('מספרים');
  static const Str domainColors = Str('צבעים');
  static const Str domainShapes = Str('צורות');
  static const Str domainLogic = Str('היגיון');
  static const Str domainCs = Str('חשיבה חישובית');
  static const Str domainMath = Str('חשבון');
  static const Str repConcrete = Str('לימוד עם עצמים להזיז');
  static const Str repPictorial = Str('לימוד עם ציורים');
  static const Str repStory = Str('לימוד דרך סיפור');
  static const Str repEmbodied = Str('לימוד בתנועה');
  static const Str repSymbolic = Str('לימוד עם סימנים');
  static const Str dayLetters = Str('א ב ג ד ה ו ש');

  // ---- parent area: time and the AI helper (M7a) ----
  static const Str timeTitle = Str('זמן משחק');
  static const Str timeLimitHeading = Str('דקות משחק ביום');
  static const Str timeBand0 = Str('גיל 3 עד 4');
  static const Str timeBand1 = Str('גיל 5 עד 6');
  static const Str timeBand2 = Str('גיל 7 עד 8');
  static const Str timeMinutes = Str('{n} דקות');
  static const Str timeLess = Str('פחות');
  static const Str timeMore = Str('יותר');
  static const Str timeRestHeading = Str('שעות מנוחה');
  static const Str timeRestOn = Str('שעות מנוחה פעילות');
  static const Str timeRestFrom = Str('מתחילות ב-{t}');
  static const Str timeRestTo = Str('נגמרות ב-{t}');
  static const Str timeEarlier = Str('חצי שעה קודם');
  static const Str timeLater = Str('חצי שעה אחר כך');
  static const Str timeLock = Str('לנעול כשהזמן נגמר');
  static const Str timeLockHelp = Str(
    'כשהזמן נגמר או בשעות מנוחה לא מוצעת פעילות חדשה, והפעילות הנוכחית מסתיימת בעדינות. כשכבוי הילד ממשיך לשחק.',
  );
  static const Str timeScheduleHeading = Str('שעות מותרות בשבוע');
  static const Str timeScheduleHelp = Str(
    'ביום שמוגדרות בו שעות משחקים רק בהן. ביום בלי שעות משחקים בכל שעה.',
  );
  static const Str timeDayAny = Str('בכל שעה');
  static const Str timeDayWindow = Str('{a} עד {b}');
  static const Str timeDay1 = Str('יום שני');
  static const Str timeDay2 = Str('יום שלישי');
  static const Str timeDay3 = Str('יום רביעי');
  static const Str timeDay4 = Str('יום חמישי');
  static const Str timeDay5 = Str('יום שישי');
  static const Str timeDay6 = Str('שבת');
  static const Str timeDay7 = Str('יום ראשון');
  static const Str warmUpHeading = Str('משחק היכרות');
  static const Str warmUpHelp = Str(
    'בביקור הראשון בכל אי, הילד משחק כמה דקות כדי שנתחיל מהמקום הנכון. אין בו ציון ולא טעויות. אפשר לכבות.',
  );
  static const Str aiHeading = Str('עוזר מילולי');
  static const Str aiHelp = Str(
    'אחרי טעות שנייה הדמות יכולה להגיד משפט עזרה בקולה. המשפטים נבדקים לפני שהילד שומע אותם, ואם משהו לא עובד נשמעת ההודעה הרגילה. כבוי כברירת מחדל.',
  );
  static const Str areaVoice = Str('תשובות בקול');
  static const Str areaVoiceHelp = Str(
    'ילדים יוכלו לענות בדיבור. הזיהוי נעשה במכשיר, ההקלטה נמחקת מיד ולא נשמרת ולא נשלחת לשום מקום. המיקרופון נפתח רק כשהילד לוחץ עליו. המילים שזוהו נשמרות רק בהתראה, ורק אם ההגדרה "לשמור בהתראה את המילים שנשמעו" מופעלת.',
  );
  static const Str areaVoiceNoModel = Str('מודל הזיהוי עוד לא הותקן במכשיר הזה.');
  static const Str areaVoiceNoPermission = Str('לא ניתנה הרשאת מיקרופון. אפשר לתת אותה בהגדרות המכשיר.');
  static const Str areaVoiceCredit = Str('זיהוי דיבור: ivrit.ai Zipformer מאת יעקב קולני, רישיון CC-BY-4.0.');
  static const Str areaPush = Str('התראות בטלפון הזה');
  static const Str areaPushHelp = Str(
    'כשנוצרת התראה חדשה, הטלפון הזה מקבל הודעה קצרה שאומרת רק "יש התראה חדשה". שמות, מילים ופרטים על הילדים לא נשלחים בהודעה, והם נפתחים רק באפליקציה, מאחורי הקוד שלכם.',
  );
  static const Str areaPushDenied = Str('לא ניתנה הרשאה להצגת הודעות. אפשר לתת אותה בהגדרות המכשיר.');
  static const Str areaPushUnavailable = Str('ההתראות בטלפון לא זמינות בגרסה הזו של האפליקציה.');
  static const Str areaPushFailed = Str('אי אפשר להגיע לשרת כרגע. נסו שוב בעוד רגע.');
  static const Str celebrateWell = Str('כׇּל הַכָּבוֹד!', nikud: true);
  static const Str stickersSemantics = Str('המדבקות שלי');
  static const Str stickerNewSemantics = Str('מדבקה חדשה');
  static const Str starsSemantics = Str('כוכבי זהב');
  static const Str landPlaySemantics = Str('לשחק');
  static const Str landBackSemantics = Str('חזרה למפה');
  static const Str bellSemantics = Str('מישהו קורא לעזרה, אפשר לבדוק שוב');
  static const Str areaVersion = Str('גרסה');
  static const Str areaOffline = Str('אין חיבור לאינטרנט, אי אפשר לטעון את רשימת המכשירים.');
  static const Str confirmYes = Str('כן');
  static const Str confirmNo = Str('ביטול');
  static const Str roleParent = Str('הורה');
  static const Str roleChild = Str('ילד');
}
