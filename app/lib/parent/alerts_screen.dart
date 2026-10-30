import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/alerts_provider.dart';
import '../app/providers.dart';
import '../app/state.dart';
import '../data/app_database.dart';
import '../design/app_text.dart';
import '../design/components.dart';
import '../design/tokens.g.dart';
import '../rewards/award.dart';
import '../rewards/names.dart';
import '../rewards/ribbons.dart';
import '../strings/he.dart';
import 'alert_scan.dart';
import 'alerts.dart';
import 'word_alert_text.dart';

/// When an alert happened, as the card shows it: day.month hours:minutes of the wall-clock time [local].
String alertWhen(DateTime local) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(local.day)}.${two(local.month)} ${two(local.hour)}:${two(local.minute)}';
}

/// What the parent has been told about, newest first, each with a severity and one line on what to do. Opening the
/// screen marks everything read. The child never sees any of it.
class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  bool _keepWords = true;

  /// The parents' promises, looked up here and never carried by an alert.
  Promises _promises = const <String, Map<String, String>>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final AppDatabase db = await ref.read(databaseProvider.future);
    final bool keep = await keepWordsOn(db);
    final Promises promises = decodeRibbons(await db.setting('ribbons'));
    await db.markAlertsRead(DateTime.fromMillisecondsSinceEpoch(ref.read(clockProvider).nowMs()));
    ref.invalidate(unreadAlertsProvider);
    if (mounted) {
      setState(() {
        _keepWords = keep;
        _promises = promises;
      });
    }
  }

  Future<void> _setKeep(bool on) async {
    final AppDatabase db = await ref.read(databaseProvider.future);
    await db.putSetting(keepWordsKey, on ? 'on' : 'off');
    if (!on) {
      await db.clearAlertWords();
      ref.invalidate(alertsProvider);
    }
    if (mounted) setState(() => _keepWords = on);
  }

  /// A trophy with a promise was earned: the alert holds the trophy's key, and the words are looked up here.
  ({String title, String detail, String todo}) _ribbon(Alert a) {
    final ({TrophyLand land, TrophyTier tier})? t = Awards.trophyOf(a.detail);
    final String trophy = t == null ? '' : trophyNamePlain(t.land, t.tier);
    final String? promise = a.profileId == null ? null : _promises[a.profileId]?[a.detail];
    return (
      title: He.alertRibbonTitle.text,
      detail: promise == null
          ? He.alertRibbonNoWords.fill(<String, String>{'t': trophy})
          : He.alertRibbonDetail.fill(<String, String>{'t': trophy, 'w': promise}),
      todo: He.alertRibbonDo.text,
    );
  }

  ({String title, String detail, String todo}) _text(Alert a) {
    String n(String s) => s.replaceAll('{n}', '${a.count}');
    return switch (a.category) {
      'ribbonEarned' => _ribbon(a),
      'pastLimit' => (
        title: He.alertPastLimitTitle.text,
        detail: n(He.alertPastLimitDetail.text),
        todo: He.alertPastLimitDo.text,
      ),
      'restHours' => (
        title: He.alertRestTitle.text,
        detail: n(He.alertRestDetail.text),
        todo: He.alertRestDo.text,
      ),
      'gateAttempts' => (
        title: He.alertGateTitle.text,
        detail: n(He.alertGateDetail.text),
        todo: He.alertGateDo.text,
      ),
      'guessing' => (title: He.alertGuessTitle.text, detail: '', todo: He.alertGuessDo.text),
      'frustration' => (title: He.alertUpsetTitle.text, detail: '', todo: He.alertUpsetDo.text),
      'absence' when a.detail == 'drop' => (
        title: He.alertDropTitle.text,
        detail: '',
        todo: He.alertDropDo.text,
      ),
      'absence' => (
        title: He.alertAbsenceTitle.text,
        detail: n(He.alertAbsenceDetail.text),
        todo: He.alertAbsenceDo.text,
      ),
      _ => (title: a.category, detail: '', todo: ''),
    };
  }

  String _severity(String s) => switch (s) {
    'important' => He.severityImportant.text,
    'attention' => He.severityAttention.text,
    _ => He.severityInfo.text,
  };

  Color _severityColor(String s) => switch (s) {
    'important' => TokenColors.domainNumbersDeep,
    'attention' => TokenColors.domainMathDeep,
    _ => TokenColors.inkSoft,
  };

  /// One line of an alert. A bullet hangs: its second line starts under the text, not under the bullet. Every line is
  /// plain text, so all of them sit on the same edge (QA-46); a word alert's lines are selectable as a whole (see
  /// [_body]), so a parent can copy a help number; the line that quotes the child's words is the one exception, it
  /// cannot be selected or copied to the clipboard (SEC-33). Numbers are never links (no link opener in the app).
  Widget _line(AlertLine l) {
    final TextStyle style = switch (l.kind) {
      AlertLineKind.heading => AppText.parent(TokenType.parentH3),
      AlertLineKind.small => AppText.parent(TokenType.parentSmall, color: TokenColors.inkSoft),
      AlertLineKind.body || AlertLineKind.bullet => AppText.parent(TokenType.parentBody),
    };
    final Text plain = Text(l.text, style: style);
    final Widget text = l.hasWords ? SelectionContainer.disabled(child: plain) : plain;
    return Padding(
      padding: EdgeInsets.only(top: l.kind == AlertLineKind.heading ? 10 : 4),
      child: l.kind != AlertLineKind.bullet
          ? text
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('•', style: style),
                const SizedBox(width: 6),
                Expanded(child: text),
              ],
            ),
    );
  }

  /// The severity a category has (the row's own is the device's word and is shown only for an unknown category).
  String _severityOf(Alert a) {
    final AlertCategory? c = AlertCategory.values.asNameMap()[a.category];
    return c == null ? a.severity : severityOf(c).name;
  }

  /// The card of one alert: a word alert has its own lines; every other kind a detail and one line on what to do.
  List<Widget> _body(Alert a, String? name) {
    final ({String title, List<AlertLine> lines})? words = wordAlertText(
      a,
      name ?? He.alertChildFallback.text,
    );
    final ({String title, String detail, String todo}) t = words == null
        ? _text(a)
        : (title: words.title, detail: '', todo: '');
    return <Widget>[
      Text(
        name == null ? t.title : He.alertAbout.fill(<String, String>{'child': name, 'title': t.title}),
        style: AppText.parent(TokenType.parentH2),
      ),
      if (words != null)
        SelectionArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[for (final AlertLine l in words.lines) _line(l)],
          ),
        )
      else ...<Widget>[
        if (t.detail.isNotEmpty) Text(t.detail, style: AppText.parent(TokenType.parentBody)),
        const SizedBox(height: 6),
        Text(t.todo, style: AppText.parent(TokenType.parentSmall)),
      ],
    ];
  }

  /// A short card for every parent: secrets and the private places (a counsellor reviews the wording).
  Widget _card() => Container(
    key: const Key('alerts-card'),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: TokenColors.paper,
      borderRadius: BorderRadius.circular(TokenRadius.md),
      border: Border.all(color: TokenColors.hairline, width: TokenBorder.thin),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(He.alertCardTitle.text, style: AppText.parent(TokenType.parentH3)),
        for (final Str s in <Str>[He.alertCard1, He.alertCard2, He.alertCard3, He.alertCard4])
          _line(AlertLine(s.text, AlertLineKind.bullet)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Alert>> alerts = ref.watch(alertsProvider);
    final DateTime Function(DateTime) local = ref.watch(localTimeProvider);
    final Map<String, String> names = <String, String>{
      for (final Profile p in ref.watch(appStateProvider).value?.profiles ?? const <Profile>[]) p.id: p.name,
    };
    return Scaffold(
      backgroundColor: TokenColors.parentBg,
      appBar: AppBar(
        backgroundColor: TokenColors.night,
        foregroundColor: Colors.white,
        title: Text(He.alertsTitle.text, style: AppText.parent(TokenType.parentH2, color: Colors.white)),
        leading: IconButton(icon: const Icon(Icons.arrow_forward_rounded), onPressed: widget.onClose),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            alerts.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object e, StackTrace s) =>
                  Text(He.setupError.text, style: AppText.parent(TokenType.parentBody)),
              data: (List<Alert> list) => list.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        He.alertsNone.text,
                        key: const Key('alerts-none'),
                        textAlign: TextAlign.center,
                        style: AppText.parent(TokenType.parentBody),
                      ),
                    )
                  : Column(
                      children: <Widget>[
                        for (final Alert a in list)
                          Container(
                            key: Key('alert-${a.dedupeKey}'),
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: TokenColors.paper,
                              borderRadius: BorderRadius.circular(TokenRadius.md),
                              border: Border.all(color: _severityColor(_severityOf(a)), width: 1.5),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Text(
                                      _severity(_severityOf(a)),
                                      style: AppText.parent(
                                        TokenType.parentSmall,
                                        color: _severityColor(_severityOf(a)),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      alertWhen(local(a.at)),
                                      style: AppText.parent(
                                        TokenType.parentSmall,
                                        color: TokenColors.inkSoft,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                ..._body(a, names[a.profileId]),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: TokenColors.paper,
                borderRadius: BorderRadius.circular(TokenRadius.md),
                border: Border.all(color: TokenColors.hairline, width: TokenBorder.thin),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(He.alertsKeepWords.text, style: AppText.parent(TokenType.parentBody)),
                        Text(He.alertsKeepWordsHelp.text, style: AppText.parent(TokenType.parentSmall)),
                        const SizedBox(height: 6),
                        Text(
                          He.alertsHonest.text,
                          key: const Key('alerts-honest'),
                          style: AppText.parent(TokenType.parentSmall, color: TokenColors.inkSoft),
                        ),
                      ],
                    ),
                  ),
                  Switch(key: const Key('keep-words'), value: _keepWords, onChanged: _setKeep),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _card(),
            const SizedBox(height: 8),
            Text(
              He.alertsNever.text,
              style: AppText.parent(TokenType.parentSmall, color: TokenColors.inkSoft),
            ),
            const SizedBox(height: 16),
            ParentButton(label: He.pinOk.text, onPressed: widget.onClose),
          ],
        ),
      ),
    );
  }
}
