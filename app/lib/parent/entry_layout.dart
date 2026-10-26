import 'package:flutter/material.dart';

import '../design/app_text.dart';
import '../design/tokens.g.dart';

/// The frame of the gate and the PIN screens. On a phone held sideways (wide and short) the text and
/// buttons sit at the start side and the keypad at the end side, so nothing needs scrolling; on a
/// taller window everything is one column.
class EntryLayout extends StatelessWidget {
  const EntryLayout({
    super.key,
    required this.title,
    required this.hint,
    required this.display,
    required this.keypad,
    required this.actions,
    this.error,
  });

  final String title;
  final String hint;
  final String? error;

  /// What the parent has typed so far (dots, or the number of a gate answer), and the question.
  final Widget display;
  final Widget keypad;
  final Widget actions;

  @override
  Widget build(BuildContext context) {
    final Widget heading = Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(title, style: AppText.parent(TokenType.parentH1)),
        const SizedBox(height: 6),
        Text(
          hint,
          style: AppText.parent(TokenType.parentBody, color: TokenColors.inkSoft),
          textAlign: TextAlign.center,
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              error!,
              style: AppText.parent(TokenType.parentSmall, color: TokenColors.domainNumbersDeep),
            ),
          ),
        const SizedBox(height: 12),
        display,
      ],
    );
    return Scaffold(
      backgroundColor: TokenColors.parentBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints box) {
            final bool sideways = box.maxWidth > box.maxHeight * 1.4;
            if (sideways) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[heading, const SizedBox(height: 12), actions],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Center(child: SingleChildScrollView(child: keypad)),
                  ],
                ),
              );
            }
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      heading,
                      const SizedBox(height: 12),
                      keypad,
                      const SizedBox(height: 16),
                      actions,
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
