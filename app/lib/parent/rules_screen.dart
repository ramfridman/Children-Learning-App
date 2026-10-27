import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/rules_providers.dart';
import '../app/tutor_providers.dart';
import '../design/app_text.dart';
import '../design/components.dart';
import '../design/tokens.g.dart';
import '../strings/he.dart';
import 'parent_rules.dart';

/// The parent's time rules and the AI helper switch, on one calm screen. Every change is saved at once; the child's
/// next tap uses it. Times move in half hours and minutes in fives, so there is nothing to type.
class RulesScreen extends ConsumerWidget {
  const RulesScreen({super.key, required this.onClose});

  final VoidCallback onClose;

  static const int _step = 5;
  static const int _half = 30;
  static const int _defaultFrom = 15 * 60;
  static const int _defaultTo = 18 * 60;

  static String clock(int minute) =>
      '${(minute ~/ 60).toString().padLeft(2, '0')}:${(minute % 60).toString().padLeft(2, '0')}';

  static int wrap(int minute) => (minute % 1440 + 1440) % 1440;

  Widget _card(String title, List<Widget> children) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: TokenColors.paper,
      borderRadius: BorderRadius.circular(TokenRadius.md),
      border: Border.all(color: TokenColors.hairline, width: TokenBorder.thin),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: AppText.parent(TokenType.parentH2)),
        const SizedBox(height: 8),
        ...children,
      ],
    ),
  );

  /// A label with a "less" and a "more" button and the value between them.
  Widget _stepper({
    required String keyName,
    required String label,
    required String value,
    required VoidCallback onLess,
    required VoidCallback onMore,
    required String lessLabel,
    required String moreLabel,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: <Widget>[
        Expanded(child: Text(label, style: AppText.parent(TokenType.parentBody))),
        IconButton(
          key: Key('$keyName-less'),
          tooltip: lessLabel,
          icon: const Icon(Icons.remove_circle_outline_rounded),
          onPressed: onLess,
        ),
        SizedBox(
          width: 96,
          child: Text(value, textAlign: TextAlign.center, style: AppText.parent(TokenType.parentBody)),
        ),
        IconButton(
          key: Key('$keyName-more'),
          tooltip: moreLabel,
          icon: const Icon(Icons.add_circle_outline_rounded),
          onPressed: onMore,
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ParentRules rules = ref.watch(rulesProvider).value ?? const ParentRules();
    final RulesNotifier notifier = ref.read(rulesProvider.notifier);
    final bool ai = ref.watch(aiHelperProvider).value ?? false;
    final List<Str> bandNames = <Str>[He.timeBand0, He.timeBand1, He.timeBand2];
    final List<Str> dayNames = <Str>[
      He.timeDay7,
      He.timeDay1,
      He.timeDay2,
      He.timeDay3,
      He.timeDay4,
      He.timeDay5,
      He.timeDay6,
    ];
    const List<int> dayNumbers = <int>[7, 1, 2, 3, 4, 5, 6];

    int limitOf(String band) => rules.limitByBand[band]!;
    void setLimit(String band, int minutes) => notifier.set(
      rules.copyWith(
        limitByBand: <String, int>{
          ...rules.limitByBand,
          band: minutes.clamp(ParentRules.minLimit, ParentRules.maxLimit),
        },
      ),
    );

    return Scaffold(
      backgroundColor: TokenColors.parentBg,
      appBar: AppBar(
        backgroundColor: TokenColors.night,
        foregroundColor: Colors.white,
        title: Text(He.timeTitle.text, style: AppText.parent(TokenType.parentH2, color: Colors.white)),
        leading: IconButton(icon: const Icon(Icons.arrow_forward_rounded), onPressed: onClose),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _card(He.timeLimitHeading.text, <Widget>[
              for (int i = 0; i < 3; i++)
                _stepper(
                  keyName: 'limit-${'ABC'[i]}',
                  label: bandNames[i].text,
                  value: He.timeMinutes.fill(<String, String>{'n': '${limitOf('ABC'[i])}'}),
                  onLess: () => setLimit('ABC'[i], limitOf('ABC'[i]) - _step),
                  onMore: () => setLimit('ABC'[i], limitOf('ABC'[i]) + _step),
                  lessLabel: He.timeLess.text,
                  moreLabel: He.timeMore.text,
                ),
            ]),
            _card(He.timeRestHeading.text, <Widget>[
              Row(
                children: <Widget>[
                  Expanded(child: Text(He.timeRestOn.text, style: AppText.parent(TokenType.parentBody))),
                  Switch(
                    key: const Key('rest-on'),
                    value: rules.restOn,
                    onChanged: (bool on) => notifier.set(rules.copyWith(restOn: on)),
                  ),
                ],
              ),
              if (rules.restOn) ...<Widget>[
                _stepper(
                  keyName: 'rest-from',
                  label: He.timeRestFrom.fill(<String, String>{'t': clock(rules.restStartMinute)}),
                  value: clock(rules.restStartMinute),
                  onLess: () =>
                      notifier.set(rules.copyWith(restStartMinute: wrap(rules.restStartMinute - _half))),
                  onMore: () =>
                      notifier.set(rules.copyWith(restStartMinute: wrap(rules.restStartMinute + _half))),
                  lessLabel: He.timeEarlier.text,
                  moreLabel: He.timeLater.text,
                ),
                _stepper(
                  keyName: 'rest-to',
                  label: He.timeRestTo.fill(<String, String>{'t': clock(rules.restEndMinute)}),
                  value: clock(rules.restEndMinute),
                  onLess: () =>
                      notifier.set(rules.copyWith(restEndMinute: wrap(rules.restEndMinute - _half))),
                  onMore: () =>
                      notifier.set(rules.copyWith(restEndMinute: wrap(rules.restEndMinute + _half))),
                  lessLabel: He.timeEarlier.text,
                  moreLabel: He.timeLater.text,
                ),
              ],
              const Divider(),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(He.timeLock.text, style: AppText.parent(TokenType.parentBody)),
                        Text(He.timeLockHelp.text, style: AppText.parent(TokenType.parentSmall)),
                      ],
                    ),
                  ),
                  Switch(
                    key: const Key('lock-when-done'),
                    value: rules.lockWhenDone,
                    onChanged: (bool on) => notifier.set(rules.copyWith(lockWhenDone: on)),
                  ),
                ],
              ),
            ]),
            _card(He.timeScheduleHeading.text, <Widget>[
              Text(He.timeScheduleHelp.text, style: AppText.parent(TokenType.parentSmall)),
              for (int i = 0; i < 7; i++)
                ...() {
                  final int day = dayNumbers[i];
                  final List<List<int>>? windows = rules.schedule[day];
                  final bool limited = windows != null && windows.isNotEmpty;
                  final List<int> w = limited ? windows.first : <int>[_defaultFrom, _defaultTo];
                  void setWindow(List<int>? next) => notifier.set(
                    rules.copyWith(
                      schedule: <int, List<List<int>>>{
                        for (final MapEntry<int, List<List<int>>> e in rules.schedule.entries)
                          if (e.key != day) e.key: e.value,
                        if (next != null) day: <List<int>>[next],
                      },
                    ),
                  );
                  return <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            '${dayNames[i].text}: ${limited ? He.timeDayWindow.fill(<String, String>{'a': clock(w[0]), 'b': clock(w[1])}) : He.timeDayAny.text}',
                            style: AppText.parent(TokenType.parentBody),
                          ),
                        ),
                        Switch(
                          key: Key('day-$day'),
                          value: limited,
                          onChanged: (bool on) => setWindow(on ? <int>[_defaultFrom, _defaultTo] : null),
                        ),
                      ],
                    ),
                    if (limited) ...<Widget>[
                      _stepper(
                        keyName: 'day-$day-from',
                        label: He.timeRestFrom.fill(<String, String>{'t': clock(w[0])}),
                        value: clock(w[0]),
                        onLess: () => setWindow(<int>[wrap(w[0] - _half), w[1]]),
                        onMore: () => setWindow(<int>[wrap(w[0] + _half), w[1]]),
                        lessLabel: He.timeEarlier.text,
                        moreLabel: He.timeLater.text,
                      ),
                      _stepper(
                        keyName: 'day-$day-to',
                        label: He.timeRestTo.fill(<String, String>{'t': clock(w[1])}),
                        value: clock(w[1]),
                        onLess: () => setWindow(<int>[w[0], wrap(w[1] - _half)]),
                        onMore: () => setWindow(<int>[w[0], wrap(w[1] + _half)]),
                        lessLabel: He.timeEarlier.text,
                        moreLabel: He.timeLater.text,
                      ),
                    ],
                  ];
                }(),
            ]),
            _card(He.aiHeading.text, <Widget>[
              Row(
                children: <Widget>[
                  Expanded(child: Text(He.aiHelp.text, style: AppText.parent(TokenType.parentSmall))),
                  Switch(
                    key: const Key('ai-helper-parent-switch'),
                    value: ai,
                    onChanged: (bool on) => ref.read(aiHelperProvider.notifier).set(on),
                  ),
                ],
              ),
            ]),
            const SizedBox(height: 8),
            ParentButton(label: He.pinOk.text, onPressed: onClose),
          ],
        ),
      ),
    );
  }
}
