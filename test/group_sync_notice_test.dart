import 'dart:async';
import 'package:bote_parroquial/design_system/design_system.dart';
import 'package:bote_parroquial/features/groups/presentation/group_sync_notice.dart';
import 'package:bote_parroquial/features/groups/providers/group_sync_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Un aviso solo aparece si la falta de confirmación persiste', (
    tester,
  ) async {
    final confirmations = StreamController<bool>.broadcast();
    addTearDown(confirmations.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupServerConfirmedProvider(
            'demo',
          ).overrideWith((ref) => confirmations.stream),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(body: GroupSyncNotice(groupId: 'demo')),
        ),
      ),
    );
    expect(find.text('Actualización pendiente'), findsNothing);
    confirmations.add(false);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 100));
    confirmations.add(true);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Actualización pendiente'), findsNothing);
    confirmations.add(false);
    await tester.pumpAndSettle();
    await tester.pump(AppMotion.statusNoticeDelay);
    expect(find.text('Actualización pendiente'), findsOneWidget);
    confirmations.add(true);
    await tester.pumpAndSettle();
    expect(find.text('Actualización pendiente'), findsNothing);
    confirmations.add(false);
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
  });
}
