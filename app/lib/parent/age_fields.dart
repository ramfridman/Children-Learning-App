import 'package:flutter/material.dart';

import '../design/app_text.dart';
import '../design/tokens.g.dart';
import '../engine/age.dart';
import '../strings/he.dart';

// The one widget that asks for a child's age (B-29, docs/design/b29-steps5-6.md section 2), in the child form and on the child's own age
// page: the month and year of birth (optional, two grids of chips) and the school stage (required, six chips). The year suggests the stage,
// the parent confirms it. It holds no state of its own: the page that shows it holds the value and decides when to save.

/// What the parent has chosen so far.
class AgeValue {
  const AgeValue({this.year, this.month, this.stage, this.stageChosen = false});

  final int? year;
  final int? month;
  final SchoolStage? stage;

  /// The parent tapped a stage chip: from then on the year no longer moves the stage.
  final bool stageChosen;

  /// A year with no month, or the reverse: it cannot be saved.
  bool get birthHalf => (year == null) != (month == null);

  /// The month and year as a birth, or null when none was given, or only one of them, or they do not make a real birth.
  BirthMonth? birthAt(DateTime now) =>
      year == null || month == null ? null : BirthMonth.tryCreate(year!, month!, now: now);

  AgeValue copyWith({
    int? year,
    int? month,
    SchoolStage? stage,
    bool? stageChosen,
    bool clearBirth = false,
  }) => AgeValue(
    year: clearBirth ? null : (year ?? this.year),
    month: clearBirth ? null : (month ?? this.month),
    stage: stage ?? this.stage,
    stageChosen: stageChosen ?? this.stageChosen,
  );
}

/// How a stage is named for a parent.
String stageName(SchoolStage s) => He.stageNames[s.index].text;

class AgeFields extends StatelessWidget {
  const AgeFields({
    super.key,
    required this.value,
    required this.onChanged,
    required this.now,
    this.suggestFromYear = true,
    this.currentStage,
    this.storedBand,
  });

  final AgeValue value;
  final ValueChanged<AgeValue> onChanged;
  final DateTime now;

  /// True in the form and for a child with no confirmed stage: choosing the year selects the stage it suggests, until the parent taps a
  /// stage. False on the page of a child whose stage is confirmed: the year never moves it, and a note says what it suggests.
  final bool suggestFromYear;

  /// The stage confirmed now (the page of a child that has one), for the note that the year suggests another.
  final SchoolStage? currentStage;

  /// The band the child has now: a stage of a lower band makes the screens look younger, which one line says before Save.
  final int? storedBand;

  /// The years offered: nine years back to two years back, earliest first (so the earliest is at the start, the right).
  List<int> get years => <int>[for (int y = now.year - 9; y <= now.year - 2; y++) y];

  void _year(int y) {
    final bool follow = suggestFromYear && !value.stageChosen;
    onChanged(value.copyWith(year: y, stage: follow ? suggestedStage(y, now) : null));
  }

  @override
  Widget build(BuildContext context) {
    final int? year = value.year;
    final SchoolStage? suggested = year == null ? null : suggestedStage(year, now);
    final SchoolStage? stage = value.stage;
    final List<Widget> stageNotes = <Widget>[
      if (suggestFromYear && !value.stageChosen && suggested != null && stage == suggested)
        _Note(He.ageStageSuggested.fill(<String, String>{'stage': stageName(suggested)})),
      if (!suggestFromYear && suggested != null && currentStage != null && suggested != currentStage)
        _Note(
          He.ageStageDiffers.fill(<String, String>{
            'suggested': stageName(suggested),
            'current': stageName(currentStage!),
          }),
        ),
      if (stage != null && storedBand != null && stage.band < storedBand!) _Note(He.ageStageYounger.text),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 4),
          child: Text.rich(
            TextSpan(
              children: <InlineSpan>[
                TextSpan(text: He.ageBirthTitle.text, style: AppText.parent(TokenType.parentH3)),
                const TextSpan(text: ' '),
                TextSpan(
                  text: He.ageBirthOptional.text,
                  style: AppText.parent(TokenType.parentSmall, color: TokenColors.inkSoft),
                ),
              ],
            ),
          ),
        ),
        Text(He.ageBirthHelp.text, style: AppText.parent(TokenType.parentSmall, color: TokenColors.inkSoft)),
        _Caption(He.ageYearLabel.text),
        ChipGrid(
          key: const Key('age-years'),
          columns: 4,
          cells: <ChipCell>[
            for (final int y in years)
              ChipCell(
                key: Key('year-$y'),
                label: '$y',
                semantics: He.ageBirthYearSemantics.fill(<String, String>{'year': '$y'}),
                selected: value.year == y,
                onTap: () => _year(y),
              ),
          ],
        ),
        _Caption(He.ageMonthLabel.text),
        ChipGrid(
          key: const Key('age-months'),
          columns: 4,
          cells: <ChipCell>[
            for (int m = 1; m <= 12; m++)
              ChipCell(
                key: Key('month-$m'),
                label: He.months[m - 1].text,
                selected: value.month == m,
                onTap: () => onChanged(value.copyWith(month: m)),
              ),
          ],
        ),
        if (value.year != null || value.month != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: _QuietButton(
                key: const Key('age-clear'),
                label: He.ageBirthClear.text,
                onTap: () => onChanged(value.copyWith(clearBirth: true)),
              ),
            ),
          ),
        if (value.birthHalf)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              He.ageBirthBoth.text,
              key: const Key('age-birth-both'),
              style: AppText.parent(TokenType.parentSmall, color: TokenColors.inkSoft),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 4),
          child: Text(He.ageStageTitle.text, style: AppText.parent(TokenType.parentH3)),
        ),
        Text(He.ageStageHelp.text, style: AppText.parent(TokenType.parentSmall, color: TokenColors.inkSoft)),
        const SizedBox(height: 8),
        ChipGrid(
          key: const Key('age-stages'),
          columns: 3,
          cells: <ChipCell>[
            for (final SchoolStage s in SchoolStage.values)
              ChipCell(
                key: Key('stage-${s.wire}'),
                label: stageName(s),
                semantics: He.ageStageSemantics.fill(<String, String>{'stage': stageName(s)}),
                selected: stage == s,
                onTap: () => onChanged(value.copyWith(stage: s, stageChosen: true)),
              ),
          ],
        ),
        ...stageNotes,
      ],
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 6),
    child: Text(text, style: AppText.parent(TokenType.parentSmall, color: TokenColors.inkSoft)),
  );
}

/// A calm note (a sea-tint box with an info glyph): what was suggested, or what a choice will do.
class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: TokenColors.seaTint,
      borderRadius: BorderRadius.circular(TokenRadius.sm),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Icon(Icons.info_rounded, size: 20, color: TokenColors.sea),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: AppText.parent(TokenType.parentSmall))),
      ],
    ),
  );
}

class _QuietButton extends StatelessWidget {
  const _QuietButton({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: TokenColors.paper,
          borderRadius: BorderRadius.circular(TokenRadius.sm),
          border: Border.all(color: TokenColors.night, width: TokenBorder.thin),
        ),
        child: Text(
          label,
          style: AppText.parent(TokenType.parentButton, color: TokenColors.night).copyWith(fontSize: 14),
        ),
      ),
    ),
  );
}

/// One cell of a [ChipGrid].
class ChipCell {
  const ChipCell({
    required this.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.semantics,
  });

  final Key key;
  final String label;
  final String? semantics;
  final bool selected;
  final VoidCallback onTap;
}

/// Equal columns of parent chips in reading order (the first at the start), each a row's cell the same width, so a row never breaks
/// raggedly. A chip is 40 high at least, grows when its label wraps (a larger text size), and shows a check when it is chosen: never colour
/// alone. Each grid is one radio group for a screen reader.
class ChipGrid extends StatelessWidget {
  const ChipGrid({super.key, required this.columns, required this.cells});

  final int columns;
  final List<ChipCell> cells;

  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = <Widget>[];
    for (int i = 0; i < cells.length; i += columns) {
      final List<ChipCell> row = cells.skip(i).take(columns).toList();
      rows.add(
        Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : TokenSpace.s2),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (int c = 0; c < columns; c++) ...<Widget>[
                  if (c > 0) const SizedBox(width: TokenSpace.s2),
                  Expanded(child: c < row.length ? _AgeChip(cell: row[c]) : const SizedBox.shrink()),
                ],
              ],
            ),
          ),
        ),
      );
    }
    return Semantics(container: true, child: Column(children: rows));
  }
}

class _AgeChip extends StatelessWidget {
  const _AgeChip({required this.cell});

  final ChipCell cell;

  @override
  Widget build(BuildContext context) {
    final bool on = cell.selected;
    return Semantics(
      key: cell.key,
      button: true,
      selected: on,
      inMutuallyExclusiveGroup: true,
      label: cell.semantics ?? cell.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: cell.onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? TokenColors.sea : TokenColors.paper,
            borderRadius: BorderRadius.circular(TokenRadius.xs),
            border: Border.all(color: TokenColors.ink, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (on) ...<Widget>[
                const Icon(Icons.check_rounded, size: 18, color: Colors.white),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  cell.label,
                  textAlign: TextAlign.center,
                  style: AppText.parent(
                    TokenType.parentButton,
                    color: on ? Colors.white : TokenColors.ink,
                  ).copyWith(fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
