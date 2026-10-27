import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/state.dart';
import '../app/tutor_log_provider.dart';
import '../data/app_database.dart';
import '../design/app_text.dart';
import '../design/components.dart';
import '../design/tokens.g.dart';
import '../strings/he.dart';

/// What the AI helper said to the family's children in the last 30 days, newest first, with the child it was said to.
/// Every sentence here passed the checks before a child heard it; a line the checks refused is not here as text, only as
/// "the usual message was heard".
class TutorLogScreen extends ConsumerWidget {
  const TutorLogScreen({super.key, required this.onClose});

  final VoidCallback onClose;

  String _when(DateTime t) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(t.day)}.${two(t.month)} ${two(t.hour)}:${two(t.minute)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<TutorLogLine>?> log = ref.watch(tutorLogProvider);
    final Map<String, String> names = <String, String>{
      for (final Profile p in ref.watch(appStateProvider).value?.profiles ?? const <Profile>[]) p.id: p.name,
    };
    return Scaffold(
      backgroundColor: TokenColors.parentBg,
      appBar: AppBar(
        backgroundColor: TokenColors.night,
        foregroundColor: Colors.white,
        title: Text(He.tutorLogOpen.text, style: AppText.parent(TokenType.parentH2, color: Colors.white)),
        leading: IconButton(icon: const Icon(Icons.arrow_forward_rounded), onPressed: onClose),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(He.tutorLogTitle.text, style: AppText.parent(TokenType.parentH2)),
            const SizedBox(height: 6),
            Text(He.tutorLogHelp.text, style: AppText.parent(TokenType.parentSmall)),
            const SizedBox(height: 12),
            log.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object e, StackTrace s) =>
                  Text(He.tutorLogOffline.text, style: AppText.parent(TokenType.parentBody)),
              data: (List<TutorLogLine>? lines) {
                if (lines == null) {
                  return Text(
                    He.tutorLogOffline.text,
                    key: const Key('log-offline'),
                    style: AppText.parent(TokenType.parentBody),
                  );
                }
                if (lines.isEmpty) {
                  return Text(
                    He.tutorLogEmpty.text,
                    key: const Key('log-empty'),
                    style: AppText.parent(TokenType.parentBody),
                  );
                }
                return Column(
                  children: <Widget>[
                    for (final TutorLogLine l in lines)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: TokenColors.paper,
                          borderRadius: BorderRadius.circular(TokenRadius.md),
                          border: Border.all(color: TokenColors.hairline, width: TokenBorder.thin),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Text(names[l.childId] ?? '', style: AppText.parent(TokenType.parentSmall)),
                                const Spacer(),
                                Text(
                                  _when(l.at),
                                  style: AppText.parent(TokenType.parentSmall, color: TokenColors.inkSoft),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l.spoken ? l.line! : He.tutorLogRule.text,
                              style: AppText.parent(
                                TokenType.parentBody,
                                color: l.spoken ? TokenColors.ink : TokenColors.inkSoft,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            ParentButton(label: He.pinOk.text, onPressed: onClose),
          ],
        ),
      ),
    );
  }
}
