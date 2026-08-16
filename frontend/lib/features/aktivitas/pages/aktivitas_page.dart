import 'package:flutter/material.dart';

import '../../../shared/widgets/placeholder_page.dart';

/// Aktivitas placeholder screen (navigation target for the bottom nav).
class AktivitasPage extends StatelessWidget {
  const AktivitasPage({super.key});

  @override
  Widget build(BuildContext context) => const PlaceholderPage(
        title: 'Aktivitas',
        icon: Icons.receipt_long_rounded,
        message: 'Riwayat aktivitas dan transaksi kamu akan tampil di sini.',
      );
}
