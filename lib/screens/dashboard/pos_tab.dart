import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_theme.dart';
import '../../core/models/models.dart';
import '../../core/providers/pos_provider.dart';
import '../../core/providers/session_provider.dart';
import 'checkout_dialog.dart';

class PosTab extends StatefulWidget {
  const PosTab({super.key});

  @override
  State<PosTab> createState() => _PosTabState();
}

class _PosTabState extends State<PosTab> {
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PosProvider>().fetchCategories();
    });
  }

  void _showCartBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: _CartPanel(
              isBottomSheet: true,
              parentContext: context,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosProvider>();
    final categories = pos.categories;
    final selectedCat = _selectedCategoryId == null
        ? (categories.isNotEmpty ? categories.first : null)
        : categories.where((c) => c.id == _selectedCategoryId).firstOrNull;
    final items = selectedCat?.items ?? [];
    final isLargeScreen = MediaQuery.of(context).size.width >= 720;

    return Column(
      children: [
        // Category tabs
        if (categories.isNotEmpty)
          Container(
            color: AppTheme.surface,
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: categories.length,
              itemBuilder: (ctx, i) {
                final cat = categories[i];
                final isSelected =
                    selectedCat?.id == cat.id || (_selectedCategoryId == null && i == 0);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedCategoryId = cat.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primary : AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(cat.name,
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppTheme.textSecondary,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              fontSize: 13,
                            )),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

        // Item grid + cart side by side (tablet layout)
        Expanded(
          child: Row(
            children: [
              // Items grid
              Expanded(
                flex: 3,
                child: pos.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppTheme.primary))
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 180,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: items.length,
                        itemBuilder: (ctx, i) => _ItemCard(item: items[i]),
                      ),
              ),

              // Cart panel
              if (isLargeScreen)
                Container(
                  width: 280,
                  decoration: const BoxDecoration(
                    color: AppTheme.surface,
                    border: Border(left: BorderSide(color: AppTheme.border)),
                  ),
                  child: const _CartPanel(),
                ),
            ],
          ),
        ),

        // Bottom shopping bar (only on mobile when cart is not empty)
        if (!isLargeScreen && pos.cart.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
              border: Border(top: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${pos.cart.fold<int>(0, (sum, item) => sum + item.quantity)} Item',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pos.cartTotalDisplay,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _showCartBottomSheet(context),
                  icon: const Icon(Icons.shopping_cart_outlined, size: 18),
                  label: const Text('Lihat Keranjang'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ItemCard extends StatelessWidget {
  final PosItemModel item;
  const _ItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final pos = context.read<PosProvider>();
    final cartItem = pos.cart.where((c) => c.item.id == item.id).firstOrNull;

    final isOutOfStock = item.stock != null && item.stock! <= 0;

    return Opacity(
      opacity: isOutOfStock ? 0.6 : 1.0,
      child: Card(
        child: InkWell(
          onTap: isOutOfStock ? null : () {
            pos.addToCart(item);
            if (pos.error != null) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(pos.error!), backgroundColor: AppTheme.danger),
              );
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Icon(Icons.inventory_2_outlined,
                          color: AppTheme.primary, size: 32),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textPrimary)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.displayPrice,
                              style: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                          if (item.stock != null)
                            Text(
                              'Stok: ${item.stock}',
                              style: TextStyle(
                                fontSize: 10,
                                color: isOutOfStock ? AppTheme.danger : AppTheme.textSecondary,
                                fontWeight: isOutOfStock ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (cartItem != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('${cartItem.quantity}',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CartPanel extends StatelessWidget {
  final bool isBottomSheet;
  final BuildContext? parentContext;

  const _CartPanel({
    super.key,
    this.isBottomSheet = false,
    this.parentContext,
  });

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosProvider>();
    final cart = pos.cart;

    return Column(
      children: [
        // Cart header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              const Text('Keranjang',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.textPrimary)),
              const Spacer(),
              if (cart.isNotEmpty)
                TextButton(
                  onPressed: pos.clearCart,
                  child: const Text('Hapus Semua',
                      style: TextStyle(color: AppTheme.danger, fontSize: 12)),
                ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Cart items
        Expanded(
          child: cart.isEmpty
              ? const Center(
                  child: Text('Belum ada item',
                      style: TextStyle(color: AppTheme.textMuted)))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: cart.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final c = cart[i];
                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.item.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                        color: AppTheme.textPrimary)),
                                Text(c.displaySubtotal,
                                    style: const TextStyle(
                                        color: AppTheme.primary, fontSize: 12)),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              _QtyButton(
                                icon: Icons.remove,
                                onTap: () => pos.removeFromCart(c.item.id),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text('${c.quantity}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textPrimary)),
                              ),
                              _QtyButton(
                                icon: Icons.add,
                                onTap: () => pos.addToCart(c.item),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),

        // Total & checkout
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                  Text(pos.cartTotalDisplay,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: AppTheme.primary)),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (cart.isEmpty || pos.isLoading)
                      ? null
                      : () {
                          if (isBottomSheet) {
                            Navigator.pop(context); // Close bottom sheet
                          }
                          _checkout(isBottomSheet ? parentContext! : context, pos);
                        },
                  child: pos.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Checkout'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _checkout(BuildContext context, PosProvider pos) async {
    // 1. Fetch active sessions first
    final sessionProv = context.read<SessionProvider>();
    await sessionProv.fetchActiveSessions();
    if (!context.mounted) return;

    // 2. Show the checkout type dialog
    final selection = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PosCheckoutTypeDialog(activeSessions: sessionProv.activeSessions),
    );

    if (selection == null) return;

    final type = selection['type'] as String;
    final sessionId = selection['sessionId'] as String?;

    if (type == 'session' && sessionId != null) {
      // Link to session
      final order = await pos.submitOrder(sessionId: sessionId);
      if (!context.mounted) return;

      if (order != null) {
        // Refresh data menu (stok) setelah transaksi
        pos.fetchCategories();
        
        // Find session unit name
        final targetSession = sessionProv.activeSessions.where((s) => s.id == sessionId).firstOrNull;
        final unitName = targetSession?.unit?.name ?? 'Unit PS';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pesanan F&B berhasil digabungkan ke $unitName!'),
            backgroundColor: AppTheme.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(pos.error ?? 'Gagal memproses pesanan'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } else {
      // Standalone checkout (original flow)
      final order = await pos.submitOrder();
      if (!context.mounted) return;

      if (order != null) {
        // Tampilkan Checkout Dialog untuk konfirmasi pembayaran & buat struk
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => CheckoutDialog(
            orderId: order.id,
            billingAmount: 0,
            posAmount: order.subtotal,
            parentContext: context,
          ),
        );

        // Refresh data menu (stok) setelah transaksi
        pos.fetchCategories();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(pos.error ?? 'Gagal memproses pesanan'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.border),
        ),
        child: Icon(icon, size: 14, color: AppTheme.textSecondary),
      ),
    );
  }
}

class PosCheckoutTypeDialog extends StatefulWidget {
  final List<SessionModel> activeSessions;

  const PosCheckoutTypeDialog({super.key, required this.activeSessions});

  @override
  State<PosCheckoutTypeDialog> createState() => _PosCheckoutTypeDialogState();
}

class _PosCheckoutTypeDialogState extends State<PosCheckoutTypeDialog> {
  String _checkoutType = 'direct'; // 'direct' or 'session'
  String? _selectedSessionId;

  @override
  void initState() {
    super.initState();
    if (widget.activeSessions.isNotEmpty) {
      _selectedSessionId = widget.activeSessions.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shopping_cart_checkout, color: AppTheme.primary),
                const SizedBox(width: 12),
                Text('Metode Checkout POS', style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const Divider(height: 32),

            // Option 1: Direct Payment
            InkWell(
              onTap: () => setState(() => _checkoutType = 'direct'),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _checkoutType == 'direct' ? AppTheme.primary.withOpacity(0.1) : AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _checkoutType == 'direct' ? AppTheme.primary : AppTheme.border,
                    width: _checkoutType == 'direct' ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.payments_outlined, color: AppTheme.primary, size: 28),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Bayar Langsung (Tunai / QRIS)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          const SizedBox(height: 2),
                          Text('Bayar dan buat struk POS terpisah sekarang', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                    Icon(
                      _checkoutType == 'direct' ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      color: _checkoutType == 'direct' ? AppTheme.primary : AppTheme.textMuted,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Option 2: Link to Session
            InkWell(
              onTap: widget.activeSessions.isEmpty ? null : () => setState(() => _checkoutType = 'session'),
              borderRadius: BorderRadius.circular(12),
              child: Opacity(
                opacity: widget.activeSessions.isEmpty ? 0.5 : 1.0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _checkoutType == 'session' ? AppTheme.primary.withOpacity(0.1) : AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _checkoutType == 'session' ? AppTheme.primary : AppTheme.border,
                      width: _checkoutType == 'session' ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.gamepad_outlined, color: AppTheme.primary, size: 28),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Gabung ke Unit PS (Bayar Nanti)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                            const SizedBox(height: 2),
                            Text(
                              widget.activeSessions.isEmpty
                                  ? 'Tidak ada unit PS yang sedang aktif'
                                  : 'Satukan dengan tagihan bermain unit PlayStation',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        _checkoutType == 'session' ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                        color: _checkoutType == 'session' ? AppTheme.primary : AppTheme.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Dropdown selection if Session is selected
            if (_checkoutType == 'session' && widget.activeSessions.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Pilih Unit PS Aktif', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedSessionId,
                    isExpanded: true,
                    dropdownColor: AppTheme.surface,
                    items: widget.activeSessions.map((s) {
                      final name = s.unit?.name ?? 'Unit';
                      final type = s.unit?.type ?? '';
                      final info = s.extendedInfo ?? (s.package?.name ?? 'Bermain');
                      return DropdownMenuItem<String>(
                        value: s.id,
                        child: Text('$name ($type) - $info', style: const TextStyle(fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedSessionId = val),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, {
                    'type': _checkoutType,
                    'sessionId': _checkoutType == 'session' ? _selectedSessionId : null,
                  });
                },
                child: const Text('Konfirmasi'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
