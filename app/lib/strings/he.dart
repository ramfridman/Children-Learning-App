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

  /// Replaces placeholders such as the child's first name (`{child}`), after validation.
  String fill(Map<String, String> values) {
    String out = text;
    values.forEach((String k, String v) => out = out.replaceAll('{$k}', v));
    return out;
  }

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
  static const Str alertsKeepWords = Str('לשמור בהתראה את המילים שנאמרו');
  static const Str alertsKeepWordsHelp = Str(
    'כשמופעל, המילים שנאמרו נשמרות עם ההתראה עד 30 יום. כשכבוי, נשמרת רק הקטגוריה.',
  );
  static const Str alertsNever = Str('ההתראות לא מוצגות בצד של הילדים, והאפליקציה אף פעם לא מוכיחה אותם.');
  static const Str severityInfo = Str('לידיעה');
  static const Str severityAttention = Str('לתשומת לב');
  static const Str severityImportant = Str('חשוב');
  static const Str alertAbout = Str('{child}: {title}');
  static const Str alertWords = Str('נאמר: {w}');
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
  static const Str alertSwearTitle = Str('נאמרו מילים לא הולמות');
  static const Str alertSwearDo = Str('אפשר לשוחח על כך בנחת. ההתראה לא מוצגת בצד של הילדים.');
  static const Str alertDisclosureTitle = Str('נאמר משהו שעשוי להדאיג');
  static const Str alertDisclosureDo = Str('כדאי לשוחח בנחת ובפרטיות, בלי ללחוץ.');
  static const Str alertAbsenceTitle = Str('לא שיחקו זמן מה');
  static const Str alertAbsenceDetail = Str('לפני {n} ימים.');
  static const Str alertAbsenceDo = Str('אפשר להזמין להרפתקה קצרה.');
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
  static const Str aiHeading = Str('עוזר מילולי');
  static const Str aiHelp = Str(
    'אחרי טעות שנייה הדמות יכולה להגיד משפט עזרה בקולה. המשפטים נבדקים לפני שהילד שומע אותם, ואם משהו לא עובד נשמעת ההודעה הרגילה. כבוי כברירת מחדל.',
  );
  static const Str areaVoice = Str('תשובות בקול');
  static const Str areaVoiceHelp = Str(
    'ילדים יוכלו לענות בדיבור. הזיהוי נעשה במכשיר, ההקלטה נמחקת מיד ולא נשמרת ולא נשלחת לשום מקום. המיקרופון נפתח רק כשהילד לוחץ עליו.',
  );
  static const Str areaVoiceNoModel = Str('מודל הזיהוי עוד לא הותקן במכשיר הזה.');
  static const Str areaVoiceNoPermission = Str('לא ניתנה הרשאת מיקרופון. אפשר לתת אותה בהגדרות המכשיר.');
  static const Str areaVoiceCredit = Str('זיהוי דיבור: ivrit.ai Zipformer מאת יעקב קולני, רישיון CC-BY-4.0.');
  static const Str areaVersion = Str('גרסה');
  static const Str areaOffline = Str('אין חיבור לאינטרנט, אי אפשר לטעון את רשימת המכשירים.');
  static const Str confirmYes = Str('כן');
  static const Str confirmNo = Str('ביטול');
  static const Str roleParent = Str('הורה');
  static const Str roleChild = Str('ילד');
}
