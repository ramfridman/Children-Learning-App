# Hebrew texts waiting for review

Made by `tools/export-hebrew-review.py` on 2026-10-28 from the repository as it is now (M8 merged). Every text below is a draft written by Claude. Nothing is approved until you say so.

How to review: open `hebrew-review.csv` in Excel or Google Sheets, write a fix in **correction** (leave it empty if the text is fine) and notes in **comment**, then send the file back. Claude applies the fixes, marks the texts approved and voices again only the lines that changed (the cost is shown first, as always).

What to look at: spelling and niqqud; grammar and agreement (plural, neutral, no line says the child's name or the speaker's gender); a word a 3 to 8 year old knows; sentences short enough to say in one breath; nothing that scolds, frightens or compares.

| Group | Texts |
|---|---|
| 1. App screens and buttons | 308 |
| 2. Core voice lines (spoken by every friend) | 26 |
| 3. Lesson content (skills, activities, misconceptions) | 672 |
| 4. Reviewed helper (tutor) lines | 66 |
| 5. Alert word lists (for an editor and someone who works with children) | 23 |
| 6. Helper lexicon (the words the AI helper may use) | 110 |
| **Total** | **1205** |

## 1. App screens and buttons

| Source | Id | Text | Status |
|---|---|---|---|
| app/lib/strings/he.dart | pickerTitle | עִם מִי נְשַׂחֵק הַיּוֹם? | needs-editor |
| app/lib/strings/he.dart | pickerAddSemantics | הוספת ילד, להורים בלבד | needs-editor |
| app/lib/strings/he.dart | friendsSemantics | לבחור חבר | needs-editor |
| app/lib/strings/he.dart | friendsTitle | מִי יִהְיֶה הֶחָבֵר שֶׁלִּי? | needs-editor |
| app/lib/strings/he.dart | friendChosenSemantics | החבר שנבחר | needs-editor |
| app/lib/strings/he.dart | homeParents | הורים | needs-editor |
| app/lib/strings/he.dart | restScene | עַכְשָׁו נָחִים קְצָת. נִפָּגֵשׁ שׁוּב אַחַר כָּךְ! | needs-editor |
| app/lib/strings/he.dart | restBackSemantics | חזרה | needs-editor |
| app/lib/strings/he.dart | restGoodbye | הָיָה כֵּיף! עַכְשָׁו נָחִים קְצָת, וְנִשְׁחַק שׁוּב אַחַר כָּךְ. | needs-editor |
| app/lib/strings/he.dart | homeDaily | הַהַרְפַּתְקָה שֶׁל הַיּוֹם | needs-editor |
| app/lib/strings/he.dart | homeBubble | {child}, הַבַּקְבּוּק הִגִּיעַ! | needs-editor |
| app/lib/strings/he.dart | landColors | מִפְרַץ הַצְּבָעִים | needs-editor |
| app/lib/strings/he.dart | landCounting | גִּבְעוֹת הַסְּפִירָה | needs-editor |
| app/lib/strings/he.dart | landNitzi | הָאִי שֶׁל נִיצִי | needs-editor |
| app/lib/strings/he.dart | landShapes | יַעַר הַצּוּרוֹת | needs-editor |
| app/lib/strings/he.dart | landLogic | מְעָרַת הַחִידוֹת | needs-editor |
| app/lib/strings/he.dart | landRobots | נְמַל הָרוֹבּוֹטִים | needs-editor |
| app/lib/strings/he.dart | landMarket | כְּפַר הַשּׁוּק | needs-editor |
| app/lib/strings/he.dart | homeMapSemantics | מפת האיים | needs-editor |
| app/lib/strings/he.dart | switchChildSemantics | החלפת ילד | needs-editor |
| app/lib/strings/he.dart | bookSemantics | הספר | needs-editor |
| app/lib/strings/he.dart | activityQuestion | כַּמָּה פְּרָחִים יֵשׁ? | needs-editor |
| app/lib/strings/he.dart | replaySemantics | שמיעה חוזרת של השאלה | needs-editor |
| app/lib/strings/he.dart | giveDoneSemantics | סיימתי | needs-editor |
| app/lib/strings/he.dart | lessonDoneSemantics | חזרה למפה | needs-editor |
| app/lib/strings/he.dart | lessonUnavailable | הַשִּׁעוּר לֹא מוּכָן עַכְשָׁו | needs-editor |
| app/lib/strings/he.dart | counterSemantics | כמה כבר נספרו | needs-editor |
| app/lib/strings/he.dart | showMeSemantics | תראו לי | needs-editor |
| app/lib/strings/he.dart | hintSemantics | רמז | needs-editor |
| app/lib/strings/he.dart | homeSemantics | הביתה | needs-editor |
| app/lib/strings/he.dart | micSemantics | מיקרופון | needs-editor |
| app/lib/strings/he.dart | micListeningSemantics | מקשיבים | needs-editor |
| app/lib/strings/he.dart | micThinkingSemantics | חושבים | needs-editor |
| app/lib/strings/he.dart | micUnderstoodSemantics | הבנו | needs-editor |
| app/lib/strings/he.dart | micNotUnderstoodSemantics | לא הבנו, אפשר לנסות שוב | needs-editor |
| app/lib/strings/he.dart | micFadedSemantics | אפשר ללחוץ על התשובה | needs-editor |
| app/lib/strings/he.dart | confirmYesSemantics | כן, זה מה שאמרתי | needs-editor |
| app/lib/strings/he.dart | confirmAgainSemantics | לומר שוב | needs-editor |
| app/lib/strings/he.dart | thinkHmm | הַמְּמ… בּוֹאוּ נַחְשֹׁב. | needs-editor |
| app/lib/strings/he.dart | listenMixed | אוֹפְּס, הָאָזְנַיִם שֶׁלִּי הִתְבַּלְבְּלוּ! אֶפְשָׁר לְהַגִּיד שׁוּב? | needs-editor |
| app/lib/strings/he.dart | listenConfirm | שָׁמַעְתִּי… נָכוֹן? | needs-editor |
| app/lib/strings/he.dart | listenTap | אֶפְשָׁר גַּם לִלְחֹץ עַל הַתְּשׁוּבָה. | needs-editor |
| app/lib/strings/he.dart | homeStickersLabel | מַדְבֵּקוֹת | needs-editor |
| app/lib/strings/he.dart | homeHallLabel | גְּבִיעִים | needs-editor |
| app/lib/strings/he.dart | stickersTitle | הַמַּדְבֵּקוֹת שֶׁלִּי | needs-editor |
| app/lib/strings/he.dart | stickersHow | מַדְבֵּקָה אַחַת עַל כָּל שִׁעוּר שֶׁמְּסַיְּמִים | needs-editor |
| app/lib/strings/he.dart | stageSketch | עוֹד מְתַרְגְּלִים | needs-editor |
| app/lib/strings/he.dart | stageColour | יוֹדְעִים! | needs-editor |
| app/lib/strings/he.dart | stageFruit | יוֹדְעִים וְגַם זוֹכְרִים! | needs-editor |
| app/lib/strings/he.dart | landPlayLabel | לְשַׂחֵק | needs-editor |
| app/lib/strings/he.dart | legendSketch | מְתַרְגְּלִים | needs-editor |
| app/lib/strings/he.dart | legendColour | יוֹדְעִים | needs-editor |
| app/lib/strings/he.dart | legendStar | וְגַם זוֹכְרִים | needs-editor |
| app/lib/strings/he.dart | legendSemantics | מה אומרים הציורים: מתרגלים, יודעים, זוכרים | needs-editor |
| app/lib/strings/he.dart | hallTitle | הֵיכַל הַגְּבִיעִים | needs-editor |
| app/lib/strings/he.dart | hallSemantics | היכל הגביעים | needs-editor |
| app/lib/strings/he.dart | hallTabTrophies | גְּבִיעִים | needs-editor |
| app/lib/strings/he.dart | hallTabMedals | מֵדַלְיוֹת | needs-editor |
| app/lib/strings/he.dart | hallTabFriend | לֶחָבֵר | needs-editor |
| app/lib/strings/he.dart | trophyBronze | גְּבִיעַ הַבְּרוֹנְזָה | needs-editor |
| app/lib/strings/he.dart | trophySilver | גְּבִיעַ הַכֶּסֶף | needs-editor |
| app/lib/strings/he.dart | trophyGold | גְּבִיעַ הַזָּהָב | needs-editor |
| app/lib/strings/he.dart | trophyHow | מְבִינִים {n} דְּבָרִים וְזוֹכְרִים גַּם אַחֲרֵי שָׁבוּעַ | needs-editor |
| app/lib/strings/he.dart | trophyComing | הַגְּבִיעִים יָבוֹאוּ כְּשֶׁיִּהְיֶה עוֹד מָה לִלְמֹד כָּאן | needs-editor |
| app/lib/strings/he.dart | trophyNewSemantics | גביע חדש מחכה | needs-editor |
| app/lib/strings/he.dart | trophyReplaySemantics | לראות שוב את הטקס | needs-editor |
| app/lib/strings/he.dart | trophyLockedSemantics | גביע שעוד לא הרווחנו | needs-editor |
| app/lib/strings/he.dart | ceremonyBronze | הִנֵּה גְּבִיעַ בְּרוֹנְזָה בִּשְׁבִילְכֶם! | needs-editor |
| app/lib/strings/he.dart | ceremonySilver | הִנֵּה גְּבִיעַ כֶּסֶף בִּשְׁבִילְכֶם! | needs-editor |
| app/lib/strings/he.dart | ceremonyGold | הִנֵּה גְּבִיעַ זָהָב בִּשְׁבִילְכֶם! | needs-editor |
| app/lib/strings/he.dart | ceremonyMedal | הִנֵּה מֵדַלְיָה בִּשְׁבִילְכֶם! | needs-editor |
| app/lib/strings/he.dart | ceremonyAlso | וְגַם לֶחָבֵר: | needs-editor |
| app/lib/strings/he.dart | ceremonyContinueSemantics | להמשיך | needs-editor |
| app/lib/strings/he.dart | medalBraveAsker | אֹמֶץ לִשְׁאֹל | needs-editor |
| app/lib/strings/he.dart | medalTryAgain | מְנַסִּים שׁוּב | needs-editor |
| app/lib/strings/he.dart | medalExplainer | אֵיךְ יָדַעְתִּי | needs-editor |
| app/lib/strings/he.dart | medalBugFixer | מְתַקְּנֵי בָּאגִים | needs-editor |
| app/lib/strings/he.dart | medalBraveAskerHow | אוֹמְרִים "לֹא בָּטוּחַ" אוֹ "תַּרְאוּ לִי" חָמֵשׁ פְּעָמִים | needs-editor |
| app/lib/strings/he.dart | medalTryAgainHow | מְנַסִּים שׁוּב וּמַצְלִיחִים שָׁלוֹשׁ פְּעָמִים | needs-editor |
| app/lib/strings/he.dart | medalExplainerHow | אֶפְשָׁר יִהְיֶה לְהַרְוִיחַ אוֹתָהּ בְּקָרוֹב | needs-editor |
| app/lib/strings/he.dart | medalBugFixerHow | אֶפְשָׁר יִהְיֶה לְהַרְוִיחַ אוֹתָהּ בְּקָרוֹב | needs-editor |
| app/lib/strings/he.dart | medalLockedSemantics | מדליה שעוד לא הרווחנו | needs-editor |
| app/lib/strings/he.dart | outfitHoney | צָעִיף דְּבַשׁ | needs-editor |
| app/lib/strings/he.dart | outfitSky | צָעִיף שָׁמַיִם | needs-editor |
| app/lib/strings/he.dart | outfitRose | צָעִיף וֶרֶד | needs-editor |
| app/lib/strings/he.dart | outfitNone | בְּלִי צָעִיף | needs-editor |
| app/lib/strings/he.dart | outfitHowBronze | מְגִיעַ עִם גְּבִיעַ בְּרוֹנְזָה | needs-editor |
| app/lib/strings/he.dart | outfitHowSilver | מְגִיעַ עִם גְּבִיעַ כֶּסֶף | needs-editor |
| app/lib/strings/he.dart | outfitHowGold | מְגִיעַ עִם גְּבִיעַ זָהָב | needs-editor |
| app/lib/strings/he.dart | outfitWearSemantics | ללבוש | needs-editor |
| app/lib/strings/he.dart | decorationLantern | פָּנָס | needs-editor |
| app/lib/strings/he.dart | decorationFlag | דֶּגֶל | needs-editor |
| app/lib/strings/he.dart | decorationFountain | מַזְרֵקָה | needs-editor |
| app/lib/strings/he.dart | stickersEmptyChild | אַחֲרֵי הַשִּׁעוּר הָרִאשׁוֹן תִּהְיֶה כָּאן מַדְבֵּקָה. | needs-editor |
| app/lib/strings/he.dart | gateTitle | לפני שנמשיך | needs-editor |
| app/lib/strings/he.dart | gateHint | השאלה הזו מיועדת להורים. ענו עליה כדי להיכנס. | needs-editor |
| app/lib/strings/he.dart | gateQuestion | כמה זה? | needs-editor |
| app/lib/strings/he.dart | gateBack | חזרה | needs-editor |
| app/lib/strings/he.dart | gateWrong | התשובה לא נכונה, נסו שוב. | needs-editor |
| app/lib/strings/he.dart | gateCoolDown | נחכה רגע ואז ננסה שוב, בעוד {s} שניות. | needs-editor |
| app/lib/strings/he.dart | gateLong | יותר מדי נסיונות. אפשר לנסות שוב בעוד {m} דקות. | needs-editor |
| app/lib/strings/he.dart | pinTitle | קוד הורים | needs-editor |
| app/lib/strings/he.dart | pinEnter | הקלידו את קוד ההורים | needs-editor |
| app/lib/strings/he.dart | pinWrong | הקוד לא נכון. | needs-editor |
| app/lib/strings/he.dart | pinLocked | נסו שוב בעוד {t}. | needs-editor |
| app/lib/strings/he.dart | pinSetTitle | בחירת קוד הורים | needs-editor |
| app/lib/strings/he.dart | pinSetHint | 4 עד 6 ספרות. הקוד שומר על אזור ההורים גם כשהילדים משתמשים במכשיר. | needs-editor |
| app/lib/strings/he.dart | pinConfirm | הקלידו את הקוד שוב לאישור | needs-editor |
| app/lib/strings/he.dart | pinMismatch | הקודים לא זהים, נסו שוב. | needs-editor |
| app/lib/strings/he.dart | pinMinutes | {n} דקות | needs-editor |
| app/lib/strings/he.dart | pinSeconds | {n} שניות | needs-editor |
| app/lib/strings/he.dart | pinDelete | מחיקת ספרה | needs-editor |
| app/lib/strings/he.dart | pinOk | אישור | needs-editor |
| app/lib/strings/he.dart | setupWelcomeTitle | ברוכים הבאים | needs-editor |
| app/lib/strings/he.dart | setupWelcomeBody | נכין את המכשיר הזה למשחק של הילדים. זה לוקח כמה דקות: כניסה, רישום המכשיר, קוד הורים ופרופיל ראשון. | needs-editor |
| app/lib/strings/he.dart | setupStart | מתחילים | needs-editor |
| app/lib/strings/he.dart | setupEmail | כתובת דוא"ל | needs-editor |
| app/lib/strings/he.dart | setupSendCode | שליחת קוד | needs-editor |
| app/lib/strings/he.dart | setupCodeSent | שלחנו קוד בן 6 ספרות לדוא"ל. | needs-editor |
| app/lib/strings/he.dart | setupCode | הקוד מהדוא"ל | needs-editor |
| app/lib/strings/he.dart | setupVerify | אימות | needs-editor |
| app/lib/strings/he.dart | setupSignedIn | נכנסתם בהצלחה. | needs-editor |
| app/lib/strings/he.dart | setupEnrolTitle | רישום המכשיר | needs-editor |
| app/lib/strings/he.dart | setupEnrolBody | המכשיר הזה יהיה מכשיר הורים: רק מי שיודע את קוד ההורים יכול לנהל ממנו את המשפחה. | needs-editor |
| app/lib/strings/he.dart | setupEnrolButton | רישום המכשיר | needs-editor |
| app/lib/strings/he.dart | setupEnrolled | המכשיר נרשם. | needs-editor |
| app/lib/strings/he.dart | setupChildTitle | הוספת ילד או ילדה | needs-editor |
| app/lib/strings/he.dart | setupName | שם פרטי | needs-editor |
| app/lib/strings/he.dart | setupAge | גיל | needs-editor |
| app/lib/strings/he.dart | setupAvatar | בחירת דמות | needs-editor |
| app/lib/strings/he.dart | setupAddress | פנייה בלשון | needs-editor |
| app/lib/strings/he.dart | addressFemale | נקבה | needs-editor |
| app/lib/strings/he.dart | addressMale | זכר | needs-editor |
| app/lib/strings/he.dart | addressNeutral | ניטרלי | needs-editor |
| app/lib/strings/he.dart | setupSave | שמירה | needs-editor |
| app/lib/strings/he.dart | setupNext | המשך | needs-editor |
| app/lib/strings/he.dart | setupBack | חזרה | needs-editor |
| app/lib/strings/he.dart | setupFinish | סיום | needs-editor |
| app/lib/strings/he.dart | setupError | משהו השתבש. בדקו את החיבור לאינטרנט ונסו שוב. | needs-editor |
| app/lib/strings/he.dart | setupWrongCode | הקוד לא נכון או שפג תוקפו. | needs-editor |
| app/lib/strings/he.dart | areaTitle | אזור הורים | needs-editor |
| app/lib/strings/he.dart | areaDevices | מכשירים | needs-editor |
| app/lib/strings/he.dart | areaThisDevice | המכשיר הזה | needs-editor |
| app/lib/strings/he.dart | areaRevoke | ניתוק | needs-editor |
| app/lib/strings/he.dart | areaRefresh | רענון | needs-editor |
| app/lib/strings/he.dart | areaProfiles | ילדים | needs-editor |
| app/lib/strings/he.dart | areaAddChild | הוספת ילד | needs-editor |
| app/lib/strings/he.dart | areaRemove | הסרה | needs-editor |
| app/lib/strings/he.dart | areaConfirmRemove | להסיר את הפרופיל של {child}? כל ההתקדמות במכשיר הזה תימחק. | needs-editor |
| app/lib/strings/he.dart | areaChangePin | שינוי קוד הורים | needs-editor |
| app/lib/strings/he.dart | areaLockNow | נעילה וחזרה למשחק | needs-editor |
| app/lib/strings/he.dart | areaTimeOpen | זמן משחק ושעות מנוחה | needs-editor |
| app/lib/strings/he.dart | tutorLogOpen | מה העוזר אמר | needs-editor |
| app/lib/strings/he.dart | tutorLogTitle | מה העוזר אמר ב-30 הימים האחרונים | needs-editor |
| app/lib/strings/he.dart | tutorLogHelp | כל משפט נבדק לפני שהילד שמע אותו. משפט שלא עבר את הבדיקות לא נשמע, ובמקומו נשמעה ההודעה הרגילה. | needs-editor |
| app/lib/strings/he.dart | tutorLogEmpty | עוד לא נשמעו משפטים של העוזר. | needs-editor |
| app/lib/strings/he.dart | tutorLogOffline | אי אפשר להגיע לשרת כרגע. נסו שוב בעוד רגע. | needs-editor |
| app/lib/strings/he.dart | tutorLogSpoken | נשמע | needs-editor |
| app/lib/strings/he.dart | tutorLogRule | נשמעה ההודעה הרגילה | needs-editor |
| app/lib/strings/he.dart | alertsTitle | התראות | needs-editor |
| app/lib/strings/he.dart | alertsOpen | התראות | needs-editor |
| app/lib/strings/he.dart | alertsOpenUnread | התראות ({n} חדשות) | needs-editor |
| app/lib/strings/he.dart | alertsNone | אין התראות. כשיהיה משהו שכדאי לדעת עליו, הוא יופיע כאן. | needs-editor |
| app/lib/strings/he.dart | alertsKeepWords | לשמור בהתראה את המילים שנאמרו | needs-editor |
| app/lib/strings/he.dart | alertsKeepWordsHelp | כשמופעל, המילים שנאמרו נשמרות עם ההתראה עד 30 יום. כשכבוי, נשמרת רק הקטגוריה. | needs-editor |
| app/lib/strings/he.dart | alertsNever | ההתראות לא מוצגות בצד של הילדים, והאפליקציה אף פעם לא מוכיחה אותם. | needs-editor |
| app/lib/strings/he.dart | severityInfo | לידיעה | needs-editor |
| app/lib/strings/he.dart | severityAttention | לתשומת לב | needs-editor |
| app/lib/strings/he.dart | severityImportant | חשוב | needs-editor |
| app/lib/strings/he.dart | alertAbout | {child}: {title} | needs-editor |
| app/lib/strings/he.dart | alertWords | נאמר: {w} | needs-editor |
| app/lib/strings/he.dart | alertPastLimitTitle | שיחקו מעבר לזמן שנקבע | needs-editor |
| app/lib/strings/he.dart | alertPastLimitDetail | ב-{n} דקות יותר מהמותר. | needs-editor |
| app/lib/strings/he.dart | alertPastLimitDo | אפשר לשנות את הגבלת הזמן, או לדבר על סיום משחק. | needs-editor |
| app/lib/strings/he.dart | alertRestTitle | שיחקו בשעות המנוחה | needs-editor |
| app/lib/strings/he.dart | alertRestDetail | כ-{n} דקות. | needs-editor |
| app/lib/strings/he.dart | alertRestDo | אפשר להפעיל נעילה בשעות המנוחה או לשנות את השעות. | needs-editor |
| app/lib/strings/he.dart | alertGateTitle | ניסיון להיכנס לאזור ההורים | needs-editor |
| app/lib/strings/he.dart | alertGateDetail | נכשלו {n} ניסיונות ברצף. | needs-editor |
| app/lib/strings/he.dart | alertGateDo | אם עוד אין קוד הורים, כדאי לקבוע אחד. | needs-editor |
| app/lib/strings/he.dart | alertGuessTitle | נראה שיש ניחושים מהירים | needs-editor |
| app/lib/strings/he.dart | alertGuessDo | כדאי לשחק יחד כמה דקות ולעבור לפעילות רגועה. | needs-editor |
| app/lib/strings/he.dart | alertUpsetTitle | נראה שיש תסכול במשחק | needs-editor |
| app/lib/strings/he.dart | alertUpsetDo | אפשר לנסות פעילות רגועה בבית, או לשחק יחד. | needs-editor |
| app/lib/strings/he.dart | alertSwearTitle | נאמרו מילים לא הולמות | needs-editor |
| app/lib/strings/he.dart | alertSwearDo | אפשר לשוחח על כך בנחת. ההתראה לא מוצגת בצד של הילדים. | needs-editor |
| app/lib/strings/he.dart | alertDisclosureTitle | נאמר משהו שעשוי להדאיג | needs-editor |
| app/lib/strings/he.dart | alertDisclosureDo | כדאי לשוחח בנחת ובפרטיות, בלי ללחוץ. | needs-editor |
| app/lib/strings/he.dart | alertAbsenceTitle | לא שיחקו זמן מה | needs-editor |
| app/lib/strings/he.dart | alertAbsenceDetail | לפני {n} ימים. | needs-editor |
| app/lib/strings/he.dart | alertAbsenceDo | אפשר להזמין להרפתקה קצרה. | needs-editor |
| app/lib/strings/he.dart | alertRibbonTitle | זכו בגביע שהובטחה עליו הבטחה | needs-editor |
| app/lib/strings/he.dart | alertRibbonDetail | {t}: {w} | needs-editor |
| app/lib/strings/he.dart | alertRibbonNoWords | {t} | needs-editor |
| app/lib/strings/he.dart | alertRibbonDo | זה הזמן לקיים את ההבטחה. | needs-editor |
| app/lib/strings/he.dart | areaPrizes | גביעים והבטחות | needs-editor |
| app/lib/strings/he.dart | areaCeremonies | טקס כשמקבלים גביע | needs-editor |
| app/lib/strings/he.dart | areaCeremoniesHelp | כשהילד מקבל גביע או מדליה, החבר מציג אותם בטקס קצר. כשהטקס כבוי, הם מחכים בהיכל הגביעים. | needs-editor |
| app/lib/strings/he.dart | areaPromisesOpen | הבטחות לגביעים | needs-editor |
| app/lib/strings/he.dart | prizesTitle | הבטחות לגביעים | needs-editor |
| app/lib/strings/he.dart | prizesHelp | אפשר לצרף הבטחה לגביע, למשל "בגביע הזהב הולכים לגלידה". כשהילד יזכה בו תקבלו התראה, וההבטחה תופיע ליד הגביע שלו בהיכל. עד 60 תווים, בלי קישורים. | needs-editor |
| app/lib/strings/he.dart | prizesBronze | גביע ברונזה | needs-editor |
| app/lib/strings/he.dart | prizesSilver | גביע כסף | needs-editor |
| app/lib/strings/he.dart | prizesGold | גביע זהב | needs-editor |
| app/lib/strings/he.dart | prizesEarned | הושג | needs-editor |
| app/lib/strings/he.dart | prizesNotYet | בקרוב, כשיהיו באי מספיק מיומנויות | needs-editor |
| app/lib/strings/he.dart | prizesHint | ההבטחה | needs-editor |
| app/lib/strings/he.dart | prizesBad | עד 60 תווים, בלי קישורים ובלי תווים מיוחדים. | needs-editor |
| app/lib/strings/he.dart | prizesTooMany | אי אפשר להוסיף עוד הבטחות (עד 30). | needs-editor |
| app/lib/strings/he.dart | prizesNoChildren | עוד אין ילדים. אפשר להוסיף ילד באזור ההורים. | needs-editor |
| app/lib/strings/he.dart | alertDropTitle | המשחק השבוע ירד בהרבה | needs-editor |
| app/lib/strings/he.dart | alertDropDo | אפשר לשאול מה קרה, ולהציע הרפתקה אהובה. | needs-editor |
| app/lib/strings/he.dart | areaProgress | התקדמות | needs-editor |
| app/lib/strings/he.dart | progressTitle | התקדמות של {child} | needs-editor |
| app/lib/strings/he.dart | progressEmpty | עוד לא שיחקו. כשיתחילו, כאן יופיע איך הלמידה מתקדמת. | needs-editor |
| app/lib/strings/he.dart | progressTileMinutes | דקות משחק השבוע | needs-editor |
| app/lib/strings/he.dart | progressTileAdventures | הרפתקאות הושלמו | needs-editor |
| app/lib/strings/he.dart | progressTileUnderstood | מיומנויות מובנות | needs-editor |
| app/lib/strings/he.dart | progressDomainCount | {a} מתוך {b} מובנות | needs-editor |
| app/lib/strings/he.dart | progressCurveSoon | הקו יתמלא ככל שיצטברו שבועות של משחק. כך נראה המצב עכשיו: | needs-editor |
| app/lib/strings/he.dart | progressNotYetPlayed | עוד לא התחילו | needs-editor |
| app/lib/strings/he.dart | progressWeek | השבוע | needs-editor |
| app/lib/strings/he.dart | progressMinutesChart | דקות משחק לפי יום | needs-editor |
| app/lib/strings/he.dart | progressSessions | {n} מפגשי משחק | needs-editor |
| app/lib/strings/he.dart | progressAdventures | {n} הרפתקאות הושלמו | needs-editor |
| app/lib/strings/he.dart | progressUnderstanding | הבנה לפי תחום | needs-editor |
| app/lib/strings/he.dart | progressGrowth | הבנה לאורך זמן | needs-editor |
| app/lib/strings/he.dart | progressGrowthHelp | כל קו מראה תחום אחד, בסוף כל שבוע בשמונה השבועות האחרונים. תחום שעוד לא התחילו בו לא מופיע. | needs-editor |
| app/lib/strings/he.dart | progressNoPoints | עוד אין מספיק נתונים לקו. | needs-editor |
| app/lib/strings/he.dart | progressHelped | מה עוזר לילד | needs-editor |
| app/lib/strings/he.dart | progressHelpedLine | {how}: הצליחו {a} מתוך {b} | needs-editor |
| app/lib/strings/he.dart | progressMisconceptions | מה כדאי לשים לב אליו | needs-editor |
| app/lib/strings/he.dart | progressResolved | נפתר | needs-editor |
| app/lib/strings/he.dart | progressHomeActivity | פעילות לבית: {w} | needs-editor |
| app/lib/strings/he.dart | progressNothingToWatch | לא נמצאו אי-הבנות. | needs-editor |
| app/lib/strings/he.dart | progressHabits | חוזקות בלמידה | needs-editor |
| app/lib/strings/he.dart | habitAsked | ביקשו עזרה כשלא היו בטוחים: {n} פעמים | needs-editor |
| app/lib/strings/he.dart | habitHints | השתמשו ברמזים: {n} פעמים | needs-editor |
| app/lib/strings/he.dart | habitKept | ניסו שוב והצליחו: {n} פעמים | needs-editor |
| app/lib/strings/he.dart | statusUnderstood | מובן | needs-editor |
| app/lib/strings/he.dart | statusPractising | בתרגול | needs-editor |
| app/lib/strings/he.dart | statusRevisit | כדאי לחזור | needs-editor |
| app/lib/strings/he.dart | statusGap | נמצא פער | needs-editor |
| app/lib/strings/he.dart | statusNotStarted | עוד לא התחילו | needs-editor |
| app/lib/strings/he.dart | domainNumbers | מספרים | needs-editor |
| app/lib/strings/he.dart | domainColors | צבעים | needs-editor |
| app/lib/strings/he.dart | domainShapes | צורות | needs-editor |
| app/lib/strings/he.dart | domainLogic | היגיון | needs-editor |
| app/lib/strings/he.dart | domainCs | חשיבה חישובית | needs-editor |
| app/lib/strings/he.dart | domainMath | חשבון | needs-editor |
| app/lib/strings/he.dart | repConcrete | לימוד עם עצמים להזיז | needs-editor |
| app/lib/strings/he.dart | repPictorial | לימוד עם ציורים | needs-editor |
| app/lib/strings/he.dart | repStory | לימוד דרך סיפור | needs-editor |
| app/lib/strings/he.dart | repEmbodied | לימוד בתנועה | needs-editor |
| app/lib/strings/he.dart | repSymbolic | לימוד עם סימנים | needs-editor |
| app/lib/strings/he.dart | dayLetters | א ב ג ד ה ו ש | needs-editor |
| app/lib/strings/he.dart | timeTitle | זמן משחק | needs-editor |
| app/lib/strings/he.dart | timeLimitHeading | דקות משחק ביום | needs-editor |
| app/lib/strings/he.dart | timeBand0 | גיל 3 עד 4 | needs-editor |
| app/lib/strings/he.dart | timeBand1 | גיל 5 עד 6 | needs-editor |
| app/lib/strings/he.dart | timeBand2 | גיל 7 עד 8 | needs-editor |
| app/lib/strings/he.dart | timeMinutes | {n} דקות | needs-editor |
| app/lib/strings/he.dart | timeLess | פחות | needs-editor |
| app/lib/strings/he.dart | timeMore | יותר | needs-editor |
| app/lib/strings/he.dart | timeRestHeading | שעות מנוחה | needs-editor |
| app/lib/strings/he.dart | timeRestOn | שעות מנוחה פעילות | needs-editor |
| app/lib/strings/he.dart | timeRestFrom | מתחילות ב-{t} | needs-editor |
| app/lib/strings/he.dart | timeRestTo | נגמרות ב-{t} | needs-editor |
| app/lib/strings/he.dart | timeEarlier | חצי שעה קודם | needs-editor |
| app/lib/strings/he.dart | timeLater | חצי שעה אחר כך | needs-editor |
| app/lib/strings/he.dart | timeLock | לנעול כשהזמן נגמר | needs-editor |
| app/lib/strings/he.dart | timeLockHelp | כשהזמן נגמר או בשעות מנוחה לא מוצעת פעילות חדשה, והפעילות הנוכחית מסתיימת בעדינות. כשכבוי הילד ממשיך לשחק. | needs-editor |
| app/lib/strings/he.dart | timeScheduleHeading | שעות מותרות בשבוע | needs-editor |
| app/lib/strings/he.dart | timeScheduleHelp | ביום שמוגדרות בו שעות משחקים רק בהן. ביום בלי שעות משחקים בכל שעה. | needs-editor |
| app/lib/strings/he.dart | timeDayAny | בכל שעה | needs-editor |
| app/lib/strings/he.dart | timeDayWindow | {a} עד {b} | needs-editor |
| app/lib/strings/he.dart | timeDay1 | יום שני | needs-editor |
| app/lib/strings/he.dart | timeDay2 | יום שלישי | needs-editor |
| app/lib/strings/he.dart | timeDay3 | יום רביעי | needs-editor |
| app/lib/strings/he.dart | timeDay4 | יום חמישי | needs-editor |
| app/lib/strings/he.dart | timeDay5 | יום שישי | needs-editor |
| app/lib/strings/he.dart | timeDay6 | שבת | needs-editor |
| app/lib/strings/he.dart | timeDay7 | יום ראשון | needs-editor |
| app/lib/strings/he.dart | aiHeading | עוזר מילולי | needs-editor |
| app/lib/strings/he.dart | aiHelp | אחרי טעות שנייה הדמות יכולה להגיד משפט עזרה בקולה. המשפטים נבדקים לפני שהילד שומע אותם, ואם משהו לא עובד נשמעת ההודעה הרגילה. כבוי כברירת מחדל. | needs-editor |
| app/lib/strings/he.dart | areaVoice | תשובות בקול | needs-editor |
| app/lib/strings/he.dart | areaVoiceHelp | ילדים יוכלו לענות בדיבור. הזיהוי נעשה במכשיר, ההקלטה נמחקת מיד ולא נשמרת ולא נשלחת לשום מקום. המיקרופון נפתח רק כשהילד לוחץ עליו. | needs-editor |
| app/lib/strings/he.dart | areaVoiceNoModel | מודל הזיהוי עוד לא הותקן במכשיר הזה. | needs-editor |
| app/lib/strings/he.dart | areaVoiceNoPermission | לא ניתנה הרשאת מיקרופון. אפשר לתת אותה בהגדרות המכשיר. | needs-editor |
| app/lib/strings/he.dart | areaVoiceCredit | זיהוי דיבור: ivrit.ai Zipformer מאת יעקב קולני, רישיון CC-BY-4.0. | needs-editor |
| app/lib/strings/he.dart | areaPush | התראות בטלפון הזה | needs-editor |
| app/lib/strings/he.dart | areaPushHelp | כשנוצרת התראה חדשה, הטלפון הזה מקבל הודעה קצרה שאומרת רק "יש התראה חדשה". שמות, מילים ופרטים על הילדים לא נשלחים בהודעה, והם נפתחים רק באפליקציה, מאחורי הקוד שלכם. | needs-editor |
| app/lib/strings/he.dart | areaPushDenied | לא ניתנה הרשאה להצגת הודעות. אפשר לתת אותה בהגדרות המכשיר. | needs-editor |
| app/lib/strings/he.dart | areaPushUnavailable | ההתראות בטלפון לא זמינות בגרסה הזו של האפליקציה. | needs-editor |
| app/lib/strings/he.dart | areaPushFailed | אי אפשר להגיע לשרת כרגע. נסו שוב בעוד רגע. | needs-editor |
| app/lib/strings/he.dart | celebrateWell | כׇּל הַכָּבוֹד! | needs-editor |
| app/lib/strings/he.dart | stickersSemantics | המדבקות שלי | needs-editor |
| app/lib/strings/he.dart | stickerNewSemantics | מדבקה חדשה | needs-editor |
| app/lib/strings/he.dart | starsSemantics | כוכבי זהב | needs-editor |
| app/lib/strings/he.dart | landPlaySemantics | לשחק | needs-editor |
| app/lib/strings/he.dart | landBackSemantics | חזרה למפה | needs-editor |
| app/lib/strings/he.dart | bellSemantics | מישהו קורא לעזרה, אפשר לבדוק שוב | needs-editor |
| app/lib/strings/he.dart | areaVersion | גרסה | needs-editor |
| app/lib/strings/he.dart | areaOffline | אין חיבור לאינטרנט, אי אפשר לטעון את רשימת המכשירים. | needs-editor |
| app/lib/strings/he.dart | confirmYes | כן | needs-editor |
| app/lib/strings/he.dart | confirmNo | ביטול | needs-editor |
| app/lib/strings/he.dart | roleParent | הורה | needs-editor |
| app/lib/strings/he.dart | roleChild | ילד | needs-editor |

## 2. Core voice lines (spoken by every friend)

| Source | Id | Text | Status |
|---|---|---|---|
| content/lines/core.he.json | core.greeting.hello | שָׁלוֹם! בּוֹאוּ נְשַׂחֵק. | needs-editor |
| content/lines/core.he.json | core.greeting.start | בּוֹאוּ נַתְחִיל! | needs-editor |
| content/lines/core.he.json | core.encourage.check | הַמְּמ… בּוֹאוּ נִבְדֹּק. | needs-editor |
| content/lines/core.he.json | core.encourage.almost | עוֹד לֹא — אֲבָל כִּמְעַט. | needs-editor |
| content/lines/core.he.json | core.encourage.ways | נִסִּיתֶם כַּמָּה דְּרָכִים — וְזֶה עָזַר! | needs-editor |
| content/lines/core.he.json | core.encourage.help | בִּקַּשְׁתֶּם עֶזְרָה — זֶה חָכָם לְבַקֵּשׁ עֶזְרָה. | needs-editor |
| content/lines/core.he.json | core.encourage.mistake | טָעִינוּ? מְעֻלֶּה — עַכְשָׁו אֲנַחְנוּ יוֹדְעִים מָה לִבְדֹּק. | needs-editor |
| content/lines/core.he.json | core.encourage.fixed | מְצָאתֶם אֶת הַטָּעוּת וְתִקַּנְתֶּם. כׇּל הַכָּבוֹד! | needs-editor |
| content/lines/core.he.json | core.encourage.persist | לֹא וִתַּרְתֶּם — וּמְצָאתֶם! | needs-editor |
| content/lines/core.he.json | core.encourage.checked | בְּדַקְתֶּם שׁוּב לִפְנֵי שֶׁעֲנִיתֶם. זֶה מַה שֶּׁמָּתֵמָטִיקָאִים עוֹשִׂים. | needs-editor |
| content/lines/core.he.json | core.encourage.effort | זֶה הָיָה קָשֶׁה, וְהַמֹּחַ שֶׁלָּכֶם הִתְאַמֵּץ וְגָדַל. | needs-editor |
| content/lines/core.he.json | core.celebrate.well | כׇּל הַכָּבוֹד! | needs-editor |
| content/lines/core.he.json | core.thinking.think | הַמְּמ… בּוֹאוּ נַחְשֹׁב. | needs-editor |
| content/lines/core.he.json | core.thinking.together | בּוֹאוּ נְגַלֶּה יַחַד! | needs-editor |
| content/lines/core.he.json | core.listen.again | לֹא שָׁמַעְתִּי טוֹב — אֶפְשָׁר שׁוּב? אוֹ לִלְחֹץ. | needs-editor |
| content/lines/core.he.json | core.listen.say | בְּבַקָּשָׁה, אִמְרוּ לִי. | needs-editor |
| content/lines/core.he.json | core.listen.mixed | אוֹפְּס, הָאָזְנַיִם שֶׁלִּי הִתְבַּלְבְּלוּ! אֶפְשָׁר לְהַגִּיד שׁוּב? | needs-editor |
| content/lines/core.he.json | core.listen.confirm | שָׁמַעְתִּי… נָכוֹן? | needs-editor |
| content/lines/core.he.json | core.listen.tap | אֶפְשָׁר גַּם לִלְחֹץ עַל הַתְּשׁוּבָה. | needs-editor |
| content/lines/core.he.json | core.stuck.later | נַחֲזֹר לָזֶה בְּפַעַם אַחֶרֶת. בּוֹאוּ נְשַׂחֵק בְּמַשֶּׁהוּ אַחֵר. | needs-editor |
| content/lines/core.he.json | core.breathe.now | בּוֹאוּ נִנְשֹׁם רֶגַע. | needs-editor |
| content/lines/core.he.json | core.goodbye.next | לָמַדְנוּ הַיּוֹם הַרְבֵּה. נִתְרָאֶה בַּפַּעַם הַבָּאָה! | needs-editor |
| content/lines/core.he.json | core.ceremony.bronze | הִנֵּה גְּבִיעַ בְּרוֹנְזָה בִּשְׁבִילְכֶם! | needs-editor |
| content/lines/core.he.json | core.ceremony.silver | הִנֵּה גְּבִיעַ כֶּסֶף בִּשְׁבִילְכֶם! | needs-editor |
| content/lines/core.he.json | core.ceremony.gold | הִנֵּה גְּבִיעַ זָהָב בִּשְׁבִילְכֶם! | needs-editor |
| content/lines/core.he.json | core.ceremony.medal | הִנֵּה מֵדַלְיָה בִּשְׁבִילְכֶם! | needs-editor |

## 3. Lesson content (skills, activities, misconceptions)

| Source | Id | Text | Status |
|---|---|---|---|
| activity.count.apples.7.json | prompt.caption.0.v | נוֹגְעִים בְּכׇל אֶחָד פַּעַם אַחַת, וְסוֹפְרִים. | needs-editor |
| activity.count.apples.7.json | answerPrompt.caption.0.v | כַּמָּה תַּפּוּחִים? | needs-editor |
| activity.count.apples.7.json | feedback.correct.caption.0.v | שֶׁבַע! סְפַרְתֶּם כׇּל אֶחָד פַּעַם אַחַת. | needs-editor |
| activity.count.apples.7.json | feedback.incorrect.0.caption.0.v | אוּלַי סָפַרְנוּ אֶחָד פַּעֲמַיִם? בּוֹאוּ נִבְדֹּק. | needs-editor |
| activity.count.apples.7.json | feedback.incorrect.1.caption.0.v | אוּלַי פִּסְפַּסְנוּ אֶחָד? בּוֹאוּ נִבְדֹּק. | needs-editor |
| activity.count.apples.7.json | feedback.incorrect.2.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.count.apples.7.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.count.apples.7.json | hints.0.caption.0.v | נוֹגְעִים בְּתַּפּוּחַ אֶחָד, וְאוֹמְרִים מִסְפָּר אֶחָד. | needs-editor |
| activity.count.apples.7.json | hints.1.caption.0.v | בּוֹאוּ נִסְפֹּר גַּם עִם הָאֶצְבָּעוֹת: אַחַת, שְׁתַּיִם, שָׁלוֹשׁ… | needs-editor |
| activity.count.apples.7.json | hints.2.caption.0.v | אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע, חָמֵשׁ, שֵׁשׁ, שֶׁבַע. הַמִּסְפָּר הָאַחֲרוֹן אוֹמֵר כַּמָּה: שֶׁבַע! עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל שֶׁבַע. | needs-editor |
| activity.count.apples.7.json | a11y.altText | נוֹגְעִים בְּכׇל אֶחָד פַּעַם אַחַת, וְסוֹפְרִים. | needs-editor |
| activity.count.birds.10.json | prompt.caption.0.v | נוֹגְעִים בְּכׇל אֶחָד פַּעַם אַחַת, וְסוֹפְרִים. | needs-editor |
| activity.count.birds.10.json | answerPrompt.caption.0.v | כַּמָּה צִפֳּרִים? | needs-editor |
| activity.count.birds.10.json | feedback.correct.caption.0.v | עֶשֶׂר! סְפַרְתֶּם כׇּל אֶחָד פַּעַם אַחַת. | needs-editor |
| activity.count.birds.10.json | feedback.incorrect.0.caption.0.v | אוּלַי פִּסְפַּסְנוּ אֶחָד? בּוֹאוּ נִבְדֹּק. | needs-editor |
| activity.count.birds.10.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.count.birds.10.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.count.birds.10.json | hints.0.caption.0.v | נוֹגְעִים בְּצִפּוֹר אֶחָד, וְאוֹמְרִים מִסְפָּר אֶחָד. | needs-editor |
| activity.count.birds.10.json | hints.1.caption.0.v | בּוֹאוּ נִסְפֹּר גַּם עִם הָאֶצְבָּעוֹת: אַחַת, שְׁתַּיִם, שָׁלוֹשׁ… | needs-editor |
| activity.count.birds.10.json | hints.2.caption.0.v | אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע, חָמֵשׁ, שֵׁשׁ, שֶׁבַע, שְׁמוֹנֶה, תֵּשַׁע, עֶשֶׂר. הַמִּסְפָּר הָאַחֲרוֹן אוֹמֵר כַּמָּה: עֶשֶׂר! עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל עֶשֶׂר. | needs-editor |
| activity.count.birds.10.json | a11y.altText | נוֹגְעִים בְּכׇל אֶחָד פַּעַם אַחַת, וְסוֹפְרִים. | needs-editor |
| activity.count.butterflies.3.json | prompt.caption.0.v | פַּרְפָּרִים בָּאוּ לַגִּנָּה! בּוֹאוּ נִסְפֹּר אוֹתָם. נוֹגְעִים בְּכׇל פַּרְפָּר פַּעַם אַחַת. | needs-editor |
| activity.count.butterflies.3.json | answerPrompt.caption.0.v | כַּמָּה פַּרְפָּרִים יֵשׁ עַל הַפֶּרַח? | needs-editor |
| activity.count.butterflies.3.json | feedback.correct.caption.0.v | שְׁלוֹשָׁה! סְפַרְתֶּם כׇּל אֶחָד פַּעַם אַחַת. | needs-editor |
| activity.count.butterflies.3.json | feedback.incorrect.0.caption.0.v | הַמְּמ… נִרְאֶה שֶׁפַּרְפָּר אֶחָד נִסְפַּר פַּעֲמַיִם. בּוֹאוּ נִסְפֹּר לְאַט. | needs-editor |
| activity.count.butterflies.3.json | feedback.incorrect.1.caption.0.v | אוּלַי פִּסְפַּסְנוּ פַּרְפָּר? בּוֹאוּ נִבְדֹּק. | needs-editor |
| activity.count.butterflies.3.json | feedback.incorrect.2.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.count.butterflies.3.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.count.butterflies.3.json | hints.0.caption.0.v | נוֹגְעִים בְּפַרְפָּר אֶחָד, וְאוֹמְרִים מִסְפָּר אֶחָד. | needs-editor |
| activity.count.butterflies.3.json | hints.1.caption.0.v | בּוֹאוּ נִסְפֹּר גַּם עִם הָאֶצְבָּעוֹת: אַחַת… שְׁתַּיִם… | needs-editor |
| activity.count.butterflies.3.json | hints.2.caption.0.v | אַחַת, שְׁתַּיִם, שָׁלוֹשׁ. הַמִּסְפָּר הָאַחֲרוֹן אוֹמֵר כַּמָּה: שָׁלוֹשׁ! עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל שָׁלוֹשׁ. | needs-editor |
| activity.count.butterflies.3.json | a11y.altText | שְׁלוֹשָׁה פַּרְפָּרִים בַּגִּנָּה | needs-editor |
| activity.count.butterflies.4.json | prompt.caption.0.v | עַכְשָׁו הֵם מְפֻזָּרִים. נִסְפֹּר שׁוּב — כׇּל פַּרְפָּר עָף לַפֶּרַח. | needs-editor |
| activity.count.butterflies.4.json | answerPrompt.caption.0.v | כַּמָּה פַּרְפָּרִים יֵשׁ עַל הַפֶּרַח? | needs-editor |
| activity.count.butterflies.4.json | feedback.correct.caption.0.v | אַרְבָּעָה! סְפַרְתֶּם כׇּל אֶחָד פַּעַם אַחַת. | needs-editor |
| activity.count.butterflies.4.json | feedback.incorrect.0.caption.0.v | הַמְּמ… נִרְאֶה שֶׁפַּרְפָּר אֶחָד נִסְפַּר פַּעֲמַיִם. בּוֹאוּ נִסְפֹּר לְאַט. | needs-editor |
| activity.count.butterflies.4.json | feedback.incorrect.1.caption.0.v | אוּלַי פִּסְפַּסְנוּ פַּרְפָּר? בּוֹאוּ נִבְדֹּק. | needs-editor |
| activity.count.butterflies.4.json | feedback.incorrect.2.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.count.butterflies.4.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.count.butterflies.4.json | hints.0.caption.0.v | נוֹגְעִים בְּפַרְפָּר אֶחָד, וְאוֹמְרִים מִסְפָּר אֶחָד. | needs-editor |
| activity.count.butterflies.4.json | hints.1.caption.0.v | בּוֹאוּ נִסְפֹּר גַּם עִם הָאֶצְבָּעוֹת: אַחַת… שְׁתַּיִם… | needs-editor |
| activity.count.butterflies.4.json | hints.2.caption.0.v | אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע. הַמִּסְפָּר הָאַחֲרוֹן אוֹמֵר כַּמָּה: אַרְבַּע! עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל אַרְבַּע. | needs-editor |
| activity.count.butterflies.4.json | a11y.altText | אַרְבָּעָה פַּרְפָּרִים בַּגִּנָּה | needs-editor |
| activity.count.butterflies.5.json | prompt.caption.0.v | הַפַּעַם הֵם נִשְׁאָרִים בַּמָּקוֹם. כַּמָּה פַּרְפָּרִים? | needs-editor |
| activity.count.butterflies.5.json | answerPrompt.caption.0.v | כַּמָּה פַּרְפָּרִים? | needs-editor |
| activity.count.butterflies.5.json | feedback.correct.caption.0.v | חֲמִשָּׁה! סְפַרְתֶּם כׇּל אֶחָד פַּעַם אַחַת. | needs-editor |
| activity.count.butterflies.5.json | feedback.incorrect.0.caption.0.v | הַמְּמ… נִרְאֶה שֶׁפַּרְפָּר אֶחָד נִסְפַּר פַּעֲמַיִם. בּוֹאוּ נִסְפֹּר לְאַט. | needs-editor |
| activity.count.butterflies.5.json | feedback.incorrect.1.caption.0.v | אוּלַי פִּסְפַּסְנוּ פַּרְפָּר? בּוֹאוּ נִבְדֹּק. | needs-editor |
| activity.count.butterflies.5.json | feedback.incorrect.2.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.count.butterflies.5.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.count.butterflies.5.json | hints.0.caption.0.v | נוֹגְעִים בְּפַרְפָּר אֶחָד, וְאוֹמְרִים מִסְפָּר אֶחָד. | needs-editor |
| activity.count.butterflies.5.json | hints.1.caption.0.v | בּוֹאוּ נִסְפֹּר גַּם עִם הָאֶצְבָּעוֹת: אַחַת… שְׁתַּיִם… | needs-editor |
| activity.count.butterflies.5.json | hints.2.caption.0.v | אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע, חָמֵשׁ. הַמִּסְפָּר הָאַחֲרוֹן אוֹמֵר כַּמָּה: חָמֵשׁ! עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל חָמֵשׁ. | needs-editor |
| activity.count.butterflies.5.json | a11y.altText | חֲמִשָּׁה פַּרְפָּרִים בַּגִּנָּה | needs-editor |
| activity.count.fish.9.json | prompt.caption.0.v | נוֹגְעִים בְּכׇל אֶחָד פַּעַם אַחַת, וְסוֹפְרִים. | needs-editor |
| activity.count.fish.9.json | answerPrompt.caption.0.v | כַּמָּה דָּגִים? | needs-editor |
| activity.count.fish.9.json | feedback.correct.caption.0.v | תֵּשַׁע! סְפַרְתֶּם כׇּל אֶחָד פַּעַם אַחַת. | needs-editor |
| activity.count.fish.9.json | feedback.incorrect.0.caption.0.v | אוּלַי סָפַרְנוּ אֶחָד פַּעֲמַיִם? בּוֹאוּ נִבְדֹּק. | needs-editor |
| activity.count.fish.9.json | feedback.incorrect.1.caption.0.v | אוּלַי פִּסְפַּסְנוּ אֶחָד? בּוֹאוּ נִבְדֹּק. | needs-editor |
| activity.count.fish.9.json | feedback.incorrect.2.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.count.fish.9.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.count.fish.9.json | hints.0.caption.0.v | נוֹגְעִים בְּדָּג אֶחָד, וְאוֹמְרִים מִסְפָּר אֶחָד. | needs-editor |
| activity.count.fish.9.json | hints.1.caption.0.v | בּוֹאוּ נִסְפֹּר גַּם עִם הָאֶצְבָּעוֹת: אַחַת, שְׁתַּיִם, שָׁלוֹשׁ… | needs-editor |
| activity.count.fish.9.json | hints.2.caption.0.v | אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע, חָמֵשׁ, שֵׁשׁ, שֶׁבַע, שְׁמוֹנֶה, תֵּשַׁע. הַמִּסְפָּר הָאַחֲרוֹן אוֹמֵר כַּמָּה: תֵּשַׁע! עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל תֵּשַׁע. | needs-editor |
| activity.count.fish.9.json | a11y.altText | נוֹגְעִים בְּכׇל אֶחָד פַּעַם אַחַת, וְסוֹפְרִים. | needs-editor |
| activity.count.ladybugs.6.json | prompt.caption.0.v | נוֹגְעִים בְּכׇל אֶחָד פַּעַם אַחַת, וְסוֹפְרִים. | needs-editor |
| activity.count.ladybugs.6.json | answerPrompt.caption.0.v | כַּמָּה חִפּוּשִׁיּוֹת? | needs-editor |
| activity.count.ladybugs.6.json | feedback.correct.caption.0.v | שֵׁשׁ! סְפַרְתֶּם כׇּל אֶחָד פַּעַם אַחַת. | needs-editor |
| activity.count.ladybugs.6.json | feedback.incorrect.0.caption.0.v | אוּלַי סָפַרְנוּ אֶחָד פַּעֲמַיִם? בּוֹאוּ נִבְדֹּק. | needs-editor |
| activity.count.ladybugs.6.json | feedback.incorrect.1.caption.0.v | אוּלַי פִּסְפַּסְנוּ אֶחָד? בּוֹאוּ נִבְדֹּק. | needs-editor |
| activity.count.ladybugs.6.json | feedback.incorrect.2.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.count.ladybugs.6.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.count.ladybugs.6.json | hints.0.caption.0.v | נוֹגְעִים בְּחִפּוּשִׁית אֶחָד, וְאוֹמְרִים מִסְפָּר אֶחָד. | needs-editor |
| activity.count.ladybugs.6.json | hints.1.caption.0.v | בּוֹאוּ נִסְפֹּר גַּם עִם הָאֶצְבָּעוֹת: אַחַת, שְׁתַּיִם, שָׁלוֹשׁ… | needs-editor |
| activity.count.ladybugs.6.json | hints.2.caption.0.v | אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע, חָמֵשׁ, שֵׁשׁ. הַמִּסְפָּר הָאַחֲרוֹן אוֹמֵר כַּמָּה: שֵׁשׁ! עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל שֵׁשׁ. | needs-editor |
| activity.count.ladybugs.6.json | a11y.altText | נוֹגְעִים בְּכׇל אֶחָד פַּעַם אַחַת, וְסוֹפְרִים. | needs-editor |
| activity.count.stars.8.json | prompt.caption.0.v | נוֹגְעִים בְּכׇל אֶחָד פַּעַם אַחַת, וְסוֹפְרִים. | needs-editor |
| activity.count.stars.8.json | answerPrompt.caption.0.v | כַּמָּה כּוֹכָבִים? | needs-editor |
| activity.count.stars.8.json | feedback.correct.caption.0.v | שְׁמוֹנֶה! סְפַרְתֶּם כׇּל אֶחָד פַּעַם אַחַת. | needs-editor |
| activity.count.stars.8.json | feedback.incorrect.0.caption.0.v | אוּלַי סָפַרְנוּ אֶחָד פַּעֲמַיִם? בּוֹאוּ נִבְדֹּק. | needs-editor |
| activity.count.stars.8.json | feedback.incorrect.1.caption.0.v | אוּלַי פִּסְפַּסְנוּ אֶחָד? בּוֹאוּ נִבְדֹּק. | needs-editor |
| activity.count.stars.8.json | feedback.incorrect.2.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.count.stars.8.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.count.stars.8.json | hints.0.caption.0.v | נוֹגְעִים בְּכּוֹכָב אֶחָד, וְאוֹמְרִים מִסְפָּר אֶחָד. | needs-editor |
| activity.count.stars.8.json | hints.1.caption.0.v | בּוֹאוּ נִסְפֹּר גַּם עִם הָאֶצְבָּעוֹת: אַחַת, שְׁתַּיִם, שָׁלוֹשׁ… | needs-editor |
| activity.count.stars.8.json | hints.2.caption.0.v | אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע, חָמֵשׁ, שֵׁשׁ, שֶׁבַע, שְׁמוֹנֶה. הַמִּסְפָּר הָאַחֲרוֹן אוֹמֵר כַּמָּה: שְׁמוֹנֶה! עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל שְׁמוֹנֶה. | needs-editor |
| activity.count.stars.8.json | a11y.altText | נוֹגְעִים בְּכׇל אֶחָד פַּעַם אַחַת, וְסוֹפְרִים. | needs-editor |
| activity.fewer.big.fish.json | prompt.caption.0.v | אֵיפֹה יֵשׁ פָּחוֹת דָּגִים? | needs-editor |
| activity.fewer.big.fish.json | answer.options.0.label | אַרְבָּעָה דָּגִים | needs-editor |
| activity.fewer.big.fish.json | answer.options.1.label | שְׁנֵי דָּגִים | needs-editor |
| activity.fewer.big.fish.json | feedback.correct.caption.0.v | כֵּן! כָּאן יֵשׁ פָּחוֹת דָּגִים. | needs-editor |
| activity.fewer.big.fish.json | feedback.incorrect.0.caption.0.v | יוֹתֵר לֹא תָּמִיד אוֹמֵר גָּדוֹל יוֹתֵר. בּוֹאוּ נַשְׁוֶה אֶחָד אֶחָד. | needs-editor |
| activity.fewer.big.fish.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.fewer.big.fish.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.fewer.big.fish.json | hints.0.caption.0.v | בּוֹאוּ נִסְתַּכֵּל שׁוּב עַל שְׁנֵי הַצְּדָדִים. | needs-editor |
| activity.fewer.big.fish.json | hints.1.caption.0.v | נַשְׁוֶה אֶחָד אֶחָד: לְכׇל אֶחָד מִצַּד זֶה, אֶחָד מִצַּד זֶה. | needs-editor |
| activity.fewer.big.fish.json | hints.2.caption.0.v | בְּצַד אֶחָד יֵשׁ שְׁנֵי דָּגִים, וּבַצַּד הָאַחֵר אַרְבָּעָה דָּגִים. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל הַנְּכוֹנָה. | needs-editor |
| activity.fewer.big.fish.json | a11y.altText | אֵיפֹה יֵשׁ פָּחוֹת דָּגִים? | needs-editor |
| activity.fewer.stars.4v2.json | prompt.caption.0.v | אֵיפֹה יֵשׁ פָּחוֹת כּוֹכָבִים? | needs-editor |
| activity.fewer.stars.4v2.json | answer.options.0.label | אַרְבָּעָה כּוֹכָבִים | needs-editor |
| activity.fewer.stars.4v2.json | answer.options.1.label | שְׁנֵי כּוֹכָבִים | needs-editor |
| activity.fewer.stars.4v2.json | feedback.correct.caption.0.v | כֵּן! כָּאן יֵשׁ פָּחוֹת כּוֹכָבִים. | needs-editor |
| activity.fewer.stars.4v2.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.fewer.stars.4v2.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.fewer.stars.4v2.json | hints.0.caption.0.v | בּוֹאוּ נִסְתַּכֵּל שׁוּב עַל שְׁנֵי הַצְּדָדִים. | needs-editor |
| activity.fewer.stars.4v2.json | hints.1.caption.0.v | נַשְׁוֶה אֶחָד אֶחָד: לְכׇל אֶחָד מִצַּד זֶה, אֶחָד מִצַּד זֶה. | needs-editor |
| activity.fewer.stars.4v2.json | hints.2.caption.0.v | בְּצַד אֶחָד יֵשׁ שְׁנֵי כּוֹכָבִים, וּבַצַּד הָאַחֵר אַרְבָּעָה כּוֹכָבִים. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל הַנְּכוֹנָה. | needs-editor |
| activity.fewer.stars.4v2.json | a11y.altText | אֵיפֹה יֵשׁ פָּחוֹת כּוֹכָבִים? | needs-editor |
| activity.flash.dice.1.json | prompt.caption.0.v | הִסְתַּכְּלוּ מַהֵר! כַּמָּה חִפּוּשִׁיּוֹת? | needs-editor |
| activity.flash.dice.1.json | feedback.correct.caption.0.v | אַחַת! רְאִיתֶם בְּלִי לִסְפֹּר. | needs-editor |
| activity.flash.dice.1.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.flash.dice.1.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.flash.dice.1.json | hints.0.caption.0.v | בּוֹאוּ נִסְתַּכֵּל שׁוּב, לְאַט. | needs-editor |
| activity.flash.dice.1.json | hints.1.caption.0.v | נַחֲזִיק אֶצְבָּעוֹת וְנִסְפֹּר: אַחַת. | needs-editor |
| activity.flash.dice.1.json | hints.2.caption.0.v | זֶה חִפּוּשִׁית אַחַת. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל אַחַת. | needs-editor |
| activity.flash.dice.1.json | a11y.altText | הִסְתַּכְּלוּ מַהֵר. כַּמָּה חִפּוּשִׁיּוֹת? | needs-editor |
| activity.flash.dice.2.json | prompt.caption.0.v | הִסְתַּכְּלוּ מַהֵר! כַּמָּה כּוֹכָבִים? | needs-editor |
| activity.flash.dice.2.json | feedback.correct.caption.0.v | שְׁתַּיִם! רְאִיתֶם בְּלִי לִסְפֹּר. | needs-editor |
| activity.flash.dice.2.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.flash.dice.2.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.flash.dice.2.json | hints.0.caption.0.v | בּוֹאוּ נִסְתַּכֵּל שׁוּב, לְאַט. | needs-editor |
| activity.flash.dice.2.json | hints.1.caption.0.v | נַחֲזִיק אֶצְבָּעוֹת וְנִסְפֹּר: אַחַת, שְׁתַּיִם. | needs-editor |
| activity.flash.dice.2.json | hints.2.caption.0.v | זֶה שְׁנֵי כּוֹכָבִים. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל שְׁתַּיִם. | needs-editor |
| activity.flash.dice.2.json | a11y.altText | הִסְתַּכְּלוּ מַהֵר. כַּמָּה כּוֹכָבִים? | needs-editor |
| activity.flash.dice.3.json | prompt.caption.0.v | הִסְתַּכְּלוּ מַהֵר! כַּמָּה תַּפּוּחִים? | needs-editor |
| activity.flash.dice.3.json | feedback.correct.caption.0.v | שָׁלוֹשׁ! רְאִיתֶם בְּלִי לִסְפֹּר. | needs-editor |
| activity.flash.dice.3.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.flash.dice.3.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.flash.dice.3.json | hints.0.caption.0.v | בּוֹאוּ נִסְתַּכֵּל שׁוּב, לְאַט. | needs-editor |
| activity.flash.dice.3.json | hints.1.caption.0.v | נַחֲזִיק אֶצְבָּעוֹת וְנִסְפֹּר: אַחַת, שְׁתַּיִם, שָׁלוֹשׁ. | needs-editor |
| activity.flash.dice.3.json | hints.2.caption.0.v | זֶה שְׁלוֹשָׁה תַּפּוּחִים. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל שָׁלוֹשׁ. | needs-editor |
| activity.flash.dice.3.json | a11y.altText | הִסְתַּכְּלוּ מַהֵר. כַּמָּה תַּפּוּחִים? | needs-editor |
| activity.flash.dice.4.json | prompt.caption.0.v | הִסְתַּכְּלוּ מַהֵר! כַּמָּה חִפּוּשִׁיּוֹת? | needs-editor |
| activity.flash.dice.4.json | feedback.correct.caption.0.v | אַרְבַּע! רְאִיתֶם בְּלִי לִסְפֹּר. | needs-editor |
| activity.flash.dice.4.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.flash.dice.4.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.flash.dice.4.json | hints.0.caption.0.v | בּוֹאוּ נִסְתַּכֵּל שׁוּב, לְאַט. | needs-editor |
| activity.flash.dice.4.json | hints.1.caption.0.v | נַחֲזִיק אֶצְבָּעוֹת וְנִסְפֹּר: אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע. | needs-editor |
| activity.flash.dice.4.json | hints.2.caption.0.v | זֶה אַרְבַּע חִפּוּשִׁיּוֹת. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל אַרְבַּע. | needs-editor |
| activity.flash.dice.4.json | a11y.altText | הִסְתַּכְּלוּ מַהֵר. כַּמָּה חִפּוּשִׁיּוֹת? | needs-editor |
| activity.flash.dice.5.json | prompt.caption.0.v | הִסְתַּכְּלוּ מַהֵר! כַּמָּה כּוֹכָבִים? | needs-editor |
| activity.flash.dice.5.json | feedback.correct.caption.0.v | חָמֵשׁ! רְאִיתֶם בְּלִי לִסְפֹּר. | needs-editor |
| activity.flash.dice.5.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.flash.dice.5.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.flash.dice.5.json | hints.0.caption.0.v | בּוֹאוּ נִסְתַּכֵּל שׁוּב, לְאַט. | needs-editor |
| activity.flash.dice.5.json | hints.1.caption.0.v | נַחֲזִיק אֶצְבָּעוֹת וְנִסְפֹּר: אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע, חָמֵשׁ. | needs-editor |
| activity.flash.dice.5.json | hints.2.caption.0.v | זֶה חֲמִשָּׁה כּוֹכָבִים. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל חָמֵשׁ. | needs-editor |
| activity.flash.dice.5.json | a11y.altText | הִסְתַּכְּלוּ מַהֵר. כַּמָּה כּוֹכָבִים? | needs-editor |
| activity.flash.frame.4.json | prompt.caption.0.v | הִסְתַּכְּלוּ מַהֵר! כַּמָּה תַּפּוּחִים? | needs-editor |
| activity.flash.frame.4.json | feedback.correct.caption.0.v | אַרְבַּע! רְאִיתֶם בְּלִי לִסְפֹּר. | needs-editor |
| activity.flash.frame.4.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.flash.frame.4.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.flash.frame.4.json | hints.0.caption.0.v | בּוֹאוּ נִסְתַּכֵּל שׁוּב, לְאַט. | needs-editor |
| activity.flash.frame.4.json | hints.1.caption.0.v | נַחֲזִיק אֶצְבָּעוֹת וְנִסְפֹּר: אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע. | needs-editor |
| activity.flash.frame.4.json | hints.2.caption.0.v | זֶה אַרְבָּעָה תַּפּוּחִים. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל אַרְבַּע. | needs-editor |
| activity.flash.frame.4.json | a11y.altText | הִסְתַּכְּלוּ מַהֵר. כַּמָּה תַּפּוּחִים? | needs-editor |
| activity.flash.frame.5.json | prompt.caption.0.v | הִסְתַּכְּלוּ מַהֵר! כַּמָּה דָּגִים? | needs-editor |
| activity.flash.frame.5.json | feedback.correct.caption.0.v | חָמֵשׁ! רְאִיתֶם בְּלִי לִסְפֹּר. | needs-editor |
| activity.flash.frame.5.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.flash.frame.5.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.flash.frame.5.json | hints.0.caption.0.v | בּוֹאוּ נִסְתַּכֵּל שׁוּב, לְאַט. | needs-editor |
| activity.flash.frame.5.json | hints.1.caption.0.v | נַחֲזִיק אֶצְבָּעוֹת וְנִסְפֹּר: אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע, חָמֵשׁ. | needs-editor |
| activity.flash.frame.5.json | hints.2.caption.0.v | זֶה חֲמִשָּׁה דָּגִים. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל חָמֵשׁ. | needs-editor |
| activity.flash.frame.5.json | a11y.altText | הִסְתַּכְּלוּ מַהֵר. כַּמָּה דָּגִים? | needs-editor |
| activity.flash.scatter.3.json | prompt.caption.0.v | הִסְתַּכְּלוּ מַהֵר! כַּמָּה חִפּוּשִׁיּוֹת? | needs-editor |
| activity.flash.scatter.3.json | feedback.correct.caption.0.v | שָׁלוֹשׁ! רְאִיתֶם בְּלִי לִסְפֹּר. | needs-editor |
| activity.flash.scatter.3.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.flash.scatter.3.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.flash.scatter.3.json | hints.0.caption.0.v | בּוֹאוּ נִסְתַּכֵּל שׁוּב, לְאַט. | needs-editor |
| activity.flash.scatter.3.json | hints.1.caption.0.v | נַחֲזִיק אֶצְבָּעוֹת וְנִסְפֹּר: אַחַת, שְׁתַּיִם, שָׁלוֹשׁ. | needs-editor |
| activity.flash.scatter.3.json | hints.2.caption.0.v | זֶה שָׁלוֹשׁ חִפּוּשִׁיּוֹת. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל שָׁלוֹשׁ. | needs-editor |
| activity.flash.scatter.3.json | a11y.altText | הִסְתַּכְּלוּ מַהֵר. כַּמָּה חִפּוּשִׁיּוֹת? | needs-editor |
| activity.give.apples.3.json | prompt.caption.0.v | תְּנוּ לִי שְׁלוֹשָׁה תַּפּוּחִים. | needs-editor |
| activity.give.apples.3.json | feedback.correct.caption.0.v | שָׁלוֹשׁ! נָתַתֶּם בְּדִיּוּק כַּמָּה שֶׁבִּקַּשְׁתִּי. | needs-editor |
| activity.give.apples.3.json | feedback.incorrect.0.caption.0.v | לָקַחְנוּ אֶת כֻּלָּם. הַפֶּרַח רוֹצֶה רַק אַרְבָּעָה — בּוֹאוּ נִסְפֹּר אוֹתָם. | needs-editor |
| activity.give.apples.3.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.give.apples.3.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.give.apples.3.json | hints.0.caption.0.v | תְּנוּ לִי שְׁלוֹשָׁה תַּפּוּחִים. סוֹפְרִים תוֹךְ כְּדֵי שֶׁלּוֹקְחִים. | needs-editor |
| activity.give.apples.3.json | hints.1.caption.0.v | נִסְפֹּר עִם הָאֶצְבָּעוֹת: אַחַת, שְׁתַּיִם, שָׁלוֹשׁ. | needs-editor |
| activity.give.apples.3.json | hints.2.caption.0.v | אַחַת, שְׁתַּיִם, שָׁלוֹשׁ. עֲצְרוּ כְּשֶׁהִגַּעְנוּ אֶל שָׁלוֹשׁ. עַכְשָׁו תּוֹרְכֶם. | needs-editor |
| activity.give.apples.3.json | a11y.altText | תְּנוּ לִי שְׁלוֹשָׁה תַּפּוּחִים. | needs-editor |
| activity.give.butterflies.4.json | prompt.caption.0.v | תְּנוּ לַפֶּרַח אַרְבָּעָה פַּרְפָּרִים. | needs-editor |
| activity.give.butterflies.4.json | feedback.correct.caption.0.v | אַרְבָּעָה! נְתַתֶּם בְּדִיּוּק אַרְבָּעָה. | needs-editor |
| activity.give.butterflies.4.json | feedback.incorrect.0.caption.0.v | לָקַחְנוּ אֶת כֻּלָּם. הַפֶּרַח רוֹצֶה רַק אַרְבָּעָה — בּוֹאוּ נִסְפֹּר אוֹתָם. | needs-editor |
| activity.give.butterflies.4.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.give.butterflies.4.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.give.butterflies.4.json | hints.0.caption.0.v | תְּנוּ לַפֶּרַח אַרְבָּעָה פַּרְפָּרִים. נוֹגְעִים בְּפַרְפָּר אֶחָד, וְאוֹמְרִים מִסְפָּר אֶחָד. | needs-editor |
| activity.give.butterflies.4.json | hints.1.caption.0.v | בּוֹאוּ נַחְשֹׁב עִם הָאֶצְבָּעוֹת: אַחַת… שְׁתַּיִם… שָׁלוֹשׁ… אַרְבַּע. | needs-editor |
| activity.give.butterflies.4.json | hints.2.caption.0.v | אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע. עַכְשָׁו תּוֹרְכֶם — לוֹקְחִים אַרְבָּעָה פַּרְפָּרִים. | needs-editor |
| activity.give.butterflies.4.json | a11y.altText | צִנְצֶנֶת עִם שִׁבְעָה פַּרְפָּרִים וּפֶרַח רֵיק | needs-editor |
| activity.give.fish.4.json | prompt.caption.0.v | תְּנוּ לִי אַרְבָּעָה דָּגִים. | needs-editor |
| activity.give.fish.4.json | feedback.correct.caption.0.v | אַרְבַּע! נָתַתֶּם בְּדִיּוּק כַּמָּה שֶׁבִּקַּשְׁתִּי. | needs-editor |
| activity.give.fish.4.json | feedback.incorrect.0.caption.0.v | לָקַחְנוּ אֶת כֻּלָּם. הַפֶּרַח רוֹצֶה רַק אַרְבָּעָה — בּוֹאוּ נִסְפֹּר אוֹתָם. | needs-editor |
| activity.give.fish.4.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.give.fish.4.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.give.fish.4.json | hints.0.caption.0.v | תְּנוּ לִי אַרְבָּעָה דָּגִים. סוֹפְרִים תוֹךְ כְּדֵי שֶׁלּוֹקְחִים. | needs-editor |
| activity.give.fish.4.json | hints.1.caption.0.v | נִסְפֹּר עִם הָאֶצְבָּעוֹת: אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע. | needs-editor |
| activity.give.fish.4.json | hints.2.caption.0.v | אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע. עֲצְרוּ כְּשֶׁהִגַּעְנוּ אֶל אַרְבַּע. עַכְשָׁו תּוֹרְכֶם. | needs-editor |
| activity.give.fish.4.json | a11y.altText | תְּנוּ לִי אַרְבָּעָה דָּגִים. | needs-editor |
| activity.give.ladybugs.2.json | prompt.caption.0.v | תְּנוּ לִי שְׁתֵּי חִפּוּשִׁיּוֹת. | needs-editor |
| activity.give.ladybugs.2.json | feedback.correct.caption.0.v | שְׁתַּיִם! נָתַתֶּם בְּדִיּוּק כַּמָּה שֶׁבִּקַּשְׁתִּי. | needs-editor |
| activity.give.ladybugs.2.json | feedback.incorrect.0.caption.0.v | לָקַחְנוּ אֶת כֻּלָּם. הַפֶּרַח רוֹצֶה רַק אַרְבָּעָה — בּוֹאוּ נִסְפֹּר אוֹתָם. | needs-editor |
| activity.give.ladybugs.2.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.give.ladybugs.2.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.give.ladybugs.2.json | hints.0.caption.0.v | תְּנוּ לִי שְׁתֵּי חִפּוּשִׁיּוֹת. סוֹפְרִים תוֹךְ כְּדֵי שֶׁלּוֹקְחִים. | needs-editor |
| activity.give.ladybugs.2.json | hints.1.caption.0.v | נִסְפֹּר עִם הָאֶצְבָּעוֹת: אַחַת, שְׁתַּיִם. | needs-editor |
| activity.give.ladybugs.2.json | hints.2.caption.0.v | אַחַת, שְׁתַּיִם. עֲצְרוּ כְּשֶׁהִגַּעְנוּ אֶל שְׁתַּיִם. עַכְשָׁו תּוֹרְכֶם. | needs-editor |
| activity.give.ladybugs.2.json | a11y.altText | תְּנוּ לִי שְׁתֵּי חִפּוּשִׁיּוֹת. | needs-editor |
| activity.give.stars.5.json | prompt.caption.0.v | תְּנוּ לִי חֲמִשָּׁה כּוֹכָבִים. | needs-editor |
| activity.give.stars.5.json | feedback.correct.caption.0.v | חָמֵשׁ! נָתַתֶּם בְּדִיּוּק כַּמָּה שֶׁבִּקַּשְׁתִּי. | needs-editor |
| activity.give.stars.5.json | feedback.incorrect.0.caption.0.v | לָקַחְנוּ אֶת כֻּלָּם. הַפֶּרַח רוֹצֶה רַק אַרְבָּעָה — בּוֹאוּ נִסְפֹּר אוֹתָם. | needs-editor |
| activity.give.stars.5.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.give.stars.5.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.give.stars.5.json | hints.0.caption.0.v | תְּנוּ לִי חֲמִשָּׁה כּוֹכָבִים. סוֹפְרִים תוֹךְ כְּדֵי שֶׁלּוֹקְחִים. | needs-editor |
| activity.give.stars.5.json | hints.1.caption.0.v | נִסְפֹּר עִם הָאֶצְבָּעוֹת: אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע, חָמֵשׁ. | needs-editor |
| activity.give.stars.5.json | hints.2.caption.0.v | אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע, חָמֵשׁ. עֲצְרוּ כְּשֶׁהִגַּעְנוּ אֶל חָמֵשׁ. עַכְשָׁו תּוֹרְכֶם. | needs-editor |
| activity.give.stars.5.json | a11y.altText | תְּנוּ לִי חֲמִשָּׁה כּוֹכָבִים. | needs-editor |
| activity.more.apples.2v4.json | prompt.caption.0.v | אֵיפֹה יֵשׁ יוֹתֵר תַּפּוּחִים? | needs-editor |
| activity.more.apples.2v4.json | answer.options.0.label | שְׁנֵי תַּפּוּחִים | needs-editor |
| activity.more.apples.2v4.json | answer.options.1.label | אַרְבָּעָה תַּפּוּחִים | needs-editor |
| activity.more.apples.2v4.json | feedback.correct.caption.0.v | כֵּן! כָּאן יֵשׁ יוֹתֵר תַּפּוּחִים. | needs-editor |
| activity.more.apples.2v4.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.more.apples.2v4.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.more.apples.2v4.json | hints.0.caption.0.v | בּוֹאוּ נִסְתַּכֵּל שׁוּב עַל שְׁנֵי הַצְּדָדִים. | needs-editor |
| activity.more.apples.2v4.json | hints.1.caption.0.v | נַשְׁוֶה אֶחָד אֶחָד: לְכׇל אֶחָד מִצַּד זֶה, אֶחָד מִצַּד זֶה. | needs-editor |
| activity.more.apples.2v4.json | hints.2.caption.0.v | בְּצַד אֶחָד יֵשׁ אַרְבָּעָה תַּפּוּחִים, וּבַצַּד הָאַחֵר שְׁנֵי תַּפּוּחִים. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל הַנְּכוֹנָה. | needs-editor |
| activity.more.apples.2v4.json | a11y.altText | אֵיפֹה יֵשׁ יוֹתֵר תַּפּוּחִים? | needs-editor |
| activity.more.big.apples.json | prompt.caption.0.v | אֵיפֹה יֵשׁ יוֹתֵר תַּפּוּחִים? | needs-editor |
| activity.more.big.apples.json | answer.options.0.label | שְׁלוֹשָׁה תַּפּוּחִים | needs-editor |
| activity.more.big.apples.json | answer.options.1.label | חֲמִשָּׁה תַּפּוּחִים | needs-editor |
| activity.more.big.apples.json | feedback.correct.caption.0.v | כֵּן! כָּאן יֵשׁ יוֹתֵר תַּפּוּחִים. | needs-editor |
| activity.more.big.apples.json | feedback.incorrect.0.caption.0.v | יוֹתֵר לֹא תָּמִיד אוֹמֵר גָּדוֹל יוֹתֵר. בּוֹאוּ נַשְׁוֶה אֶחָד אֶחָד. | needs-editor |
| activity.more.big.apples.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.more.big.apples.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.more.big.apples.json | hints.0.caption.0.v | בּוֹאוּ נִסְתַּכֵּל שׁוּב עַל שְׁנֵי הַצְּדָדִים. | needs-editor |
| activity.more.big.apples.json | hints.1.caption.0.v | נַשְׁוֶה אֶחָד אֶחָד: לְכׇל אֶחָד מִצַּד זֶה, אֶחָד מִצַּד זֶה. | needs-editor |
| activity.more.big.apples.json | hints.2.caption.0.v | בְּצַד אֶחָד יֵשׁ חֲמִשָּׁה תַּפּוּחִים, וּבַצַּד הָאַחֵר שְׁלוֹשָׁה תַּפּוּחִים. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל הַנְּכוֹנָה. | needs-editor |
| activity.more.big.apples.json | a11y.altText | אֵיפֹה יֵשׁ יוֹתֵר תַּפּוּחִים? | needs-editor |
| activity.more.fish.3v5.json | prompt.caption.0.v | אֵיפֹה יֵשׁ יוֹתֵר דָּגִים? | needs-editor |
| activity.more.fish.3v5.json | answer.options.0.label | חֲמִשָּׁה דָּגִים | needs-editor |
| activity.more.fish.3v5.json | answer.options.1.label | שְׁלוֹשָׁה דָּגִים | needs-editor |
| activity.more.fish.3v5.json | feedback.correct.caption.0.v | כֵּן! כָּאן יֵשׁ יוֹתֵר דָּגִים. | needs-editor |
| activity.more.fish.3v5.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.more.fish.3v5.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.more.fish.3v5.json | hints.0.caption.0.v | בּוֹאוּ נִסְתַּכֵּל שׁוּב עַל שְׁנֵי הַצְּדָדִים. | needs-editor |
| activity.more.fish.3v5.json | hints.1.caption.0.v | נַשְׁוֶה אֶחָד אֶחָד: לְכׇל אֶחָד מִצַּד זֶה, אֶחָד מִצַּד זֶה. | needs-editor |
| activity.more.fish.3v5.json | hints.2.caption.0.v | בְּצַד אֶחָד יֵשׁ חֲמִשָּׁה דָּגִים, וּבַצַּד הָאַחֵר שְׁלוֹשָׁה דָּגִים. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל הַנְּכוֹנָה. | needs-editor |
| activity.more.fish.3v5.json | a11y.altText | אֵיפֹה יֵשׁ יוֹתֵר דָּגִים? | needs-editor |
| activity.more.spread.stars.json | prompt.caption.0.v | אֵיפֹה יֵשׁ יוֹתֵר כּוֹכָבִים? | needs-editor |
| activity.more.spread.stars.json | answer.options.0.label | אַרְבָּעָה כּוֹכָבִים | needs-editor |
| activity.more.spread.stars.json | answer.options.1.label | שִׁשָּׁה כּוֹכָבִים | needs-editor |
| activity.more.spread.stars.json | feedback.correct.caption.0.v | כֵּן! כָּאן יֵשׁ יוֹתֵר כּוֹכָבִים. | needs-editor |
| activity.more.spread.stars.json | feedback.incorrect.0.caption.0.v | יוֹתֵר לֹא תָּמִיד אוֹמֵר גָּדוֹל יוֹתֵר. בּוֹאוּ נַשְׁוֶה אֶחָד אֶחָד. | needs-editor |
| activity.more.spread.stars.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.more.spread.stars.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.more.spread.stars.json | hints.0.caption.0.v | בּוֹאוּ נִסְתַּכֵּל שׁוּב עַל שְׁנֵי הַצְּדָדִים. | needs-editor |
| activity.more.spread.stars.json | hints.1.caption.0.v | נַשְׁוֶה אֶחָד אֶחָד: לְכׇל אֶחָד מִצַּד זֶה, אֶחָד מִצַּד זֶה. | needs-editor |
| activity.more.spread.stars.json | hints.2.caption.0.v | בְּצַד אֶחָד יֵשׁ שִׁשָּׁה כּוֹכָבִים, וּבַצַּד הָאַחֵר אַרְבָּעָה כּוֹכָבִים. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל הַנְּכוֹנָה. | needs-editor |
| activity.more.spread.stars.json | a11y.altText | אֵיפֹה יֵשׁ יוֹתֵר כּוֹכָבִים? | needs-editor |
| activity.next.after.1.json | prompt.caption.0.v | מָה בָּא אַחֲרֵי אַחַת? | needs-editor |
| activity.next.after.1.json | answer.options.0.label | אַחַת | needs-editor |
| activity.next.after.1.json | answer.options.1.label | שְׁתַּיִם | needs-editor |
| activity.next.after.1.json | answer.options.2.label | שָׁלוֹשׁ | needs-editor |
| activity.next.after.1.json | feedback.correct.caption.0.v | שְׁתַּיִם! כָּךְ סוֹפְרִים. | needs-editor |
| activity.next.after.1.json | feedback.incorrect.0.caption.0.v | הַמְּמ… בּוֹאוּ נִסְפֹּר לְאַט, מִסְפָּר אַחֲרֵי מִסְפָּר. | needs-editor |
| activity.next.after.1.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.next.after.1.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.next.after.1.json | hints.0.caption.0.v | בּוֹאוּ נִסְפֹּר יַחַד מֵהַהַתְחָלָה: אַחַת. | needs-editor |
| activity.next.after.1.json | hints.1.caption.0.v | נִסְפֹּר גַּם עִם הָאֶצְבָּעוֹת: אַחַת. | needs-editor |
| activity.next.after.1.json | hints.2.caption.0.v | אַחַת, וְאַחֲרֵי אַחַת בָּא שְׁתַּיִם. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל שְׁתַּיִם. | needs-editor |
| activity.next.after.1.json | a11y.altText | מָה בָּא אַחֲרֵי אַחַת? | needs-editor |
| activity.next.after.2.json | prompt.caption.0.v | מָה בָּא אַחֲרֵי שְׁתַּיִם? | needs-editor |
| activity.next.after.2.json | answer.options.0.label | שְׁתַּיִם | needs-editor |
| activity.next.after.2.json | answer.options.1.label | שָׁלוֹשׁ | needs-editor |
| activity.next.after.2.json | answer.options.2.label | אַרְבַּע | needs-editor |
| activity.next.after.2.json | feedback.correct.caption.0.v | שָׁלוֹשׁ! כָּךְ סוֹפְרִים. | needs-editor |
| activity.next.after.2.json | feedback.incorrect.0.caption.0.v | הַמְּמ… בּוֹאוּ נִסְפֹּר לְאַט, מִסְפָּר אַחֲרֵי מִסְפָּר. | needs-editor |
| activity.next.after.2.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.next.after.2.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.next.after.2.json | hints.0.caption.0.v | בּוֹאוּ נִסְפֹּר יַחַד מֵהַהַתְחָלָה: אַחַת, שְׁתַּיִם. | needs-editor |
| activity.next.after.2.json | hints.1.caption.0.v | נִסְפֹּר גַּם עִם הָאֶצְבָּעוֹת: אַחַת, שְׁתַּיִם. | needs-editor |
| activity.next.after.2.json | hints.2.caption.0.v | אַחַת, שְׁתַּיִם, וְאַחֲרֵי שְׁתַּיִם בָּא שָׁלוֹשׁ. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל שָׁלוֹשׁ. | needs-editor |
| activity.next.after.2.json | a11y.altText | מָה בָּא אַחֲרֵי שְׁתַּיִם? | needs-editor |
| activity.next.after.4.json | prompt.caption.0.v | מָה בָּא אַחֲרֵי אַרְבַּע? | needs-editor |
| activity.next.after.4.json | answer.options.0.label | שָׁלוֹשׁ | needs-editor |
| activity.next.after.4.json | answer.options.1.label | חָמֵשׁ | needs-editor |
| activity.next.after.4.json | answer.options.2.label | שֵׁשׁ | needs-editor |
| activity.next.after.4.json | feedback.correct.caption.0.v | חָמֵשׁ! כָּךְ סוֹפְרִים. | needs-editor |
| activity.next.after.4.json | feedback.incorrect.0.caption.0.v | הַמְּמ… בּוֹאוּ נִסְפֹּר לְאַט, מִסְפָּר אַחֲרֵי מִסְפָּר. | needs-editor |
| activity.next.after.4.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.next.after.4.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.next.after.4.json | hints.0.caption.0.v | בּוֹאוּ נִסְפֹּר יַחַד מֵהַהַתְחָלָה: אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע. | needs-editor |
| activity.next.after.4.json | hints.1.caption.0.v | נִסְפֹּר גַּם עִם הָאֶצְבָּעוֹת: אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע. | needs-editor |
| activity.next.after.4.json | hints.2.caption.0.v | אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע, וְאַחֲרֵי אַרְבַּע בָּא חָמֵשׁ. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל חָמֵשׁ. | needs-editor |
| activity.next.after.4.json | a11y.altText | מָה בָּא אַחֲרֵי אַרְבַּע? | needs-editor |
| activity.next.after.6.json | prompt.caption.0.v | מָה בָּא אַחֲרֵי שֵׁשׁ? | needs-editor |
| activity.next.after.6.json | answer.options.0.label | שֵׁשׁ | needs-editor |
| activity.next.after.6.json | answer.options.1.label | שֶׁבַע | needs-editor |
| activity.next.after.6.json | answer.options.2.label | שְׁמוֹנֶה | needs-editor |
| activity.next.after.6.json | feedback.correct.caption.0.v | שֶׁבַע! כָּךְ סוֹפְרִים. | needs-editor |
| activity.next.after.6.json | feedback.incorrect.0.caption.0.v | הַמְּמ… בּוֹאוּ נִסְפֹּר לְאַט, מִסְפָּר אַחֲרֵי מִסְפָּר. | needs-editor |
| activity.next.after.6.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.next.after.6.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.next.after.6.json | hints.0.caption.0.v | בּוֹאוּ נִסְפֹּר יַחַד מֵהַהַתְחָלָה: אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע, חָמֵשׁ. | needs-editor |
| activity.next.after.6.json | hints.1.caption.0.v | נִסְפֹּר גַּם עִם הָאֶצְבָּעוֹת: אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע, חָמֵשׁ. | needs-editor |
| activity.next.after.6.json | hints.2.caption.0.v | אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע, חָמֵשׁ, שֵׁשׁ, וְאַחֲרֵי שֵׁשׁ בָּא שֶׁבַע. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל שֶׁבַע. | needs-editor |
| activity.next.after.6.json | a11y.altText | מָה בָּא אַחֲרֵי שֵׁשׁ? | needs-editor |
| activity.next.after.8.json | prompt.caption.0.v | מָה בָּא אַחֲרֵי שְׁמוֹנֶה? | needs-editor |
| activity.next.after.8.json | answer.options.0.label | שֶׁבַע | needs-editor |
| activity.next.after.8.json | answer.options.1.label | תֵּשַׁע | needs-editor |
| activity.next.after.8.json | answer.options.2.label | עֶשֶׂר | needs-editor |
| activity.next.after.8.json | feedback.correct.caption.0.v | תֵּשַׁע! כָּךְ סוֹפְרִים. | needs-editor |
| activity.next.after.8.json | feedback.incorrect.0.caption.0.v | הַמְּמ… בּוֹאוּ נִסְפֹּר לְאַט, מִסְפָּר אַחֲרֵי מִסְפָּר. | needs-editor |
| activity.next.after.8.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.next.after.8.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.next.after.8.json | hints.0.caption.0.v | בּוֹאוּ נִסְפֹּר יַחַד מֵהַהַתְחָלָה: אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע, חָמֵשׁ. | needs-editor |
| activity.next.after.8.json | hints.1.caption.0.v | נִסְפֹּר גַּם עִם הָאֶצְבָּעוֹת: אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע, חָמֵשׁ. | needs-editor |
| activity.next.after.8.json | hints.2.caption.0.v | אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע, חָמֵשׁ, שֵׁשׁ, שֶׁבַע, שְׁמוֹנֶה, וְאַחֲרֵי שְׁמוֹנֶה בָּא תֵּשַׁע. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל תֵּשַׁע. | needs-editor |
| activity.next.after.8.json | a11y.altText | מָה בָּא אַחֲרֵי שְׁמוֹנֶה? | needs-editor |
| activity.next.before.7.json | prompt.caption.0.v | מָה בָּא לִפְנֵי שֶׁבַע? | needs-editor |
| activity.next.before.7.json | answer.options.0.label | חָמֵשׁ | needs-editor |
| activity.next.before.7.json | answer.options.1.label | שֵׁשׁ | needs-editor |
| activity.next.before.7.json | answer.options.2.label | שֶׁבַע | needs-editor |
| activity.next.before.7.json | feedback.correct.caption.0.v | שֵׁשׁ! כָּךְ סוֹפְרִים. | needs-editor |
| activity.next.before.7.json | feedback.incorrect.0.caption.0.v | הַמְּמ… בּוֹאוּ נִסְפֹּר לְאַט, מִסְפָּר אַחֲרֵי מִסְפָּר. | needs-editor |
| activity.next.before.7.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.next.before.7.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.next.before.7.json | hints.0.caption.0.v | בּוֹאוּ נִסְפֹּר יַחַד מֵהַהַתְחָלָה: אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע, חָמֵשׁ. | needs-editor |
| activity.next.before.7.json | hints.1.caption.0.v | נִסְפֹּר גַּם עִם הָאֶצְבָּעוֹת: אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע, חָמֵשׁ. | needs-editor |
| activity.next.before.7.json | hints.2.caption.0.v | אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע, חָמֵשׁ, שֵׁשׁ, שֶׁבַע. לִפְנֵי שֶׁבַע בָּא שֵׁשׁ. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל שֵׁשׁ. | needs-editor |
| activity.next.before.7.json | a11y.altText | מָה בָּא לִפְנֵי שֶׁבַע? | needs-editor |
| activity.nonzero.nest.2.json | prompt.caption.0.v | כַּמָּה צִפֳּרִים בַּקֵּן? | needs-editor |
| activity.nonzero.nest.2.json | answer.options.0.label | אֶפֶס | needs-editor |
| activity.nonzero.nest.2.json | answer.options.1.label | אַחַת | needs-editor |
| activity.nonzero.nest.2.json | answer.options.2.label | שְׁתַּיִם | needs-editor |
| activity.nonzero.nest.2.json | feedback.correct.caption.0.v | שְׁתַּיִם! נָכוֹן. | needs-editor |
| activity.nonzero.nest.2.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.nonzero.nest.2.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.nonzero.nest.2.json | hints.0.caption.0.v | בּוֹאוּ נִסְתַּכֵּל שׁוּב. | needs-editor |
| activity.nonzero.nest.2.json | hints.1.caption.0.v | נִסְפֹּר עִם הָאֶצְבָּעוֹת: אַחַת, שְׁתַּיִם. | needs-editor |
| activity.nonzero.nest.2.json | hints.2.caption.0.v | אַחַת, שְׁתַּיִם. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל שְׁתַּיִם. | needs-editor |
| activity.nonzero.nest.2.json | a11y.altText | כַּמָּה צִפֳּרִים בַּקֵּן? | needs-editor |
| activity.numeral.apples.2.json | prompt.caption.0.v | כַּמָּה תַּפּוּחִים יֵשׁ? בּוֹחֲרִים אֶת הַמִּסְפָּר. | needs-editor |
| activity.numeral.apples.2.json | answer.options.0.label | אַחַת | needs-editor |
| activity.numeral.apples.2.json | answer.options.1.label | שְׁתַּיִם | needs-editor |
| activity.numeral.apples.2.json | answer.options.2.label | שָׁלוֹשׁ | needs-editor |
| activity.numeral.apples.2.json | feedback.correct.caption.0.v | שְׁתַּיִם! זֶה הַמִּסְפָּר. | needs-editor |
| activity.numeral.apples.2.json | feedback.incorrect.0.caption.0.v | אוּלַי סָפַרְנוּ אֶחָד פַּעֲמַיִם? בּוֹאוּ נִבְדֹּק. | needs-editor |
| activity.numeral.apples.2.json | feedback.incorrect.1.caption.0.v | אוּלַי פִּסְפַּסְנוּ אֶחָד? בּוֹאוּ נִבְדֹּק. | needs-editor |
| activity.numeral.apples.2.json | feedback.incorrect.2.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.numeral.apples.2.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.numeral.apples.2.json | hints.0.caption.0.v | בּוֹאוּ נְנַסֶּה לִסְפֹּר לְאַט. | needs-editor |
| activity.numeral.apples.2.json | hints.1.caption.0.v | נִסְפֹּר עִם הָאֶצְבָּעוֹת: אַחַת, שְׁתַּיִם. | needs-editor |
| activity.numeral.apples.2.json | hints.2.caption.0.v | אַחַת, שְׁתַּיִם. יֵשׁ שְׁנֵי תַּפּוּחִים. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל שְׁתַּיִם. | needs-editor |
| activity.numeral.apples.2.json | a11y.altText | כַּמָּה תַּפּוּחִים יֵשׁ? בּוֹחֲרִים אֶת הַמִּסְפָּר. | needs-editor |
| activity.numeral.bugs.5.json | prompt.caption.0.v | כַּמָּה חִפּוּשִׁיּוֹת יֵשׁ? בּוֹחֲרִים אֶת הַמִּסְפָּר. | needs-editor |
| activity.numeral.bugs.5.json | answer.options.0.label | אַרְבַּע | needs-editor |
| activity.numeral.bugs.5.json | answer.options.1.label | חָמֵשׁ | needs-editor |
| activity.numeral.bugs.5.json | answer.options.2.label | שֵׁשׁ | needs-editor |
| activity.numeral.bugs.5.json | feedback.correct.caption.0.v | חָמֵשׁ! זֶה הַמִּסְפָּר. | needs-editor |
| activity.numeral.bugs.5.json | feedback.incorrect.0.caption.0.v | אוּלַי סָפַרְנוּ אֶחָד פַּעֲמַיִם? בּוֹאוּ נִבְדֹּק. | needs-editor |
| activity.numeral.bugs.5.json | feedback.incorrect.1.caption.0.v | אוּלַי פִּסְפַּסְנוּ אֶחָד? בּוֹאוּ נִבְדֹּק. | needs-editor |
| activity.numeral.bugs.5.json | feedback.incorrect.2.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.numeral.bugs.5.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.numeral.bugs.5.json | hints.0.caption.0.v | בּוֹאוּ נְנַסֶּה לִסְפֹּר לְאַט. | needs-editor |
| activity.numeral.bugs.5.json | hints.1.caption.0.v | נִסְפֹּר עִם הָאֶצְבָּעוֹת: אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע, חָמֵשׁ. | needs-editor |
| activity.numeral.bugs.5.json | hints.2.caption.0.v | אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע, חָמֵשׁ. יֵשׁ חָמֵשׁ חִפּוּשִׁיּוֹת. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל חָמֵשׁ. | needs-editor |
| activity.numeral.bugs.5.json | a11y.altText | כַּמָּה חִפּוּשִׁיּוֹת יֵשׁ? בּוֹחֲרִים אֶת הַמִּסְפָּר. | needs-editor |
| activity.numeral.fish.4.json | prompt.caption.0.v | כַּמָּה דָּגִים יֵשׁ? בּוֹחֲרִים אֶת הַמִּסְפָּר. | needs-editor |
| activity.numeral.fish.4.json | answer.options.0.label | שָׁלוֹשׁ | needs-editor |
| activity.numeral.fish.4.json | answer.options.1.label | אַרְבַּע | needs-editor |
| activity.numeral.fish.4.json | answer.options.2.label | חָמֵשׁ | needs-editor |
| activity.numeral.fish.4.json | feedback.correct.caption.0.v | אַרְבַּע! זֶה הַמִּסְפָּר. | needs-editor |
| activity.numeral.fish.4.json | feedback.incorrect.0.caption.0.v | אוּלַי סָפַרְנוּ אֶחָד פַּעֲמַיִם? בּוֹאוּ נִבְדֹּק. | needs-editor |
| activity.numeral.fish.4.json | feedback.incorrect.1.caption.0.v | אוּלַי פִּסְפַּסְנוּ אֶחָד? בּוֹאוּ נִבְדֹּק. | needs-editor |
| activity.numeral.fish.4.json | feedback.incorrect.2.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.numeral.fish.4.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.numeral.fish.4.json | hints.0.caption.0.v | בּוֹאוּ נְנַסֶּה לִסְפֹּר לְאַט. | needs-editor |
| activity.numeral.fish.4.json | hints.1.caption.0.v | נִסְפֹּר עִם הָאֶצְבָּעוֹת: אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע. | needs-editor |
| activity.numeral.fish.4.json | hints.2.caption.0.v | אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע. יֵשׁ אַרְבָּעָה דָּגִים. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל אַרְבַּע. | needs-editor |
| activity.numeral.fish.4.json | a11y.altText | כַּמָּה דָּגִים יֵשׁ? בּוֹחֲרִים אֶת הַמִּסְפָּר. | needs-editor |
| activity.numeral.stars.3.json | prompt.caption.0.v | כַּמָּה כּוֹכָבִים יֵשׁ? בּוֹחֲרִים אֶת הַמִּסְפָּר. | needs-editor |
| activity.numeral.stars.3.json | answer.options.0.label | שְׁתַּיִם | needs-editor |
| activity.numeral.stars.3.json | answer.options.1.label | שָׁלוֹשׁ | needs-editor |
| activity.numeral.stars.3.json | answer.options.2.label | אַרְבַּע | needs-editor |
| activity.numeral.stars.3.json | feedback.correct.caption.0.v | שָׁלוֹשׁ! זֶה הַמִּסְפָּר. | needs-editor |
| activity.numeral.stars.3.json | feedback.incorrect.0.caption.0.v | אוּלַי סָפַרְנוּ אֶחָד פַּעֲמַיִם? בּוֹאוּ נִבְדֹּק. | needs-editor |
| activity.numeral.stars.3.json | feedback.incorrect.1.caption.0.v | אוּלַי פִּסְפַּסְנוּ אֶחָד? בּוֹאוּ נִבְדֹּק. | needs-editor |
| activity.numeral.stars.3.json | feedback.incorrect.2.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.numeral.stars.3.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.numeral.stars.3.json | hints.0.caption.0.v | בּוֹאוּ נְנַסֶּה לִסְפֹּר לְאַט. | needs-editor |
| activity.numeral.stars.3.json | hints.1.caption.0.v | נִסְפֹּר עִם הָאֶצְבָּעוֹת: אַחַת, שְׁתַּיִם, שָׁלוֹשׁ. | needs-editor |
| activity.numeral.stars.3.json | hints.2.caption.0.v | אַחַת, שְׁתַּיִם, שָׁלוֹשׁ. יֵשׁ שְׁלוֹשָׁה כּוֹכָבִים. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל שָׁלוֹשׁ. | needs-editor |
| activity.numeral.stars.3.json | a11y.altText | כַּמָּה כּוֹכָבִים יֵשׁ? בּוֹחֲרִים אֶת הַמִּסְפָּר. | needs-editor |
| activity.ordinal.first.json | prompt.caption.0.v | מִי רִאשׁוֹן בַּתּוֹר? | needs-editor |
| activity.ordinal.first.json | answer.options.0.label | חָתוּל | needs-editor |
| activity.ordinal.first.json | answer.options.1.label | כֶּלֶב | needs-editor |
| activity.ordinal.first.json | answer.options.2.label | בַּרְוָז | needs-editor |
| activity.ordinal.first.json | feedback.correct.caption.0.v | כֵּן! זֶה הרִאשׁוֹן בַּתּוֹר. | needs-editor |
| activity.ordinal.first.json | feedback.incorrect.0.caption.0.v | הַמָּקוֹם בַּתּוֹר אֵינוֹ כַּמָּה יֵשׁ. בּוֹאוּ נִסְפֹּר מֵהַהַתְחָלָה. | needs-editor |
| activity.ordinal.first.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.ordinal.first.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.ordinal.first.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.ordinal.first.json | hints.1.caption.0.v | נִסְפֹּר בַּתּוֹר מֵהַהַתְחָלָה: רִאשׁוֹן. | needs-editor |
| activity.ordinal.first.json | hints.2.caption.0.v | הַמָּקוֹם רִאשׁוֹן בַּתּוֹר הוּא חָתוּל. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.ordinal.first.json | a11y.altText | מִי רִאשׁוֹן בַּתּוֹר? | needs-editor |
| activity.ordinal.last.json | prompt.caption.0.v | מִי הָאַחֲרוֹן בַּתּוֹר? | needs-editor |
| activity.ordinal.last.json | answer.options.0.label | חָתוּל | needs-editor |
| activity.ordinal.last.json | answer.options.1.label | בַּרְוָז | needs-editor |
| activity.ordinal.last.json | answer.options.2.label | כֶּלֶב | needs-editor |
| activity.ordinal.last.json | answer.options.3.label | דָּג | needs-editor |
| activity.ordinal.last.json | feedback.correct.caption.0.v | כֵּן! זֶה האַחֲרוֹן בַּתּוֹר. | needs-editor |
| activity.ordinal.last.json | feedback.incorrect.0.caption.0.v | הַמָּקוֹם בַּתּוֹר אֵינוֹ כַּמָּה יֵשׁ. בּוֹאוּ נִסְפֹּר מֵהַהַתְחָלָה. | needs-editor |
| activity.ordinal.last.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.ordinal.last.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.ordinal.last.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.ordinal.last.json | hints.1.caption.0.v | נִסְפֹּר בַּתּוֹר מֵהַהַתְחָלָה: רִאשׁוֹן, שֵׁנִי, שְׁלִישִׁי, רְבִיעִי. | needs-editor |
| activity.ordinal.last.json | hints.2.caption.0.v | הַמָּקוֹם הָאַחֲרוֹן בַּתּוֹר הוּא דָּג. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.ordinal.last.json | a11y.altText | מִי הָאַחֲרוֹן בַּתּוֹר? | needs-editor |
| activity.ordinal.second.json | prompt.caption.0.v | מִי שֵׁנִי בַּתּוֹר? | needs-editor |
| activity.ordinal.second.json | answer.options.0.label | כֶּלֶב | needs-editor |
| activity.ordinal.second.json | answer.options.1.label | בַּרְוָז | needs-editor |
| activity.ordinal.second.json | answer.options.2.label | חָתוּל | needs-editor |
| activity.ordinal.second.json | feedback.correct.caption.0.v | כֵּן! זֶה השֵׁנִי בַּתּוֹר. | needs-editor |
| activity.ordinal.second.json | feedback.incorrect.0.caption.0.v | הַמָּקוֹם בַּתּוֹר אֵינוֹ כַּמָּה יֵשׁ. בּוֹאוּ נִסְפֹּר מֵהַהַתְחָלָה. | needs-editor |
| activity.ordinal.second.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.ordinal.second.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.ordinal.second.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.ordinal.second.json | hints.1.caption.0.v | נִסְפֹּר בַּתּוֹר מֵהַהַתְחָלָה: רִאשׁוֹן, שֵׁנִי. | needs-editor |
| activity.ordinal.second.json | hints.2.caption.0.v | הַמָּקוֹם שֵׁנִי בַּתּוֹר הוּא בַּרְוָז. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.ordinal.second.json | a11y.altText | מִי שֵׁנִי בַּתּוֹר? | needs-editor |
| activity.ordinal.third.json | prompt.caption.0.v | מִי שְׁלִישִׁי בַּתּוֹר? | needs-editor |
| activity.ordinal.third.json | answer.options.0.label | בַּרְוָז | needs-editor |
| activity.ordinal.third.json | answer.options.1.label | חָתוּל | needs-editor |
| activity.ordinal.third.json | answer.options.2.label | כֶּלֶב | needs-editor |
| activity.ordinal.third.json | feedback.correct.caption.0.v | כֵּן! זֶה השְׁלִישִׁי בַּתּוֹר. | needs-editor |
| activity.ordinal.third.json | feedback.incorrect.0.caption.0.v | הַמָּקוֹם בַּתּוֹר אֵינוֹ כַּמָּה יֵשׁ. בּוֹאוּ נִסְפֹּר מֵהַהַתְחָלָה. | needs-editor |
| activity.ordinal.third.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.ordinal.third.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.ordinal.third.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.ordinal.third.json | hints.1.caption.0.v | נִסְפֹּר בַּתּוֹר מֵהַהַתְחָלָה: רִאשׁוֹן, שֵׁנִי, שְׁלִישִׁי. | needs-editor |
| activity.ordinal.third.json | hints.2.caption.0.v | הַמָּקוֹם שְׁלִישִׁי בַּתּוֹר הוּא כֶּלֶב. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.ordinal.third.json | a11y.altText | מִי שְׁלִישִׁי בַּתּוֹר? | needs-editor |
| activity.ordinal.third.of4.json | prompt.caption.0.v | מִי שְׁלִישִׁי בַּתּוֹר? | needs-editor |
| activity.ordinal.third.of4.json | answer.options.0.label | דָּג | needs-editor |
| activity.ordinal.third.of4.json | answer.options.1.label | כֶּלֶב | needs-editor |
| activity.ordinal.third.of4.json | answer.options.2.label | חָתוּל | needs-editor |
| activity.ordinal.third.of4.json | answer.options.3.label | בַּרְוָז | needs-editor |
| activity.ordinal.third.of4.json | feedback.correct.caption.0.v | כֵּן! זֶה השְׁלִישִׁי בַּתּוֹר. | needs-editor |
| activity.ordinal.third.of4.json | feedback.incorrect.0.caption.0.v | הַמָּקוֹם בַּתּוֹר אֵינוֹ כַּמָּה יֵשׁ. בּוֹאוּ נִסְפֹּר מֵהַהַתְחָלָה. | needs-editor |
| activity.ordinal.third.of4.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.ordinal.third.of4.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.ordinal.third.of4.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.ordinal.third.of4.json | hints.1.caption.0.v | נִסְפֹּר בַּתּוֹר מֵהַהַתְחָלָה: רִאשׁוֹן, שֵׁנִי, שְׁלִישִׁי. | needs-editor |
| activity.ordinal.third.of4.json | hints.2.caption.0.v | הַמָּקוֹם שְׁלִישִׁי בַּתּוֹר הוּא חָתוּל. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.ordinal.third.of4.json | a11y.altText | מִי שְׁלִישִׁי בַּתּוֹר? | needs-editor |
| activity.pick.numeral.2.json | prompt.caption.0.v | אֵיפֹה הַמִּסְפָּר שְׁתַּיִם? | needs-editor |
| activity.pick.numeral.2.json | answer.options.0.label | אַחַת | needs-editor |
| activity.pick.numeral.2.json | answer.options.1.label | שְׁתַּיִם | needs-editor |
| activity.pick.numeral.2.json | answer.options.2.label | שָׁלוֹשׁ | needs-editor |
| activity.pick.numeral.2.json | feedback.correct.caption.0.v | שְׁתַּיִם! מָצָאתֶם אֶת הַמִּסְפָּר. | needs-editor |
| activity.pick.numeral.2.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.pick.numeral.2.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.pick.numeral.2.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב: שְׁתַּיִם. | needs-editor |
| activity.pick.numeral.2.json | hints.1.caption.0.v | נִסְפֹּר עִם הָאֶצְבָּעוֹת עַד שְׁתַּיִם: אַחַת, שְׁתַּיִם. | needs-editor |
| activity.pick.numeral.2.json | hints.2.caption.0.v | אַחַת, שְׁתַּיִם. הַמִּסְפָּר הָאַחֲרוֹן הוּא שְׁתַּיִם. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל שְׁתַּיִם. | needs-editor |
| activity.pick.numeral.2.json | a11y.altText | אֵיפֹה הַמִּסְפָּר שְׁתַּיִם? | needs-editor |
| activity.pick.numeral.3.json | prompt.caption.0.v | אֵיפֹה הַמִּסְפָּר שָׁלוֹשׁ? | needs-editor |
| activity.pick.numeral.3.json | answer.options.0.label | שְׁתַּיִם | needs-editor |
| activity.pick.numeral.3.json | answer.options.1.label | שָׁלוֹשׁ | needs-editor |
| activity.pick.numeral.3.json | answer.options.2.label | חָמֵשׁ | needs-editor |
| activity.pick.numeral.3.json | feedback.correct.caption.0.v | שָׁלוֹשׁ! מָצָאתֶם אֶת הַמִּסְפָּר. | needs-editor |
| activity.pick.numeral.3.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.pick.numeral.3.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.pick.numeral.3.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב: שָׁלוֹשׁ. | needs-editor |
| activity.pick.numeral.3.json | hints.1.caption.0.v | נִסְפֹּר עִם הָאֶצְבָּעוֹת עַד שָׁלוֹשׁ: אַחַת, שְׁתַּיִם, שָׁלוֹשׁ. | needs-editor |
| activity.pick.numeral.3.json | hints.2.caption.0.v | אַחַת, שְׁתַּיִם, שָׁלוֹשׁ. הַמִּסְפָּר הָאַחֲרוֹן הוּא שָׁלוֹשׁ. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל שָׁלוֹשׁ. | needs-editor |
| activity.pick.numeral.3.json | a11y.altText | אֵיפֹה הַמִּסְפָּר שָׁלוֹשׁ? | needs-editor |
| activity.pick.numeral.4.json | prompt.caption.0.v | אֵיפֹה הַמִּסְפָּר אַרְבַּע? | needs-editor |
| activity.pick.numeral.4.json | answer.options.0.label | שָׁלוֹשׁ | needs-editor |
| activity.pick.numeral.4.json | answer.options.1.label | אַרְבַּע | needs-editor |
| activity.pick.numeral.4.json | answer.options.2.label | חָמֵשׁ | needs-editor |
| activity.pick.numeral.4.json | feedback.correct.caption.0.v | אַרְבַּע! מָצָאתֶם אֶת הַמִּסְפָּר. | needs-editor |
| activity.pick.numeral.4.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.pick.numeral.4.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.pick.numeral.4.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב: אַרְבַּע. | needs-editor |
| activity.pick.numeral.4.json | hints.1.caption.0.v | נִסְפֹּר עִם הָאֶצְבָּעוֹת עַד אַרְבַּע: אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע. | needs-editor |
| activity.pick.numeral.4.json | hints.2.caption.0.v | אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע. הַמִּסְפָּר הָאַחֲרוֹן הוּא אַרְבַּע. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל אַרְבַּע. | needs-editor |
| activity.pick.numeral.4.json | a11y.altText | אֵיפֹה הַמִּסְפָּר אַרְבַּע? | needs-editor |
| activity.pick.numeral.5.json | prompt.caption.0.v | אֵיפֹה הַמִּסְפָּר חָמֵשׁ? | needs-editor |
| activity.pick.numeral.5.json | answer.options.0.label | אַחַת | needs-editor |
| activity.pick.numeral.5.json | answer.options.1.label | אַרְבַּע | needs-editor |
| activity.pick.numeral.5.json | answer.options.2.label | חָמֵשׁ | needs-editor |
| activity.pick.numeral.5.json | feedback.correct.caption.0.v | חָמֵשׁ! מָצָאתֶם אֶת הַמִּסְפָּר. | needs-editor |
| activity.pick.numeral.5.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.pick.numeral.5.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.pick.numeral.5.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב: חָמֵשׁ. | needs-editor |
| activity.pick.numeral.5.json | hints.1.caption.0.v | נִסְפֹּר עִם הָאֶצְבָּעוֹת עַד חָמֵשׁ: אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע, חָמֵשׁ. | needs-editor |
| activity.pick.numeral.5.json | hints.2.caption.0.v | אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע, חָמֵשׁ. הַמִּסְפָּר הָאַחֲרוֹן הוּא חָמֵשׁ. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל חָמֵשׁ. | needs-editor |
| activity.pick.numeral.5.json | a11y.altText | אֵיפֹה הַמִּסְפָּר חָמֵשׁ? | needs-editor |
| activity.pick.red.flower.json | prompt.caption.0.v | אֵיפֹה הַפֶּרַח הָאָדֹם? | needs-editor |
| activity.pick.red.flower.json | answer.options.0.label | פֶּרַח אָדֹם | needs-editor |
| activity.pick.red.flower.json | answer.options.1.label | פֶּרַח צָהֹב | needs-editor |
| activity.pick.red.flower.json | feedback.correct.caption.0.v | זֶה הוּא! הַפֶּרַח הָאָדֹם. | needs-editor |
| activity.pick.red.flower.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.pick.red.flower.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.pick.red.flower.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב: אֵיפֹה הַפֶּרַח הָאָדֹם? | needs-editor |
| activity.pick.red.flower.json | a11y.altText | שְׁנֵי פְּרָחִים בַּגִּנָּה, אֶחָד אָדֹם וְאֶחָד צָהֹב | needs-editor |
| activity.same.apples.4v5.json | prompt.caption.0.v | הַאִם יֵשׁ אוֹתוֹ מִסְפָּר בִּשְׁנֵי הַצְּדָדִים? | needs-editor |
| activity.same.apples.4v5.json | answer.options.0.label | כֵּן | needs-editor |
| activity.same.apples.4v5.json | answer.options.1.label | לֹא | needs-editor |
| activity.same.apples.4v5.json | feedback.correct.caption.0.v | כֵּן, צָדַקְתֶּם! | needs-editor |
| activity.same.apples.4v5.json | feedback.incorrect.0.caption.0.v | יוֹתֵר לֹא תָּמִיד אוֹמֵר גָּדוֹל יוֹתֵר. בּוֹאוּ נַשְׁוֶה אֶחָד אֶחָד. | needs-editor |
| activity.same.apples.4v5.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.same.apples.4v5.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.same.apples.4v5.json | hints.0.caption.0.v | בּוֹאוּ נִסְתַּכֵּל שׁוּב עַל שְׁנֵי הַצְּדָדִים. | needs-editor |
| activity.same.apples.4v5.json | hints.1.caption.0.v | נַשְׁוֶה אֶחָד אֶחָד: לְכׇל אֶחָד מִצַּד זֶה, אֶחָד מִצַּד זֶה. | needs-editor |
| activity.same.apples.4v5.json | hints.2.caption.0.v | בְּצַד אֶחָד יֵשׁ אַרְבָּעָה תַּפּוּחִים, וּבַצַּד הָאַחֵר חֲמִשָּׁה תַּפּוּחִים. זֶה לֹא אוֹתוֹ דָּבָר. | needs-editor |
| activity.same.apples.4v5.json | a11y.altText | הַאִם יֵשׁ אוֹתוֹ מִסְפָּר בִּשְׁנֵי הַצְּדָדִים? | needs-editor |
| activity.same.bugs.3v3.json | prompt.caption.0.v | הַאִם יֵשׁ אוֹתוֹ מִסְפָּר בִּשְׁנֵי הַצְּדָדִים? | needs-editor |
| activity.same.bugs.3v3.json | answer.options.0.label | כֵּן | needs-editor |
| activity.same.bugs.3v3.json | answer.options.1.label | לֹא | needs-editor |
| activity.same.bugs.3v3.json | feedback.correct.caption.0.v | כֵּן, צָדַקְתֶּם! | needs-editor |
| activity.same.bugs.3v3.json | feedback.incorrect.0.caption.0.v | יוֹתֵר לֹא תָּמִיד אוֹמֵר גָּדוֹל יוֹתֵר. בּוֹאוּ נַשְׁוֶה אֶחָד אֶחָד. | needs-editor |
| activity.same.bugs.3v3.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.same.bugs.3v3.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.same.bugs.3v3.json | hints.0.caption.0.v | בּוֹאוּ נִסְתַּכֵּל שׁוּב עַל שְׁנֵי הַצְּדָדִים. | needs-editor |
| activity.same.bugs.3v3.json | hints.1.caption.0.v | נַשְׁוֶה אֶחָד אֶחָד: לְכׇל אֶחָד מִצַּד זֶה, אֶחָד מִצַּד זֶה. | needs-editor |
| activity.same.bugs.3v3.json | hints.2.caption.0.v | בִּשְׁנֵי הַצְּדָדִים יֵשׁ אוֹתוֹ מִסְפָּר: שָׁלוֹשׁ. | needs-editor |
| activity.same.bugs.3v3.json | a11y.altText | הַאִם יֵשׁ אוֹתוֹ מִסְפָּר בִּשְׁנֵי הַצְּדָדִים? | needs-editor |
| activity.show.apples.3.json | prompt.caption.0.v | אֵיפֹה יֵשׁ שְׁלוֹשָׁה תַּפּוּחִים? | needs-editor |
| activity.show.apples.3.json | answer.options.0.label | שְׁנֵי תַּפּוּחִים | needs-editor |
| activity.show.apples.3.json | answer.options.1.label | שְׁלוֹשָׁה תַּפּוּחִים | needs-editor |
| activity.show.apples.3.json | answer.options.2.label | אַרְבָּעָה תַּפּוּחִים | needs-editor |
| activity.show.apples.3.json | feedback.correct.caption.0.v | כֵּן! זֶה שְׁלוֹשָׁה תַּפּוּחִים. | needs-editor |
| activity.show.apples.3.json | feedback.incorrect.0.caption.0.v | אוּלַי סָפַרְנוּ אֶחָד פַּעֲמַיִם? בּוֹאוּ נִבְדֹּק. | needs-editor |
| activity.show.apples.3.json | feedback.incorrect.1.caption.0.v | אוּלַי פִּסְפַּסְנוּ אֶחָד? בּוֹאוּ נִבְדֹּק. | needs-editor |
| activity.show.apples.3.json | feedback.incorrect.2.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.show.apples.3.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.show.apples.3.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַמִּסְפָּר. | needs-editor |
| activity.show.apples.3.json | hints.1.caption.0.v | נִסְפֹּר עִם הָאֶצְבָּעוֹת: אַחַת, שְׁתַּיִם, שָׁלוֹשׁ. | needs-editor |
| activity.show.apples.3.json | hints.2.caption.0.v | אַחַת, שְׁתַּיִם, שָׁלוֹשׁ. זֶה שְׁלוֹשָׁה תַּפּוּחִים. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל הַנְּכוֹנָה. | needs-editor |
| activity.show.apples.3.json | a11y.altText | אֵיפֹה יֵשׁ שְׁלוֹשָׁה תַּפּוּחִים? | needs-editor |
| activity.show.birds.4.json | prompt.caption.0.v | אֵיפֹה יֵשׁ אַרְבַּע צִפֳּרִים? | needs-editor |
| activity.show.birds.4.json | answer.options.0.label | שָׁלוֹשׁ צִפֳּרִים | needs-editor |
| activity.show.birds.4.json | answer.options.1.label | אַרְבַּע צִפֳּרִים | needs-editor |
| activity.show.birds.4.json | answer.options.2.label | חָמֵשׁ צִפֳּרִים | needs-editor |
| activity.show.birds.4.json | feedback.correct.caption.0.v | כֵּן! זֶה אַרְבַּע צִפֳּרִים. | needs-editor |
| activity.show.birds.4.json | feedback.incorrect.0.caption.0.v | אוּלַי סָפַרְנוּ אֶחָד פַּעֲמַיִם? בּוֹאוּ נִבְדֹּק. | needs-editor |
| activity.show.birds.4.json | feedback.incorrect.1.caption.0.v | אוּלַי פִּסְפַּסְנוּ אֶחָד? בּוֹאוּ נִבְדֹּק. | needs-editor |
| activity.show.birds.4.json | feedback.incorrect.2.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.show.birds.4.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.show.birds.4.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַמִּסְפָּר. | needs-editor |
| activity.show.birds.4.json | hints.1.caption.0.v | נִסְפֹּר עִם הָאֶצְבָּעוֹת: אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע. | needs-editor |
| activity.show.birds.4.json | hints.2.caption.0.v | אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע. זֶה אַרְבַּע צִפֳּרִים. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל הַנְּכוֹנָה. | needs-editor |
| activity.show.birds.4.json | a11y.altText | אֵיפֹה יֵשׁ אַרְבַּע צִפֳּרִים? | needs-editor |
| activity.show.stars.5.json | prompt.caption.0.v | אֵיפֹה יֵשׁ חֲמִשָּׁה כּוֹכָבִים? | needs-editor |
| activity.show.stars.5.json | answer.options.0.label | שְׁלוֹשָׁה כּוֹכָבִים | needs-editor |
| activity.show.stars.5.json | answer.options.1.label | אַרְבָּעָה כּוֹכָבִים | needs-editor |
| activity.show.stars.5.json | answer.options.2.label | חֲמִשָּׁה כּוֹכָבִים | needs-editor |
| activity.show.stars.5.json | feedback.correct.caption.0.v | כֵּן! זֶה חֲמִשָּׁה כּוֹכָבִים. | needs-editor |
| activity.show.stars.5.json | feedback.incorrect.0.caption.0.v | אוּלַי פִּסְפַּסְנוּ אֶחָד? בּוֹאוּ נִבְדֹּק. | needs-editor |
| activity.show.stars.5.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.show.stars.5.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.show.stars.5.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַמִּסְפָּר. | needs-editor |
| activity.show.stars.5.json | hints.1.caption.0.v | נִסְפֹּר עִם הָאֶצְבָּעוֹת: אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע, חָמֵשׁ. | needs-editor |
| activity.show.stars.5.json | hints.2.caption.0.v | אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע, חָמֵשׁ. זֶה חֲמִשָּׁה כּוֹכָבִים. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל הַנְּכוֹנָה. | needs-editor |
| activity.show.stars.5.json | a11y.altText | אֵיפֹה יֵשׁ חֲמִשָּׁה כּוֹכָבִים? | needs-editor |
| activity.zero.basket.json | prompt.caption.0.v | כַּמָּה תַּפּוּחִים בַּסַּל? | needs-editor |
| activity.zero.basket.json | answer.options.0.label | אֶפֶס | needs-editor |
| activity.zero.basket.json | answer.options.1.label | אַחַת | needs-editor |
| activity.zero.basket.json | answer.options.2.label | שָׁלוֹשׁ | needs-editor |
| activity.zero.basket.json | feedback.correct.caption.0.v | אֶפֶס! אֵין אַף תַּפּוּחַ. | needs-editor |
| activity.zero.basket.json | feedback.incorrect.0.caption.0.v | גַּם אֶפֶס הוּא מִסְפָּר: כְּשֶׁאֵין כְּלוּם, יֵשׁ אֶפֶס. | needs-editor |
| activity.zero.basket.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.zero.basket.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.zero.basket.json | hints.0.caption.0.v | בּוֹאוּ נִסְתַּכֵּל שׁוּב. | needs-editor |
| activity.zero.basket.json | hints.1.caption.0.v | נִסְפֹּר עִם הָאֶצְבָּעוֹת: אֵין כְּלוּם לִסְפֹּר. | needs-editor |
| activity.zero.basket.json | hints.2.caption.0.v | אֵין אַף תַּפּוּחַ. כְּשֶׁאֵין כְּלוּם, הַמִּסְפָּר הוּא אֶפֶס. עַכְשָׁו תּוֹרְכֶם. | needs-editor |
| activity.zero.basket.json | a11y.altText | כַּמָּה תַּפּוּחִים בַּסַּל? | needs-editor |
| activity.zero.bowl.json | prompt.caption.0.v | כַּמָּה דָּגִים בַּקְעָרָה? | needs-editor |
| activity.zero.bowl.json | answer.options.0.label | אֶפֶס | needs-editor |
| activity.zero.bowl.json | answer.options.1.label | אַחַת | needs-editor |
| activity.zero.bowl.json | answer.options.2.label | שְׁתַּיִם | needs-editor |
| activity.zero.bowl.json | feedback.correct.caption.0.v | אֶפֶס! אֵין אַף דָּג. | needs-editor |
| activity.zero.bowl.json | feedback.incorrect.0.caption.0.v | גַּם אֶפֶס הוּא מִסְפָּר: כְּשֶׁאֵין כְּלוּם, יֵשׁ אֶפֶס. | needs-editor |
| activity.zero.bowl.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.zero.bowl.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.zero.bowl.json | hints.0.caption.0.v | בּוֹאוּ נִסְתַּכֵּל שׁוּב. | needs-editor |
| activity.zero.bowl.json | hints.1.caption.0.v | נִסְפֹּר עִם הָאֶצְבָּעוֹת: אֵין כְּלוּם לִסְפֹּר. | needs-editor |
| activity.zero.bowl.json | hints.2.caption.0.v | אֵין אַף דָּג. כְּשֶׁאֵין כְּלוּם, הַמִּסְפָּר הוּא אֶפֶס. עַכְשָׁו תּוֹרְכֶם. | needs-editor |
| activity.zero.bowl.json | a11y.altText | כַּמָּה דָּגִים בַּקְעָרָה? | needs-editor |
| activity.zero.nest.json | prompt.caption.0.v | כַּמָּה צִפֳּרִים בַּקֵּן? | needs-editor |
| activity.zero.nest.json | answer.options.0.label | אֶפֶס | needs-editor |
| activity.zero.nest.json | answer.options.1.label | אַחַת | needs-editor |
| activity.zero.nest.json | answer.options.2.label | שְׁתַּיִם | needs-editor |
| activity.zero.nest.json | feedback.correct.caption.0.v | אֶפֶס! אֵין אַף צִפּוֹר. | needs-editor |
| activity.zero.nest.json | feedback.incorrect.0.caption.0.v | גַּם אֶפֶס הוּא מִסְפָּר: כְּשֶׁאֵין כְּלוּם, יֵשׁ אֶפֶס. | needs-editor |
| activity.zero.nest.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.zero.nest.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.zero.nest.json | hints.0.caption.0.v | בּוֹאוּ נִסְתַּכֵּל שׁוּב. | needs-editor |
| activity.zero.nest.json | hints.1.caption.0.v | נִסְפֹּר עִם הָאֶצְבָּעוֹת: אֵין כְּלוּם לִסְפֹּר. | needs-editor |
| activity.zero.nest.json | hints.2.caption.0.v | אֵין אַף צִפּוֹר. כְּשֶׁאֵין כְּלוּם, הַמִּסְפָּר הוּא אֶפֶס. עַכְשָׁו תּוֹרְכֶם. | needs-editor |
| activity.zero.nest.json | a11y.altText | כַּמָּה צִפֳּרִים בַּקֵּן? | needs-editor |
| lesson.butterflies.json | title.0.v | פַּרְפָּרִים בַּגִּנָּה | needs-editor |
| lesson.butterflies.json | celebration.caption.0.v | כׇּל הַכָּבוֹד! סְפַרְתֶּם לְאַט וּבְדַקְתֶּם כׇּל פַּרְפָּר. | needs-editor |
| lesson.count-to-ten.json | title.0.v | סוֹפְרִים עַד עֶשֶׂר | needs-editor |
| lesson.count-to-ten.json | celebration.caption.0.v | וַאוּ! סְפַרְתֶּם עַד עֶשֶׂר. | needs-editor |
| lesson.counting-words.json | title.0.v | סוֹפְרִים לְפִי הַסֵּדֶר | needs-editor |
| lesson.counting-words.json | celebration.caption.0.v | כׇּל הַכָּבוֹד! סְפַרְתֶּם לְפִי הַסֵּדֶר. | needs-editor |
| lesson.find-the-number.json | title.0.v | מוֹצְאִים אֶת הַמִּסְפָּר | needs-editor |
| lesson.find-the-number.json | celebration.caption.0.v | יָפֶה מְאֹד! הִכַּרְתֶּם אֶת הַמִּסְפָּרִים. | needs-editor |
| lesson.giving.json | title.0.v | נוֹתְנִים בְּדִיּוּק | needs-editor |
| lesson.giving.json | celebration.caption.0.v | כׇּל הַכָּבוֹד! נְתַתֶּם בְּדִיּוּק כַּמָּה שֶׁבִּקְשׁוּ. | needs-editor |
| lesson.glance-more.json | title.0.v | רוֹאִים אַרְבַּע וְחָמֵשׁ | needs-editor |
| lesson.glance-more.json | celebration.caption.0.v | מַדְהִים! רְאִיתֶם אַרְבַּע וְחָמֵשׁ בְּמַבָּט אֶחָד. | needs-editor |
| lesson.glance-small.json | title.0.v | רוֹאִים בְּמַבָּט אֶחָד | needs-editor |
| lesson.glance-small.json | celebration.caption.0.v | וַאוּ! רְאִיתֶם כַּמָּה בְּלִי לִסְפֹּר. | needs-editor |
| lesson.more-or-less.json | title.0.v | יוֹתֵר אוֹ פָּחוֹת | needs-editor |
| lesson.more-or-less.json | celebration.caption.0.v | כׇּל הַכָּבוֹד! יְדַעְתֶּם אֵיפֹה יוֹתֵר וְאֵיפֹה פָּחוֹת. | needs-editor |
| lesson.nothing-there.json | title.0.v | אֵין כְּלוּם | needs-editor |
| lesson.nothing-there.json | celebration.caption.0.v | יָפֶה מְאֹד! אֵין כְּלוּם זֶה אֶפֶס. | needs-editor |
| lesson.numbers-and-things.json | title.0.v | מִסְפָּרִים וְדְּבָרִים | needs-editor |
| lesson.numbers-and-things.json | celebration.caption.0.v | כׇּל הַכָּבוֹד! מָצָאתֶם אֶת הַמִּסְפָּר הַנָּכוֹן. | needs-editor |
| lesson.tricky-sizes.json | title.0.v | לֹא לְפִי הַגֹּדֶל | needs-editor |
| lesson.tricky-sizes.json | celebration.caption.0.v | חֲכָמִים! סְפַרְתֶּם וְלֹא הִסְתַּכַּלְתֶּם עַל הַגֹּדֶל. | needs-editor |
| lesson.who-is-first.json | title.0.v | מִי רִאשׁוֹן בַּתּוֹר? | needs-editor |
| lesson.who-is-first.json | celebration.caption.0.v | כׇּל הַכָּבוֹד! יְדַעְתֶּם מִי רִאשׁוֹן, שֵׁנִי וּשְׁלִישִׁי. | needs-editor |
| misconception.M-CNT-CARD.json | parentText | הילד סופר שוב במקום לומר כמה יש בסך הכול, או נותן את כל העצמים כשמבקשים מספר מסוים. | needs-editor |
| misconception.M-CNT-CARD.json | homeActivity.0.v | בארוחה, לבקש מהילד להגיש שלושה פירות ולספור אותם בקול. אחרי הספירה לשאול: כמה יש בסך הכול? בלי לתקן, רק לספור שוב יחד. | needs-editor |
| misconception.M-CNT-DOUBLE.json | parentText | הילד סופר עצם אחד פעמיים ולכן מקבל מספר גדול מדי. | needs-editor |
| misconception.M-CNT-DOUBLE.json | homeActivity.0.v | לסדר חמש כוסות בשורה ולבקש מהילד להזיז כוס אחת הצידה בכל פעם שהוא סופר אותה, כך שאי אפשר לספור אותה פעמיים. | needs-editor |
| misconception.M-CNT-SEQ.json | parentText | הילד מדלג על מילות ספירה או אומר אותן שלא לפי הסדר. | needs-editor |
| misconception.M-CNT-SEQ.json | homeActivity.0.v | לשיר יחד שיר ספירה, או לעלות במדרגות ולספור כל מדרגה בקול. חמש דקות מספיקות, בלי לתקן, רק לחזור שוב. | needs-editor |
| misconception.M-CNT-SIZE.json | parentText | הילד שופט מי יותר לפי הגודל או הפיזור של העצמים ולא לפי המספר. | needs-editor |
| misconception.M-CNT-SIZE.json | homeActivity.0.v | להניח על השולחן שתי קבוצות של כפיות: שלוש רחוקות זו מזו וחמש צפופות. לשאול איפה יש יותר, ואז לסדר זוגות, כפית מול כפית, ולראות יחד. | needs-editor |
| misconception.M-CNT-SKIP.json | parentText | הילד מפספס עצם אחד בספירה ולכן מקבל מספר קטן מדי. | needs-editor |
| misconception.M-CNT-SKIP.json | homeActivity.0.v | לשים צעצועים במעגל ולסמן את הראשון בכובע, כדי לדעת איפה הספירה מתחילה ונגמרת. לספור יחד ולגעת בכל אחד פעם אחת. | needs-editor |
| misconception.M-NUM-ZERO.json | parentText | הילד חושב שאפס הוא לא מספר, ואומר 'אחת' או 'כלום' כשאין עצמים. | needs-editor |
| misconception.M-NUM-ZERO.json | homeActivity.0.v | להראות קערה ריקה ולשאול כמה תפוחים יש בה. לתת לילד להגיד 'אפס', ואז להכניס תפוח ולשאול שוב. | needs-editor |
| misconception.M-ORD-CARD.json | parentText | הילד מבלבל בין 'השלישי' בתור לבין 'שלושה' ילדים. | needs-editor |
| misconception.M-ORD-CARD.json | homeActivity.0.v | לעמוד בתור עם בובות: מי הראשון, מי השני, מי האחרון? להחליף את המקומות ולשאול שוב. | needs-editor |
| skill.COL-A-02.json | title.0.v | מצביעים על אדום, כחול, צהוב וירוק כששומעים את שמם | needs-editor |
| skill.COL-A-02.json | childLine.0.v | מַצְבִּיעִים עַל אָדֹם, כָּחֹל, צָהֹב וְיָרֹק | needs-editor |
| skill.NUM-A-01.json | title.0.v | אומרים את מילות הספירה 1–5 לפי הסדר | needs-editor |
| skill.NUM-A-01.json | childLine.0.v | סוֹפְרִים עַד חָמֵשׁ, לְפִי הַסֵּדֶר | needs-editor |
| skill.NUM-A-02.json | title.0.v | אומרים את מילות הספירה 1–10 לפי הסדר | needs-editor |
| skill.NUM-A-02.json | childLine.0.v | סוֹפְרִים עַד עֶשֶׂר, לְפִי הַסֵּדֶר | needs-editor |
| skill.NUM-A-03.json | title.0.v | נוגעים בכל עצם פעם אחת בזמן הספירה (עד 5) | needs-editor |
| skill.NUM-A-03.json | childLine.0.v | נוֹגְעִים בְּכָל אֶחָד פַּעַם אַחַת כְּשֶׁסּוֹפְרִים | needs-editor |
| skill.NUM-A-04.json | title.0.v | עונים כמה יש לפי המספר האחרון שנספר (עד 5) | needs-editor |
| skill.NUM-A-04.json | childLine.0.v | יוֹדְעִים כַּמָּה יֵשׁ: הַמִּסְפָּר הָאַחֲרוֹן שֶׁסָּפַרְנוּ | needs-editor |
| skill.NUM-A-05.json | title.0.v | מזהים 1–3 במבט אחד בלי לספור | needs-editor |
| skill.NUM-A-05.json | childLine.0.v | רוֹאִים כַּמָּה בְּמַבָּט אֶחָד | needs-editor |
| skill.NUM-A-06.json | title.0.v | מוציאים כמות מבוקשת (עד 5) מערימה גדולה יותר | needs-editor |
| skill.NUM-A-06.json | childLine.0.v | נוֹתְנִים בְּדִיּוּק כַּמָּה שֶׁבִּקְשׁוּ | needs-editor |
| skill.NUM-A-07.json | title.0.v | מתאימים מספרים 1–5 לכמויות | needs-editor |
| skill.NUM-A-07.json | childLine.0.v | מַתְאִימִים מִסְפָּר לַכַּמּוּת | needs-editor |
| skill.NUM-A-08.json | title.0.v | בוחרים את הספרה 1–5 כשאומרים אותה | needs-editor |
| skill.NUM-A-08.json | childLine.0.v | מוֹצְאִים אֶת הַמִּסְפָּר שֶׁאוֹמְרִים | needs-editor |
| skill.NUM-A-09.json | title.0.v | סופרים 6–10 עצמים | needs-editor |
| skill.NUM-A-09.json | childLine.0.v | סוֹפְרִים עַד עֶשֶׂר | needs-editor |
| skill.NUM-A-10.json | title.0.v | מזהים 4–5 בקובייה ובמסגרת עשר במבט אחד | needs-editor |
| skill.NUM-A-10.json | childLine.0.v | רוֹאִים אַרְבַּע וְחָמֵשׁ בְּמַבָּט אֶחָד | needs-editor |
| skill.NUM-A-11.json | title.0.v | משווים שתי קבוצות עד 5: יותר, פחות, אותו דבר | needs-editor |
| skill.NUM-A-11.json | childLine.0.v | יוֹדְעִים אֵיפֹה יוֹתֵר וְאֵיפֹה פָּחוֹת | needs-editor |
| skill.NUM-A-12.json | title.0.v | משווים לפי המספר גם כשהעצמים גדולים או צפופים | needs-editor |
| skill.NUM-A-12.json | childLine.0.v | סוֹפְרִים כְּדֵי לְהַשְׁוֹת, לֹא מִסְתַּכְּלִים עַל הַגֹּדֶל | needs-editor |
| skill.NUM-A-13.json | title.0.v | משתמשים ב'ראשון', 'שני', 'שלישי' ו'אחרון' | needs-editor |
| skill.NUM-A-13.json | childLine.0.v | יוֹדְעִים מִי רִאשׁוֹן, שֵׁנִי, שְׁלִישִׁי וְאַחֲרוֹן | needs-editor |
| skill.NUM-A-14.json | title.0.v | יודעים ש'אין כלום' הוא אפס | needs-editor |
| skill.NUM-A-14.json | childLine.0.v | יוֹדְעִים שֶׁאֵין כְּלוּם זֶה אֶפֶס | needs-editor |

## 4. Reviewed helper (tutor) lines

| Source | Id | Text | Status |
|---|---|---|---|
| hero-son.json | count.butterflies.3 / mistake default / hint 0 / band A | נספר יחד, נגע בכל פרפר פעם אחת. | approved |
| hero-son.json | count.butterflies.3 / mistake M-CNT-SKIP / hint 2 / band A | נספר יחד, נוגעים בכל פרפר פעם אחת. | approved |
| hero-son.json | count.butterflies.3 / mistake default / hint 0 / band A | בוא נסה להצביע על כל פרפר באצבע אחת. | approved |
| hero-son.json | count.butterflies.3 / mistake M-CNT-DOUBLE / hint 2 / band A | בואו נספור לאט, נוגעים בכל פרפר פעם אחת. | approved |
| hero-son.json | count.butterflies.3 / mistake M-CNT-SKIP / hint 2 / band A | בואו נספר לאט, נוגעים בכל פרפר פעם אחת. | approved |
| hero-son.json | count.butterflies.3 / mistake default / hint 0 / band B | בואי נסתכל שוב על הפרפרים, נספור לאט. | approved |
| hero-son.json | count.butterflies.3 / mistake M-CNT-SKIP / hint 2 / band B | נסי לגעת בכל פרפר פעם אחת, אולי יש פרפר שעוד לא ספרנו. | approved |
| hero-son.json | count.butterflies.3 / mistake default / hint 0 / band B | נסה לגעת בכל פרפר פעם אחת, לאט לאט. | approved |
| hero-son.json | count.butterflies.3 / mistake M-CNT-DOUBLE / hint 2 / band B | נספר יחד, נגע בכל פרפר פעם אחת ונאמר מספר לכל אחד. | approved |
| hero-son.json | count.butterflies.3 / mistake default / hint 0 / band B | בואו ננסה ביחד, נגע בפרפר אחד בכל פעם. | approved |
| hero-son.json | count.butterflies.3 / mistake M-CNT-DOUBLE / hint 2 / band B | בואו נספור לאט, נוגעים בפרפר ואומרים מספר, ואז ממשיכים. | approved |
| hero-son.json | count.butterflies.3 / mistake default / hint 0 / band C | נסי לגעת בכל פרפר פעם אחת, בואי נספר יחד. | approved |
| hero-son.json | count.butterflies.3 / mistake M-CNT-DOUBLE / hint 2 / band C | נסי לגעת בכל פרפר פעם אחת, ואז נספור ביחד. | approved |
| hero-son.json | count.butterflies.3 / mistake M-CNT-SKIP / hint 2 / band C | נסי לגעת בכל פרפר פעם אחת, אולי יש פרפר שעוד לא ספרנו. | approved |
| hero-son.json | count.butterflies.3 / mistake default / hint 0 / band C | בוא נסה לספור לאט, נוגעים בכל פרפר פעם אחת. | approved |
| hero-son.json | count.butterflies.3 / mistake M-CNT-SKIP / hint 2 / band C | בואו נספר לאט ונגע בכל פרפר פעם אחת, ונראה אם אחד נשאר בלי מספר. | approved |
| hero-son.json | count.butterflies.4 / mistake default / hint 0 / band A | נספר יחד, נגע בכל פרפר פעם אחת. | approved |
| hero-son.json | count.butterflies.4 / mistake M-CNT-DOUBLE / hint 2 / band A | נסי לגעת בכל פרפר פעם אחת, ואז נספר ביחד. | approved |
| hero-son.json | count.butterflies.4 / mistake M-CNT-SKIP / hint 2 / band A | נספר שוב, אולי יש פרפר שלא ספרנו עדיין. | approved |
| hero-son.json | count.butterflies.4 / mistake M-CNT-SKIP / hint 2 / band A | נסה לגעת בכל פרפר פעם אחת, ואז נספר שוב. | approved |
| hero-son.json | count.butterflies.4 / mistake default / hint 0 / band A | בואו נספר יחד, אחד אחד, בלי לדלג. | approved |
| hero-son.json | count.butterflies.4 / mistake M-CNT-SKIP / hint 2 / band A | בואו נספר לאט ונגע בכל פרפר פעם אחת. | approved |
| hero-son.json | count.butterflies.4 / mistake M-CNT-SKIP / hint 2 / band B | נסי לגעת בכל פרפר פעם אחת, ואז נספר ביחד. | approved |
| hero-son.json | count.butterflies.4 / mistake default / hint 0 / band B | בוא נסה לגעת בכל פרפר אחד אחד ולספור בשקט. | approved |
| hero-son.json | count.butterflies.4 / mistake M-CNT-SKIP / hint 2 / band B | בוא נגע בכל פרפר פעם אחת, ואז נספור שוב. | approved |
| hero-son.json | count.butterflies.4 / mistake default / hint 0 / band B | בואו נספור יחד, פרפר אחד בכל פעם. | approved |
| hero-son.json | count.butterflies.4 / mistake M-CNT-DOUBLE / hint 2 / band B | בואו נספר לאט, נגע בכל פרפר פעם אחת. | approved |
| hero-son.json | count.butterflies.4 / mistake M-CNT-SKIP / hint 2 / band B | בואו נספר לאט, נגע בכל פרפר פעם אחת. | approved |
| hero-son.json | count.butterflies.4 / mistake default / hint 0 / band C | נסי לגעת בכל פרפר פעם אחת, לאט לאט, ונספר יחד. | approved |
| hero-son.json | count.butterflies.4 / mistake M-CNT-SKIP / hint 2 / band C | נסי לגעת בכל פרפר פעם אחת, ואולי יש פרפר שעוד לא ספרנו. | approved |
| hero-son.json | count.butterflies.4 / mistake default / hint 0 / band C | בוא נספר שוב, נגע בכל פרפר פעם אחת בלבד ואז נאמר את המספר. | approved |
| hero-son.json | count.butterflies.4 / mistake default / hint 0 / band C | בואו נספר יחד, פרפר אחד בכל פעם. | approved |
| hero-son.json | count.butterflies.4 / mistake M-CNT-SKIP / hint 2 / band C | בואו נספר לאט, נגע בכל פרפר פעם אחת. | approved |
| hero-son.json | count.butterflies.5 / mistake default / hint 0 / band A | נסי לגעת בכל פרפר פעם אחת, לאט. | approved |
| hero-son.json | count.butterflies.5 / mistake M-CNT-DOUBLE / hint 2 / band A | נספור יחד, נגע בכל פרפר פעם אחת בלבד. | approved |
| hero-son.json | count.butterflies.5 / mistake default / hint 0 / band A | בוא נסה להצביע עם אצבע על כל פרפר פעם אחת. | approved |
| hero-son.json | count.butterflies.5 / mistake M-CNT-SKIP / hint 2 / band A | בוא נגע בכל פרפר פעם אחת, ונספר שוב. | approved |
| hero-son.json | count.butterflies.5 / mistake default / hint 0 / band A | בואו נספר יחד, פרפר אחד בכל פעם. | approved |
| hero-son.json | count.butterflies.5 / mistake M-CNT-DOUBLE / hint 2 / band A | בואו נספר לאט, נגע בכל פרפר פעם אחת. | approved |
| hero-son.json | count.butterflies.5 / mistake M-CNT-SKIP / hint 2 / band A | בואו נספר לאט ונגע בכל פרפר פעם אחת. | approved |
| hero-son.json | count.butterflies.5 / mistake default / hint 0 / band B | נסי לגעת בכל פרפר פעם אחת, לאט לאט. | approved |
| hero-son.json | count.butterflies.5 / mistake M-CNT-DOUBLE / hint 2 / band B | נסי לגעת בכל פרפר פעם אחת, ונספר יחד בשקט. | approved |
| hero-son.json | count.butterflies.5 / mistake M-CNT-SKIP / hint 2 / band B | נסי לגעת בכל פרפר פעם אחת, ואולי יש פרפר שלא נספר. | approved |
| hero-son.json | count.butterflies.5 / mistake default / hint 0 / band B | בוא נסה לספור כל פרפר פעם אחת, עם האצבע. | approved |
| hero-son.json | count.butterflies.5 / mistake M-CNT-SKIP / hint 2 / band B | בוא נגע בכל פרפר פעם אחת, ואז נספר שוב. | approved |
| hero-son.json | count.butterflies.5 / mistake default / hint 0 / band B | בואו נספור יחד, פרפר אחד בכל פעם. | approved |
| hero-son.json | count.butterflies.5 / mistake M-CNT-DOUBLE / hint 2 / band B | בואו נספר לאט, פרפר אחד, ואז נזיז לפרפר הבא. | approved |
| hero-son.json | count.butterflies.5 / mistake M-CNT-SKIP / hint 2 / band B | בואו נספר לאט, ונגע בכל פרפר פעם אחת. | approved |
| hero-son.json | count.butterflies.5 / mistake M-CNT-SKIP / hint 2 / band C | נסי לגעת בכל פרפר פעם אחת, ותראי אם יש פרפר אחד שלא נספר. | approved |
| hero-son.json | count.butterflies.5 / mistake M-CNT-DOUBLE / hint 2 / band C | נספר יחד, נגע בפרפר אחד בכל פעם ונגיד מספר רק כשנגיע לפרפר חדש. | approved |
| hero-son.json | count.butterflies.5 / mistake default / hint 0 / band C | בואו נספר יחד, נגע בכל פרפר פעם אחת. | approved |
| hero-son.json | count.butterflies.5 / mistake M-CNT-DOUBLE / hint 2 / band C | בואו נספר לאט, נגע בכל פרפר פעם אחת ונגיד מספר. | approved |
| hero-son.json | count.butterflies.5 / mistake M-CNT-SKIP / hint 2 / band C | בואו נספר לאט, נגע בכל פרפר פעם אחת, ונראה אם יש פרפר שלא ספרנו. | approved |
| hero-son.json | give.butterflies.4 / mistake default / hint 0 / band A | נסי לתת לפרח ארבעה פרפרים, אחד אחד. | approved |
| hero-son.json | give.butterflies.4 / mistake default / hint 0 / band A | בוא ננסה שוב, נצביע על כל פרפר אחד אחד. | approved |
| hero-son.json | give.butterflies.4 / mistake M-CNT-CARD / hint 2 / band A | בוא נספור פרפרים אחד אחד, ונעצור בארבעה. | approved |
| hero-son.json | give.butterflies.4 / mistake default / hint 0 / band A | בואו נתחיל ביחד, אחד אחד. | approved |
| hero-son.json | give.butterflies.4 / mistake M-CNT-CARD / hint 2 / band A | בואו נתן פרפר אחד, ואז נספור עוד. | approved |
| hero-son.json | give.butterflies.4 / mistake default / hint 0 / band B | בוא נתן לפרח ארבעה פרפרים, נצביע על כל אחד ונספר בשקט. | approved |
| hero-son.json | give.butterflies.4 / mistake M-CNT-CARD / hint 2 / band B | בוא נספור פרפרים אחד אחד, ונעצור כשנגיע לארבעה. | approved |
| hero-son.json | give.butterflies.4 / mistake default / hint 0 / band B | בואו נתן פרפר אחד בכל פעם, ביחד. | approved |
| hero-son.json | give.butterflies.4 / mistake M-CNT-CARD / hint 2 / band B | בואו נתן פרפר אחד בכל פעם ונעצור בארבעה. | approved |
| hero-son.json | give.butterflies.4 / mistake default / hint 0 / band C | בואי נסי שוב לאט, נספר את הפרפרים אחד אחד. | approved |
| hero-son.json | give.butterflies.4 / mistake default / hint 0 / band C | בוא נסה להצביע על כל פרפר אחד אחד, ולעצור אחרי ארבעה. | approved |
| hero-son.json | give.butterflies.4 / mistake default / hint 0 / band C | בואו ניקח פרפר אחד בכל פעם, נספר יחד. | approved |
| hero-son.json | give.butterflies.4 / mistake M-CNT-CARD / hint 2 / band C | בואו נספר ביחד ונתן לפרח ארבעה פרפרים בלבד, לא יותר. | approved |

## 5. Alert word lists (for an editor and someone who works with children)

Source: `app/lib/speech/alert_words.dart`. One word per entry.

אני לבד בבית · אני רוצה למות · זונה · זין · חרא · לא רוצה לחיות · מאיים עלי · מאיימים עלי · מזדיין · מזדיינת · מכה אותי · מכים אותי · מניאק · מפחידים אותי · מרביץ לי · מרביצה לי · מרביצים לי · נגעו בי · נוגעים בי · פוחד לחזור הביתה · פוחדת לחזור הביתה · שרמוטה · תזדיין

## 6. Helper lexicon (the words the AI helper may use)

Source: `app/lib/speech/lexicon.dart`. One word per entry.

אדום · אדומה · אדומות · אדומים · אחד · אחת · אני לא יודע · אני לא יודעת · אני רוצה לעצור · אפס · אפשר שוב · ארבע · ארבעה · ארבעת · בטח · ברור · די · ורוד · ורודה · ורודות · ורודים · חום · חומה · חומות · חומים · חמישה · חמש · חמשת · טעות · ירוק · ירוקה · ירוקות · ירוקים · כחול · כחולה · כחולות · כחולים · כחלחל · כן · כן כן · כתום · כתומה · כתומות · כתומים · כתמתם · לא · לא בטוח · לא בטוחה · לא יודע · לא יודעת · לא לא · לא נכון · לבן · לבנה · לבנות · לבנים · מה · מספיק · נכון · סגול · סגולה · סגולות · סגולים · סגלגל · עוד פעם · עוד פעם בבקשה · עזור לי · עזרה · עזרי לי · עצור · עשר · עשרה · עשרים · עשרת · צהוב · צהובה · צהובות · צהובים · שבע · שבעה · שבעת · שוב · שחור · שחורה · שחורות · שחורים · שישה · שלוש · שלושה · שלושת · שמונה · שמונת · שני · שניים · שנים · שנים עשר · שש · ששת · שתי · שתיים · שתים · שתים עשרה · תכלת · תעזור לי · תעזרי לי · תפסיק · תפסיקי · תשע · תשעה · תשעת
