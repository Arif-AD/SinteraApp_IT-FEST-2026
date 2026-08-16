import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';

final wargaPointsProvider = FutureProvider<int>((ref) async {
  // Read the current auth state once. Fetching profile updates the same auth store,
  // and watching it here causes the provider to re-enter itself repeatedly.
  final user = ref.read(authStorageProvider).value;
  if (user == null) return 0;

  final authService = ref.read(laravelAuthServiceProvider);

  try {
    final response = await authService.getWargaPoints();
    final points = response['points'];

    if (points is int) return points;
    return int.tryParse(points?.toString() ?? '0') ?? 0;
  } catch (_) {
    return 0;
  }
});

final wargaPointTransactionsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = ref.read(authStorageProvider).value;
  if (user == null) return const [];

  final authService = ref.read(laravelAuthServiceProvider);

  try {
    return await authService.getWargaPointTransactions();
  } catch (_) {
    return const [];
  }
});

// Optional local override to reflect recent deductions on the client
final wargaPointsOverrideProvider = StateProvider<int?>((_) => null);

// Ensure consumers see override when set
final effectiveWargaPointsProvider = Provider<int>((ref) {
  final override = ref.watch(wargaPointsOverrideProvider);
  if (override != null) return override;
  // Note: read the async provider synchronously by returning 0 while loading;
  final asyncVal = ref.watch(wargaPointsProvider);
  return asyncVal.maybeWhen(data: (v) => v, orElse: () => 0);
});
