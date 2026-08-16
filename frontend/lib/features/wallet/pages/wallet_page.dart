import 'package:flutter/material.dart';

import '../../../shared/widgets/placeholder_page.dart';

/// Dompet placeholder screen (navigation target for the bottom nav).
class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) => const PlaceholderPage(
        title: 'Dompet',
        icon: Icons.account_balance_wallet_rounded,
        message: 'Saldo, poin, dan riwayat transaksi akan tersedia di sini.',
      );
}
