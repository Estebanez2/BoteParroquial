import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/movement.dart';
import '../../../models/refund_source.dart';
import '../../../models/year_month.dart';
import '../../../repositories/refund_repository.dart';
import '../../movements/providers/movement_providers.dart';
import 'allocation_providers.dart';

final refundRepositoryProvider = Provider((ref) => const RefundRepository());
final refundSourceProvider = Provider.autoDispose
    .family<AsyncValue<RefundSource>, (String, String, String?)>((ref, key) {
      final view = ref.watch(incomeAllocationViewProvider((key.$1, key.$2)));
      return view.whenData(
        (v) => ref
            .read(refundRepositoryProvider)
            .source(
              groupId: key.$1,
              incomeId: key.$2,
              originalId: key.$3,
              settlement: v.settlement,
              movements: ref.watch(movementsProvider(key.$1)).requireValue,
              allocations: ref
                  .watch(
                    allocationsProvider((key.$1, v.movement.input.personId!)),
                  )
                  .requireValue,
            ),
      );
    });
final refundEditorProvider = Provider.autoDispose
    .family<RefundEditor, (String, String, String?)>(
      (ref, key) => RefundEditor(ref, key),
    );

class RefundEditor {
  const RefundEditor(this._ref, this._key);
  final Ref _ref;
  final (String, String, String?) _key;
  MovementInput prepare({
    required Map<YearMonth, int?> selected,
    required int? unallocatedCents,
    required DateTime occurredAt,
    required String description,
  }) => _ref
      .read(refundRepositoryProvider)
      .prepare(
        source: _ref.read(refundSourceProvider(_key)).requireValue,
        selected: selected,
        unallocatedCents: unallocatedCents,
        occurredAt: occurredAt,
        description: description,
      );
}
