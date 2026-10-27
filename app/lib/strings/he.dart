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
