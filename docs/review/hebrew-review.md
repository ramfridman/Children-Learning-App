# Hebrew texts waiting for review

Made by `tools/export-hebrew-review.py` on 2026-10-28 from the repository as it is now (M8 merged). Every text below is a draft written by Claude. Nothing is approved until you say so.

How to review: open `hebrew-review.csv` in Excel or Google Sheets, write a fix in **correction** (leave it empty if the text is fine) and notes in **comment**, then send the file back. Claude applies the fixes, marks the texts approved and voices again only the lines that changed (the cost is shown first, as always).

What to look at: spelling and niqqud; grammar and agreement (plural, neutral, no line says the child's name or the speaker's gender); a word a 3 to 8 year old knows; sentences short enough to say in one breath; nothing that scolds, frightens or compares.

| Group | Texts |
|---|---|
| 1. App screens and buttons | 311 |
| 2. Core voice lines (spoken by every friend) | 27 |
| 3. Lesson content (skills, activities, misconceptions) | 2241 |
| 4. Reviewed helper (tutor) lines | 66 |
| 5. Alert word lists (for an editor and someone who works with children) | 23 |
| 6. Helper lexicon (the words the AI helper may use) | 110 |
| **Total** | **2778** |

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
| app/lib/strings/he.dart | placementDone | יָפֶה מְאֹד! עַכְשָׁו נֵדַע מֵאֵיפֹה לְהַתְחִיל. | needs-editor |
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
| app/lib/strings/he.dart | warmUpHeading | משחק היכרות | needs-editor |
| app/lib/strings/he.dart | warmUpHelp | בביקור הראשון בכל אי, הילד משחק כמה דקות כדי שנתחיל מהמקום הנכון. אין בו ציון ולא טעויות. אפשר לכבות. | needs-editor |
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
| content/lines/core.he.json | core.placement.done | יָפֶה מְאֹד! עַכְשָׁו נֵדַע מֵאֵיפֹה לְהַתְחִיל. | needs-editor |
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
| activity.col.find.blue.ball.json | prompt.caption.0.v | אֵיפֹה הַכַּדּוּר הַכָּחֹל? | needs-editor |
| activity.col.find.blue.ball.json | answer.options.0.label | בָּלוֹן כָּחֹל | needs-editor |
| activity.col.find.blue.ball.json | answer.options.1.label | כַּדּוּר צָהֹב | needs-editor |
| activity.col.find.blue.ball.json | answer.options.2.label | פֶּרַח אָדֹם | needs-editor |
| activity.col.find.blue.ball.json | answer.options.3.label | כַּדּוּר כָּחֹל | needs-editor |
| activity.col.find.blue.ball.json | feedback.correct.caption.0.v | כֵּן! זֶה כַּדּוּר כָּחֹל. | needs-editor |
| activity.col.find.blue.ball.json | feedback.incorrect.0.caption.0.v | יֵשׁ שְׁנֵי דְּבָרִים לִבְדֹּק: מָה זֶה, וְאֵיזֶה צֶבַע. | needs-editor |
| activity.col.find.blue.ball.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.col.find.blue.ball.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.col.find.blue.ball.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.col.find.blue.ball.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.col.find.blue.ball.json | hints.2.caption.0.v | זֶה כַּדּוּר כָּחֹל. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.col.find.blue.ball.json | a11y.altText | אֵיפֹה הַכַּדּוּר הַכָּחֹל? | needs-editor |
| activity.col.find.green.balloon.json | prompt.caption.0.v | אֵיפֹה הַבָּלוֹן הַיָּרֹק? | needs-editor |
| activity.col.find.green.balloon.json | answer.options.0.label | בָּלוֹן יָרֹק | needs-editor |
| activity.col.find.green.balloon.json | answer.options.1.label | כַּדּוּר יָרֹק | needs-editor |
| activity.col.find.green.balloon.json | answer.options.2.label | בָּלוֹן אָדֹם | needs-editor |
| activity.col.find.green.balloon.json | answer.options.3.label | פֶּרַח כָּחֹל | needs-editor |
| activity.col.find.green.balloon.json | feedback.correct.caption.0.v | כֵּן! זֶה בָּלוֹן יָרֹק. | needs-editor |
| activity.col.find.green.balloon.json | feedback.incorrect.0.caption.0.v | יֵשׁ שְׁנֵי דְּבָרִים לִבְדֹּק: מָה זֶה, וְאֵיזֶה צֶבַע. | needs-editor |
| activity.col.find.green.balloon.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.col.find.green.balloon.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.col.find.green.balloon.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.col.find.green.balloon.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.col.find.green.balloon.json | hints.2.caption.0.v | זֶה בָּלוֹן יָרֹק. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.col.find.green.balloon.json | a11y.altText | אֵיפֹה הַבָּלוֹן הַיָּרֹק? | needs-editor |
| activity.col.find.red.balloon.json | prompt.caption.0.v | אֵיפֹה הַבָּלוֹן הָאָדֹם? | needs-editor |
| activity.col.find.red.balloon.json | answer.options.0.label | כַּדּוּר אָדֹם | needs-editor |
| activity.col.find.red.balloon.json | answer.options.1.label | בָּלוֹן כָּחֹל | needs-editor |
| activity.col.find.red.balloon.json | answer.options.2.label | פֶּרַח יָרֹק | needs-editor |
| activity.col.find.red.balloon.json | answer.options.3.label | בָּלוֹן אָדֹם | needs-editor |
| activity.col.find.red.balloon.json | feedback.correct.caption.0.v | כֵּן! זֶה בָּלוֹן אָדֹם. | needs-editor |
| activity.col.find.red.balloon.json | feedback.incorrect.0.caption.0.v | יֵשׁ שְׁנֵי דְּבָרִים לִבְדֹּק: מָה זֶה, וְאֵיזֶה צֶבַע. | needs-editor |
| activity.col.find.red.balloon.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.col.find.red.balloon.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.col.find.red.balloon.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.col.find.red.balloon.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.col.find.red.balloon.json | hints.2.caption.0.v | זֶה בָּלוֹן אָדֹם. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.col.find.red.balloon.json | a11y.altText | אֵיפֹה הַבָּלוֹן הָאָדֹם? | needs-editor |
| activity.col.find.yellow.flower.json | prompt.caption.0.v | אֵיפֹה הַפֶּרַח הַצָּהֹב? | needs-editor |
| activity.col.find.yellow.flower.json | answer.options.0.label | פֶּרַח יָרֹק | needs-editor |
| activity.col.find.yellow.flower.json | answer.options.1.label | בָּלוֹן צָהֹב | needs-editor |
| activity.col.find.yellow.flower.json | answer.options.2.label | כַּדּוּר אָדֹם | needs-editor |
| activity.col.find.yellow.flower.json | answer.options.3.label | פֶּרַח צָהֹב | needs-editor |
| activity.col.find.yellow.flower.json | feedback.correct.caption.0.v | כֵּן! זֶה פֶּרַח צָהֹב. | needs-editor |
| activity.col.find.yellow.flower.json | feedback.incorrect.0.caption.0.v | יֵשׁ שְׁנֵי דְּבָרִים לִבְדֹּק: מָה זֶה, וְאֵיזֶה צֶבַע. | needs-editor |
| activity.col.find.yellow.flower.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.col.find.yellow.flower.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.col.find.yellow.flower.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.col.find.yellow.flower.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.col.find.yellow.flower.json | hints.2.caption.0.v | זֶה פֶּרַח צָהֹב. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.col.find.yellow.flower.json | a11y.altText | אֵיפֹה הַפֶּרַח הַצָּהֹב? | needs-editor |
| activity.col.match.blue.json | prompt.caption.0.v | אֵיפֹה אוֹתוֹ צֶבַע? | needs-editor |
| activity.col.match.blue.json | answer.options.0.label | בָּלוֹן צָהֹב | needs-editor |
| activity.col.match.blue.json | answer.options.1.label | בָּלוֹן אָדֹם | needs-editor |
| activity.col.match.blue.json | answer.options.2.label | בָּלוֹן כָּחֹל | needs-editor |
| activity.col.match.blue.json | feedback.correct.caption.0.v | כֵּן! זֶה בָּלוֹן כָּחֹל. | needs-editor |
| activity.col.match.blue.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.col.match.blue.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.col.match.blue.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.col.match.blue.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.col.match.blue.json | hints.2.caption.0.v | זֶה בָּלוֹן כָּחֹל. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.col.match.blue.json | a11y.altText | אֵיפֹה אוֹתוֹ צֶבַע? | needs-editor |
| activity.col.match.green.json | prompt.caption.0.v | אֵיפֹה אוֹתוֹ צֶבַע? | needs-editor |
| activity.col.match.green.json | answer.options.0.label | כַּדּוּר אָדֹם | needs-editor |
| activity.col.match.green.json | answer.options.1.label | כַּדּוּר צָהֹב | needs-editor |
| activity.col.match.green.json | answer.options.2.label | כַּדּוּר יָרֹק | needs-editor |
| activity.col.match.green.json | feedback.correct.caption.0.v | כֵּן! זֶה כַּדּוּר יָרֹק. | needs-editor |
| activity.col.match.green.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.col.match.green.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.col.match.green.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.col.match.green.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.col.match.green.json | hints.2.caption.0.v | זֶה כַּדּוּר יָרֹק. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.col.match.green.json | a11y.altText | אֵיפֹה אוֹתוֹ צֶבַע? | needs-editor |
| activity.col.match.red.json | prompt.caption.0.v | אֵיפֹה אוֹתוֹ צֶבַע? | needs-editor |
| activity.col.match.red.json | answer.options.0.label | בָּלוֹן יָרֹק | needs-editor |
| activity.col.match.red.json | answer.options.1.label | בָּלוֹן אָדֹם | needs-editor |
| activity.col.match.red.json | answer.options.2.label | בָּלוֹן כָּחֹל | needs-editor |
| activity.col.match.red.json | feedback.correct.caption.0.v | כֵּן! זֶה בָּלוֹן אָדֹם. | needs-editor |
| activity.col.match.red.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.col.match.red.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.col.match.red.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.col.match.red.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.col.match.red.json | hints.2.caption.0.v | זֶה בָּלוֹן אָדֹם. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.col.match.red.json | a11y.altText | אֵיפֹה אוֹתוֹ צֶבַע? | needs-editor |
| activity.col.match.yellow.json | prompt.caption.0.v | אֵיפֹה אוֹתוֹ צֶבַע? | needs-editor |
| activity.col.match.yellow.json | answer.options.0.label | בָּלוֹן יָרֹק | needs-editor |
| activity.col.match.yellow.json | answer.options.1.label | בָּלוֹן צָהֹב | needs-editor |
| activity.col.match.yellow.json | answer.options.2.label | בָּלוֹן כָּחֹל | needs-editor |
| activity.col.match.yellow.json | feedback.correct.caption.0.v | כֵּן! זֶה בָּלוֹן צָהֹב. | needs-editor |
| activity.col.match.yellow.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.col.match.yellow.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.col.match.yellow.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.col.match.yellow.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.col.match.yellow.json | hints.2.caption.0.v | זֶה בָּלוֹן צָהֹב. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.col.match.yellow.json | a11y.altText | אֵיפֹה אוֹתוֹ צֶבַע? | needs-editor |
| activity.col.name.black.json | prompt.caption.0.v | אֵיפֹה הַכַּדּוּר הַשָּׁחֹר? | needs-editor |
| activity.col.name.black.json | answer.options.0.label | כַּדּוּר לָבָן | needs-editor |
| activity.col.name.black.json | answer.options.1.label | כַּדּוּר שָׁחֹר | needs-editor |
| activity.col.name.black.json | answer.options.2.label | כַּדּוּר כָּחֹל | needs-editor |
| activity.col.name.black.json | feedback.correct.caption.0.v | כֵּן! זֶה כַּדּוּר שָׁחֹר. | needs-editor |
| activity.col.name.black.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.col.name.black.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.col.name.black.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.col.name.black.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.col.name.black.json | hints.2.caption.0.v | זֶה כַּדּוּר שָׁחֹר. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.col.name.black.json | a11y.altText | אֵיפֹה הַכַּדּוּר הַשָּׁחֹר? | needs-editor |
| activity.col.name.blue.balloon.json | prompt.caption.0.v | אֵיפֹה הַבָּלוֹן הַכָּחֹל? | needs-editor |
| activity.col.name.blue.balloon.json | answer.options.0.label | בָּלוֹן יָרֹק | needs-editor |
| activity.col.name.blue.balloon.json | answer.options.1.label | בָּלוֹן כָּחֹל | needs-editor |
| activity.col.name.blue.balloon.json | answer.options.2.label | בָּלוֹן אָדֹם | needs-editor |
| activity.col.name.blue.balloon.json | feedback.correct.caption.0.v | כֵּן! זֶה בָּלוֹן כָּחֹל. | needs-editor |
| activity.col.name.blue.balloon.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.col.name.blue.balloon.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.col.name.blue.balloon.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.col.name.blue.balloon.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.col.name.blue.balloon.json | hints.2.caption.0.v | זֶה בָּלוֹן כָּחֹל. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.col.name.blue.balloon.json | a11y.altText | אֵיפֹה הַבָּלוֹן הַכָּחֹל? | needs-editor |
| activity.col.name.brown.json | prompt.caption.0.v | אֵיפֹה הַכַּדּוּר הַחוּם? | needs-editor |
| activity.col.name.brown.json | answer.options.0.label | כַּדּוּר חוּם | needs-editor |
| activity.col.name.brown.json | answer.options.1.label | כַּדּוּר כָּתֹם | needs-editor |
| activity.col.name.brown.json | answer.options.2.label | כַּדּוּר שָׁחֹר | needs-editor |
| activity.col.name.brown.json | feedback.correct.caption.0.v | כֵּן! זֶה כַּדּוּר חוּם. | needs-editor |
| activity.col.name.brown.json | feedback.incorrect.0.caption.0.v | הַצְּבָעִים דּוֹמִים. בּוֹאוּ נִסְתַּכֵּל שׁוּב, לְאַט. | needs-editor |
| activity.col.name.brown.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.col.name.brown.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.col.name.brown.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.col.name.brown.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.col.name.brown.json | hints.2.caption.0.v | זֶה כַּדּוּר חוּם. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.col.name.brown.json | a11y.altText | אֵיפֹה הַכַּדּוּר הַחוּם? | needs-editor |
| activity.col.name.green.ball.json | prompt.caption.0.v | אֵיפֹה הַכַּדּוּר הַיָּרֹק? | needs-editor |
| activity.col.name.green.ball.json | answer.options.0.label | כַּדּוּר אָדֹם | needs-editor |
| activity.col.name.green.ball.json | answer.options.1.label | כַּדּוּר כָּחֹל | needs-editor |
| activity.col.name.green.ball.json | answer.options.2.label | כַּדּוּר יָרֹק | needs-editor |
| activity.col.name.green.ball.json | feedback.correct.caption.0.v | כֵּן! זֶה כַּדּוּר יָרֹק. | needs-editor |
| activity.col.name.green.ball.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.col.name.green.ball.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.col.name.green.ball.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.col.name.green.ball.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.col.name.green.ball.json | hints.2.caption.0.v | זֶה כַּדּוּר יָרֹק. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.col.name.green.ball.json | a11y.altText | אֵיפֹה הַכַּדּוּר הַיָּרֹק? | needs-editor |
| activity.col.name.grey.flower.json | prompt.caption.0.v | אֵיפֹה הַפֶּרַח הָאָפֹר? | needs-editor |
| activity.col.name.grey.flower.json | answer.options.0.label | פֶּרַח חוּם | needs-editor |
| activity.col.name.grey.flower.json | answer.options.1.label | פֶּרַח כָּחֹל | needs-editor |
| activity.col.name.grey.flower.json | answer.options.2.label | פֶּרַח אָפֹר | needs-editor |
| activity.col.name.grey.flower.json | feedback.correct.caption.0.v | כֵּן! זֶה פֶּרַח אָפֹר. | needs-editor |
| activity.col.name.grey.flower.json | feedback.incorrect.0.caption.0.v | הַצְּבָעִים דּוֹמִים. בּוֹאוּ נִסְתַּכֵּל שׁוּב, לְאַט. | needs-editor |
| activity.col.name.grey.flower.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.col.name.grey.flower.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.col.name.grey.flower.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.col.name.grey.flower.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.col.name.grey.flower.json | hints.2.caption.0.v | זֶה פֶּרַח אָפֹר. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.col.name.grey.flower.json | a11y.altText | אֵיפֹה הַפֶּרַח הָאָפֹר? | needs-editor |
| activity.col.name.grey.json | prompt.caption.0.v | אֵיפֹה הַבָּלוֹן הָאָפֹר? | needs-editor |
| activity.col.name.grey.json | answer.options.0.label | בָּלוֹן לָבָן | needs-editor |
| activity.col.name.grey.json | answer.options.1.label | בָּלוֹן אָפֹר | needs-editor |
| activity.col.name.grey.json | answer.options.2.label | בָּלוֹן שָׁחֹר | needs-editor |
| activity.col.name.grey.json | feedback.correct.caption.0.v | כֵּן! זֶה בָּלוֹן אָפֹר. | needs-editor |
| activity.col.name.grey.json | feedback.incorrect.0.caption.0.v | הַצְּבָעִים דּוֹמִים. בּוֹאוּ נִסְתַּכֵּל שׁוּב, לְאַט. | needs-editor |
| activity.col.name.grey.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.col.name.grey.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.col.name.grey.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.col.name.grey.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.col.name.grey.json | hints.2.caption.0.v | זֶה בָּלוֹן אָפֹר. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.col.name.grey.json | a11y.altText | אֵיפֹה הַבָּלוֹן הָאָפֹר? | needs-editor |
| activity.col.name.orange.json | prompt.caption.0.v | אֵיפֹה הַכַּדּוּר הַכָּתֹם? | needs-editor |
| activity.col.name.orange.json | answer.options.0.label | כַּדּוּר אָדֹם | needs-editor |
| activity.col.name.orange.json | answer.options.1.label | כַּדּוּר כָּתֹם | needs-editor |
| activity.col.name.orange.json | answer.options.2.label | כַּדּוּר צָהֹב | needs-editor |
| activity.col.name.orange.json | feedback.correct.caption.0.v | כֵּן! זֶה כַּדּוּר כָּתֹם. | needs-editor |
| activity.col.name.orange.json | feedback.incorrect.0.caption.0.v | הַצְּבָעִים דּוֹמִים. בּוֹאוּ נִסְתַּכֵּל שׁוּב, לְאַט. | needs-editor |
| activity.col.name.orange.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.col.name.orange.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.col.name.orange.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.col.name.orange.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.col.name.orange.json | hints.2.caption.0.v | זֶה כַּדּוּר כָּתֹם. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.col.name.orange.json | a11y.altText | אֵיפֹה הַכַּדּוּר הַכָּתֹם? | needs-editor |
| activity.col.name.pink.json | prompt.caption.0.v | אֵיפֹה הַפֶּרַח הַוָּרֹד? | needs-editor |
| activity.col.name.pink.json | answer.options.0.label | פֶּרַח אָדֹם | needs-editor |
| activity.col.name.pink.json | answer.options.1.label | פֶּרַח וָרֹד | needs-editor |
| activity.col.name.pink.json | answer.options.2.label | פֶּרַח סָגֹל | needs-editor |
| activity.col.name.pink.json | feedback.correct.caption.0.v | כֵּן! זֶה פֶּרַח וָרֹד. | needs-editor |
| activity.col.name.pink.json | feedback.incorrect.0.caption.0.v | הַצְּבָעִים דּוֹמִים. בּוֹאוּ נִסְתַּכֵּל שׁוּב, לְאַט. | needs-editor |
| activity.col.name.pink.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.col.name.pink.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.col.name.pink.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.col.name.pink.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.col.name.pink.json | hints.2.caption.0.v | זֶה פֶּרַח וָרֹד. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.col.name.pink.json | a11y.altText | אֵיפֹה הַפֶּרַח הַוָּרֹד? | needs-editor |
| activity.col.name.purple.json | prompt.caption.0.v | אֵיפֹה הַבָּלוֹן הַסָּגֹל? | needs-editor |
| activity.col.name.purple.json | answer.options.0.label | בָּלוֹן כָּחֹל | needs-editor |
| activity.col.name.purple.json | answer.options.1.label | בָּלוֹן וָרֹד | needs-editor |
| activity.col.name.purple.json | answer.options.2.label | בָּלוֹן סָגֹל | needs-editor |
| activity.col.name.purple.json | feedback.correct.caption.0.v | כֵּן! זֶה בָּלוֹן סָגֹל. | needs-editor |
| activity.col.name.purple.json | feedback.incorrect.0.caption.0.v | הַצְּבָעִים דּוֹמִים. בּוֹאוּ נִסְתַּכֵּל שׁוּב, לְאַט. | needs-editor |
| activity.col.name.purple.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.col.name.purple.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.col.name.purple.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.col.name.purple.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.col.name.purple.json | hints.2.caption.0.v | זֶה בָּלוֹן סָגֹל. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.col.name.purple.json | a11y.altText | אֵיפֹה הַבָּלוֹן הַסָּגֹל? | needs-editor |
| activity.col.name.red.ball.json | prompt.caption.0.v | אֵיפֹה הַכַּדּוּר הָאָדֹם? | needs-editor |
| activity.col.name.red.ball.json | answer.options.0.label | כַּדּוּר כָּחֹל | needs-editor |
| activity.col.name.red.ball.json | answer.options.1.label | כַּדּוּר אָדֹם | needs-editor |
| activity.col.name.red.ball.json | answer.options.2.label | כַּדּוּר צָהֹב | needs-editor |
| activity.col.name.red.ball.json | feedback.correct.caption.0.v | כֵּן! זֶה כַּדּוּר אָדֹם. | needs-editor |
| activity.col.name.red.ball.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.col.name.red.ball.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.col.name.red.ball.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.col.name.red.ball.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.col.name.red.ball.json | hints.2.caption.0.v | זֶה כַּדּוּר אָדֹם. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.col.name.red.ball.json | a11y.altText | אֵיפֹה הַכַּדּוּר הָאָדֹם? | needs-editor |
| activity.col.name.red.near.json | prompt.caption.0.v | אֵיפֹה הַבָּלוֹן הָאָדֹם? | needs-editor |
| activity.col.name.red.near.json | answer.options.0.label | בָּלוֹן כָּתֹם | needs-editor |
| activity.col.name.red.near.json | answer.options.1.label | בָּלוֹן אָדֹם | needs-editor |
| activity.col.name.red.near.json | answer.options.2.label | בָּלוֹן כָּחֹל | needs-editor |
| activity.col.name.red.near.json | feedback.correct.caption.0.v | כֵּן! זֶה בָּלוֹן אָדֹם. | needs-editor |
| activity.col.name.red.near.json | feedback.incorrect.0.caption.0.v | הַצְּבָעִים דּוֹמִים. בּוֹאוּ נִסְתַּכֵּל שׁוּב, לְאַט. | needs-editor |
| activity.col.name.red.near.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.col.name.red.near.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.col.name.red.near.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.col.name.red.near.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.col.name.red.near.json | hints.2.caption.0.v | זֶה בָּלוֹן אָדֹם. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.col.name.red.near.json | a11y.altText | אֵיפֹה הַבָּלוֹן הָאָדֹם? | needs-editor |
| activity.col.name.white.json | prompt.caption.0.v | אֵיפֹה הַבָּלוֹן הַלָּבָן? | needs-editor |
| activity.col.name.white.json | answer.options.0.label | בָּלוֹן לָבָן | needs-editor |
| activity.col.name.white.json | answer.options.1.label | בָּלוֹן צָהֹב | needs-editor |
| activity.col.name.white.json | answer.options.2.label | בָּלוֹן אָפֹר | needs-editor |
| activity.col.name.white.json | feedback.correct.caption.0.v | כֵּן! זֶה בָּלוֹן לָבָן. | needs-editor |
| activity.col.name.white.json | feedback.incorrect.0.caption.0.v | הַצְּבָעִים דּוֹמִים. בּוֹאוּ נִסְתַּכֵּל שׁוּב, לְאַט. | needs-editor |
| activity.col.name.white.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.col.name.white.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.col.name.white.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.col.name.white.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.col.name.white.json | hints.2.caption.0.v | זֶה בָּלוֹן לָבָן. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.col.name.white.json | a11y.altText | אֵיפֹה הַבָּלוֹן הַלָּבָן? | needs-editor |
| activity.col.name.yellow.flower.json | prompt.caption.0.v | אֵיפֹה הַפֶּרַח הַצָּהֹב? | needs-editor |
| activity.col.name.yellow.flower.json | answer.options.0.label | פֶּרַח צָהֹב | needs-editor |
| activity.col.name.yellow.flower.json | answer.options.1.label | פֶּרַח כָּחֹל | needs-editor |
| activity.col.name.yellow.flower.json | answer.options.2.label | פֶּרַח יָרֹק | needs-editor |
| activity.col.name.yellow.flower.json | feedback.correct.caption.0.v | כֵּן! זֶה פֶּרַח צָהֹב. | needs-editor |
| activity.col.name.yellow.flower.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.col.name.yellow.flower.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.col.name.yellow.flower.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.col.name.yellow.flower.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.col.name.yellow.flower.json | hints.2.caption.0.v | זֶה פֶּרַח צָהֹב. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.col.name.yellow.flower.json | a11y.altText | אֵיפֹה הַפֶּרַח הַצָּהֹב? | needs-editor |
| activity.col.sort.blue.json | prompt.caption.0.v | מִי עוֹד כָּחֹל? | needs-editor |
| activity.col.sort.blue.json | answer.options.0.label | פֶּרַח כָּחֹל | needs-editor |
| activity.col.sort.blue.json | answer.options.1.label | בָּלוֹן צָהֹב | needs-editor |
| activity.col.sort.blue.json | answer.options.2.label | כַּדּוּר אָדֹם | needs-editor |
| activity.col.sort.blue.json | feedback.correct.caption.0.v | כֵּן! זֶה פֶּרַח כָּחֹל. | needs-editor |
| activity.col.sort.blue.json | feedback.incorrect.0.caption.0.v | מְחַפְּשִׂים אֶת אוֹתוֹ צֶבַע, לֹא אוֹתוֹ דָּבָר. בּוֹאוּ נִבְדֹּק. | needs-editor |
| activity.col.sort.blue.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.col.sort.blue.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.col.sort.blue.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.col.sort.blue.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.col.sort.blue.json | hints.2.caption.0.v | זֶה פֶּרַח כָּחֹל. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.col.sort.blue.json | a11y.altText | מִי עוֹד כָּחֹל? | needs-editor |
| activity.col.sort.green.json | prompt.caption.0.v | מִי עוֹד יָרֹק? | needs-editor |
| activity.col.sort.green.json | answer.options.0.label | פֶּרַח אָדֹם | needs-editor |
| activity.col.sort.green.json | answer.options.1.label | כַּדּוּר יָרֹק | needs-editor |
| activity.col.sort.green.json | answer.options.2.label | בָּלוֹן צָהֹב | needs-editor |
| activity.col.sort.green.json | feedback.correct.caption.0.v | כֵּן! זֶה כַּדּוּר יָרֹק. | needs-editor |
| activity.col.sort.green.json | feedback.incorrect.0.caption.0.v | מְחַפְּשִׂים אֶת אוֹתוֹ צֶבַע, לֹא אוֹתוֹ דָּבָר. בּוֹאוּ נִבְדֹּק. | needs-editor |
| activity.col.sort.green.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.col.sort.green.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.col.sort.green.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.col.sort.green.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.col.sort.green.json | hints.2.caption.0.v | זֶה כַּדּוּר יָרֹק. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.col.sort.green.json | a11y.altText | מִי עוֹד יָרֹק? | needs-editor |
| activity.col.sort.red.json | prompt.caption.0.v | מִי עוֹד אָדֹם? | needs-editor |
| activity.col.sort.red.json | answer.options.0.label | פֶּרַח יָרֹק | needs-editor |
| activity.col.sort.red.json | answer.options.1.label | כַּדּוּר כָּחֹל | needs-editor |
| activity.col.sort.red.json | answer.options.2.label | בָּלוֹן אָדֹם | needs-editor |
| activity.col.sort.red.json | feedback.correct.caption.0.v | כֵּן! זֶה בָּלוֹן אָדֹם. | needs-editor |
| activity.col.sort.red.json | feedback.incorrect.0.caption.0.v | מְחַפְּשִׂים אֶת אוֹתוֹ צֶבַע, לֹא אוֹתוֹ דָּבָר. בּוֹאוּ נִבְדֹּק. | needs-editor |
| activity.col.sort.red.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.col.sort.red.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.col.sort.red.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.col.sort.red.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.col.sort.red.json | hints.2.caption.0.v | זֶה בָּלוֹן אָדֹם. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.col.sort.red.json | a11y.altText | מִי עוֹד אָדֹם? | needs-editor |
| activity.col.world.apple.json | prompt.caption.0.v | תַּפּוּחַ יָכוֹל לִהְיוֹת גַּם יָרֹק. אֵיפֹה הַתַּפּוּחַ? | needs-editor |
| activity.col.world.apple.json | answer.options.0.label | כַּדּוּר יָרֹק | needs-editor |
| activity.col.world.apple.json | answer.options.1.label | תַּפּוּחַ יָרֹק | needs-editor |
| activity.col.world.apple.json | answer.options.2.label | כַּדּוּר אָדֹם | needs-editor |
| activity.col.world.apple.json | feedback.correct.caption.0.v | כֵּן! זֶה תַּפּוּחַ יָרֹק. | needs-editor |
| activity.col.world.apple.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.col.world.apple.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.col.world.apple.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.col.world.apple.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.col.world.apple.json | hints.2.caption.0.v | זֶה תַּפּוּחַ יָרֹק. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.col.world.apple.json | a11y.altText | תַּפּוּחַ יָכוֹל לִהְיוֹת גַּם יָרֹק. אֵיפֹה הַתַּפּוּחַ? | needs-editor |
| activity.col.world.banana.json | prompt.caption.0.v | גַּם בָּנָנָה יְרֻקָּה הִיא בָּנָנָה. אֵיפֹה הַבָּנָנָה? | needs-editor |
| activity.col.world.banana.json | answer.options.0.label | כַּדּוּר צָהֹב | needs-editor |
| activity.col.world.banana.json | answer.options.1.label | בָּנָנָה יְרֻקָּה | needs-editor |
| activity.col.world.banana.json | answer.options.2.label | כַּדּוּר יָרֹק | needs-editor |
| activity.col.world.banana.json | feedback.correct.caption.0.v | כֵּן! זוֹ בָּנָנָה יְרֻקָּה. | needs-editor |
| activity.col.world.banana.json | feedback.incorrect.0.caption.0.v | דְּבָרִים יְכוֹלִים לִהְיוֹת בְּכַמָּה צְבָעִים. בּוֹאוּ נִסְתַּכֵּל שׁוּב. | needs-editor |
| activity.col.world.banana.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.col.world.banana.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.col.world.banana.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.col.world.banana.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.col.world.banana.json | hints.2.caption.0.v | זֹאת בָּנָנָה. הִיא יְרֻקָּה כִּי עוֹד לֹא הִבְשִׁילָה. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלֶיהָ. | needs-editor |
| activity.col.world.banana.json | a11y.altText | גַּם בָּנָנָה יְרֻקָּה הִיא בָּנָנָה. אֵיפֹה הַבָּנָנָה? | needs-editor |
| activity.col.world.grass.json | prompt.caption.0.v | אֵיזֶה צֶבַע הָעֵשֶׂב? | needs-editor |
| activity.col.world.grass.json | answer.options.0.label | כַּדּוּר אָדֹם | needs-editor |
| activity.col.world.grass.json | answer.options.1.label | כַּדּוּר כָּחֹל | needs-editor |
| activity.col.world.grass.json | answer.options.2.label | כַּדּוּר יָרֹק | needs-editor |
| activity.col.world.grass.json | feedback.correct.caption.0.v | כֵּן! זֶה כַּדּוּר יָרֹק. | needs-editor |
| activity.col.world.grass.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.col.world.grass.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.col.world.grass.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.col.world.grass.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.col.world.grass.json | hints.2.caption.0.v | זֶה כַּדּוּר יָרֹק. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.col.world.grass.json | a11y.altText | אֵיזֶה צֶבַע הָעֵשֶׂב? | needs-editor |
| activity.col.world.sun.json | prompt.caption.0.v | אֵיזֶה צֶבַע הַשֶּׁמֶשׁ? | needs-editor |
| activity.col.world.sun.json | answer.options.0.label | כַּדּוּר כָּחֹל | needs-editor |
| activity.col.world.sun.json | answer.options.1.label | כַּדּוּר צָהֹב | needs-editor |
| activity.col.world.sun.json | answer.options.2.label | כַּדּוּר יָרֹק | needs-editor |
| activity.col.world.sun.json | feedback.correct.caption.0.v | כֵּן! זֶה כַּדּוּר צָהֹב. | needs-editor |
| activity.col.world.sun.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.col.world.sun.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.col.world.sun.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.col.world.sun.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.col.world.sun.json | hints.2.caption.0.v | זֶה כַּדּוּר צָהֹב. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.col.world.sun.json | a11y.altText | אֵיזֶה צֶבַע הַשֶּׁמֶשׁ? | needs-editor |
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
| activity.cs.robot.direct.1.json | prompt.caption.0.v | מַזִּיזִים אֶת הָרוֹבּוֹט אֶל הַדֶּגֶל. | needs-editor |
| activity.cs.robot.direct.1.json | feedback.correct.caption.0.v | כֵּן! הָרוֹבּוֹט הִגִּיעַ אֶל הַדֶּגֶל. | needs-editor |
| activity.cs.robot.direct.1.json | feedback.incorrect.0.caption.0.v | בּוֹאוּ נִסְפֹּר אֶת הַצְּעָדִים: כׇּל צַעַד עוֹבֵר לְמִשְׁבֶּצֶת הַבָּאָה. | needs-editor |
| activity.cs.robot.direct.1.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.cs.robot.direct.1.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.cs.robot.direct.1.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.cs.robot.direct.1.json | hints.1.caption.0.v | נִסְתַּכֵּל עַל הַדֶּרֶךְ, מִשְׁבֶּצֶת אַחַר מִשְׁבֶּצֶת. | needs-editor |
| activity.cs.robot.direct.1.json | hints.2.caption.0.v | הַצְּעָדִים הֵם: יָמִינָה, יָמִינָה. עַכְשָׁו תּוֹרְכֶם. | needs-editor |
| activity.cs.robot.direct.1.json | a11y.altText | מַזִּיזִים אֶת הָרוֹבּוֹט אֶל הַדֶּגֶל. | needs-editor |
| activity.cs.robot.direct.2.json | prompt.caption.0.v | מַזִּיזִים אֶת הָרוֹבּוֹט אֶל הַדֶּגֶל. | needs-editor |
| activity.cs.robot.direct.2.json | feedback.correct.caption.0.v | כֵּן! הָרוֹבּוֹט הִגִּיעַ אֶל הַדֶּגֶל. | needs-editor |
| activity.cs.robot.direct.2.json | feedback.incorrect.0.caption.0.v | בּוֹאוּ נִסְפֹּר אֶת הַצְּעָדִים: כׇּל צַעַד עוֹבֵר לְמִשְׁבֶּצֶת הַבָּאָה. | needs-editor |
| activity.cs.robot.direct.2.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.cs.robot.direct.2.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.cs.robot.direct.2.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.cs.robot.direct.2.json | hints.1.caption.0.v | נִסְתַּכֵּל עַל הַדֶּרֶךְ, מִשְׁבֶּצֶת אַחַר מִשְׁבֶּצֶת. | needs-editor |
| activity.cs.robot.direct.2.json | hints.2.caption.0.v | הַצְּעָדִים הֵם: יָמִינָה, לְמַטָּה, לְמַטָּה. עַכְשָׁו תּוֹרְכֶם. | needs-editor |
| activity.cs.robot.direct.2.json | a11y.altText | מַזִּיזִים אֶת הָרוֹבּוֹט אֶל הַדֶּגֶל. | needs-editor |
| activity.cs.robot.direct.3.json | prompt.caption.0.v | הָרוֹבּוֹט צָרִיךְ לַחֲזֹר אֶל הַדֶּגֶל. | needs-editor |
| activity.cs.robot.direct.3.json | feedback.correct.caption.0.v | כֵּן! הָרוֹבּוֹט הִגִּיעַ אֶל הַדֶּגֶל. | needs-editor |
| activity.cs.robot.direct.3.json | feedback.incorrect.0.caption.0.v | בּוֹאוּ נִסְפֹּר אֶת הַצְּעָדִים: כׇּל צַעַד עוֹבֵר לְמִשְׁבֶּצֶת הַבָּאָה. | needs-editor |
| activity.cs.robot.direct.3.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.cs.robot.direct.3.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.cs.robot.direct.3.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.cs.robot.direct.3.json | hints.1.caption.0.v | נִסְתַּכֵּל עַל הַדֶּרֶךְ, מִשְׁבֶּצֶת אַחַר מִשְׁבֶּצֶת. | needs-editor |
| activity.cs.robot.direct.3.json | hints.2.caption.0.v | הַצְּעָדִים הֵם: שְׂמֹאלָה, שְׂמֹאלָה, לְמַעְלָה, לְמַעְלָה. עַכְשָׁו תּוֹרְכֶם. | needs-editor |
| activity.cs.robot.direct.3.json | a11y.altText | הָרוֹבּוֹט צָרִיךְ לַחֲזֹר אֶל הַדֶּגֶל. | needs-editor |
| activity.cs.robot.plan.1.json | prompt.caption.0.v | מְתַכְנְנִים אֶת הַצְּעָדִים, וְאָז לוֹחֲצִים עַל הַכַּפְתּוֹר הַכָּתֹם. | needs-editor |
| activity.cs.robot.plan.1.json | feedback.correct.caption.0.v | כֵּן! הָרוֹבּוֹט הִגִּיעַ אֶל הַדֶּגֶל. | needs-editor |
| activity.cs.robot.plan.1.json | feedback.incorrect.0.caption.0.v | בּוֹאוּ נִסְפֹּר אֶת הַצְּעָדִים: כׇּל צַעַד עוֹבֵר לְמִשְׁבֶּצֶת הַבָּאָה. | needs-editor |
| activity.cs.robot.plan.1.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.cs.robot.plan.1.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.cs.robot.plan.1.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.cs.robot.plan.1.json | hints.1.caption.0.v | נִסְתַּכֵּל עַל הַדֶּרֶךְ, מִשְׁבֶּצֶת אַחַר מִשְׁבֶּצֶת. | needs-editor |
| activity.cs.robot.plan.1.json | hints.2.caption.0.v | הַצְּעָדִים הֵם: יָמִינָה, יָמִינָה. עַכְשָׁו תּוֹרְכֶם. | needs-editor |
| activity.cs.robot.plan.1.json | a11y.altText | מְתַכְנְנִים אֶת הַצְּעָדִים, וְאָז לוֹחֲצִים עַל הַכַּפְתּוֹר הַכָּתֹם. | needs-editor |
| activity.cs.robot.plan.2.json | prompt.caption.0.v | מְתַכְנְנִים אֶת הַצְּעָדִים, וְאָז לוֹחֲצִים עַל הַכַּפְתּוֹר הַכָּתֹם. | needs-editor |
| activity.cs.robot.plan.2.json | feedback.correct.caption.0.v | כֵּן! הָרוֹבּוֹט הִגִּיעַ אֶל הַדֶּגֶל. | needs-editor |
| activity.cs.robot.plan.2.json | feedback.incorrect.0.caption.0.v | בּוֹאוּ נִסְפֹּר אֶת הַצְּעָדִים: כׇּל צַעַד עוֹבֵר לְמִשְׁבֶּצֶת הַבָּאָה. | needs-editor |
| activity.cs.robot.plan.2.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.cs.robot.plan.2.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.cs.robot.plan.2.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.cs.robot.plan.2.json | hints.1.caption.0.v | נִסְתַּכֵּל עַל הַדֶּרֶךְ, מִשְׁבֶּצֶת אַחַר מִשְׁבֶּצֶת. | needs-editor |
| activity.cs.robot.plan.2.json | hints.2.caption.0.v | הַצְּעָדִים הֵם: יָמִינָה, יָמִינָה, לְמַטָּה. עַכְשָׁו תּוֹרְכֶם. | needs-editor |
| activity.cs.robot.plan.2.json | a11y.altText | מְתַכְנְנִים אֶת הַצְּעָדִים, וְאָז לוֹחֲצִים עַל הַכַּפְתּוֹר הַכָּתֹם. | needs-editor |
| activity.cs.robot.plan.3.json | prompt.caption.0.v | מְתַכְנְנִים אֶת הַצְּעָדִים, וְאָז לוֹחֲצִים עַל הַכַּפְתּוֹר הַכָּתֹם. | needs-editor |
| activity.cs.robot.plan.3.json | feedback.correct.caption.0.v | כֵּן! הָרוֹבּוֹט הִגִּיעַ אֶל הַדֶּגֶל. | needs-editor |
| activity.cs.robot.plan.3.json | feedback.incorrect.0.caption.0.v | בּוֹאוּ נִסְפֹּר אֶת הַצְּעָדִים: כׇּל צַעַד עוֹבֵר לְמִשְׁבֶּצֶת הַבָּאָה. | needs-editor |
| activity.cs.robot.plan.3.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.cs.robot.plan.3.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.cs.robot.plan.3.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.cs.robot.plan.3.json | hints.1.caption.0.v | נִסְתַּכֵּל עַל הַדֶּרֶךְ, מִשְׁבֶּצֶת אַחַר מִשְׁבֶּצֶת. | needs-editor |
| activity.cs.robot.plan.3.json | hints.2.caption.0.v | הַצְּעָדִים הֵם: יָמִינָה, יָמִינָה, יָמִינָה, לְמַעְלָה. עַכְשָׁו תּוֹרְכֶם. | needs-editor |
| activity.cs.robot.plan.3.json | a11y.altText | מְתַכְנְנִים אֶת הַצְּעָדִים, וְאָז לוֹחֲצִים עַל הַכַּפְתּוֹר הַכָּתֹם. | needs-editor |
| activity.cs.routine.teeth.first.json | prompt.caption.0.v | מְצַחְצְחִים שִׁנַּיִם. מָה עוֹשִׂים קֹדֶם? | needs-editor |
| activity.cs.routine.teeth.first.json | answer.options.0.label | כּוֹס מַיִם | needs-editor |
| activity.cs.routine.teeth.first.json | answer.options.1.label | מִבְרֶשֶׁת | needs-editor |
| activity.cs.routine.teeth.first.json | answer.options.2.label | מִשְׁחָה | needs-editor |
| activity.cs.routine.teeth.first.json | feedback.correct.caption.0.v | כֵּן! קֹדֶם שָׂמִים מִשְׁחָה. | needs-editor |
| activity.cs.routine.teeth.first.json | feedback.incorrect.0.caption.0.v | בּוֹאוּ נַחְשֹׁב: מָה קוֹרֶה קֹדֶם, וּמָה אַחַר כָּךְ? | needs-editor |
| activity.cs.routine.teeth.first.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.cs.routine.teeth.first.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.cs.routine.teeth.first.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.cs.routine.teeth.first.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.cs.routine.teeth.first.json | hints.2.caption.0.v | קֹדֶם מִשְׁחָה, אַחַר כָּךְ מִבְרֶשֶׁת, וּבַסּוֹף כּוֹס מַיִם. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל הַמִּשְׁחָה. | needs-editor |
| activity.cs.routine.teeth.first.json | a11y.altText | מְצַחְצְחִים שִׁנַּיִם. מָה עוֹשִׂים קֹדֶם? | needs-editor |
| activity.cs.routine.teeth.last.json | prompt.caption.0.v | מְצַחְצְחִים שִׁנַּיִם. מָה עוֹשִׂים בַּסּוֹף? | needs-editor |
| activity.cs.routine.teeth.last.json | answer.options.0.label | מִשְׁחָה | needs-editor |
| activity.cs.routine.teeth.last.json | answer.options.1.label | כּוֹס מַיִם | needs-editor |
| activity.cs.routine.teeth.last.json | answer.options.2.label | מִבְרֶשֶׁת | needs-editor |
| activity.cs.routine.teeth.last.json | feedback.correct.caption.0.v | כֵּן! בַּסּוֹף שׁוֹטְפִים בְּמַיִם. | needs-editor |
| activity.cs.routine.teeth.last.json | feedback.incorrect.0.caption.0.v | בּוֹאוּ נַחְשֹׁב: מָה קוֹרֶה קֹדֶם, וּמָה אַחַר כָּךְ? | needs-editor |
| activity.cs.routine.teeth.last.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.cs.routine.teeth.last.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.cs.routine.teeth.last.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.cs.routine.teeth.last.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.cs.routine.teeth.last.json | hints.2.caption.0.v | קֹדֶם מִשְׁחָה, אַחַר כָּךְ מִבְרֶשֶׁת, וּבַסּוֹף כּוֹס מַיִם. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל כּוֹס הַמַּיִם. | needs-editor |
| activity.cs.routine.teeth.last.json | a11y.altText | מְצַחְצְחִים שִׁנַּיִם. מָה עוֹשִׂים בַּסּוֹף? | needs-editor |
| activity.cs.routine.wash.first.json | prompt.caption.0.v | רוֹחֲצִים יָדַיִם. מָה עוֹשִׂים קֹדֶם? | needs-editor |
| activity.cs.routine.wash.first.json | answer.options.0.label | מַגֶּבֶת | needs-editor |
| activity.cs.routine.wash.first.json | answer.options.1.label | בָּרֶז | needs-editor |
| activity.cs.routine.wash.first.json | answer.options.2.label | סַבּוֹן | needs-editor |
| activity.cs.routine.wash.first.json | feedback.correct.caption.0.v | כֵּן! קֹדֶם פּוֹתְחִים אֶת הַבָּרֶז. | needs-editor |
| activity.cs.routine.wash.first.json | feedback.incorrect.0.caption.0.v | בּוֹאוּ נַחְשֹׁב: מָה קוֹרֶה קֹדֶם, וּמָה אַחַר כָּךְ? | needs-editor |
| activity.cs.routine.wash.first.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.cs.routine.wash.first.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.cs.routine.wash.first.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.cs.routine.wash.first.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.cs.routine.wash.first.json | hints.2.caption.0.v | קֹדֶם בָּרֶז, אַחַר כָּךְ סַבּוֹן, וּבַסּוֹף מַגֶּבֶת. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל הַבָּרֶז. | needs-editor |
| activity.cs.routine.wash.first.json | a11y.altText | רוֹחֲצִים יָדַיִם. מָה עוֹשִׂים קֹדֶם? | needs-editor |
| activity.cs.routine.wash.last.json | prompt.caption.0.v | רוֹחֲצִים יָדַיִם. מָה עוֹשִׂים בַּסּוֹף? | needs-editor |
| activity.cs.routine.wash.last.json | answer.options.0.label | סַבּוֹן | needs-editor |
| activity.cs.routine.wash.last.json | answer.options.1.label | מַגֶּבֶת | needs-editor |
| activity.cs.routine.wash.last.json | answer.options.2.label | בָּרֶז | needs-editor |
| activity.cs.routine.wash.last.json | feedback.correct.caption.0.v | כֵּן! בַּסּוֹף מְיַבְּשִׁים בְּמַגֶּבֶת. | needs-editor |
| activity.cs.routine.wash.last.json | feedback.incorrect.0.caption.0.v | בּוֹאוּ נַחְשֹׁב: מָה קוֹרֶה קֹדֶם, וּמָה אַחַר כָּךְ? | needs-editor |
| activity.cs.routine.wash.last.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.cs.routine.wash.last.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.cs.routine.wash.last.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.cs.routine.wash.last.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.cs.routine.wash.last.json | hints.2.caption.0.v | קֹדֶם בָּרֶז, אַחַר כָּךְ סַבּוֹן, וּבַסּוֹף מַגֶּבֶת. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל הַמַּגֶּבֶת. | needs-editor |
| activity.cs.routine.wash.last.json | a11y.altText | רוֹחֲצִים יָדַיִם. מָה עוֹשִׂים בַּסּוֹף? | needs-editor |
| activity.cs.wrong.teeth.json | prompt.caption.0.v | מְצַחְצְחִים שִׁנַּיִם. מָה לֹא שַׁיָּךְ? | needs-editor |
| activity.cs.wrong.teeth.json | answer.options.0.label | סַבּוֹן | needs-editor |
| activity.cs.wrong.teeth.json | answer.options.1.label | מִבְרֶשֶׁת | needs-editor |
| activity.cs.wrong.teeth.json | answer.options.2.label | כּוֹס מַיִם | needs-editor |
| activity.cs.wrong.teeth.json | feedback.correct.caption.0.v | כֵּן! סַבּוֹן לֹא צָרִיךְ לְצִחְצוּחַ שִׁנַּיִם. | needs-editor |
| activity.cs.wrong.teeth.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.cs.wrong.teeth.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.cs.wrong.teeth.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.cs.wrong.teeth.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.cs.wrong.teeth.json | hints.2.caption.0.v | לְצִחְצוּחַ שִׁנַּיִם צְרִיכִים מִשְׁחָה, מִבְרֶשֶׁת וְכוֹס מַיִם. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל הַסַּבּוֹן. | needs-editor |
| activity.cs.wrong.teeth.json | a11y.altText | מְצַחְצְחִים שִׁנַּיִם. מָה לֹא שַׁיָּךְ? | needs-editor |
| activity.cs.wrong.wash.json | prompt.caption.0.v | רוֹחֲצִים יָדַיִם. מָה לֹא שַׁיָּךְ? | needs-editor |
| activity.cs.wrong.wash.json | answer.options.0.label | סַבּוֹן | needs-editor |
| activity.cs.wrong.wash.json | answer.options.1.label | מִבְרֶשֶׁת | needs-editor |
| activity.cs.wrong.wash.json | answer.options.2.label | בָּרֶז | needs-editor |
| activity.cs.wrong.wash.json | feedback.correct.caption.0.v | כֵּן! מִבְרֶשֶׁת לֹא צְרִיכָה לִרְחִיצַת יָדַיִם. | needs-editor |
| activity.cs.wrong.wash.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.cs.wrong.wash.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.cs.wrong.wash.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.cs.wrong.wash.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.cs.wrong.wash.json | hints.2.caption.0.v | לִרְחִיצַת יָדַיִם צְרִיכִים בָּרֶז, סַבּוֹן וּמַגֶּבֶת. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל הַמִּבְרֶשֶׁת. | needs-editor |
| activity.cs.wrong.wash.json | a11y.altText | רוֹחֲצִים יָדַיִם. מָה לֹא שַׁיָּךְ? | needs-editor |
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
| activity.flash.dice.1.json | hints.2.caption.0.v | זוֹ חִפּוּשִׁית אַחַת. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל אַחַת. | needs-editor |
| activity.flash.dice.1.json | a11y.altText | הִסְתַּכְּלוּ מַהֵר. כַּמָּה חִפּוּשִׁיּוֹת? | needs-editor |
| activity.flash.dice.2.json | prompt.caption.0.v | הִסְתַּכְּלוּ מַהֵר! כַּמָּה כּוֹכָבִים? | needs-editor |
| activity.flash.dice.2.json | feedback.correct.caption.0.v | שְׁתַּיִם! רְאִיתֶם בְּלִי לִסְפֹּר. | needs-editor |
| activity.flash.dice.2.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.flash.dice.2.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.flash.dice.2.json | hints.0.caption.0.v | בּוֹאוּ נִסְתַּכֵּל שׁוּב, לְאַט. | needs-editor |
| activity.flash.dice.2.json | hints.1.caption.0.v | נַחֲזִיק אֶצְבָּעוֹת וְנִסְפֹּר: אַחַת, שְׁתַּיִם. | needs-editor |
| activity.flash.dice.2.json | hints.2.caption.0.v | אֵלֶּה שְׁנֵי כּוֹכָבִים. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל שְׁתַּיִם. | needs-editor |
| activity.flash.dice.2.json | a11y.altText | הִסְתַּכְּלוּ מַהֵר. כַּמָּה כּוֹכָבִים? | needs-editor |
| activity.flash.dice.3.json | prompt.caption.0.v | הִסְתַּכְּלוּ מַהֵר! כַּמָּה תַּפּוּחִים? | needs-editor |
| activity.flash.dice.3.json | feedback.correct.caption.0.v | שָׁלוֹשׁ! רְאִיתֶם בְּלִי לִסְפֹּר. | needs-editor |
| activity.flash.dice.3.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.flash.dice.3.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.flash.dice.3.json | hints.0.caption.0.v | בּוֹאוּ נִסְתַּכֵּל שׁוּב, לְאַט. | needs-editor |
| activity.flash.dice.3.json | hints.1.caption.0.v | נַחֲזִיק אֶצְבָּעוֹת וְנִסְפֹּר: אַחַת, שְׁתַּיִם, שָׁלוֹשׁ. | needs-editor |
| activity.flash.dice.3.json | hints.2.caption.0.v | אֵלֶּה שְׁלוֹשָׁה תַּפּוּחִים. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל שָׁלוֹשׁ. | needs-editor |
| activity.flash.dice.3.json | a11y.altText | הִסְתַּכְּלוּ מַהֵר. כַּמָּה תַּפּוּחִים? | needs-editor |
| activity.flash.dice.4.json | prompt.caption.0.v | הִסְתַּכְּלוּ מַהֵר! כַּמָּה חִפּוּשִׁיּוֹת? | needs-editor |
| activity.flash.dice.4.json | feedback.correct.caption.0.v | אַרְבַּע! רְאִיתֶם בְּלִי לִסְפֹּר. | needs-editor |
| activity.flash.dice.4.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.flash.dice.4.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.flash.dice.4.json | hints.0.caption.0.v | בּוֹאוּ נִסְתַּכֵּל שׁוּב, לְאַט. | needs-editor |
| activity.flash.dice.4.json | hints.1.caption.0.v | נַחֲזִיק אֶצְבָּעוֹת וְנִסְפֹּר: אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע. | needs-editor |
| activity.flash.dice.4.json | hints.2.caption.0.v | אֵלֶּה אַרְבַּע חִפּוּשִׁיּוֹת. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל אַרְבַּע. | needs-editor |
| activity.flash.dice.4.json | a11y.altText | הִסְתַּכְּלוּ מַהֵר. כַּמָּה חִפּוּשִׁיּוֹת? | needs-editor |
| activity.flash.dice.5.json | prompt.caption.0.v | הִסְתַּכְּלוּ מַהֵר! כַּמָּה כּוֹכָבִים? | needs-editor |
| activity.flash.dice.5.json | feedback.correct.caption.0.v | חָמֵשׁ! רְאִיתֶם בְּלִי לִסְפֹּר. | needs-editor |
| activity.flash.dice.5.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.flash.dice.5.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.flash.dice.5.json | hints.0.caption.0.v | בּוֹאוּ נִסְתַּכֵּל שׁוּב, לְאַט. | needs-editor |
| activity.flash.dice.5.json | hints.1.caption.0.v | נַחֲזִיק אֶצְבָּעוֹת וְנִסְפֹּר: אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע, חָמֵשׁ. | needs-editor |
| activity.flash.dice.5.json | hints.2.caption.0.v | אֵלֶּה חֲמִשָּׁה כּוֹכָבִים. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל חָמֵשׁ. | needs-editor |
| activity.flash.dice.5.json | a11y.altText | הִסְתַּכְּלוּ מַהֵר. כַּמָּה כּוֹכָבִים? | needs-editor |
| activity.flash.frame.4.json | prompt.caption.0.v | הִסְתַּכְּלוּ מַהֵר! כַּמָּה תַּפּוּחִים? | needs-editor |
| activity.flash.frame.4.json | feedback.correct.caption.0.v | אַרְבַּע! רְאִיתֶם בְּלִי לִסְפֹּר. | needs-editor |
| activity.flash.frame.4.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.flash.frame.4.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.flash.frame.4.json | hints.0.caption.0.v | בּוֹאוּ נִסְתַּכֵּל שׁוּב, לְאַט. | needs-editor |
| activity.flash.frame.4.json | hints.1.caption.0.v | נַחֲזִיק אֶצְבָּעוֹת וְנִסְפֹּר: אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע. | needs-editor |
| activity.flash.frame.4.json | hints.2.caption.0.v | אֵלֶּה אַרְבָּעָה תַּפּוּחִים. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל אַרְבַּע. | needs-editor |
| activity.flash.frame.4.json | a11y.altText | הִסְתַּכְּלוּ מַהֵר. כַּמָּה תַּפּוּחִים? | needs-editor |
| activity.flash.frame.5.json | prompt.caption.0.v | הִסְתַּכְּלוּ מַהֵר! כַּמָּה דָּגִים? | needs-editor |
| activity.flash.frame.5.json | feedback.correct.caption.0.v | חָמֵשׁ! רְאִיתֶם בְּלִי לִסְפֹּר. | needs-editor |
| activity.flash.frame.5.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.flash.frame.5.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.flash.frame.5.json | hints.0.caption.0.v | בּוֹאוּ נִסְתַּכֵּל שׁוּב, לְאַט. | needs-editor |
| activity.flash.frame.5.json | hints.1.caption.0.v | נַחֲזִיק אֶצְבָּעוֹת וְנִסְפֹּר: אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע, חָמֵשׁ. | needs-editor |
| activity.flash.frame.5.json | hints.2.caption.0.v | אֵלֶּה חֲמִשָּׁה דָּגִים. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל חָמֵשׁ. | needs-editor |
| activity.flash.frame.5.json | a11y.altText | הִסְתַּכְּלוּ מַהֵר. כַּמָּה דָּגִים? | needs-editor |
| activity.flash.scatter.3.json | prompt.caption.0.v | הִסְתַּכְּלוּ מַהֵר! כַּמָּה חִפּוּשִׁיּוֹת? | needs-editor |
| activity.flash.scatter.3.json | feedback.correct.caption.0.v | שָׁלוֹשׁ! רְאִיתֶם בְּלִי לִסְפֹּר. | needs-editor |
| activity.flash.scatter.3.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.flash.scatter.3.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.flash.scatter.3.json | hints.0.caption.0.v | בּוֹאוּ נִסְתַּכֵּל שׁוּב, לְאַט. | needs-editor |
| activity.flash.scatter.3.json | hints.1.caption.0.v | נַחֲזִיק אֶצְבָּעוֹת וְנִסְפֹּר: אַחַת, שְׁתַּיִם, שָׁלוֹשׁ. | needs-editor |
| activity.flash.scatter.3.json | hints.2.caption.0.v | אֵלֶּה שָׁלוֹשׁ חִפּוּשִׁיּוֹת. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל שָׁלוֹשׁ. | needs-editor |
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
| activity.log.copy.animals.json | prompt.caption.0.v | מַעֲתִיקִים אֶת הַסֵּדֶר. | needs-editor |
| activity.log.copy.animals.json | feedback.correct.caption.0.v | כֵּן! הֶעְתַּקְתֶּם אֶת הַסֵּדֶר. | needs-editor |
| activity.log.copy.animals.json | feedback.incorrect.0.caption.0.v | בּוֹאוּ נִסְתַּכֵּל בַּסֵּדֶר: מָה הָרִאשׁוֹן, וּמָה הַשֵּׁנִי? | needs-editor |
| activity.log.copy.animals.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.log.copy.animals.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.log.copy.animals.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.log.copy.animals.json | hints.1.caption.0.v | נִסְתַּכֵּל בַּסֵּדֶר מֵהַהַתְחָלָה, אֶחָד אֶחָד. | needs-editor |
| activity.log.copy.animals.json | hints.2.caption.0.v | חָתוּל, כֶּלֶב, חָתוּל, כֶּלֶב. עַכְשָׁו תּוֹרְכֶם. | needs-editor |
| activity.log.copy.animals.json | a11y.altText | מַעֲתִיקִים אֶת הַסֵּדֶר. | needs-editor |
| activity.log.copy.balloons.json | prompt.caption.0.v | מַעֲתִיקִים אֶת הַסֵּדֶר. | needs-editor |
| activity.log.copy.balloons.json | feedback.correct.caption.0.v | כֵּן! הֶעְתַּקְתֶּם אֶת הַסֵּדֶר. | needs-editor |
| activity.log.copy.balloons.json | feedback.incorrect.0.caption.0.v | בּוֹאוּ נִסְתַּכֵּל בַּסֵּדֶר: מָה הָרִאשׁוֹן, וּמָה הַשֵּׁנִי? | needs-editor |
| activity.log.copy.balloons.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.log.copy.balloons.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.log.copy.balloons.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.log.copy.balloons.json | hints.1.caption.0.v | נִסְתַּכֵּל בַּסֵּדֶר מֵהַהַתְחָלָה, אֶחָד אֶחָד. | needs-editor |
| activity.log.copy.balloons.json | hints.2.caption.0.v | צָהֹב, צָהֹב, יָרֹק. עַכְשָׁו תּוֹרְכֶם. | needs-editor |
| activity.log.copy.balloons.json | a11y.altText | מַעֲתִיקִים אֶת הַסֵּדֶר. | needs-editor |
| activity.log.copy.colours.json | prompt.caption.0.v | מַעֲתִיקִים אֶת הַסֵּדֶר. | needs-editor |
| activity.log.copy.colours.json | feedback.correct.caption.0.v | כֵּן! הֶעְתַּקְתֶּם אֶת הַסֵּדֶר. | needs-editor |
| activity.log.copy.colours.json | feedback.incorrect.0.caption.0.v | בּוֹאוּ נִסְתַּכֵּל בַּסֵּדֶר: מָה הָרִאשׁוֹן, וּמָה הַשֵּׁנִי? | needs-editor |
| activity.log.copy.colours.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.log.copy.colours.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.log.copy.colours.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.log.copy.colours.json | hints.1.caption.0.v | נִסְתַּכֵּל בַּסֵּדֶר מֵהַהַתְחָלָה, אֶחָד אֶחָד. | needs-editor |
| activity.log.copy.colours.json | hints.2.caption.0.v | אָדֹם, כָּחֹל, אָדֹם, כָּחֹל. עַכְשָׁו תּוֹרְכֶם. | needs-editor |
| activity.log.copy.colours.json | a11y.altText | מַעֲתִיקִים אֶת הַסֵּדֶר. | needs-editor |
| activity.log.copy.three.json | prompt.caption.0.v | מַעֲתִיקִים אֶת הַסֵּדֶר. | needs-editor |
| activity.log.copy.three.json | feedback.correct.caption.0.v | כֵּן! הֶעְתַּקְתֶּם אֶת הַסֵּדֶר. | needs-editor |
| activity.log.copy.three.json | feedback.incorrect.0.caption.0.v | בּוֹאוּ נִסְתַּכֵּל בַּסֵּדֶר: מָה הָרִאשׁוֹן, וּמָה הַשֵּׁנִי? | needs-editor |
| activity.log.copy.three.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.log.copy.three.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.log.copy.three.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.log.copy.three.json | hints.1.caption.0.v | נִסְתַּכֵּל בַּסֵּדֶר מֵהַהַתְחָלָה, אֶחָד אֶחָד. | needs-editor |
| activity.log.copy.three.json | hints.2.caption.0.v | כּוֹכָב, תַּפּוּחַ, דָּג, כּוֹכָב, תַּפּוּחַ, דָּג. עַכְשָׁו תּוֹרְכֶם. | needs-editor |
| activity.log.copy.three.json | a11y.altText | מַעֲתִיקִים אֶת הַסֵּדֶר. | needs-editor |
| activity.log.fix.animals.json | prompt.caption.0.v | הַסֵּדֶר נִשְׁבַּר. מָה חָסֵר? | needs-editor |
| activity.log.fix.animals.json | answer.options.0.label | דָּג | needs-editor |
| activity.log.fix.animals.json | answer.options.1.label | צִפּוֹר | needs-editor |
| activity.log.fix.animals.json | answer.options.2.label | כּוֹכָב | needs-editor |
| activity.log.fix.animals.json | feedback.correct.caption.0.v | כֵּן! דָּג, צִפּוֹר, דָּג, צִפּוֹר, דָּג, צִפּוֹר. | needs-editor |
| activity.log.fix.animals.json | feedback.incorrect.0.caption.0.v | בּוֹאוּ נֹאמַר אֶת הַסֵּדֶר בְּקוֹל, וְנִרְאֶה מָה בָּא. | needs-editor |
| activity.log.fix.animals.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.log.fix.animals.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.log.fix.animals.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.log.fix.animals.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.log.fix.animals.json | hints.2.caption.0.v | דָּג, צִפּוֹר, דָּג — בַּמָּקוֹם הֶחָסֵר בָּאָה צִפּוֹר. עַכְשָׁו תּוֹרְכֶם. | needs-editor |
| activity.log.fix.animals.json | a11y.altText | הַסֵּדֶר נִשְׁבַּר. מָה חָסֵר? | needs-editor |
| activity.log.fix.balloons.json | prompt.caption.0.v | הַסֵּדֶר נִשְׁבַּר. מָה חָסֵר? | needs-editor |
| activity.log.fix.balloons.json | answer.options.0.label | בָּלוֹן יָרֹק | needs-editor |
| activity.log.fix.balloons.json | answer.options.1.label | בָּלוֹן צָהֹב | needs-editor |
| activity.log.fix.balloons.json | answer.options.2.label | בָּלוֹן אָדֹם | needs-editor |
| activity.log.fix.balloons.json | feedback.correct.caption.0.v | כֵּן! צָהֹב, יָרֹק, צָהֹב, יָרֹק, צָהֹב, יָרֹק. | needs-editor |
| activity.log.fix.balloons.json | feedback.incorrect.0.caption.0.v | בּוֹאוּ נֹאמַר אֶת הַסֵּדֶר בְּקוֹל, וְנִרְאֶה מָה בָּא. | needs-editor |
| activity.log.fix.balloons.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.log.fix.balloons.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.log.fix.balloons.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.log.fix.balloons.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.log.fix.balloons.json | hints.2.caption.0.v | צָהֹב, יָרֹק, צָהֹב, יָרֹק — בַּהַתְחָלָה בָּא צָהֹב. עַכְשָׁו תּוֹרְכֶם. | needs-editor |
| activity.log.fix.balloons.json | a11y.altText | הַסֵּדֶר נִשְׁבַּר. מָה חָסֵר? | needs-editor |
| activity.log.fix.colours.json | prompt.caption.0.v | הַסֵּדֶר נִשְׁבַּר. מָה חָסֵר? | needs-editor |
| activity.log.fix.colours.json | answer.options.0.label | כַּדּוּר כָּחֹל | needs-editor |
| activity.log.fix.colours.json | answer.options.1.label | כַּדּוּר יָרֹק | needs-editor |
| activity.log.fix.colours.json | answer.options.2.label | כַּדּוּר אָדֹם | needs-editor |
| activity.log.fix.colours.json | feedback.correct.caption.0.v | כֵּן! אָדֹם, כָּחֹל, אָדֹם, כָּחֹל, אָדֹם, כָּחֹל. | needs-editor |
| activity.log.fix.colours.json | feedback.incorrect.0.caption.0.v | בּוֹאוּ נֹאמַר אֶת הַסֵּדֶר בְּקוֹל, וְנִרְאֶה מָה בָּא. | needs-editor |
| activity.log.fix.colours.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.log.fix.colours.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.log.fix.colours.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.log.fix.colours.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.log.fix.colours.json | hints.2.caption.0.v | אָדֹם, כָּחֹל, אָדֹם, כָּחֹל — בַּמָּקוֹם הֶחָסֵר בָּא אָדֹם. עַכְשָׁו תּוֹרְכֶם. | needs-editor |
| activity.log.fix.colours.json | a11y.altText | הַסֵּדֶר נִשְׁבַּר. מָה חָסֵר? | needs-editor |
| activity.log.next.animals.json | prompt.caption.0.v | מָה בָּא אַחַר כָּךְ? | needs-editor |
| activity.log.next.animals.json | answer.options.0.label | כֶּלֶב | needs-editor |
| activity.log.next.animals.json | answer.options.1.label | חָתוּל | needs-editor |
| activity.log.next.animals.json | answer.options.2.label | בַּרְוָז | needs-editor |
| activity.log.next.animals.json | feedback.correct.caption.0.v | כֵּן! חָתוּל, כֶּלֶב, חָתוּל, כֶּלֶב, חָתוּל, כֶּלֶב. | needs-editor |
| activity.log.next.animals.json | feedback.incorrect.0.caption.0.v | בּוֹאוּ נֹאמַר אֶת הַסֵּדֶר בְּקוֹל, וְנִרְאֶה מָה בָּא. | needs-editor |
| activity.log.next.animals.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.log.next.animals.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.log.next.animals.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.log.next.animals.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.log.next.animals.json | hints.2.caption.0.v | חָתוּל, כֶּלֶב, חָתוּל, כֶּלֶב, חָתוּל — וְאָז כֶּלֶב. עַכְשָׁו תּוֹרְכֶם. | needs-editor |
| activity.log.next.animals.json | a11y.altText | מָה בָּא אַחַר כָּךְ? | needs-editor |
| activity.log.next.balloons.json | prompt.caption.0.v | מָה בָּא אַחַר כָּךְ? | needs-editor |
| activity.log.next.balloons.json | answer.options.0.label | בָּלוֹן יָרֹק | needs-editor |
| activity.log.next.balloons.json | answer.options.1.label | בָּלוֹן צָהֹב | needs-editor |
| activity.log.next.balloons.json | answer.options.2.label | בָּלוֹן אָדֹם | needs-editor |
| activity.log.next.balloons.json | feedback.correct.caption.0.v | כֵּן! צָהֹב, יָרֹק, צָהֹב, יָרֹק, צָהֹב. | needs-editor |
| activity.log.next.balloons.json | feedback.incorrect.0.caption.0.v | בּוֹאוּ נֹאמַר אֶת הַסֵּדֶר בְּקוֹל, וְנִרְאֶה מָה בָּא. | needs-editor |
| activity.log.next.balloons.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.log.next.balloons.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.log.next.balloons.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.log.next.balloons.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.log.next.balloons.json | hints.2.caption.0.v | צָהֹב, יָרֹק, צָהֹב, יָרֹק — וְאָז צָהֹב. עַכְשָׁו תּוֹרְכֶם. | needs-editor |
| activity.log.next.balloons.json | a11y.altText | מָה בָּא אַחַר כָּךְ? | needs-editor |
| activity.log.next.colours.json | prompt.caption.0.v | מָה בָּא אַחַר כָּךְ? | needs-editor |
| activity.log.next.colours.json | answer.options.0.label | כַּדּוּר אָדֹם | needs-editor |
| activity.log.next.colours.json | answer.options.1.label | כַּדּוּר כָּחֹל | needs-editor |
| activity.log.next.colours.json | answer.options.2.label | כַּדּוּר יָרֹק | needs-editor |
| activity.log.next.colours.json | feedback.correct.caption.0.v | כֵּן! אָדֹם, כָּחֹל, אָדֹם, כָּחֹל, אָדֹם, כָּחֹל. | needs-editor |
| activity.log.next.colours.json | feedback.incorrect.0.caption.0.v | בּוֹאוּ נֹאמַר אֶת הַסֵּדֶר בְּקוֹל, וְנִרְאֶה מָה בָּא. | needs-editor |
| activity.log.next.colours.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.log.next.colours.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.log.next.colours.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.log.next.colours.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.log.next.colours.json | hints.2.caption.0.v | אָדֹם, כָּחֹל, אָדֹם, כָּחֹל, אָדֹם — וְאָז כָּחֹל. עַכְשָׁו תּוֹרְכֶם. | needs-editor |
| activity.log.next.colours.json | a11y.altText | מָה בָּא אַחַר כָּךְ? | needs-editor |
| activity.log.next.stars.json | prompt.caption.0.v | מָה בָּא אַחַר כָּךְ? | needs-editor |
| activity.log.next.stars.json | answer.options.0.label | כּוֹכָב | needs-editor |
| activity.log.next.stars.json | answer.options.1.label | דָּג | needs-editor |
| activity.log.next.stars.json | answer.options.2.label | תַּפּוּחַ | needs-editor |
| activity.log.next.stars.json | feedback.correct.caption.0.v | כֵּן! כּוֹכָב, תַּפּוּחַ, כּוֹכָב, תַּפּוּחַ, כּוֹכָב, תַּפּוּחַ. | needs-editor |
| activity.log.next.stars.json | feedback.incorrect.0.caption.0.v | בּוֹאוּ נֹאמַר אֶת הַסֵּדֶר בְּקוֹל, וְנִרְאֶה מָה בָּא. | needs-editor |
| activity.log.next.stars.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.log.next.stars.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.log.next.stars.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.log.next.stars.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.log.next.stars.json | hints.2.caption.0.v | כּוֹכָב, תַּפּוּחַ, כּוֹכָב, תַּפּוּחַ, כּוֹכָב — וְאָז תַּפּוּחַ. עַכְשָׁו תּוֹרְכֶם. | needs-editor |
| activity.log.next.stars.json | a11y.altText | מָה בָּא אַחַר כָּךְ? | needs-editor |
| activity.log.odd.animal.json | prompt.caption.0.v | מִי שׁוֹנֶה? | needs-editor |
| activity.log.odd.animal.json | answer.options.0.label | חָתוּל | needs-editor |
| activity.log.odd.animal.json | answer.options.1.label | כֶּלֶב | needs-editor |
| activity.log.odd.animal.json | feedback.correct.caption.0.v | כֵּן! זֶה כֶּלֶב. | needs-editor |
| activity.log.odd.animal.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.log.odd.animal.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.log.odd.animal.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.log.odd.animal.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.log.odd.animal.json | hints.2.caption.0.v | הַכֶּלֶב שׁוֹנֶה מֵהַחֲתוּלִים. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.log.odd.animal.json | a11y.altText | מִי שׁוֹנֶה? | needs-editor |
| activity.log.odd.colour.json | prompt.caption.0.v | מִי שׁוֹנֶה? | needs-editor |
| activity.log.odd.colour.json | answer.options.0.label | כַּדּוּר אָדֹם | needs-editor |
| activity.log.odd.colour.json | answer.options.1.label | כַּדּוּר כָּחֹל | needs-editor |
| activity.log.odd.colour.json | feedback.correct.caption.0.v | כֵּן! זֶה כַּדּוּר כָּחֹל. | needs-editor |
| activity.log.odd.colour.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.log.odd.colour.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.log.odd.colour.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.log.odd.colour.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.log.odd.colour.json | hints.2.caption.0.v | הַכַּדּוּר הַכָּחֹל שׁוֹנֶה מֵהָאֲחֵרִים. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.log.odd.colour.json | a11y.altText | מִי שׁוֹנֶה? | needs-editor |
| activity.log.odd.thing.json | prompt.caption.0.v | מִי שׁוֹנֶה? | needs-editor |
| activity.log.odd.thing.json | answer.options.0.label | כַּדּוּר יָרֹק | needs-editor |
| activity.log.odd.thing.json | answer.options.1.label | בָּלוֹן יָרֹק | needs-editor |
| activity.log.odd.thing.json | feedback.correct.caption.0.v | כֵּן! זֶה בָּלוֹן יָרֹק. | needs-editor |
| activity.log.odd.thing.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.log.odd.thing.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.log.odd.thing.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.log.odd.thing.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.log.odd.thing.json | hints.2.caption.0.v | הַבָּלוֹן שׁוֹנֶה מֵהַכַּדּוּרִים. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.log.odd.thing.json | a11y.altText | מִי שׁוֹנֶה? | needs-editor |
| activity.log.pair.brush.json | prompt.caption.0.v | מָה הוֹלֵךְ עִם הַמִּבְרֶשֶׁת? | needs-editor |
| activity.log.pair.brush.json | answer.options.0.label | מִשְׁחָה | needs-editor |
| activity.log.pair.brush.json | answer.options.1.label | מַפְתֵּחַ | needs-editor |
| activity.log.pair.brush.json | answer.options.2.label | נַעַל | needs-editor |
| activity.log.pair.brush.json | feedback.correct.caption.0.v | כֵּן! זוֹ מִשְׁחָה. | needs-editor |
| activity.log.pair.brush.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.log.pair.brush.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.log.pair.brush.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.log.pair.brush.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.log.pair.brush.json | hints.2.caption.0.v | מִבְרֶשֶׁת וּמִשְׁחָה הוֹלְכוֹת יַחַד. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל הַמִּשְׁחָה. | needs-editor |
| activity.log.pair.brush.json | a11y.altText | מָה הוֹלֵךְ עִם הַמִּבְרֶשֶׁת? | needs-editor |
| activity.log.pair.key.json | prompt.caption.0.v | מָה הוֹלֵךְ עִם הַמַּפְתֵּחַ? | needs-editor |
| activity.log.pair.key.json | answer.options.0.label | גֶּרֶב | needs-editor |
| activity.log.pair.key.json | answer.options.1.label | מִבְרֶשֶׁת | needs-editor |
| activity.log.pair.key.json | answer.options.2.label | מַנְעוּל | needs-editor |
| activity.log.pair.key.json | feedback.correct.caption.0.v | כֵּן! זֶה מַנְעוּל. | needs-editor |
| activity.log.pair.key.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.log.pair.key.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.log.pair.key.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.log.pair.key.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.log.pair.key.json | hints.2.caption.0.v | מַפְתֵּחַ וּמַנְעוּל הוֹלְכִים יַחַד. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל הַמַּנְעוּל. | needs-editor |
| activity.log.pair.key.json | a11y.altText | מָה הוֹלֵךְ עִם הַמַּפְתֵּחַ? | needs-editor |
| activity.log.pair.sock.json | prompt.caption.0.v | מָה הוֹלֵךְ עִם הַגֶּרֶב? | needs-editor |
| activity.log.pair.sock.json | answer.options.0.label | מַנְעוּל | needs-editor |
| activity.log.pair.sock.json | answer.options.1.label | נַעַל | needs-editor |
| activity.log.pair.sock.json | answer.options.2.label | מִשְׁחָה | needs-editor |
| activity.log.pair.sock.json | feedback.correct.caption.0.v | כֵּן! זוֹ נַעַל. | needs-editor |
| activity.log.pair.sock.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.log.pair.sock.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.log.pair.sock.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.log.pair.sock.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.log.pair.sock.json | hints.2.caption.0.v | גֶּרֶב וְנַעַל הוֹלְכוֹת יַחַד. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל הַנַּעַל. | needs-editor |
| activity.log.pair.sock.json | a11y.altText | מָה הוֹלֵךְ עִם הַגֶּרֶב? | needs-editor |
| activity.log.pat.no.mixed.json | prompt.caption.0.v | הַאִם הַסֵּדֶר חוֹזֵר? | needs-editor |
| activity.log.pat.no.mixed.json | answer.options.0.label | כֵּן | needs-editor |
| activity.log.pat.no.mixed.json | answer.options.1.label | לֹא | needs-editor |
| activity.log.pat.no.mixed.json | feedback.correct.caption.0.v | לֹא, כָּאן הַסֵּדֶר לֹא חוֹזֵר. | needs-editor |
| activity.log.pat.no.mixed.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.log.pat.no.mixed.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.log.pat.no.mixed.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.log.pat.no.mixed.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.log.pat.no.mixed.json | hints.2.caption.0.v | אָדֹם, כָּחֹל, יָרֹק, אָדֹם, צָהֹב — לֹא, הוּא לֹא חוֹזֵר. עַכְשָׁו תּוֹרְכֶם. | needs-editor |
| activity.log.pat.no.mixed.json | a11y.altText | הַאִם הַסֵּדֶר חוֹזֵר? | needs-editor |
| activity.log.pat.yes.animals.json | prompt.caption.0.v | הַאִם הַסֵּדֶר חוֹזֵר? | needs-editor |
| activity.log.pat.yes.animals.json | answer.options.0.label | לֹא | needs-editor |
| activity.log.pat.yes.animals.json | answer.options.1.label | כֵּן | needs-editor |
| activity.log.pat.yes.animals.json | feedback.correct.caption.0.v | כֵּן, הַסֵּדֶר חוֹזֵר: חָתוּל, כֶּלֶב, חָתוּל, כֶּלֶב. | needs-editor |
| activity.log.pat.yes.animals.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.log.pat.yes.animals.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.log.pat.yes.animals.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.log.pat.yes.animals.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.log.pat.yes.animals.json | hints.2.caption.0.v | חָתוּל, כֶּלֶב, חָתוּל, כֶּלֶב — כֵּן, הוּא חוֹזֵר. עַכְשָׁו תּוֹרְכֶם. | needs-editor |
| activity.log.pat.yes.animals.json | a11y.altText | הַאִם הַסֵּדֶר חוֹזֵר? | needs-editor |
| activity.log.pat.yes.colours.json | prompt.caption.0.v | הַאִם הַסֵּדֶר חוֹזֵר? | needs-editor |
| activity.log.pat.yes.colours.json | answer.options.0.label | לֹא | needs-editor |
| activity.log.pat.yes.colours.json | answer.options.1.label | כֵּן | needs-editor |
| activity.log.pat.yes.colours.json | feedback.correct.caption.0.v | כֵּן, הַסֵּדֶר חוֹזֵר: אָדֹם, כָּחֹל, אָדֹם, כָּחֹל. | needs-editor |
| activity.log.pat.yes.colours.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.log.pat.yes.colours.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.log.pat.yes.colours.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.log.pat.yes.colours.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.log.pat.yes.colours.json | hints.2.caption.0.v | אָדֹם, כָּחֹל, אָדֹם, כָּחֹל — כֵּן, הוּא חוֹזֵר. עַכְשָׁו תּוֹרְכֶם. | needs-editor |
| activity.log.pat.yes.colours.json | a11y.altText | הַאִם הַסֵּדֶר חוֹזֵר? | needs-editor |
| activity.log.same.cat.json | prompt.caption.0.v | אֵיפֹה אוֹתוֹ הַדָּבָר? | needs-editor |
| activity.log.same.cat.json | answer.options.0.label | כֶּלֶב | needs-editor |
| activity.log.same.cat.json | answer.options.1.label | חָתוּל | needs-editor |
| activity.log.same.cat.json | answer.options.2.label | בַּרְוָז | needs-editor |
| activity.log.same.cat.json | feedback.correct.caption.0.v | כֵּן! זֶה חָתוּל. | needs-editor |
| activity.log.same.cat.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.log.same.cat.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.log.same.cat.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.log.same.cat.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.log.same.cat.json | hints.2.caption.0.v | זֶה חָתוּל. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.log.same.cat.json | a11y.altText | אֵיפֹה אוֹתוֹ הַדָּבָר? | needs-editor |
| activity.log.same.duck.json | prompt.caption.0.v | אֵיפֹה אוֹתוֹ הַדָּבָר? | needs-editor |
| activity.log.same.duck.json | answer.options.0.label | בַּרְוָז | needs-editor |
| activity.log.same.duck.json | answer.options.1.label | צִפּוֹר | needs-editor |
| activity.log.same.duck.json | answer.options.2.label | חָתוּל | needs-editor |
| activity.log.same.duck.json | feedback.correct.caption.0.v | כֵּן! זֶה בַּרְוָז. | needs-editor |
| activity.log.same.duck.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.log.same.duck.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.log.same.duck.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.log.same.duck.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.log.same.duck.json | hints.2.caption.0.v | זֶה בַּרְוָז. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.log.same.duck.json | a11y.altText | אֵיפֹה אוֹתוֹ הַדָּבָר? | needs-editor |
| activity.log.same.star.json | prompt.caption.0.v | אֵיפֹה אוֹתוֹ הַדָּבָר? | needs-editor |
| activity.log.same.star.json | answer.options.0.label | דָּג | needs-editor |
| activity.log.same.star.json | answer.options.1.label | תַּפּוּחַ | needs-editor |
| activity.log.same.star.json | answer.options.2.label | כּוֹכָב | needs-editor |
| activity.log.same.star.json | feedback.correct.caption.0.v | כֵּן! זֶה כּוֹכָב. | needs-editor |
| activity.log.same.star.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.log.same.star.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.log.same.star.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.log.same.star.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.log.same.star.json | hints.2.caption.0.v | זֶה כּוֹכָב. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.log.same.star.json | a11y.altText | אֵיפֹה אוֹתוֹ הַדָּבָר? | needs-editor |
| activity.log.size.last.json | prompt.caption.0.v | מָה בָּא בַּסּוֹף? | needs-editor |
| activity.log.size.last.json | answer.options.0.label | כַּדּוּר בֵּינוֹנִי | needs-editor |
| activity.log.size.last.json | answer.options.1.label | כַּדּוּר גָּדוֹל | needs-editor |
| activity.log.size.last.json | answer.options.2.label | כַּדּוּר קָטָן | needs-editor |
| activity.log.size.last.json | feedback.correct.caption.0.v | כֵּן! קָטָן, בֵּינוֹנִי, גָּדוֹל. | needs-editor |
| activity.log.size.last.json | feedback.incorrect.0.caption.0.v | מְחַפְּשִׂים אֶת הָאֶמְצַע: לֹא הַכִּי קָטָן וְלֹא הַכִּי גָּדוֹל. | needs-editor |
| activity.log.size.last.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.log.size.last.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.log.size.last.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.log.size.last.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.log.size.last.json | hints.2.caption.0.v | קָטָן, בֵּינוֹנִי, וְאַחַר כָּךְ גָּדוֹל. עַכְשָׁו תּוֹרְכֶם. | needs-editor |
| activity.log.size.last.json | a11y.altText | מָה בָּא בַּסּוֹף? | needs-editor |
| activity.log.size.middle.down.json | prompt.caption.0.v | מָה בָּאֶמְצַע? | needs-editor |
| activity.log.size.middle.down.json | answer.options.0.label | כַּדּוּר קָטָן | needs-editor |
| activity.log.size.middle.down.json | answer.options.1.label | כַּדּוּר גָּדוֹל | needs-editor |
| activity.log.size.middle.down.json | answer.options.2.label | כַּדּוּר בֵּינוֹנִי | needs-editor |
| activity.log.size.middle.down.json | feedback.correct.caption.0.v | כֵּן! גָּדוֹל, בֵּינוֹנִי, קָטָן. | needs-editor |
| activity.log.size.middle.down.json | feedback.incorrect.0.caption.0.v | מְחַפְּשִׂים אֶת הָאֶמְצַע: לֹא הַכִּי קָטָן וְלֹא הַכִּי גָּדוֹל. | needs-editor |
| activity.log.size.middle.down.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.log.size.middle.down.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.log.size.middle.down.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.log.size.middle.down.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.log.size.middle.down.json | hints.2.caption.0.v | גָּדוֹל, בֵּינוֹנִי, קָטָן — בָּאֶמְצַע בָּא הַבֵּינוֹנִי. עַכְשָׁו תּוֹרְכֶם. | needs-editor |
| activity.log.size.middle.down.json | a11y.altText | מָה בָּאֶמְצַע? | needs-editor |
| activity.log.size.middle.json | prompt.caption.0.v | מָה בָּאֶמְצַע? | needs-editor |
| activity.log.size.middle.json | answer.options.0.label | כַּדּוּר קָטָן | needs-editor |
| activity.log.size.middle.json | answer.options.1.label | כַּדּוּר בֵּינוֹנִי | needs-editor |
| activity.log.size.middle.json | answer.options.2.label | כַּדּוּר גָּדוֹל | needs-editor |
| activity.log.size.middle.json | feedback.correct.caption.0.v | כֵּן! קָטָן, בֵּינוֹנִי, גָּדוֹל. | needs-editor |
| activity.log.size.middle.json | feedback.incorrect.0.caption.0.v | מְחַפְּשִׂים אֶת הָאֶמְצַע: לֹא הַכִּי קָטָן וְלֹא הַכִּי גָּדוֹל. | needs-editor |
| activity.log.size.middle.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.log.size.middle.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.log.size.middle.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.log.size.middle.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.log.size.middle.json | hints.2.caption.0.v | קָטָן, בֵּינוֹנִי, גָּדוֹל — בָּאֶמְצַע בָּא הַבֵּינוֹנִי. עַכְשָׁו תּוֹרְכֶם. | needs-editor |
| activity.log.size.middle.json | a11y.altText | מָה בָּאֶמְצַע? | needs-editor |
| activity.log.sort.animal.json | prompt.caption.0.v | לְאָן הוֹלֵךְ הַכֶּלֶב? | needs-editor |
| activity.log.sort.animal.json | answer.options.0.label | חָתוּל | needs-editor |
| activity.log.sort.animal.json | answer.options.1.label | כֶּלֶב | needs-editor |
| activity.log.sort.animal.json | feedback.correct.caption.0.v | כֵּן! זֶה כֶּלֶב. | needs-editor |
| activity.log.sort.animal.json | feedback.incorrect.0.caption.0.v | מְחַפְּשִׂים אֶת אוֹתוֹ צֶבַע, לֹא אוֹתוֹ דָּבָר. בּוֹאוּ נִבְדֹּק. | needs-editor |
| activity.log.sort.animal.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.log.sort.animal.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.log.sort.animal.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.log.sort.animal.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.log.sort.animal.json | hints.2.caption.0.v | הַכֶּלֶב הוֹלֵךְ אֶל הַכְּלָבִים. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל הַקְּבוּצָה. | needs-editor |
| activity.log.sort.animal.json | a11y.altText | לְאָן הוֹלֵךְ הַכֶּלֶב? | needs-editor |
| activity.log.sort.balloon.json | prompt.caption.0.v | לְאָן הוֹלֵךְ הַבָּלוֹן? | needs-editor |
| activity.log.sort.balloon.json | answer.options.0.label | בָּלוֹן יָרֹק | needs-editor |
| activity.log.sort.balloon.json | answer.options.1.label | בָּלוֹן צָהֹב | needs-editor |
| activity.log.sort.balloon.json | feedback.correct.caption.0.v | כֵּן! זֶה בָּלוֹן צָהֹב. | needs-editor |
| activity.log.sort.balloon.json | feedback.incorrect.0.caption.0.v | מְחַפְּשִׂים אֶת אוֹתוֹ צֶבַע, לֹא אוֹתוֹ דָּבָר. בּוֹאוּ נִבְדֹּק. | needs-editor |
| activity.log.sort.balloon.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.log.sort.balloon.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.log.sort.balloon.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.log.sort.balloon.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.log.sort.balloon.json | hints.2.caption.0.v | הַבָּלוֹן צָהֹב, אָז הוּא הוֹלֵךְ אֶל הַצְּהֻבִּים. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל הַקְּבוּצָה. | needs-editor |
| activity.log.sort.balloon.json | a11y.altText | לְאָן הוֹלֵךְ הַבָּלוֹן? | needs-editor |
| activity.log.sort.colour.json | prompt.caption.0.v | לְאָן הוֹלֵךְ הַכַּדּוּר? | needs-editor |
| activity.log.sort.colour.json | answer.options.0.label | כַּדּוּר כָּחֹל | needs-editor |
| activity.log.sort.colour.json | answer.options.1.label | כַּדּוּר אָדֹם | needs-editor |
| activity.log.sort.colour.json | feedback.correct.caption.0.v | כֵּן! זֶה כַּדּוּר אָדֹם. | needs-editor |
| activity.log.sort.colour.json | feedback.incorrect.0.caption.0.v | מְחַפְּשִׂים אֶת אוֹתוֹ צֶבַע, לֹא אוֹתוֹ דָּבָר. בּוֹאוּ נִבְדֹּק. | needs-editor |
| activity.log.sort.colour.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.log.sort.colour.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.log.sort.colour.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.log.sort.colour.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.log.sort.colour.json | hints.2.caption.0.v | הַכַּדּוּר אָדֹם, אָז הוּא הוֹלֵךְ אֶל הָאֲדֻמִּים. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל הַקְּבוּצָה. | needs-editor |
| activity.log.sort.colour.json | a11y.altText | לְאָן הוֹלֵךְ הַכַּדּוּר? | needs-editor |
| activity.log.sortdrag.animals.json | prompt.caption.0.v | מַעֲבִירִים כׇּל חַיָּה אֶל הַקְּבוּצָה שֶׁלָּהּ. | needs-editor |
| activity.log.sortdrag.animals.json | scene.bins.0.label | חָתוּל | needs-editor |
| activity.log.sortdrag.animals.json | scene.bins.1.label | כֶּלֶב | needs-editor |
| activity.log.sortdrag.animals.json | feedback.correct.caption.0.v | כֵּן! מִיַּנְתֶּם אֶת כֻּלָּם. | needs-editor |
| activity.log.sortdrag.animals.json | feedback.incorrect.0.caption.0.v | מְחַפְּשִׂים אֶת אוֹתוֹ צֶבַע, לֹא אוֹתוֹ דָּבָר. בּוֹאוּ נִבְדֹּק. | needs-editor |
| activity.log.sortdrag.animals.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.log.sortdrag.animals.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.log.sortdrag.animals.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.log.sortdrag.animals.json | hints.1.caption.0.v | נִסְתַּכֵּל עַל כׇּל קְבוּצָה, וְנִרְאֶה מָה יֵשׁ לָהּ. | needs-editor |
| activity.log.sortdrag.animals.json | hints.2.caption.0.v | הַחֲתוּלִים אֶל הַחֲתוּלִים, וְהַכְּלָבִים אֶל הַכְּלָבִים. עַכְשָׁו תּוֹרְכֶם. | needs-editor |
| activity.log.sortdrag.animals.json | a11y.altText | מַעֲבִירִים כׇּל חַיָּה אֶל הַקְּבוּצָה שֶׁלָּהּ. | needs-editor |
| activity.log.sortdrag.colour.json | prompt.caption.0.v | מַעֲבִירִים כׇּל כַּדּוּר אֶל הַקְּבוּצָה שֶׁלּוֹ. | needs-editor |
| activity.log.sortdrag.colour.json | scene.bins.0.label | כַּדּוּר אָדֹם | needs-editor |
| activity.log.sortdrag.colour.json | scene.bins.1.label | כַּדּוּר כָּחֹל | needs-editor |
| activity.log.sortdrag.colour.json | feedback.correct.caption.0.v | כֵּן! מִיַּנְתֶּם אֶת כֻּלָּם. | needs-editor |
| activity.log.sortdrag.colour.json | feedback.incorrect.0.caption.0.v | מְחַפְּשִׂים אֶת אוֹתוֹ צֶבַע, לֹא אוֹתוֹ דָּבָר. בּוֹאוּ נִבְדֹּק. | needs-editor |
| activity.log.sortdrag.colour.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.log.sortdrag.colour.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.log.sortdrag.colour.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.log.sortdrag.colour.json | hints.1.caption.0.v | נִסְתַּכֵּל עַל כׇּל קְבוּצָה, וְנִרְאֶה מָה יֵשׁ לָהּ. | needs-editor |
| activity.log.sortdrag.colour.json | hints.2.caption.0.v | הָאֲדֻמִּים אֶל הָאֲדֻמִּים, וְהַכְּחֻלִּים אֶל הַכְּחֻלִּים. עַכְשָׁו תּוֹרְכֶם. | needs-editor |
| activity.log.sortdrag.colour.json | a11y.altText | מַעֲבִירִים כׇּל כַּדּוּר אֶל הַקְּבוּצָה שֶׁלּוֹ. | needs-editor |
| activity.log.sortdrag.three.json | prompt.caption.0.v | מְמַיְּנִים לִשְׁלוֹשׁ קְבוּצוֹת. | needs-editor |
| activity.log.sortdrag.three.json | scene.bins.0.label | תַּפּוּחַ | needs-editor |
| activity.log.sortdrag.three.json | scene.bins.1.label | כּוֹכָב | needs-editor |
| activity.log.sortdrag.three.json | scene.bins.2.label | דָּג | needs-editor |
| activity.log.sortdrag.three.json | feedback.correct.caption.0.v | כֵּן! מִיַּנְתֶּם אֶת כֻּלָּם. | needs-editor |
| activity.log.sortdrag.three.json | feedback.incorrect.0.caption.0.v | מְחַפְּשִׂים אֶת אוֹתוֹ צֶבַע, לֹא אוֹתוֹ דָּבָר. בּוֹאוּ נִבְדֹּק. | needs-editor |
| activity.log.sortdrag.three.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.log.sortdrag.three.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.log.sortdrag.three.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.log.sortdrag.three.json | hints.1.caption.0.v | נִסְתַּכֵּל עַל כׇּל קְבוּצָה, וְנִרְאֶה מָה יֵשׁ לָהּ. | needs-editor |
| activity.log.sortdrag.three.json | hints.2.caption.0.v | תַּפּוּחִים עִם תַּפּוּחִים, כּוֹכָבִים עִם כּוֹכָבִים, דָּגִים עִם דָּגִים. עַכְשָׁו תּוֹרְכֶם. | needs-editor |
| activity.log.sortdrag.three.json | a11y.altText | מְמַיְּנִים לִשְׁלוֹשׁ קְבוּצוֹת. | needs-editor |
| activity.log.story.egg.then.json | prompt.caption.0.v | הַבֵּיצָה נִסְדְּקָה. מָה בָּא אַחַר כָּךְ? | needs-editor |
| activity.log.story.egg.then.json | answer.options.0.label | בֵּיצָה | needs-editor |
| activity.log.story.egg.then.json | answer.options.1.label | אֶפְרוֹחַ | needs-editor |
| activity.log.story.egg.then.json | answer.options.2.label | זֶרַע | needs-editor |
| activity.log.story.egg.then.json | feedback.correct.caption.0.v | כֵּן! אַחַר כָּךְ יוֹצֵא אֶפְרוֹחַ. | needs-editor |
| activity.log.story.egg.then.json | feedback.incorrect.0.caption.0.v | בּוֹאוּ נַחְשֹׁב: מָה קוֹרֶה קֹדֶם, וּמָה אַחַר כָּךְ? | needs-editor |
| activity.log.story.egg.then.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.log.story.egg.then.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.log.story.egg.then.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.log.story.egg.then.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.log.story.egg.then.json | hints.2.caption.0.v | הַבֵּיצָה נִסְדְּקָה, וְאַחַר כָּךְ יוֹצֵא אֶפְרוֹחַ. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל הָאֶפְרוֹחַ. | needs-editor |
| activity.log.story.egg.then.json | a11y.altText | הַבֵּיצָה נִסְדְּקָה. מָה בָּא אַחַר כָּךְ? | needs-editor |
| activity.log.story.plant.first.json | prompt.caption.0.v | מָה קוֹרֶה קֹדֶם? | needs-editor |
| activity.log.story.plant.first.json | answer.options.0.label | פֶּרַח | needs-editor |
| activity.log.story.plant.first.json | answer.options.1.label | זֶרַע | needs-editor |
| activity.log.story.plant.first.json | answer.options.2.label | נֵבֶט | needs-editor |
| activity.log.story.plant.first.json | feedback.correct.caption.0.v | כֵּן! קֹדֶם שׁוֹתְלִים זֶרַע. | needs-editor |
| activity.log.story.plant.first.json | feedback.incorrect.0.caption.0.v | בּוֹאוּ נַחְשֹׁב: מָה קוֹרֶה קֹדֶם, וּמָה אַחַר כָּךְ? | needs-editor |
| activity.log.story.plant.first.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.log.story.plant.first.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.log.story.plant.first.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.log.story.plant.first.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.log.story.plant.first.json | hints.2.caption.0.v | קֹדֶם זֶרַע, אַחַר כָּךְ נֵבֶט, וּבַסּוֹף פֶּרַח. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל הַזֶּרַע. | needs-editor |
| activity.log.story.plant.first.json | a11y.altText | מָה קוֹרֶה קֹדֶם? | needs-editor |
| activity.log.story.plant.last.json | prompt.caption.0.v | מָה קוֹרֶה בַּסּוֹף? | needs-editor |
| activity.log.story.plant.last.json | answer.options.0.label | זֶרַע | needs-editor |
| activity.log.story.plant.last.json | answer.options.1.label | פֶּרַח | needs-editor |
| activity.log.story.plant.last.json | answer.options.2.label | נֵבֶט | needs-editor |
| activity.log.story.plant.last.json | feedback.correct.caption.0.v | כֵּן! בַּסּוֹף הַזֶּרַע נַעֲשָׂה פֶּרַח. | needs-editor |
| activity.log.story.plant.last.json | feedback.incorrect.0.caption.0.v | בּוֹאוּ נַחְשֹׁב: מָה קוֹרֶה קֹדֶם, וּמָה אַחַר כָּךְ? | needs-editor |
| activity.log.story.plant.last.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.log.story.plant.last.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.log.story.plant.last.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.log.story.plant.last.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.log.story.plant.last.json | hints.2.caption.0.v | קֹדֶם זֶרַע, אַחַר כָּךְ נֵבֶט, וּבַסּוֹף פֶּרַח. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל הַפֶּרַח. | needs-editor |
| activity.log.story.plant.last.json | a11y.altText | מָה קוֹרֶה בַּסּוֹף? | needs-editor |
| activity.math.add.apples.json | prompt.caption.0.v | יֵשׁ שְׁלוֹשָׁה תַּפּוּחִים, וּבָא עוֹד תַּפּוּחַ אֶחָד. כַּמָּה עַכְשָׁו? | needs-editor |
| activity.math.add.apples.json | answer.options.0.label | שָׁלוֹשׁ | needs-editor |
| activity.math.add.apples.json | answer.options.1.label | אַרְבַּע | needs-editor |
| activity.math.add.apples.json | answer.options.2.label | חָמֵשׁ | needs-editor |
| activity.math.add.apples.json | feedback.correct.caption.0.v | אַרְבַּע! שְׁלוֹשָׁה וְעוֹד אֶחָד. | needs-editor |
| activity.math.add.apples.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.math.add.apples.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.math.add.apples.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.math.add.apples.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.math.add.apples.json | hints.2.caption.0.v | שְׁלוֹשָׁה תַּפּוּחִים וְעוֹד אֶחָד: אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל אַרְבַּע. | needs-editor |
| activity.math.add.apples.json | a11y.altText | יֵשׁ שְׁלוֹשָׁה תַּפּוּחִים, וּבָא עוֹד תַּפּוּחַ אֶחָד. כַּמָּה עַכְשָׁו? | needs-editor |
| activity.math.add.ducks.json | prompt.caption.0.v | יֵשׁ שְׁנֵי בַּרְוָזִים, וּבָא עוֹד בַּרְוָז אֶחָד. כַּמָּה עַכְשָׁו? | needs-editor |
| activity.math.add.ducks.json | answer.options.0.label | שְׁתַּיִם | needs-editor |
| activity.math.add.ducks.json | answer.options.1.label | שָׁלוֹשׁ | needs-editor |
| activity.math.add.ducks.json | answer.options.2.label | אַרְבַּע | needs-editor |
| activity.math.add.ducks.json | feedback.correct.caption.0.v | שָׁלוֹשׁ! שְׁנַיִם וְעוֹד אֶחָד. | needs-editor |
| activity.math.add.ducks.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.math.add.ducks.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.math.add.ducks.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.math.add.ducks.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.math.add.ducks.json | hints.2.caption.0.v | שְׁנֵי בַּרְוָזִים וְעוֹד אֶחָד: אַחַת, שְׁתַּיִם, שָׁלוֹשׁ. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל שָׁלוֹשׁ. | needs-editor |
| activity.math.add.ducks.json | a11y.altText | יֵשׁ שְׁנֵי בַּרְוָזִים, וּבָא עוֹד בַּרְוָז אֶחָד. כַּמָּה עַכְשָׁו? | needs-editor |
| activity.math.add.fish.json | prompt.caption.0.v | יֵשׁ שְׁנֵי דָּגִים, וּבָאוּ עוֹד שְׁנֵי דָּגִים. כַּמָּה עַכְשָׁו? | needs-editor |
| activity.math.add.fish.json | answer.options.0.label | שָׁלוֹשׁ | needs-editor |
| activity.math.add.fish.json | answer.options.1.label | אַרְבַּע | needs-editor |
| activity.math.add.fish.json | answer.options.2.label | חָמֵשׁ | needs-editor |
| activity.math.add.fish.json | feedback.correct.caption.0.v | אַרְבַּע! שְׁנַיִם וְעוֹד שְׁנַיִם. | needs-editor |
| activity.math.add.fish.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.math.add.fish.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.math.add.fish.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.math.add.fish.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.math.add.fish.json | hints.2.caption.0.v | שְׁנֵי דָּגִים וְעוֹד שְׁנַיִם: אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל אַרְבַּע. | needs-editor |
| activity.math.add.fish.json | a11y.altText | יֵשׁ שְׁנֵי דָּגִים, וּבָאוּ עוֹד שְׁנֵי דָּגִים. כַּמָּה עַכְשָׁו? | needs-editor |
| activity.math.add.stars.json | prompt.caption.0.v | יֵשׁ שְׁלוֹשָׁה כּוֹכָבִים, וּבָאוּ עוֹד שְׁנֵי כּוֹכָבִים. כַּמָּה עַכְשָׁו? | needs-editor |
| activity.math.add.stars.json | answer.options.0.label | אַרְבַּע | needs-editor |
| activity.math.add.stars.json | answer.options.1.label | חָמֵשׁ | needs-editor |
| activity.math.add.stars.json | answer.options.2.label | שֵׁשׁ | needs-editor |
| activity.math.add.stars.json | feedback.correct.caption.0.v | חָמֵשׁ! שְׁלוֹשָׁה וְעוֹד שְׁנַיִם. | needs-editor |
| activity.math.add.stars.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.math.add.stars.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.math.add.stars.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.math.add.stars.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.math.add.stars.json | hints.2.caption.0.v | שְׁלוֹשָׁה כּוֹכָבִים וְעוֹד שְׁנַיִם: אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע, חָמֵשׁ. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל חָמֵשׁ. | needs-editor |
| activity.math.add.stars.json | a11y.altText | יֵשׁ שְׁלוֹשָׁה כּוֹכָבִים, וּבָאוּ עוֹד שְׁנֵי כּוֹכָבִים. כַּמָּה עַכְשָׁו? | needs-editor |
| activity.math.graph.apples.json | prompt.caption.0.v | אֵיפֹה יֵשׁ יוֹתֵר תַּפּוּחִים? | needs-editor |
| activity.math.graph.apples.json | answer.options.0.label | חֲמִשָּׁה תַּפּוּחִים | needs-editor |
| activity.math.graph.apples.json | answer.options.1.label | שְׁנֵי תַּפּוּחִים | needs-editor |
| activity.math.graph.apples.json | feedback.correct.caption.0.v | כֵּן! כָּאן יֵשׁ יוֹתֵר תַּפּוּחִים. | needs-editor |
| activity.math.graph.apples.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.math.graph.apples.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.math.graph.apples.json | hints.0.caption.0.v | בּוֹאוּ נִסְתַּכֵּל שׁוּב עַל שְׁנֵי הַצְּדָדִים. | needs-editor |
| activity.math.graph.apples.json | hints.1.caption.0.v | נַשְׁוֶה אֶחָד אֶחָד: לְכׇל אֶחָד מִצַּד זֶה, אֶחָד מִצַּד זֶה. | needs-editor |
| activity.math.graph.apples.json | hints.2.caption.0.v | בְּצַד אֶחָד יֵשׁ חֲמִשָּׁה תַּפּוּחִים, וּבַצַּד הָאַחֵר שְׁנֵי תַּפּוּחִים. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל הַנְּכוֹנָה. | needs-editor |
| activity.math.graph.apples.json | a11y.altText | אֵיפֹה יֵשׁ יוֹתֵר תַּפּוּחִים? | needs-editor |
| activity.math.graph.fish.json | prompt.caption.0.v | אֵיפֹה יֵשׁ יוֹתֵר דָּגִים? | needs-editor |
| activity.math.graph.fish.json | answer.options.0.label | שְׁלוֹשָׁה דָּגִים | needs-editor |
| activity.math.graph.fish.json | answer.options.1.label | אַרְבָּעָה דָּגִים | needs-editor |
| activity.math.graph.fish.json | feedback.correct.caption.0.v | כֵּן! כָּאן יֵשׁ יוֹתֵר דָּגִים. | needs-editor |
| activity.math.graph.fish.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.math.graph.fish.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.math.graph.fish.json | hints.0.caption.0.v | בּוֹאוּ נִסְתַּכֵּל שׁוּב עַל שְׁנֵי הַצְּדָדִים. | needs-editor |
| activity.math.graph.fish.json | hints.1.caption.0.v | נַשְׁוֶה אֶחָד אֶחָד: לְכׇל אֶחָד מִצַּד זֶה, אֶחָד מִצַּד זֶה. | needs-editor |
| activity.math.graph.fish.json | hints.2.caption.0.v | בְּצַד אֶחָד יֵשׁ אַרְבָּעָה דָּגִים, וּבַצַּד הָאַחֵר שְׁלוֹשָׁה דָּגִים. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל הַנְּכוֹנָה. | needs-editor |
| activity.math.graph.fish.json | a11y.altText | אֵיפֹה יֵשׁ יוֹתֵר דָּגִים? | needs-editor |
| activity.math.graph.stars.json | prompt.caption.0.v | אֵיפֹה יֵשׁ פָּחוֹת כּוֹכָבִים? | needs-editor |
| activity.math.graph.stars.json | answer.options.0.label | אַרְבָּעָה כּוֹכָבִים | needs-editor |
| activity.math.graph.stars.json | answer.options.1.label | שְׁנֵי כּוֹכָבִים | needs-editor |
| activity.math.graph.stars.json | feedback.correct.caption.0.v | כֵּן! כָּאן יֵשׁ פָּחוֹת כּוֹכָבִים. | needs-editor |
| activity.math.graph.stars.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.math.graph.stars.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.math.graph.stars.json | hints.0.caption.0.v | בּוֹאוּ נִסְתַּכֵּל שׁוּב עַל שְׁנֵי הַצְּדָדִים. | needs-editor |
| activity.math.graph.stars.json | hints.1.caption.0.v | נַשְׁוֶה אֶחָד אֶחָד: לְכׇל אֶחָד מִצַּד זֶה, אֶחָד מִצַּד זֶה. | needs-editor |
| activity.math.graph.stars.json | hints.2.caption.0.v | בְּצַד אֶחָד יֵשׁ שְׁנֵי כּוֹכָבִים, וּבַצַּד הָאַחֵר אַרְבָּעָה כּוֹכָבִים. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל הַנְּכוֹנָה. | needs-editor |
| activity.math.graph.stars.json | a11y.altText | אֵיפֹה יֵשׁ פָּחוֹת כּוֹכָבִים? | needs-editor |
| activity.math.share.apples.json | prompt.caption.0.v | מְחַלְּקִים אַרְבָּעָה תַּפּוּחִים בֵּין הֶחָתוּל לַכֶּלֶב. לִשְׁנֵיהֶם אוֹתוֹ מִסְפָּר. | needs-editor |
| activity.math.share.apples.json | scene.bins.0.label | חָתוּל | needs-editor |
| activity.math.share.apples.json | scene.bins.1.label | כֶּלֶב | needs-editor |
| activity.math.share.apples.json | feedback.correct.caption.0.v | כֵּן! לִשְׁנֵיהֶם יֵשׁ אוֹתוֹ מִסְפָּר. | needs-editor |
| activity.math.share.apples.json | feedback.incorrect.0.caption.0.v | בּוֹאוּ נַחֲלֹק אֶחָד אֶחָד, לְכׇל חָבֵר בַּתּוֹר. | needs-editor |
| activity.math.share.apples.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.math.share.apples.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.math.share.apples.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.math.share.apples.json | hints.1.caption.0.v | נַחֲלֹק אֶחָד לָזֶה, וְאֶחָד לָזֶה, בַּתּוֹר. | needs-editor |
| activity.math.share.apples.json | hints.2.caption.0.v | אֶחָד לָזֶה, אֶחָד לָזֶה, עַד שֶׁנִּגְמַר. לְכׇל אֶחָד יֵשׁ אוֹתוֹ מִסְפָּר. עַכְשָׁו תּוֹרְכֶם. | needs-editor |
| activity.math.share.apples.json | a11y.altText | מְחַלְּקִים אַרְבָּעָה תַּפּוּחִים בֵּין הֶחָתוּל לַכֶּלֶב. לִשְׁנֵיהֶם אוֹתוֹ מִסְפָּר. | needs-editor |
| activity.math.share.fish.json | prompt.caption.0.v | מְחַלְּקִים שְׁנֵי דָּגִים בֵּין הֶחָתוּל לַכֶּלֶב. לִשְׁנֵיהֶם אוֹתוֹ מִסְפָּר. | needs-editor |
| activity.math.share.fish.json | scene.bins.0.label | חָתוּל | needs-editor |
| activity.math.share.fish.json | scene.bins.1.label | כֶּלֶב | needs-editor |
| activity.math.share.fish.json | feedback.correct.caption.0.v | כֵּן! לִשְׁנֵיהֶם יֵשׁ אוֹתוֹ מִסְפָּר. | needs-editor |
| activity.math.share.fish.json | feedback.incorrect.0.caption.0.v | בּוֹאוּ נַחֲלֹק אֶחָד אֶחָד, לְכׇל חָבֵר בַּתּוֹר. | needs-editor |
| activity.math.share.fish.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.math.share.fish.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.math.share.fish.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.math.share.fish.json | hints.1.caption.0.v | נַחֲלֹק אֶחָד לָזֶה, וְאֶחָד לָזֶה, בַּתּוֹר. | needs-editor |
| activity.math.share.fish.json | hints.2.caption.0.v | אֶחָד לָזֶה, אֶחָד לָזֶה, עַד שֶׁנִּגְמַר. לְכׇל אֶחָד יֵשׁ אוֹתוֹ מִסְפָּר. עַכְשָׁו תּוֹרְכֶם. | needs-editor |
| activity.math.share.fish.json | a11y.altText | מְחַלְּקִים שְׁנֵי דָּגִים בֵּין הֶחָתוּל לַכֶּלֶב. לִשְׁנֵיהֶם אוֹתוֹ מִסְפָּר. | needs-editor |
| activity.math.share.stars.json | prompt.caption.0.v | מְחַלְּקִים שִׁשָּׁה כּוֹכָבִים בֵּין הֶחָתוּל לַכֶּלֶב. לִשְׁנֵיהֶם אוֹתוֹ מִסְפָּר. | needs-editor |
| activity.math.share.stars.json | scene.bins.0.label | חָתוּל | needs-editor |
| activity.math.share.stars.json | scene.bins.1.label | כֶּלֶב | needs-editor |
| activity.math.share.stars.json | feedback.correct.caption.0.v | כֵּן! לִשְׁנֵיהֶם יֵשׁ אוֹתוֹ מִסְפָּר. | needs-editor |
| activity.math.share.stars.json | feedback.incorrect.0.caption.0.v | בּוֹאוּ נַחֲלֹק אֶחָד אֶחָד, לְכׇל חָבֵר בַּתּוֹר. | needs-editor |
| activity.math.share.stars.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.math.share.stars.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.math.share.stars.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.math.share.stars.json | hints.1.caption.0.v | נַחֲלֹק אֶחָד לָזֶה, וְאֶחָד לָזֶה, בַּתּוֹר. | needs-editor |
| activity.math.share.stars.json | hints.2.caption.0.v | אֶחָד לָזֶה, אֶחָד לָזֶה, עַד שֶׁנִּגְמַר. לְכׇל אֶחָד יֵשׁ אוֹתוֹ מִסְפָּר. עַכְשָׁו תּוֹרְכֶם. | needs-editor |
| activity.math.share.stars.json | a11y.altText | מְחַלְּקִים שִׁשָּׁה כּוֹכָבִים בֵּין הֶחָתוּל לַכֶּלֶב. לִשְׁנֵיהֶם אוֹתוֹ מִסְפָּר. | needs-editor |
| activity.math.shop.apples.json | prompt.caption.0.v | כׇּל תַּפּוּחַ עוֹלֶה מַטְבֵּעַ אֶחָד. קוֹנִים שְׁלוֹשָׁה תַּפּוּחִים. | needs-editor |
| activity.math.shop.apples.json | feedback.correct.caption.0.v | שָׁלוֹשׁ! מַטְבֵּעַ אֶחָד לְכׇל תַּפּוּחַ. | needs-editor |
| activity.math.shop.apples.json | feedback.incorrect.0.caption.0.v | לָקַחְנוּ אֶת כֻּלָּם. הַפֶּרַח רוֹצֶה רַק אַרְבָּעָה — בּוֹאוּ נִסְפֹּר אוֹתָם. | needs-editor |
| activity.math.shop.apples.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.math.shop.apples.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.math.shop.apples.json | hints.0.caption.0.v | תְּנוּ לִי שְׁלוֹשָׁה מַטְבְּעוֹת. סוֹפְרִים תוֹךְ כְּדֵי שֶׁלּוֹקְחִים. | needs-editor |
| activity.math.shop.apples.json | hints.1.caption.0.v | נִסְפֹּר עִם הָאֶצְבָּעוֹת: אַחַת, שְׁתַּיִם, שָׁלוֹשׁ. | needs-editor |
| activity.math.shop.apples.json | hints.2.caption.0.v | אַחַת, שְׁתַּיִם, שָׁלוֹשׁ. עֲצְרוּ כְּשֶׁהִגַּעְנוּ אֶל שָׁלוֹשׁ. עַכְשָׁו תּוֹרְכֶם. | needs-editor |
| activity.math.shop.apples.json | a11y.altText | כׇּל תַּפּוּחַ עוֹלֶה מַטְבֵּעַ אֶחָד. קוֹנִים שְׁלוֹשָׁה תַּפּוּחִים. | needs-editor |
| activity.math.shop.fish.json | prompt.caption.0.v | כׇּל דָּג עוֹלֶה מַטְבֵּעַ אֶחָד. קוֹנִים שְׁנֵי דָּגִים. | needs-editor |
| activity.math.shop.fish.json | feedback.correct.caption.0.v | שְׁתַּיִם! מַטְבֵּעַ אֶחָד לְכׇל דָּג. | needs-editor |
| activity.math.shop.fish.json | feedback.incorrect.0.caption.0.v | לָקַחְנוּ אֶת כֻּלָּם. הַפֶּרַח רוֹצֶה רַק אַרְבָּעָה — בּוֹאוּ נִסְפֹּר אוֹתָם. | needs-editor |
| activity.math.shop.fish.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.math.shop.fish.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.math.shop.fish.json | hints.0.caption.0.v | תְּנוּ לִי שְׁנֵי מַטְבְּעוֹת. סוֹפְרִים תוֹךְ כְּדֵי שֶׁלּוֹקְחִים. | needs-editor |
| activity.math.shop.fish.json | hints.1.caption.0.v | נִסְפֹּר עִם הָאֶצְבָּעוֹת: אַחַת, שְׁתַּיִם. | needs-editor |
| activity.math.shop.fish.json | hints.2.caption.0.v | אַחַת, שְׁתַּיִם. עֲצְרוּ כְּשֶׁהִגַּעְנוּ אֶל שְׁתַּיִם. עַכְשָׁו תּוֹרְכֶם. | needs-editor |
| activity.math.shop.fish.json | a11y.altText | כׇּל דָּג עוֹלֶה מַטְבֵּעַ אֶחָד. קוֹנִים שְׁנֵי דָּגִים. | needs-editor |
| activity.math.shop.stars.json | prompt.caption.0.v | כׇּל כּוֹכָב עוֹלֶה מַטְבֵּעַ אֶחָד. קוֹנִים אַרְבָּעָה כּוֹכָבִים. | needs-editor |
| activity.math.shop.stars.json | feedback.correct.caption.0.v | אַרְבַּע! מַטְבֵּעַ אֶחָד לְכׇל כּוֹכָב. | needs-editor |
| activity.math.shop.stars.json | feedback.incorrect.0.caption.0.v | לָקַחְנוּ אֶת כֻּלָּם. הַפֶּרַח רוֹצֶה רַק אַרְבָּעָה — בּוֹאוּ נִסְפֹּר אוֹתָם. | needs-editor |
| activity.math.shop.stars.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.math.shop.stars.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.math.shop.stars.json | hints.0.caption.0.v | תְּנוּ לִי אַרְבָּעָה מַטְבְּעוֹת. סוֹפְרִים תוֹךְ כְּדֵי שֶׁלּוֹקְחִים. | needs-editor |
| activity.math.shop.stars.json | hints.1.caption.0.v | נִסְפֹּר עִם הָאֶצְבָּעוֹת: אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע. | needs-editor |
| activity.math.shop.stars.json | hints.2.caption.0.v | אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע. עֲצְרוּ כְּשֶׁהִגַּעְנוּ אֶל אַרְבַּע. עַכְשָׁו תּוֹרְכֶם. | needs-editor |
| activity.math.shop.stars.json | a11y.altText | כׇּל כּוֹכָב עוֹלֶה מַטְבֵּעַ אֶחָד. קוֹנִים אַרְבָּעָה כּוֹכָבִים. | needs-editor |
| activity.math.size.big.json | prompt.caption.0.v | אֵיזֶה כַּדּוּר גָּדוֹל? | needs-editor |
| activity.math.size.big.json | answer.options.0.label | כַּדּוּר אָדֹם | needs-editor |
| activity.math.size.big.json | answer.options.1.label | כַּדּוּר אָדֹם | needs-editor |
| activity.math.size.big.json | feedback.correct.caption.0.v | כֵּן! זֶה הַכַּדּוּר הַגָּדוֹל. | needs-editor |
| activity.math.size.big.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.math.size.big.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.math.size.big.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.math.size.big.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.math.size.big.json | hints.2.caption.0.v | הַכַּדּוּר הַגָּדוֹל תּוֹפֵס יוֹתֵר מָקוֹם. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.math.size.big.json | a11y.altText | אֵיזֶה כַּדּוּר גָּדוֹל? | needs-editor |
| activity.math.size.heavy.json | prompt.caption.0.v | מָה כָּבֵד? | needs-editor |
| activity.math.size.heavy.json | answer.options.0.label | נוֹצָה | needs-editor |
| activity.math.size.heavy.json | answer.options.1.label | אֶבֶן | needs-editor |
| activity.math.size.heavy.json | feedback.correct.caption.0.v | כֵּן! אֶבֶן כְּבֵדָה. | needs-editor |
| activity.math.size.heavy.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.math.size.heavy.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.math.size.heavy.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.math.size.heavy.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.math.size.heavy.json | hints.2.caption.0.v | אֶבֶן כְּבֵדָה, וְנוֹצָה קַלָּה. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל הָאֶבֶן. | needs-editor |
| activity.math.size.heavy.json | a11y.altText | מָה כָּבֵד? | needs-editor |
| activity.math.size.light.json | prompt.caption.0.v | מָה קַל? | needs-editor |
| activity.math.size.light.json | answer.options.0.label | אֶבֶן | needs-editor |
| activity.math.size.light.json | answer.options.1.label | נוֹצָה | needs-editor |
| activity.math.size.light.json | feedback.correct.caption.0.v | כֵּן! נוֹצָה קַלָּה. | needs-editor |
| activity.math.size.light.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.math.size.light.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.math.size.light.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.math.size.light.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.math.size.light.json | hints.2.caption.0.v | נוֹצָה קַלָּה, וְאֶבֶן כְּבֵדָה. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל הַנּוֹצָה. | needs-editor |
| activity.math.size.light.json | a11y.altText | מָה קַל? | needs-editor |
| activity.math.size.long.json | prompt.caption.0.v | אֵיזֶה מַקֵּל אָרֹךְ? | needs-editor |
| activity.math.size.long.json | answer.options.0.label | מַקֵּל קָצָר | needs-editor |
| activity.math.size.long.json | answer.options.1.label | מַקֵּל אָרֹךְ | needs-editor |
| activity.math.size.long.json | feedback.correct.caption.0.v | כֵּן! הַמַּקֵּל הָאָרֹךְ. | needs-editor |
| activity.math.size.long.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.math.size.long.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.math.size.long.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.math.size.long.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.math.size.long.json | hints.2.caption.0.v | הַמַּקֵּל הָאָרֹךְ מַגִּיעַ רָחוֹק יוֹתֵר. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.math.size.long.json | a11y.altText | אֵיזֶה מַקֵּל אָרֹךְ? | needs-editor |
| activity.math.size.short.json | prompt.caption.0.v | אֵיזֶה מַקֵּל קָצָר? | needs-editor |
| activity.math.size.short.json | answer.options.0.label | מַקֵּל אָרֹךְ | needs-editor |
| activity.math.size.short.json | answer.options.1.label | מַקֵּל קָצָר | needs-editor |
| activity.math.size.short.json | feedback.correct.caption.0.v | כֵּן! הַמַּקֵּל הַקָּצָר. | needs-editor |
| activity.math.size.short.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.math.size.short.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.math.size.short.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.math.size.short.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.math.size.short.json | hints.2.caption.0.v | הַמַּקֵּל הַקָּצָר מַגִּיעַ פָּחוֹת רָחוֹק. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.math.size.short.json | a11y.altText | אֵיזֶה מַקֵּל קָצָר? | needs-editor |
| activity.math.size.small.json | prompt.caption.0.v | אֵיזֶה כַּדּוּר קָטָן? | needs-editor |
| activity.math.size.small.json | answer.options.0.label | כַּדּוּר אָדֹם | needs-editor |
| activity.math.size.small.json | answer.options.1.label | כַּדּוּר אָדֹם | needs-editor |
| activity.math.size.small.json | feedback.correct.caption.0.v | כֵּן! זֶה הַכַּדּוּר הַקָּטָן. | needs-editor |
| activity.math.size.small.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.math.size.small.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.math.size.small.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.math.size.small.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.math.size.small.json | hints.2.caption.0.v | הַכַּדּוּר הַקָּטָן תּוֹפֵס פָּחוֹת מָקוֹם. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.math.size.small.json | a11y.altText | אֵיזֶה כַּדּוּר קָטָן? | needs-editor |
| activity.math.take.apples.json | prompt.caption.0.v | יֵשׁ אַרְבָּעָה תַּפּוּחִים. אֶחָד נֶאֱכַל. כַּמָּה נִשְׁאֲרוּ? | needs-editor |
| activity.math.take.apples.json | answer.options.0.label | שְׁתַּיִם | needs-editor |
| activity.math.take.apples.json | answer.options.1.label | שָׁלוֹשׁ | needs-editor |
| activity.math.take.apples.json | answer.options.2.label | אַרְבַּע | needs-editor |
| activity.math.take.apples.json | feedback.correct.caption.0.v | שָׁלוֹשׁ! אַרְבָּעָה פָּחוֹת אֶחָד. | needs-editor |
| activity.math.take.apples.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.math.take.apples.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.math.take.apples.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.math.take.apples.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.math.take.apples.json | hints.2.caption.0.v | אַרְבָּעָה פָּחוֹת אֶחָד: אַחַת, שְׁתַּיִם, שָׁלוֹשׁ. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל שָׁלוֹשׁ. | needs-editor |
| activity.math.take.apples.json | a11y.altText | יֵשׁ אַרְבָּעָה תַּפּוּחִים. אֶחָד נֶאֱכַל. כַּמָּה נִשְׁאֲרוּ? | needs-editor |
| activity.math.take.fish.json | prompt.caption.0.v | יֵשׁ שְׁלוֹשָׁה דָּגִים. אֶחָד שָׂחָה לְהֵרָחֵק. כַּמָּה נִשְׁאֲרוּ? | needs-editor |
| activity.math.take.fish.json | answer.options.0.label | אַחַת | needs-editor |
| activity.math.take.fish.json | answer.options.1.label | שְׁתַּיִם | needs-editor |
| activity.math.take.fish.json | answer.options.2.label | שָׁלוֹשׁ | needs-editor |
| activity.math.take.fish.json | feedback.correct.caption.0.v | שְׁתַּיִם! שְׁלוֹשָׁה פָּחוֹת אֶחָד. | needs-editor |
| activity.math.take.fish.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.math.take.fish.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.math.take.fish.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.math.take.fish.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.math.take.fish.json | hints.2.caption.0.v | שְׁלוֹשָׁה פָּחוֹת אֶחָד: אַחַת, שְׁתַּיִם. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל שְׁתַּיִם. | needs-editor |
| activity.math.take.fish.json | a11y.altText | יֵשׁ שְׁלוֹשָׁה דָּגִים. אֶחָד שָׂחָה לְהֵרָחֵק. כַּמָּה נִשְׁאֲרוּ? | needs-editor |
| activity.math.take.stars.json | prompt.caption.0.v | יֵשׁ חֲמִשָּׁה כּוֹכָבִים. אֶחָד נָפַל. כַּמָּה נִשְׁאֲרוּ? | needs-editor |
| activity.math.take.stars.json | answer.options.0.label | שָׁלוֹשׁ | needs-editor |
| activity.math.take.stars.json | answer.options.1.label | אַרְבַּע | needs-editor |
| activity.math.take.stars.json | answer.options.2.label | חָמֵשׁ | needs-editor |
| activity.math.take.stars.json | feedback.correct.caption.0.v | אַרְבַּע! חֲמִשָּׁה פָּחוֹת אֶחָד. | needs-editor |
| activity.math.take.stars.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.math.take.stars.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.math.take.stars.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.math.take.stars.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.math.take.stars.json | hints.2.caption.0.v | חֲמִשָּׁה פָּחוֹת אֶחָד: אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל אַרְבַּע. | needs-editor |
| activity.math.take.stars.json | a11y.altText | יֵשׁ חֲמִשָּׁה כּוֹכָבִים. אֶחָד נָפַל. כַּמָּה נִשְׁאֲרוּ? | needs-editor |
| activity.math.time.after.json | prompt.caption.0.v | מָה בָּא אַחֲרֵי הַבֹּקֶר? | needs-editor |
| activity.math.time.after.json | answer.options.0.label | לַיְלָה | needs-editor |
| activity.math.time.after.json | answer.options.1.label | צָהֳרַיִם | needs-editor |
| activity.math.time.after.json | answer.options.2.label | בֹּקֶר | needs-editor |
| activity.math.time.after.json | feedback.correct.caption.0.v | כֵּן! אַחֲרֵי הַבֹּקֶר בָּאִים הַצָּהֳרַיִם. | needs-editor |
| activity.math.time.after.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.math.time.after.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.math.time.after.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.math.time.after.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.math.time.after.json | hints.2.caption.0.v | קֹדֶם בֹּקֶר, אַחַר כָּךְ צָהֳרַיִם, אַחַר כָּךְ עֶרֶב, וּבַסּוֹף לַיְלָה. עַכְשָׁו תּוֹרְכֶם. | needs-editor |
| activity.math.time.after.json | a11y.altText | מָה בָּא אַחֲרֵי הַבֹּקֶר? | needs-editor |
| activity.math.time.evening.json | prompt.caption.0.v | אֵיזוֹ תְּמוּנָה הִיא עֶרֶב? | needs-editor |
| activity.math.time.evening.json | answer.options.0.label | בֹּקֶר | needs-editor |
| activity.math.time.evening.json | answer.options.1.label | צָהֳרַיִם | needs-editor |
| activity.math.time.evening.json | answer.options.2.label | עֶרֶב | needs-editor |
| activity.math.time.evening.json | feedback.correct.caption.0.v | כֵּן! בָּעֶרֶב הַשֶּׁמֶשׁ יוֹרֶדֶת. | needs-editor |
| activity.math.time.evening.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.math.time.evening.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.math.time.evening.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.math.time.evening.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.math.time.evening.json | hints.2.caption.0.v | בָּעֶרֶב הַשֶּׁמֶשׁ יוֹרֶדֶת וְהַשָּׁמַיִם כְּתֻמִּים. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל הָעֶרֶב. | needs-editor |
| activity.math.time.evening.json | a11y.altText | אֵיזוֹ תְּמוּנָה הִיא עֶרֶב? | needs-editor |
| activity.math.time.morning.json | prompt.caption.0.v | אֵיזוֹ תְּמוּנָה הִיא בֹּקֶר? | needs-editor |
| activity.math.time.morning.json | answer.options.0.label | לַיְלָה | needs-editor |
| activity.math.time.morning.json | answer.options.1.label | בֹּקֶר | needs-editor |
| activity.math.time.morning.json | answer.options.2.label | צָהֳרַיִם | needs-editor |
| activity.math.time.morning.json | feedback.correct.caption.0.v | כֵּן! בַּבֹּקֶר הַשֶּׁמֶשׁ עוֹלָה. | needs-editor |
| activity.math.time.morning.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.math.time.morning.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.math.time.morning.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.math.time.morning.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.math.time.morning.json | hints.2.caption.0.v | בַּבֹּקֶר הַשֶּׁמֶשׁ עוֹלָה לְאַט. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל הַבֹּקֶר. | needs-editor |
| activity.math.time.morning.json | a11y.altText | אֵיזוֹ תְּמוּנָה הִיא בֹּקֶר? | needs-editor |
| activity.math.time.night.json | prompt.caption.0.v | אֵיזוֹ תְּמוּנָה הִיא לַיְלָה? | needs-editor |
| activity.math.time.night.json | answer.options.0.label | לַיְלָה | needs-editor |
| activity.math.time.night.json | answer.options.1.label | צָהֳרַיִם | needs-editor |
| activity.math.time.night.json | answer.options.2.label | בֹּקֶר | needs-editor |
| activity.math.time.night.json | feedback.correct.caption.0.v | כֵּן! בַּלַּיְלָה יֵשׁ יָרֵחַ וְכוֹכָבִים. | needs-editor |
| activity.math.time.night.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.math.time.night.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.math.time.night.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.math.time.night.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.math.time.night.json | hints.2.caption.0.v | בַּלַּיְלָה חָשׁוּךְ, וְיֵשׁ יָרֵחַ וְכוֹכָבִים. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל הַלַּיְלָה. | needs-editor |
| activity.math.time.night.json | a11y.altText | אֵיזוֹ תְּמוּנָה הִיא לַיְלָה? | needs-editor |
| activity.math.time.noon.json | prompt.caption.0.v | אֵיזוֹ תְּמוּנָה הִיא צָהֳרַיִם? | needs-editor |
| activity.math.time.noon.json | answer.options.0.label | צָהֳרַיִם | needs-editor |
| activity.math.time.noon.json | answer.options.1.label | עֶרֶב | needs-editor |
| activity.math.time.noon.json | answer.options.2.label | לַיְלָה | needs-editor |
| activity.math.time.noon.json | feedback.correct.caption.0.v | כֵּן! בַּצָּהֳרַיִם הַשֶּׁמֶשׁ גְּבוֹהָה. | needs-editor |
| activity.math.time.noon.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.math.time.noon.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.math.time.noon.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.math.time.noon.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.math.time.noon.json | hints.2.caption.0.v | בַּצָּהֳרַיִם הַשֶּׁמֶשׁ גְּבוֹהָה בַּשָּׁמַיִם. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל הַצָּהֳרַיִם. | needs-editor |
| activity.math.time.noon.json | a11y.altText | אֵיזוֹ תְּמוּנָה הִיא צָהֳרַיִם? | needs-editor |
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
| activity.ordinal.first.json | feedback.correct.caption.0.v | כֵּן! זֶה הָרִאשׁוֹן בַּתּוֹר. | needs-editor |
| activity.ordinal.first.json | feedback.incorrect.0.caption.0.v | הַמָּקוֹם בַּתּוֹר אֵינוֹ כַּמָּה יֵשׁ. בּוֹאוּ נִסְפֹּר מֵהַהַתְחָלָה. | needs-editor |
| activity.ordinal.first.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.ordinal.first.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.ordinal.first.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.ordinal.first.json | hints.1.caption.0.v | נִסְפֹּר בַּתּוֹר מֵהַהַתְחָלָה: רִאשׁוֹן. | needs-editor |
| activity.ordinal.first.json | hints.2.caption.0.v | זֶה הָרִאשׁוֹן בַּתּוֹר. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.ordinal.first.json | a11y.altText | מִי רִאשׁוֹן בַּתּוֹר? | needs-editor |
| activity.ordinal.last.json | prompt.caption.0.v | מִי הָאַחֲרוֹן בַּתּוֹר? | needs-editor |
| activity.ordinal.last.json | answer.options.0.label | חָתוּל | needs-editor |
| activity.ordinal.last.json | answer.options.1.label | בַּרְוָז | needs-editor |
| activity.ordinal.last.json | answer.options.2.label | כֶּלֶב | needs-editor |
| activity.ordinal.last.json | answer.options.3.label | דָּג | needs-editor |
| activity.ordinal.last.json | feedback.correct.caption.0.v | כֵּן! זֶה הָאַחֲרוֹן בַּתּוֹר. | needs-editor |
| activity.ordinal.last.json | feedback.incorrect.0.caption.0.v | הַמָּקוֹם בַּתּוֹר אֵינוֹ כַּמָּה יֵשׁ. בּוֹאוּ נִסְפֹּר מֵהַהַתְחָלָה. | needs-editor |
| activity.ordinal.last.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.ordinal.last.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.ordinal.last.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.ordinal.last.json | hints.1.caption.0.v | נִסְפֹּר בַּתּוֹר מֵהַהַתְחָלָה: רִאשׁוֹן, שֵׁנִי, שְׁלִישִׁי, רְבִיעִי. | needs-editor |
| activity.ordinal.last.json | hints.2.caption.0.v | זֶה הָאַחֲרוֹן בַּתּוֹר. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.ordinal.last.json | a11y.altText | מִי הָאַחֲרוֹן בַּתּוֹר? | needs-editor |
| activity.ordinal.second.json | prompt.caption.0.v | מִי שֵׁנִי בַּתּוֹר? | needs-editor |
| activity.ordinal.second.json | answer.options.0.label | כֶּלֶב | needs-editor |
| activity.ordinal.second.json | answer.options.1.label | בַּרְוָז | needs-editor |
| activity.ordinal.second.json | answer.options.2.label | חָתוּל | needs-editor |
| activity.ordinal.second.json | feedback.correct.caption.0.v | כֵּן! זֶה הַשֵּׁנִי בַּתּוֹר. | needs-editor |
| activity.ordinal.second.json | feedback.incorrect.0.caption.0.v | הַמָּקוֹם בַּתּוֹר אֵינוֹ כַּמָּה יֵשׁ. בּוֹאוּ נִסְפֹּר מֵהַהַתְחָלָה. | needs-editor |
| activity.ordinal.second.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.ordinal.second.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.ordinal.second.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.ordinal.second.json | hints.1.caption.0.v | נִסְפֹּר בַּתּוֹר מֵהַהַתְחָלָה: רִאשׁוֹן, שֵׁנִי. | needs-editor |
| activity.ordinal.second.json | hints.2.caption.0.v | זֶה הַשֵּׁנִי בַּתּוֹר. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.ordinal.second.json | a11y.altText | מִי שֵׁנִי בַּתּוֹר? | needs-editor |
| activity.ordinal.third.json | prompt.caption.0.v | מִי שְׁלִישִׁי בַּתּוֹר? | needs-editor |
| activity.ordinal.third.json | answer.options.0.label | בַּרְוָז | needs-editor |
| activity.ordinal.third.json | answer.options.1.label | חָתוּל | needs-editor |
| activity.ordinal.third.json | answer.options.2.label | כֶּלֶב | needs-editor |
| activity.ordinal.third.json | feedback.correct.caption.0.v | כֵּן! זֶה הַשְּׁלִישִׁי בַּתּוֹר. | needs-editor |
| activity.ordinal.third.json | feedback.incorrect.0.caption.0.v | הַמָּקוֹם בַּתּוֹר אֵינוֹ כַּמָּה יֵשׁ. בּוֹאוּ נִסְפֹּר מֵהַהַתְחָלָה. | needs-editor |
| activity.ordinal.third.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.ordinal.third.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.ordinal.third.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.ordinal.third.json | hints.1.caption.0.v | נִסְפֹּר בַּתּוֹר מֵהַהַתְחָלָה: רִאשׁוֹן, שֵׁנִי, שְׁלִישִׁי. | needs-editor |
| activity.ordinal.third.json | hints.2.caption.0.v | זֶה הַשְּׁלִישִׁי בַּתּוֹר. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.ordinal.third.json | a11y.altText | מִי שְׁלִישִׁי בַּתּוֹר? | needs-editor |
| activity.ordinal.third.of4.json | prompt.caption.0.v | מִי שְׁלִישִׁי בַּתּוֹר? | needs-editor |
| activity.ordinal.third.of4.json | answer.options.0.label | דָּג | needs-editor |
| activity.ordinal.third.of4.json | answer.options.1.label | כֶּלֶב | needs-editor |
| activity.ordinal.third.of4.json | answer.options.2.label | חָתוּל | needs-editor |
| activity.ordinal.third.of4.json | answer.options.3.label | בַּרְוָז | needs-editor |
| activity.ordinal.third.of4.json | feedback.correct.caption.0.v | כֵּן! זֶה הַשְּׁלִישִׁי בַּתּוֹר. | needs-editor |
| activity.ordinal.third.of4.json | feedback.incorrect.0.caption.0.v | הַמָּקוֹם בַּתּוֹר אֵינוֹ כַּמָּה יֵשׁ. בּוֹאוּ נִסְפֹּר מֵהַהַתְחָלָה. | needs-editor |
| activity.ordinal.third.of4.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.ordinal.third.of4.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.ordinal.third.of4.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.ordinal.third.of4.json | hints.1.caption.0.v | נִסְפֹּר בַּתּוֹר מֵהַהַתְחָלָה: רִאשׁוֹן, שֵׁנִי, שְׁלִישִׁי. | needs-editor |
| activity.ordinal.third.of4.json | hints.2.caption.0.v | זֶה הַשְּׁלִישִׁי בַּתּוֹר. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
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
| activity.show.apples.3.json | feedback.correct.caption.0.v | כֵּן! אֵלֶּה שְׁלוֹשָׁה תַּפּוּחִים. | needs-editor |
| activity.show.apples.3.json | feedback.incorrect.0.caption.0.v | אוּלַי סָפַרְנוּ אֶחָד פַּעֲמַיִם? בּוֹאוּ נִבְדֹּק. | needs-editor |
| activity.show.apples.3.json | feedback.incorrect.1.caption.0.v | אוּלַי פִּסְפַּסְנוּ אֶחָד? בּוֹאוּ נִבְדֹּק. | needs-editor |
| activity.show.apples.3.json | feedback.incorrect.2.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.show.apples.3.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.show.apples.3.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַמִּסְפָּר. | needs-editor |
| activity.show.apples.3.json | hints.1.caption.0.v | נִסְפֹּר עִם הָאֶצְבָּעוֹת: אַחַת, שְׁתַּיִם, שָׁלוֹשׁ. | needs-editor |
| activity.show.apples.3.json | hints.2.caption.0.v | אַחַת, שְׁתַּיִם, שָׁלוֹשׁ. אֵלֶּה שְׁלוֹשָׁה תַּפּוּחִים. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל הַנְּכוֹנָה. | needs-editor |
| activity.show.apples.3.json | a11y.altText | אֵיפֹה יֵשׁ שְׁלוֹשָׁה תַּפּוּחִים? | needs-editor |
| activity.show.birds.4.json | prompt.caption.0.v | אֵיפֹה יֵשׁ אַרְבַּע צִפֳּרִים? | needs-editor |
| activity.show.birds.4.json | answer.options.0.label | שָׁלוֹשׁ צִפֳּרִים | needs-editor |
| activity.show.birds.4.json | answer.options.1.label | אַרְבַּע צִפֳּרִים | needs-editor |
| activity.show.birds.4.json | answer.options.2.label | חָמֵשׁ צִפֳּרִים | needs-editor |
| activity.show.birds.4.json | feedback.correct.caption.0.v | כֵּן! אֵלֶּה אַרְבַּע צִפֳּרִים. | needs-editor |
| activity.show.birds.4.json | feedback.incorrect.0.caption.0.v | אוּלַי סָפַרְנוּ אֶחָד פַּעֲמַיִם? בּוֹאוּ נִבְדֹּק. | needs-editor |
| activity.show.birds.4.json | feedback.incorrect.1.caption.0.v | אוּלַי פִּסְפַּסְנוּ אֶחָד? בּוֹאוּ נִבְדֹּק. | needs-editor |
| activity.show.birds.4.json | feedback.incorrect.2.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.show.birds.4.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.show.birds.4.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַמִּסְפָּר. | needs-editor |
| activity.show.birds.4.json | hints.1.caption.0.v | נִסְפֹּר עִם הָאֶצְבָּעוֹת: אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע. | needs-editor |
| activity.show.birds.4.json | hints.2.caption.0.v | אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע. אֵלֶּה אַרְבַּע צִפֳּרִים. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל הַנְּכוֹנָה. | needs-editor |
| activity.show.birds.4.json | a11y.altText | אֵיפֹה יֵשׁ אַרְבַּע צִפֳּרִים? | needs-editor |
| activity.show.stars.5.json | prompt.caption.0.v | אֵיפֹה יֵשׁ חֲמִשָּׁה כּוֹכָבִים? | needs-editor |
| activity.show.stars.5.json | answer.options.0.label | שְׁלוֹשָׁה כּוֹכָבִים | needs-editor |
| activity.show.stars.5.json | answer.options.1.label | אַרְבָּעָה כּוֹכָבִים | needs-editor |
| activity.show.stars.5.json | answer.options.2.label | חֲמִשָּׁה כּוֹכָבִים | needs-editor |
| activity.show.stars.5.json | feedback.correct.caption.0.v | כֵּן! אֵלֶּה חֲמִשָּׁה כּוֹכָבִים. | needs-editor |
| activity.show.stars.5.json | feedback.incorrect.0.caption.0.v | אוּלַי פִּסְפַּסְנוּ אֶחָד? בּוֹאוּ נִבְדֹּק. | needs-editor |
| activity.show.stars.5.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.show.stars.5.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.show.stars.5.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַמִּסְפָּר. | needs-editor |
| activity.show.stars.5.json | hints.1.caption.0.v | נִסְפֹּר עִם הָאֶצְבָּעוֹת: אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע, חָמֵשׁ. | needs-editor |
| activity.show.stars.5.json | hints.2.caption.0.v | אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע, חָמֵשׁ. אֵלֶּה חֲמִשָּׁה כּוֹכָבִים. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל הַנְּכוֹנָה. | needs-editor |
| activity.show.stars.5.json | a11y.altText | אֵיפֹה יֵשׁ חֲמִשָּׁה כּוֹכָבִים? | needs-editor |
| activity.shp.any.down.json | prompt.caption.0.v | אֵיפֹה הַמְּשֻׁלָּשׁ? | needs-editor |
| activity.shp.any.down.json | answer.options.0.label | מְשֻׁלָּשׁ | needs-editor |
| activity.shp.any.down.json | answer.options.1.label | רִבּוּעַ | needs-editor |
| activity.shp.any.down.json | answer.options.2.label | עִגּוּל | needs-editor |
| activity.shp.any.down.json | feedback.correct.caption.0.v | כֵּן! זֶה מְשֻׁלָּשׁ. | needs-editor |
| activity.shp.any.down.json | feedback.incorrect.0.caption.0.v | צוּרָה נִשְׁאֶרֶת אוֹתָהּ צוּרָה גַּם כְּשֶׁמְּסֹבְבִים אוֹתָהּ. בּוֹאוּ נִבְדֹּק. | needs-editor |
| activity.shp.any.down.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.shp.any.down.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.shp.any.down.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.shp.any.down.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.shp.any.down.json | hints.2.caption.0.v | זֶה מְשֻׁלָּשׁ. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.shp.any.down.json | a11y.altText | אֵיפֹה הַמְּשֻׁלָּשׁ? | needs-editor |
| activity.shp.any.small.json | prompt.caption.0.v | אֵיפֹה הַמְּשֻׁלָּשׁ? | needs-editor |
| activity.shp.any.small.json | answer.options.0.label | עִגּוּל | needs-editor |
| activity.shp.any.small.json | answer.options.1.label | מְשֻׁלָּשׁ | needs-editor |
| activity.shp.any.small.json | answer.options.2.label | רִבּוּעַ | needs-editor |
| activity.shp.any.small.json | feedback.correct.caption.0.v | כֵּן! זֶה מְשֻׁלָּשׁ. | needs-editor |
| activity.shp.any.small.json | feedback.incorrect.0.caption.0.v | צוּרָה גְּדוֹלָה וְצוּרָה קְטַנָּה יְכוֹלוֹת לִהְיוֹת אוֹתָהּ צוּרָה. בּוֹאוּ נִבְדֹּק. | needs-editor |
| activity.shp.any.small.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.shp.any.small.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.shp.any.small.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.shp.any.small.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.shp.any.small.json | hints.2.caption.0.v | זֶה מְשֻׁלָּשׁ. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.shp.any.small.json | a11y.altText | אֵיפֹה הַמְּשֻׁלָּשׁ? | needs-editor |
| activity.shp.any.thin.json | prompt.caption.0.v | אֵיפֹה הַמְּשֻׁלָּשׁ? | needs-editor |
| activity.shp.any.thin.json | answer.options.0.label | מַלְבֵּן | needs-editor |
| activity.shp.any.thin.json | answer.options.1.label | עִגּוּל | needs-editor |
| activity.shp.any.thin.json | answer.options.2.label | מְשֻׁלָּשׁ | needs-editor |
| activity.shp.any.thin.json | feedback.correct.caption.0.v | כֵּן! זֶה מְשֻׁלָּשׁ. | needs-editor |
| activity.shp.any.thin.json | feedback.incorrect.0.caption.0.v | אוֹתָהּ צוּרָה יְכוֹלָה לְהֵרָאוֹת קְצָת אַחֶרֶת. בּוֹאוּ נִסְפֹּר צְלָעוֹת. | needs-editor |
| activity.shp.any.thin.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.shp.any.thin.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.shp.any.thin.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.shp.any.thin.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.shp.any.thin.json | hints.2.caption.0.v | זֶה מְשֻׁלָּשׁ. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.shp.any.thin.json | a11y.altText | אֵיפֹה הַמְּשֻׁלָּשׁ? | needs-editor |
| activity.shp.any.tilt.json | prompt.caption.0.v | אֵיפֹה הָרִבּוּעַ? | needs-editor |
| activity.shp.any.tilt.json | answer.options.0.label | עִגּוּל | needs-editor |
| activity.shp.any.tilt.json | answer.options.1.label | רִבּוּעַ | needs-editor |
| activity.shp.any.tilt.json | answer.options.2.label | מַלְבֵּן | needs-editor |
| activity.shp.any.tilt.json | feedback.correct.caption.0.v | כֵּן! זֶה רִבּוּעַ. | needs-editor |
| activity.shp.any.tilt.json | feedback.incorrect.0.caption.0.v | צוּרָה נִשְׁאֶרֶת אוֹתָהּ צוּרָה גַּם כְּשֶׁמְּסֹבְבִים אוֹתָהּ. בּוֹאוּ נִבְדֹּק. | needs-editor |
| activity.shp.any.tilt.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.shp.any.tilt.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.shp.any.tilt.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.shp.any.tilt.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.shp.any.tilt.json | hints.2.caption.0.v | זֶה רִבּוּעַ. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.shp.any.tilt.json | a11y.altText | אֵיפֹה הָרִבּוּעַ? | needs-editor |
| activity.shp.line.curved.json | prompt.caption.0.v | אֵיפֹה הַקַּו הָעָקֹם? | needs-editor |
| activity.shp.line.curved.json | answer.options.0.label | קַו עָקֹם | needs-editor |
| activity.shp.line.curved.json | answer.options.1.label | קַו יָשָׁר | needs-editor |
| activity.shp.line.curved.json | feedback.correct.caption.0.v | כֵּן! זֶה קַו עָקֹם. | needs-editor |
| activity.shp.line.curved.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.shp.line.curved.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.shp.line.curved.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.shp.line.curved.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.shp.line.curved.json | hints.2.caption.0.v | זֶה קַו עָקֹם. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.shp.line.curved.json | a11y.altText | אֵיפֹה הַקַּו הָעָקֹם? | needs-editor |
| activity.shp.line.straight.json | prompt.caption.0.v | אֵיפֹה הַקַּו הַיָּשָׁר? | needs-editor |
| activity.shp.line.straight.json | answer.options.0.label | קַו עָקֹם | needs-editor |
| activity.shp.line.straight.json | answer.options.1.label | קַו יָשָׁר | needs-editor |
| activity.shp.line.straight.json | feedback.correct.caption.0.v | כֵּן! זֶה קַו יָשָׁר. | needs-editor |
| activity.shp.line.straight.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.shp.line.straight.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.shp.line.straight.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.shp.line.straight.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.shp.line.straight.json | hints.2.caption.0.v | זֶה קַו יָשָׁר. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.shp.line.straight.json | a11y.altText | אֵיפֹה הַקַּו הַיָּשָׁר? | needs-editor |
| activity.shp.match.circle.json | prompt.caption.0.v | אֵיפֹה אוֹתָהּ צוּרָה? | needs-editor |
| activity.shp.match.circle.json | answer.options.0.label | רִבּוּעַ | needs-editor |
| activity.shp.match.circle.json | answer.options.1.label | עִגּוּל | needs-editor |
| activity.shp.match.circle.json | answer.options.2.label | מְשֻׁלָּשׁ | needs-editor |
| activity.shp.match.circle.json | feedback.correct.caption.0.v | כֵּן! זֶה עִגּוּל. | needs-editor |
| activity.shp.match.circle.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.shp.match.circle.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.shp.match.circle.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.shp.match.circle.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.shp.match.circle.json | hints.2.caption.0.v | זֶה עִגּוּל. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.shp.match.circle.json | a11y.altText | אֵיפֹה אוֹתָהּ צוּרָה? | needs-editor |
| activity.shp.match.square.json | prompt.caption.0.v | אֵיפֹה אוֹתָהּ צוּרָה? | needs-editor |
| activity.shp.match.square.json | answer.options.0.label | רִבּוּעַ | needs-editor |
| activity.shp.match.square.json | answer.options.1.label | עִגּוּל | needs-editor |
| activity.shp.match.square.json | answer.options.2.label | מְשֻׁלָּשׁ | needs-editor |
| activity.shp.match.square.json | feedback.correct.caption.0.v | כֵּן! זֶה רִבּוּעַ. | needs-editor |
| activity.shp.match.square.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.shp.match.square.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.shp.match.square.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.shp.match.square.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.shp.match.square.json | hints.2.caption.0.v | זֶה רִבּוּעַ. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.shp.match.square.json | a11y.altText | אֵיפֹה אוֹתָהּ צוּרָה? | needs-editor |
| activity.shp.match.triangle.json | prompt.caption.0.v | אֵיפֹה אוֹתָהּ צוּרָה? | needs-editor |
| activity.shp.match.triangle.json | answer.options.0.label | עִגּוּל | needs-editor |
| activity.shp.match.triangle.json | answer.options.1.label | רִבּוּעַ | needs-editor |
| activity.shp.match.triangle.json | answer.options.2.label | מְשֻׁלָּשׁ | needs-editor |
| activity.shp.match.triangle.json | feedback.correct.caption.0.v | כֵּן! זֶה מְשֻׁלָּשׁ. | needs-editor |
| activity.shp.match.triangle.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.shp.match.triangle.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.shp.match.triangle.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.shp.match.triangle.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.shp.match.triangle.json | hints.2.caption.0.v | זֶה מְשֻׁלָּשׁ. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.shp.match.triangle.json | a11y.altText | אֵיפֹה אוֹתָהּ צוּרָה? | needs-editor |
| activity.shp.name.circle.json | prompt.caption.0.v | אֵיפֹה הָעִגּוּל? | needs-editor |
| activity.shp.name.circle.json | answer.options.0.label | מְשֻׁלָּשׁ | needs-editor |
| activity.shp.name.circle.json | answer.options.1.label | עִגּוּל | needs-editor |
| activity.shp.name.circle.json | answer.options.2.label | רִבּוּעַ | needs-editor |
| activity.shp.name.circle.json | feedback.correct.caption.0.v | כֵּן! זֶה עִגּוּל. | needs-editor |
| activity.shp.name.circle.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.shp.name.circle.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.shp.name.circle.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.shp.name.circle.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.shp.name.circle.json | hints.2.caption.0.v | זֶה עִגּוּל. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.shp.name.circle.json | a11y.altText | אֵיפֹה הָעִגּוּל? | needs-editor |
| activity.shp.name.mix.json | prompt.caption.0.v | אֵיפֹה הָעִגּוּל? | needs-editor |
| activity.shp.name.mix.json | answer.options.0.label | רִבּוּעַ | needs-editor |
| activity.shp.name.mix.json | answer.options.1.label | מְשֻׁלָּשׁ | needs-editor |
| activity.shp.name.mix.json | answer.options.2.label | עִגּוּל | needs-editor |
| activity.shp.name.mix.json | feedback.correct.caption.0.v | כֵּן! זֶה עִגּוּל. | needs-editor |
| activity.shp.name.mix.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.shp.name.mix.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.shp.name.mix.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.shp.name.mix.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.shp.name.mix.json | hints.2.caption.0.v | זֶה עִגּוּל. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.shp.name.mix.json | a11y.altText | אֵיפֹה הָעִגּוּל? | needs-editor |
| activity.shp.name.square.json | prompt.caption.0.v | אֵיפֹה הָרִבּוּעַ? | needs-editor |
| activity.shp.name.square.json | answer.options.0.label | רִבּוּעַ | needs-editor |
| activity.shp.name.square.json | answer.options.1.label | עִגּוּל | needs-editor |
| activity.shp.name.square.json | answer.options.2.label | מְשֻׁלָּשׁ | needs-editor |
| activity.shp.name.square.json | feedback.correct.caption.0.v | כֵּן! זֶה רִבּוּעַ. | needs-editor |
| activity.shp.name.square.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.shp.name.square.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.shp.name.square.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.shp.name.square.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.shp.name.square.json | hints.2.caption.0.v | זֶה רִבּוּעַ. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.shp.name.square.json | a11y.altText | אֵיפֹה הָרִבּוּעַ? | needs-editor |
| activity.shp.name.triangle.json | prompt.caption.0.v | אֵיפֹה הַמְּשֻׁלָּשׁ? | needs-editor |
| activity.shp.name.triangle.json | answer.options.0.label | עִגּוּל | needs-editor |
| activity.shp.name.triangle.json | answer.options.1.label | מְשֻׁלָּשׁ | needs-editor |
| activity.shp.name.triangle.json | answer.options.2.label | רִבּוּעַ | needs-editor |
| activity.shp.name.triangle.json | feedback.correct.caption.0.v | כֵּן! זֶה מְשֻׁלָּשׁ. | needs-editor |
| activity.shp.name.triangle.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.shp.name.triangle.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.shp.name.triangle.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.shp.name.triangle.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.shp.name.triangle.json | hints.2.caption.0.v | זֶה מְשֻׁלָּשׁ. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.shp.name.triangle.json | a11y.altText | אֵיפֹה הַמְּשֻׁלָּשׁ? | needs-editor |
| activity.shp.rect.find.json | prompt.caption.0.v | אֵיפֹה הַמַּלְבֵּן? | needs-editor |
| activity.shp.rect.find.json | answer.options.0.label | מַלְבֵּן | needs-editor |
| activity.shp.rect.find.json | answer.options.1.label | רִבּוּעַ | needs-editor |
| activity.shp.rect.find.json | answer.options.2.label | עִגּוּל | needs-editor |
| activity.shp.rect.find.json | feedback.correct.caption.0.v | כֵּן! זֶה מַלְבֵּן. | needs-editor |
| activity.shp.rect.find.json | feedback.incorrect.0.caption.0.v | בְּרִבּוּעַ כׇּל הַצְּלָעוֹת שָׁווֹת. בְּמַלְבֵּן יֵשׁ צְלָעוֹת אֲרֻכּוֹת וּקְצָרוֹת. | needs-editor |
| activity.shp.rect.find.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.shp.rect.find.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.shp.rect.find.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.shp.rect.find.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.shp.rect.find.json | hints.2.caption.0.v | זֶה מַלְבֵּן. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.shp.rect.find.json | a11y.altText | אֵיפֹה הַמַּלְבֵּן? | needs-editor |
| activity.shp.rect.long.json | prompt.caption.0.v | אֵיזוֹ צוּרָה אֲרֻכָּה? | needs-editor |
| activity.shp.rect.long.json | answer.options.0.label | רִבּוּעַ | needs-editor |
| activity.shp.rect.long.json | answer.options.1.label | עִגּוּל | needs-editor |
| activity.shp.rect.long.json | answer.options.2.label | מַלְבֵּן | needs-editor |
| activity.shp.rect.long.json | feedback.correct.caption.0.v | כֵּן! הַמַּלְבֵּן אָרֹךְ. | needs-editor |
| activity.shp.rect.long.json | feedback.incorrect.0.caption.0.v | בְּרִבּוּעַ כׇּל הַצְּלָעוֹת שָׁווֹת. בְּמַלְבֵּן יֵשׁ צְלָעוֹת אֲרֻכּוֹת וּקְצָרוֹת. | needs-editor |
| activity.shp.rect.long.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.shp.rect.long.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.shp.rect.long.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.shp.rect.long.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.shp.rect.long.json | hints.2.caption.0.v | זֶה מַלְבֵּן. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.shp.rect.long.json | a11y.altText | אֵיזוֹ צוּרָה אֲרֻכָּה? | needs-editor |
| activity.shp.rect.square.json | prompt.caption.0.v | אֵיפֹה הָרִבּוּעַ? | needs-editor |
| activity.shp.rect.square.json | answer.options.0.label | מַלְבֵּן | needs-editor |
| activity.shp.rect.square.json | answer.options.1.label | מְשֻׁלָּשׁ | needs-editor |
| activity.shp.rect.square.json | answer.options.2.label | רִבּוּעַ | needs-editor |
| activity.shp.rect.square.json | feedback.correct.caption.0.v | כֵּן! זֶה רִבּוּעַ. | needs-editor |
| activity.shp.rect.square.json | feedback.incorrect.0.caption.0.v | בְּרִבּוּעַ כׇּל הַצְּלָעוֹת שָׁווֹת. בְּמַלְבֵּן יֵשׁ צְלָעוֹת אֲרֻכּוֹת וּקְצָרוֹת. | needs-editor |
| activity.shp.rect.square.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.shp.rect.square.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.shp.rect.square.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.shp.rect.square.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.shp.rect.square.json | hints.2.caption.0.v | זֶה רִבּוּעַ. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.shp.rect.square.json | a11y.altText | אֵיפֹה הָרִבּוּעַ? | needs-editor |
| activity.shp.solid.rolls.json | prompt.caption.0.v | מָה מִתְגַּלְגֵּל? | needs-editor |
| activity.shp.solid.rolls.json | answer.options.0.label | קֻבִּיָּה | needs-editor |
| activity.shp.solid.rolls.json | answer.options.1.label | כַּדּוּר אָדֹם | needs-editor |
| activity.shp.solid.rolls.json | feedback.correct.caption.0.v | כֵּן! זֶה כַּדּוּר אָדֹם. | needs-editor |
| activity.shp.solid.rolls.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.shp.solid.rolls.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.shp.solid.rolls.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.shp.solid.rolls.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.shp.solid.rolls.json | hints.2.caption.0.v | זֶה כַּדּוּר אָדֹם. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.shp.solid.rolls.json | a11y.altText | מָה מִתְגַּלְגֵּל? | needs-editor |
| activity.shp.solid.stacks.json | prompt.caption.0.v | מָה אֶפְשָׁר לַעֲרֹם? | needs-editor |
| activity.shp.solid.stacks.json | answer.options.0.label | כַּדּוּר אָדֹם | needs-editor |
| activity.shp.solid.stacks.json | answer.options.1.label | קֻבִּיָּה | needs-editor |
| activity.shp.solid.stacks.json | feedback.correct.caption.0.v | כֵּן! זוֹ קֻבִּיָּה. | needs-editor |
| activity.shp.solid.stacks.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.shp.solid.stacks.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.shp.solid.stacks.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.shp.solid.stacks.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.shp.solid.stacks.json | hints.2.caption.0.v | זוֹ קֻבִּיָּה. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.shp.solid.stacks.json | a11y.altText | מָה אֶפְשָׁר לַעֲרֹם? | needs-editor |
| activity.shp.solid.which.json | prompt.caption.0.v | מָה לֹא מִתְגַּלְגֵּל? | needs-editor |
| activity.shp.solid.which.json | answer.options.0.label | כַּדּוּר אָדֹם | needs-editor |
| activity.shp.solid.which.json | answer.options.1.label | קֻבִּיָּה | needs-editor |
| activity.shp.solid.which.json | feedback.correct.caption.0.v | כֵּן! זוֹ קֻבִּיָּה. | needs-editor |
| activity.shp.solid.which.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.shp.solid.which.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.shp.solid.which.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.shp.solid.which.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.shp.solid.which.json | hints.2.caption.0.v | זוֹ קֻבִּיָּה. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.shp.solid.which.json | a11y.altText | מָה לֹא מִתְגַּלְגֵּל? | needs-editor |
| activity.shp.where.in.json | prompt.caption.0.v | אֵיפֹה הַכַּדּוּר? בְּתוֹךְ הַקֻּפְסָה. | needs-editor |
| activity.shp.where.in.json | answer.options.0.label | עַל | needs-editor |
| activity.shp.where.in.json | answer.options.1.label | מֵעַל | needs-editor |
| activity.shp.where.in.json | answer.options.2.label | בְּתוֹךְ | needs-editor |
| activity.shp.where.in.json | feedback.correct.caption.0.v | כֵּן! הַכַּדּוּר בְּתוֹךְ הַקֻּפְסָה. | needs-editor |
| activity.shp.where.in.json | feedback.incorrect.0.caption.0.v | הַמִּלָּה אוֹמֶרֶת אֵיפֹה הַכַּדּוּר. בּוֹאוּ נִסְתַּכֵּל שׁוּב. | needs-editor |
| activity.shp.where.in.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.shp.where.in.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.shp.where.in.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.shp.where.in.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.shp.where.in.json | hints.2.caption.0.v | הַכַּדּוּר בִּפְנִים, בְּתוֹךְ הַקֻּפְסָה. עַכְשָׁו תּוֹרְכֶם. | needs-editor |
| activity.shp.where.in.json | a11y.altText | אֵיפֹה הַכַּדּוּר? בְּתוֹךְ הַקֻּפְסָה. | needs-editor |
| activity.shp.where.next.json | prompt.caption.0.v | אֵיפֹה הַכַּדּוּר? לְיַד הַקֻּפְסָה. | needs-editor |
| activity.shp.where.next.json | answer.options.0.label | בְּתוֹךְ | needs-editor |
| activity.shp.where.next.json | answer.options.1.label | לְיַד | needs-editor |
| activity.shp.where.next.json | answer.options.2.label | עַל | needs-editor |
| activity.shp.where.next.json | feedback.correct.caption.0.v | כֵּן! הַכַּדּוּר לְיַד הַקֻּפְסָה. | needs-editor |
| activity.shp.where.next.json | feedback.incorrect.0.caption.0.v | הַמִּלָּה אוֹמֶרֶת אֵיפֹה הַכַּדּוּר. בּוֹאוּ נִסְתַּכֵּל שׁוּב. | needs-editor |
| activity.shp.where.next.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.shp.where.next.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.shp.where.next.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.shp.where.next.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.shp.where.next.json | hints.2.caption.0.v | הַכַּדּוּר עוֹמֵד לְצַד הַקֻּפְסָה. עַכְשָׁו תּוֹרְכֶם. | needs-editor |
| activity.shp.where.next.json | a11y.altText | אֵיפֹה הַכַּדּוּר? לְיַד הַקֻּפְסָה. | needs-editor |
| activity.shp.where.on.json | prompt.caption.0.v | אֵיפֹה הַכַּדּוּר? עַל הַקֻּפְסָה. | needs-editor |
| activity.shp.where.on.json | answer.options.0.label | מִתַּחַת | needs-editor |
| activity.shp.where.on.json | answer.options.1.label | עַל | needs-editor |
| activity.shp.where.on.json | answer.options.2.label | לְיַד | needs-editor |
| activity.shp.where.on.json | feedback.correct.caption.0.v | כֵּן! הַכַּדּוּר עַל הַקֻּפְסָה. | needs-editor |
| activity.shp.where.on.json | feedback.incorrect.0.caption.0.v | הַמִּלָּה אוֹמֶרֶת אֵיפֹה הַכַּדּוּר. בּוֹאוּ נִסְתַּכֵּל שׁוּב. | needs-editor |
| activity.shp.where.on.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.shp.where.on.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.shp.where.on.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.shp.where.on.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.shp.where.on.json | hints.2.caption.0.v | הַכַּדּוּר נִמְצָא מֵעַל הַקֻּפְסָה, וְנוֹגֵעַ בָּהּ. עַכְשָׁו תּוֹרְכֶם. | needs-editor |
| activity.shp.where.on.json | a11y.altText | אֵיפֹה הַכַּדּוּר? עַל הַקֻּפְסָה. | needs-editor |
| activity.shp.where.under.json | prompt.caption.0.v | אֵיפֹה הַכַּדּוּר? מִתַּחַת לַשֻּׁלְחָן. | needs-editor |
| activity.shp.where.under.json | answer.options.0.label | עַל | needs-editor |
| activity.shp.where.under.json | answer.options.1.label | מִתַּחַת | needs-editor |
| activity.shp.where.under.json | answer.options.2.label | מֵעַל | needs-editor |
| activity.shp.where.under.json | feedback.correct.caption.0.v | כֵּן! הַכַּדּוּר מִתַּחַת לַשֻּׁלְחָן. | needs-editor |
| activity.shp.where.under.json | feedback.incorrect.0.caption.0.v | הַמִּלָּה אוֹמֶרֶת אֵיפֹה הַכַּדּוּר. בּוֹאוּ נִסְתַּכֵּל שׁוּב. | needs-editor |
| activity.shp.where.under.json | feedback.incorrect.1.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.shp.where.under.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.shp.where.under.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.shp.where.under.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.shp.where.under.json | hints.2.caption.0.v | הַשֻּׁלְחָן לְמַעְלָה, וְהַכַּדּוּר מִתַּחְתָּיו. עַכְשָׁו תּוֹרְכֶם. | needs-editor |
| activity.shp.where.under.json | a11y.altText | אֵיפֹה הַכַּדּוּר? מִתַּחַת לַשֻּׁלְחָן. | needs-editor |
| activity.shp.world.circle.json | prompt.caption.0.v | מָה בְּצוּרַת עִגּוּל? | needs-editor |
| activity.shp.world.circle.json | answer.options.0.label | חַלּוֹן | needs-editor |
| activity.shp.world.circle.json | answer.options.1.label | שֶׁלֶט | needs-editor |
| activity.shp.world.circle.json | answer.options.2.label | צַלַּחַת | needs-editor |
| activity.shp.world.circle.json | feedback.correct.caption.0.v | כֵּן! זוֹ צַלַּחַת. | needs-editor |
| activity.shp.world.circle.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.shp.world.circle.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.shp.world.circle.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.shp.world.circle.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.shp.world.circle.json | hints.2.caption.0.v | זוֹ צַלַּחַת. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.shp.world.circle.json | a11y.altText | מָה בְּצוּרַת עִגּוּל? | needs-editor |
| activity.shp.world.rect.json | prompt.caption.0.v | מָה בְּצוּרַת מַלְבֵּן? | needs-editor |
| activity.shp.world.rect.json | answer.options.0.label | צַלַּחַת | needs-editor |
| activity.shp.world.rect.json | answer.options.1.label | חַלּוֹן | needs-editor |
| activity.shp.world.rect.json | answer.options.2.label | שֶׁלֶט | needs-editor |
| activity.shp.world.rect.json | feedback.correct.caption.0.v | כֵּן! זֶה חַלּוֹן. | needs-editor |
| activity.shp.world.rect.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.shp.world.rect.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.shp.world.rect.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.shp.world.rect.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.shp.world.rect.json | hints.2.caption.0.v | זֶה חַלּוֹן. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.shp.world.rect.json | a11y.altText | מָה בְּצוּרַת מַלְבֵּן? | needs-editor |
| activity.shp.world.triangle.json | prompt.caption.0.v | מָה בְּצוּרַת מְשֻׁלָּשׁ? | needs-editor |
| activity.shp.world.triangle.json | answer.options.0.label | שֶׁלֶט | needs-editor |
| activity.shp.world.triangle.json | answer.options.1.label | צַלַּחַת | needs-editor |
| activity.shp.world.triangle.json | answer.options.2.label | חַלּוֹן | needs-editor |
| activity.shp.world.triangle.json | feedback.correct.caption.0.v | כֵּן! זֶה שֶׁלֶט. | needs-editor |
| activity.shp.world.triangle.json | feedback.incorrect.0.caption.0.v | כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב. | needs-editor |
| activity.shp.world.triangle.json | feedback.unsure.caption.0.v | שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד. | needs-editor |
| activity.shp.world.triangle.json | hints.0.caption.0.v | בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה. | needs-editor |
| activity.shp.world.triangle.json | hints.1.caption.0.v | נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד. | needs-editor |
| activity.shp.world.triangle.json | hints.2.caption.0.v | זֶה שֶׁלֶט. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | needs-editor |
| activity.shp.world.triangle.json | a11y.altText | מָה בְּצוּרַת מְשֻׁלָּשׁ? | needs-editor |
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
| lesson.add-one-more.json | title.0.v | עוֹד אֶחָד, עוֹד שְׁנַיִם | needs-editor |
| lesson.add-one-more.json | celebration.caption.0.v | כׇּל הַכָּבוֹד! הוֹסַפְתֶּם וְסְפַרְתֶּם. | needs-editor |
| lesson.any-shape.json | title.0.v | בְּכׇל גֹּדֶל וּבְכׇל כִּוּוּן | needs-editor |
| lesson.any-shape.json | celebration.caption.0.v | חֲכָמִים! צוּרָה נִשְׁאֶרֶת אוֹתָהּ צוּרָה. | needs-editor |
| lesson.big-small-long-heavy.json | title.0.v | גָּדוֹל, קָצָר, כָּבֵד | needs-editor |
| lesson.big-small-long-heavy.json | celebration.caption.0.v | חֲכָמִים! הִשְׁוִיתֶם גָּדוֹל וְקָטָן, אָרֹךְ וְקָצָר, כָּבֵד וְקַל. | needs-editor |
| lesson.butterflies.json | title.0.v | פַּרְפָּרִים בַּגִּנָּה | needs-editor |
| lesson.butterflies.json | celebration.caption.0.v | כׇּל הַכָּבוֹד! סְפַרְתֶּם לְאַט וּבְדַקְתֶּם כׇּל פַּרְפָּר. | needs-editor |
| lesson.by-size.json | title.0.v | מְסַדְּרִים לְפִי גֹּדֶל | needs-editor |
| lesson.by-size.json | celebration.caption.0.v | יָפֶה מְאֹד! סִדַּרְתֶּם לְפִי גֹּדֶל. | needs-editor |
| lesson.colour-match.json | title.0.v | מוֹצְאִים אֶת אוֹתוֹ צֶבַע | needs-editor |
| lesson.colour-match.json | celebration.caption.0.v | כׇּל הַכָּבוֹד! מְצָאתֶם אֶת הַצְּבָעִים. | needs-editor |
| lesson.colour-names.json | title.0.v | שֵׁמוֹת שֶׁל צְבָעִים | needs-editor |
| lesson.colour-names.json | celebration.caption.0.v | יָפֶה מְאֹד! הִכַּרְתֶּם עוֹד צְבָעִים. | needs-editor |
| lesson.colour-sorting.json | title.0.v | מְמַיְּנִים לְפִי צֶבַע | needs-editor |
| lesson.colour-sorting.json | celebration.caption.0.v | חֲכָמִים! הִסְתַּכַּלְתֶּם עַל הַצֶּבַע וְעַל הַדָּבָר. | needs-editor |
| lesson.colours-of-things.json | title.0.v | הַצְּבָעִים שֶׁל הָעוֹלָם | needs-editor |
| lesson.colours-of-things.json | celebration.caption.0.v | וַאוּ! יְדַעְתֶּם אֵיזֶה צֶבַע יֵשׁ לַדְּבָרִים. | needs-editor |
| lesson.copy-patterns.json | title.0.v | מַעֲתִיקִים סֵדֶר | needs-editor |
| lesson.copy-patterns.json | celebration.caption.0.v | כׇּל הַכָּבוֹד! הֶעְתַּקְתֶּם אֶת הַסֵּדֶר. | needs-editor |
| lesson.count-to-ten.json | title.0.v | סוֹפְרִים עַד עֶשֶׂר | needs-editor |
| lesson.count-to-ten.json | celebration.caption.0.v | וַאוּ! סְפַרְתֶּם עַד עֶשֶׂר. | needs-editor |
| lesson.counting-words.json | title.0.v | סוֹפְרִים לְפִי הַסֵּדֶר | needs-editor |
| lesson.counting-words.json | celebration.caption.0.v | כׇּל הַכָּבוֹד! סְפַרְתֶּם לְפִי הַסֵּדֶר. | needs-editor |
| lesson.find-the-number.json | title.0.v | מוֹצְאִים אֶת הַמִּסְפָּר | needs-editor |
| lesson.find-the-number.json | celebration.caption.0.v | יָפֶה מְאֹד! הִכַּרְתֶּם אֶת הַמִּסְפָּרִים. | needs-editor |
| lesson.first-then-last.json | title.0.v | קֹדֶם, אַחַר כָּךְ, בַּסּוֹף | needs-editor |
| lesson.first-then-last.json | celebration.caption.0.v | כׇּל הַכָּבוֹד! יְדַעְתֶּם מָה קוֹרֶה קֹדֶם וּמָה הוֹלֵךְ יַחַד. | needs-editor |
| lesson.giving.json | title.0.v | נוֹתְנִים בְּדִיּוּק | needs-editor |
| lesson.giving.json | celebration.caption.0.v | כׇּל הַכָּבוֹד! נְתַתֶּם בְּדִיּוּק כַּמָּה שֶׁבִּקְשׁוּ. | needs-editor |
| lesson.glance-more.json | title.0.v | רוֹאִים אַרְבַּע וְחָמֵשׁ | needs-editor |
| lesson.glance-more.json | celebration.caption.0.v | מַדְהִים! רְאִיתֶם אַרְבַּע וְחָמֵשׁ בְּמַבָּט אֶחָד. | needs-editor |
| lesson.glance-small.json | title.0.v | רוֹאִים בְּמַבָּט אֶחָד | needs-editor |
| lesson.glance-small.json | celebration.caption.0.v | וַאוּ! רְאִיתֶם כַּמָּה בְּלִי לִסְפֹּר. | needs-editor |
| lesson.more-colours.json | title.0.v | עוֹד צְבָעִים | needs-editor |
| lesson.more-colours.json | celebration.caption.0.v | מַדְהִים! אַתֶּם מַכִּירִים הַרְבֵּה צְבָעִים. | needs-editor |
| lesson.more-or-less.json | title.0.v | יוֹתֵר אוֹ פָּחוֹת | needs-editor |
| lesson.more-or-less.json | celebration.caption.0.v | כׇּל הַכָּבוֹד! יְדַעְתֶּם אֵיפֹה יוֹתֵר וְאֵיפֹה פָּחוֹת. | needs-editor |
| lesson.more-patterns.json | title.0.v | עוֹד סְדָרִים | needs-editor |
| lesson.more-patterns.json | celebration.caption.0.v | חֲכָמִים! תִּקַּנְתֶּם אֶת הַסֵּדֶר. | needs-editor |
| lesson.my-day.json | title.0.v | הַיּוֹם שֶׁלִּי | needs-editor |
| lesson.my-day.json | celebration.caption.0.v | וַאוּ! הִכַּרְתֶּם אֶת הַיּוֹם: בֹּקֶר, צָהֳרַיִם, עֶרֶב וְלַיְלָה. | needs-editor |
| lesson.nothing-there.json | title.0.v | אֵין כְּלוּם | needs-editor |
| lesson.nothing-there.json | celebration.caption.0.v | יָפֶה מְאֹד! אֵין כְּלוּם זֶה אֶפֶס. | needs-editor |
| lesson.numbers-and-things.json | title.0.v | מִסְפָּרִים וְדְּבָרִים | needs-editor |
| lesson.numbers-and-things.json | celebration.caption.0.v | כׇּל הַכָּבוֹד! מָצָאתֶם אֶת הַמִּסְפָּר הַנָּכוֹן. | needs-editor |
| lesson.patterns.json | title.0.v | סֵדֶר שֶׁחוֹזֵר | needs-editor |
| lesson.patterns.json | celebration.caption.0.v | וַאוּ! הִמְשַׁכְתֶּם אֶת הַסֵּדֶר. | needs-editor |
| lesson.picture-graph.json | title.0.v | אֵיפֹה יוֹתֵר? | needs-editor |
| lesson.picture-graph.json | celebration.caption.0.v | יָפֶה מְאֹד! יְדַעְתֶּם אֵיפֹה יוֹתֵר וְאֵיפֹה פָּחוֹת. | needs-editor |
| lesson.rectangle.json | title.0.v | מַלְבֵּן וְרִבּוּעַ | needs-editor |
| lesson.rectangle.json | celebration.caption.0.v | יָפֶה מְאֹד! הִבְדַּלְתֶּם בֵּין מַלְבֵּן לְרִבּוּעַ. | needs-editor |
| lesson.robot-moves.json | title.0.v | מְזִיזִים אֶת הָרוֹבּוֹט | needs-editor |
| lesson.robot-moves.json | celebration.caption.0.v | כׇּל הַכָּבוֹד! הַרוֹבּוֹט הִגִּיעַ אֶל הַדֶּגֶל. | needs-editor |
| lesson.robot-plans.json | title.0.v | מְתַכְנְנִים לָרוֹבּוֹט | needs-editor |
| lesson.robot-plans.json | celebration.caption.0.v | וַאוּ! תִּכְנַנְתֶּם אֶת הַדֶּרֶךְ. | needs-editor |
| lesson.roll-or-stack.json | title.0.v | מִתְגַּלְגֵּל אוֹ נֶעֱרָם | needs-editor |
| lesson.roll-or-stack.json | celebration.caption.0.v | כׇּל הַכָּבוֹד! יְדַעְתֶּם מָה מִתְגַּלְגֵּל וּמָה נֶעֱרָם. | needs-editor |
| lesson.same-and-different.json | title.0.v | זֶהֶה וְשׁוֹנֶה | needs-editor |
| lesson.same-and-different.json | celebration.caption.0.v | כׇּל הַכָּבוֹד! מְצָאתֶם מִי זֶהֶה וּמִי שׁוֹנֶה. | needs-editor |
| lesson.shape-friends.json | title.0.v | חֲבֵרִים צוּרוֹת | needs-editor |
| lesson.shape-friends.json | celebration.caption.0.v | כׇּל הַכָּבוֹד! הִכַּרְתֶּם אֶת הַצּוּרוֹת. | needs-editor |
| lesson.shapes-around-us.json | title.0.v | צוּרוֹת סְבִיבֵנוּ | needs-editor |
| lesson.shapes-around-us.json | celebration.caption.0.v | וַאוּ! מְצָאתֶם צוּרוֹת בְּכׇל מָקוֹם. | needs-editor |
| lesson.sharing.json | title.0.v | מְחַלְּקִים בְּהֲגִינוּת | needs-editor |
| lesson.sharing.json | celebration.caption.0.v | כׇּל הַכָּבוֹד! חִלַּקְתֶּם בְּהֲגִינוּת. | needs-editor |
| lesson.sort-by-hand.json | title.0.v | מְמַיְּנִים בַּיָּדַיִם | needs-editor |
| lesson.sort-by-hand.json | celebration.caption.0.v | יָפֶה מְאֹד! מִיַּנְתֶּם בְּעַצְמְכֶם. | needs-editor |
| lesson.sorting-groups.json | title.0.v | מְמַיְּנִים לִקְבוּצוֹת | needs-editor |
| lesson.sorting-groups.json | celebration.caption.0.v | יָפֶה מְאֹד! מִיַּנְתֶּם לְפִי הַכְּלָל. | needs-editor |
| lesson.step-by-step.json | title.0.v | צַעַד אַחַר צַעַד | needs-editor |
| lesson.step-by-step.json | celebration.caption.0.v | כׇּל הַכָּבוֹד! יְדַעְתֶּם מָה בָּא קֹדֶם וּמָה בַּסּוֹף. | needs-editor |
| lesson.take-one-away.json | title.0.v | אֶחָד הָלַךְ | needs-editor |
| lesson.take-one-away.json | celebration.caption.0.v | יָפֶה מְאֹד! יְדַעְתֶּם כַּמָּה נִשְׁאֲרוּ. | needs-editor |
| lesson.the-shop.json | title.0.v | הַחֲנוּת | needs-editor |
| lesson.the-shop.json | celebration.caption.0.v | כׇּל הַכָּבוֹד! שִׁלַּמְתֶּם מַטְבֵּעַ אֶחָד לְכׇל דָּבָר. | needs-editor |
| lesson.tricky-sizes.json | title.0.v | לֹא לְפִי הַגֹּדֶל | needs-editor |
| lesson.tricky-sizes.json | celebration.caption.0.v | חֲכָמִים! סְפַרְתֶּם וְלֹא הִסְתַּכַּלְתֶּם עַל הַגֹּדֶל. | needs-editor |
| lesson.where-is-it.json | title.0.v | אֵיפֹה זֶה? | needs-editor |
| lesson.where-is-it.json | celebration.caption.0.v | יָפֶה מְאֹד! הֵבַנְתֶּם אֵיפֹה כֻּל דָּבָר. | needs-editor |
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
| misconception.M-COL-NAME.json | parentText | הילד קורא לגוון אחד בשם של גוון אחר, למשל כתום 'אדום'. | needs-editor |
| misconception.M-COL-NAME.json | homeActivity.0.v | לשחק בחיפוש צבעים בבית: 'תביא משהו אדום', ואחר כך 'משהו כתום'. אם הילד מתבלבל, להניח את שני הדברים זה ליד זה ולהסתכל יחד. | needs-editor |
| misconception.M-COL-OBJECT.json | parentText | הילד חושב שלכל דבר יש צבע אחד בלבד, ולא מקבל בננה ירוקה. | needs-editor |
| misconception.M-COL-OBJECT.json | homeActivity.0.v | להראות בננה ירוקה ובננה צהובה בשוק או בתמונה, ולשאול מה זה. לדבר על כך שהפרי משנה צבע כשהוא מבשיל. | needs-editor |
| misconception.M-COL-ONEATTR.json | parentText | הילד שם לב רק לצבע או רק לסוג הדבר, ולא לשניהם יחד. | needs-editor |
| misconception.M-COL-ONEATTR.json | homeActivity.0.v | לבקש 'את הכדור הכחול' כשיש על השולחן כדורים וגם בלונים בצבעים שונים. קודם לבחור את הכדורים, ואחר כך את הכחול. | needs-editor |
| misconception.M-CS-OFF1.json | parentText | הילד מתכנן מסלול שמסתיים משבצת אחת לפני היעד או אחריו, כי ספר גם את משבצת ההתחלה או פספס צעד. | needs-editor |
| misconception.M-CS-OFF1.json | homeActivity.0.v | לצייר על הרצפה או על דף שורה של משבצות, להניח בובה בהתחלה ולבקש מהילד לתכנן כמה צעדים עד למשבצת ההיא. לקפוץ יחד, צעד אחד בכל פעם, ולספור. | needs-editor |
| misconception.M-NUM-ZERO.json | parentText | הילד חושב שאפס הוא לא מספר, ואומר 'אחת' או 'כלום' כשאין עצמים. | needs-editor |
| misconception.M-NUM-ZERO.json | homeActivity.0.v | להראות קערה ריקה ולשאול כמה תפוחים יש בה. לתת לילד להגיד 'אפס', ואז להכניס תפוח ולשאול שוב. | needs-editor |
| misconception.M-ORD-CARD.json | parentText | הילד מבלבל בין 'השלישי' בתור לבין 'שלושה' ילדים. | needs-editor |
| misconception.M-ORD-CARD.json | homeActivity.0.v | לעמוד בתור עם בובות: מי הראשון, מי השני, מי האחרון? להחליף את המקומות ולשאול שוב. | needs-editor |
| misconception.M-PAT-COPY.json | parentText | הילד מעתיק את האיברים בלי הסדר: מניח אותם בסדר אחר. | needs-editor |
| misconception.M-PAT-COPY.json | homeActivity.0.v | להניח שלוש חרוזים או כפתורים בסדר מסוים ולבקש מהילד להניח מתחתם את אותו סדר, אחד מתחת לאחד. לשים אצבע על כל זוג. | needs-editor |
| misconception.M-PAT-NEXT.json | parentText | הילד ממשיך סדר חוזר באיבר האחרון שראה, או באיבר אקראי. | needs-editor |
| misconception.M-PAT-NEXT.json | homeActivity.0.v | להכין סדר של כפית וסכין על השולחן ולבקש מהילד להמשיך. לומר את הסדר בקול ('כפית, סכין, כפית, סכין') ולהמשיך יחד. | needs-editor |
| misconception.M-SEQ-CAUSE.json | parentText | הילד מסדר שלבים בלי להתחשב בסיבה ותוצאה, למשל שובר את הביצה אחרי שהעוגה אפויה. | needs-editor |
| misconception.M-SEQ-CAUSE.json | homeActivity.0.v | לספר סיפור קצר על דבר שקורה בבית (לשתול זרע, לאפות עוגה) ולשאול בכל שלב: מה קרה קודם, ומה אחר כך? | needs-editor |
| misconception.M-SER-ENDS.json | parentText | הילד מסדר לפי גודל רק את הקצוות (הכי גדול, הכי קטן) ומשאיר את האמצע באקראי. | needs-editor |
| misconception.M-SER-ENDS.json | homeActivity.0.v | לסדר שלוש כוסות בגדלים שונים בשורה, ולבקש מהילד למצוא את זו שבאמצע. אחר כך להחליף את הסדר ולבקש שוב. | needs-editor |
| misconception.M-SHARE-UNEQ.json | parentText | הילד מחלק לא שווה, למשל אחד לך ושניים לי. | needs-editor |
| misconception.M-SHARE-UNEQ.json | homeActivity.0.v | לחלק ביחד ארבעה תפוחים או כפתורים בין שתי בובות: אחד לזו, אחד לזו, עד שנגמר. אחר כך לספור אצל כל בובה. | needs-editor |
| misconception.M-SHP-ORIENT.json | parentText | הילד לא מכיר ריבוע מסובב או משולש הפוך כאותה צורה. | needs-editor |
| misconception.M-SHP-ORIENT.json | homeActivity.0.v | לגזור ריבוע מנייר ולסובב אותו על השולחן, ולשאול בכל פעם: מה זה? להראות שהצורה נשארת אותה צורה. | needs-editor |
| misconception.M-SHP-PROTO.json | parentText | הילד מזהה רק את הצורה הרגילה, למשל משולש שווה צלעות, ולא משולש צר וגבוה. | needs-editor |
| misconception.M-SHP-PROTO.json | homeActivity.0.v | לצייר יחד כמה משולשים שונים, רחבים וצרים, ולספור בכל אחד שלוש צלעות. | needs-editor |
| misconception.M-SHP-SIZE.json | parentText | הילד חושב שצורה גדולה וצורה קטנה הן צורות שונות. | needs-editor |
| misconception.M-SHP-SIZE.json | homeActivity.0.v | להניח עיגול גדול ועיגול קטן זה ליד זה, ולשאול: מה אותו דבר? לעזור לו להגיד 'שניהם עיגולים'. | needs-editor |
| misconception.M-SHP-SQRECT.json | parentText | הילד מבלבל בין ריבוע למלבן. | needs-editor |
| misconception.M-SHP-SQRECT.json | homeActivity.0.v | למדוד בנייר שני צדדים של ריבוע ושל מלבן, ולהשוות: במה הם שונים? | needs-editor |
| misconception.M-SORT-SHIFT.json | parentText | הילד מחליף את כלל המיון באמצע: מתחיל לפי צבע וממשיך לפי צורה. | needs-editor |
| misconception.M-SORT-SHIFT.json | homeActivity.0.v | למיין כפתורים או גרביים לשתי קופסאות ולהגיד בקול את הכלל ('כל האדומים'). אם הילד מחליף כלל, להגיד את הכלל שוב. | needs-editor |
| misconception.M-SPACE-WORD.json | parentText | הילד מבלבל בין מילות מקום כמו על ומתחת. | needs-editor |
| misconception.M-SPACE-WORD.json | homeActivity.0.v | להניח כדור על שולחן ומתחתיו, ולהגיד את המילה בכל פעם ('על השולחן', 'מתחת לשולחן'). אחר כך לבקש מהילד להניח לפי המילה. | needs-editor |
| skill.COL-A-01.json | title.0.v | מתאימים צבעים זהים | needs-editor |
| skill.COL-A-01.json | childLine.0.v | מוֹצְאִים אֶת אוֹתוֹ צֶבַע | needs-editor |
| skill.COL-A-02.json | title.0.v | מצביעים על אדום, כחול, צהוב וירוק כששומעים את שמם | needs-editor |
| skill.COL-A-02.json | childLine.0.v | מַצְבִּיעִים עַל אָדֹם, כָּחֹל, צָהֹב וְיָרֹק | needs-editor |
| skill.COL-A-03.json | title.0.v | מזהים כתום, סגול, ורוד, שחור ולבן כשהם נקראים בשם | needs-editor |
| skill.COL-A-03.json | childLine.0.v | מַכִּירִים עוֹד צְבָעִים | needs-editor |
| skill.COL-A-04.json | title.0.v | ממיינים לפי צבע, בלי להתחשב בצורה ובגודל | needs-editor |
| skill.COL-A-04.json | childLine.0.v | מְמַיְּנִים לְפִי צֶבַע | needs-editor |
| skill.COL-A-05.json | title.0.v | יודעים את הצבעים הרגילים של דברים, ושהם יכולים להשתנות | needs-editor |
| skill.COL-A-05.json | childLine.0.v | יוֹדְעִים אֵיזֶה צֶבַע יֵשׁ לַדְּבָרִים | needs-editor |
| skill.COL-A-06.json | title.0.v | מזהים חום ואפור | needs-editor |
| skill.COL-A-06.json | childLine.0.v | מַכִּירִים חוּם וְאָפֹר | needs-editor |
| skill.COL-A-07.json | title.0.v | מוצאים דבר לפי צבע וסוג ('הבלון האדום') | needs-editor |
| skill.COL-A-07.json | childLine.0.v | מוֹצְאִים אֶת הַדָּבָר הַנָּכוֹן לְפִי הַצֶּבַע | needs-editor |
| skill.CS-A-01.json | title.0.v | מסדרים שלושה שלבים של שגרה (רחצת ידיים, צחצוח שיניים) | needs-editor |
| skill.CS-A-01.json | childLine.0.v | מַסְדִּירִים שְׁלָבִים: מָה קֹדֶם, מָה בַּסּוֹף | needs-editor |
| skill.CS-A-03.json | title.0.v | מזיזים רובוט צעד אחר צעד בחיצים (שליטה ישירה) | needs-editor |
| skill.CS-A-03.json | childLine.0.v | מְזִיזִים רוֹבּוֹט בַּחִצִּים | needs-editor |
| skill.CS-A-04.json | title.0.v | מתכננים מסלול של 2 עד 3 צעדים ואז לוחצים "יוצאים" | needs-editor |
| skill.CS-A-04.json | childLine.0.v | מְתַכְנְנִים אֶת הַדֶּרֶךְ וְאָז יוֹצְאִים | needs-editor |
| skill.CS-A-05.json | title.0.v | מוצאים את השלב שלא שייך לרצף | needs-editor |
| skill.CS-A-05.json | childLine.0.v | מוֹצְאִים אֶת הַשָּׁלָב שֶׁלֹּא שַׁיָּךְ | needs-editor |
| skill.LOG-A-01.json | title.0.v | מוצאים את הדבר שזהה | needs-editor |
| skill.LOG-A-01.json | childLine.0.v | מוֹצְאִים אֶת הַדָּבָר הַזֵּהֶה | needs-editor |
| skill.LOG-A-02.json | title.0.v | מוצאים את החריג לפי תכונה אחת | needs-editor |
| skill.LOG-A-02.json | childLine.0.v | מוֹצְאִים מִי שׁוֹנֶה | needs-editor |
| skill.LOG-A-03.json | title.0.v | ממיינים לשתי קבוצות לפי כלל נתון | needs-editor |
| skill.LOG-A-03.json | childLine.0.v | מְמַיְּנִים לְשָׁתֵּי קְבוּצוֹת | needs-editor |
| skill.LOG-A-04.json | title.0.v | מזהים סדר שחוזר על עצמו | needs-editor |
| skill.LOG-A-04.json | childLine.0.v | מַכִּירִים סֵדֶר שֶׁחוֹזֵר | needs-editor |
| skill.LOG-A-05.json | title.0.v | מעתיקים סדר שחוזר (אב) | needs-editor |
| skill.LOG-A-05.json | childLine.0.v | מַעֲתִיקִים אֶת הַסֵּדֶר | needs-editor |
| skill.LOG-A-06.json | title.0.v | ממשיכים סדר של שני איברים | needs-editor |
| skill.LOG-A-06.json | childLine.0.v | מַמְשִׁיכִים אֶת הַסֵּדֶר | needs-editor |
| skill.LOG-A-07.json | title.0.v | מתקנים סדר שנשבר | needs-editor |
| skill.LOG-A-07.json | childLine.0.v | מְתַקְּנִים סֵדֶר שֶׁנִּשְׁבַּר | needs-editor |
| skill.LOG-A-08.json | title.0.v | מסדרים סיפור בן שלוש תמונות: קודם, אחר כך, בסוף | needs-editor |
| skill.LOG-A-08.json | childLine.0.v | מַסְדִּירִים סִפּוּר: קֹדֶם, אַחַר כָּךְ, בַּסּוֹף | needs-editor |
| skill.LOG-A-09.json | title.0.v | מתאימים דברים שהולכים יחד | needs-editor |
| skill.LOG-A-09.json | childLine.0.v | מוֹצְאִים מָה הוֹלֵךְ יַחַד | needs-editor |
| skill.LOG-A-10.json | title.0.v | מסדרים 3 עצמים לפי גודל | needs-editor |
| skill.LOG-A-10.json | childLine.0.v | מַסְדִּירִים לְפִי גֹּדֶל | needs-editor |
| skill.MATH-A-01.json | title.0.v | מוסיפים 1 או 2 לקבוצה קטנה (עד 5) ואומרים כמה יש עכשיו | needs-editor |
| skill.MATH-A-01.json | childLine.0.v | מוֹסִיפִים עוֹד וְסוֹפְרִים כַּמָּה | needs-editor |
| skill.MATH-A-02.json | title.0.v | לוקחים 1 מקבוצה קטנה (עד 5) ואומרים כמה נשאר | needs-editor |
| skill.MATH-A-02.json | childLine.0.v | לוֹקְחִים אֶחָד וְסוֹפְרִים כַּמָּה נִשְׁאַר | needs-editor |
| skill.MATH-A-03.json | title.0.v | מחלקים בהגינות בין שני חברים (עד 6) | needs-editor |
| skill.MATH-A-03.json | childLine.0.v | מְחַלְּקִים בְּהֲגִינוּת: לְכׇל אֶחָד אוֹתוֹ דָּבָר | needs-editor |
| skill.MATH-A-04.json | title.0.v | משווים גדול וקטן, ארוך וקצר, כבד וקל | needs-editor |
| skill.MATH-A-04.json | childLine.0.v | מַשְׁווִים גָּדוֹל וְקָטָן, אָרֹךְ וְקָצָר, כָּבֵד וְקַל | needs-editor |
| skill.MATH-A-05.json | title.0.v | מכירים בוקר, צהריים, ערב ולילה | needs-editor |
| skill.MATH-A-05.json | childLine.0.v | מַכִּירִים בֹּקֶר, צָהֳרַיִם, עֶרֶב וְלַיְלָה | needs-editor |
| skill.MATH-A-06.json | title.0.v | משחקים בחנות: מטבע אחד על כל פריט | needs-editor |
| skill.MATH-A-06.json | childLine.0.v | קוֹנִים בַּחֲנוּת: מַטְבֵּעַ לְכׇל דָּבָר | needs-editor |
| skill.MATH-A-07.json | title.0.v | משווים קבוצות בתרשים תמונות: איפה יותר | needs-editor |
| skill.MATH-A-07.json | childLine.0.v | מַשְׁווִים בְּתַרְשִׁים תְּמוּנוֹת | needs-editor |
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
| skill.SHP-A-01.json | title.0.v | מתאימים עיגולים, ריבועים ומשולשים זהים | needs-editor |
| skill.SHP-A-01.json | childLine.0.v | מוֹצְאִים אֶת אוֹתָהּ צוּרָה | needs-editor |
| skill.SHP-A-02.json | title.0.v | קוראים בשם לעיגול, ריבוע ומשולש | needs-editor |
| skill.SHP-A-02.json | childLine.0.v | מַכִּירִים עִגּוּל, רִבּוּעַ וּמְשֻׁלָּשׁ | needs-editor |
| skill.SHP-A-03.json | title.0.v | מזהים צורות בכל גודל ובכל כיוון | needs-editor |
| skill.SHP-A-03.json | childLine.0.v | מַכִּירִים צוּרוֹת גְּדוֹלוֹת, קְטַנּוֹת וּמְסֻבָּבוֹת | needs-editor |
| skill.SHP-A-04.json | title.0.v | מזהים מלבן ומבדילים אותו מריבוע | needs-editor |
| skill.SHP-A-04.json | childLine.0.v | מַכִּירִים מַלְבֵּן | needs-editor |
| skill.SHP-A-05.json | title.0.v | מוצאים צורות בעולם: חלון, צלחת, שלט | needs-editor |
| skill.SHP-A-05.json | childLine.0.v | מוֹצְאִים צוּרוֹת בָּעוֹלָם | needs-editor |
| skill.SHP-A-07.json | title.0.v | מבדילים כדור מקובייה: מתגלגל או נערם | needs-editor |
| skill.SHP-A-07.json | childLine.0.v | יוֹדְעִים מָה מִתְגַּלְגֵּל וּמָה נֶעֱרָם | needs-editor |
| skill.SHP-A-08.json | title.0.v | מבינים על, מתחת, בתוך, ליד ומעל | needs-editor |
| skill.SHP-A-08.json | childLine.0.v | מְבִינִים עַל, מִתַּחַת, בְּתוֹךְ וְלְיַד | needs-editor |
| skill.SHP-A-10.json | title.0.v | מבדילים קו ישר מקו עקום | needs-editor |
| skill.SHP-A-10.json | childLine.0.v | מַכִּירִים קַו יָשָׁר וְקַו עָקֹם | needs-editor |

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
