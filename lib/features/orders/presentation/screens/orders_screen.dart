import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/models/order_record.dart';
import '../../../../data/remote/orders_repository.dart';
import '../../../../shared/formatters/currency_formatter.dart';
import '../../../../shared/formatters/date_formatter.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';

/// Order history with void/cancel/reprint actions. Needs the API to be online;
/// shows an empty state when the repository is unavailable (tests).
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  OrdersRepository? _repository;
  List<OrderRecord> _orders = const [];
  String? _statusFilter;
  bool _loading = true;
  String? _error;

  static const _filters = <String?, String>{
    null: 'Semua',
    'held': 'Parkir',
    'confirmed': 'Berjalan',
    'completed': 'Selesai',
    'voided': 'Void',
  };

  @override
  void initState() {
    super.initState();
    try {
      _repository = context.read<OrdersRepository>();
    } catch (_) {
      _repository = null;
    }
    _load();
  }

  Future<void> _load() async {
    final repo = _repository;
    if (repo == null) {
      setState(() {
        _loading = false;
        _error = 'Riwayat pesanan butuh koneksi backend.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final orders = await repo.fetchOrders(status: _statusFilter);
      setState(() {
        _orders = orders;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1116),
      appBar: AppBar(
        backgroundColor: LpColors.surfacePanel,
        title: const Text('Riwayat Pesanan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
            tooltip: 'Muat ulang',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: const Color(0xFF0E1116),
      child: Row(
        children: _filters.entries.map((entry) {
          final selected = _statusFilter == entry.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(entry.value),
              selected: selected,
              onSelected: (_) {
                setState(() => _statusFilter = entry.key);
                _load();
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: LpColors.primaryLight),
      );
    }
    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: LpColors.textSecondary)),
      );
    }
    if (_orders.isEmpty) {
      return const Center(
        child: Text('Tidak ada pesanan.', style: TextStyle(color: LpColors.textSecondary)),
      );
    }
    return ListView.separated(
      itemCount: _orders.length,
      separatorBuilder: (_, _) => const Divider(height: 1, color: LpColors.borderDark),
      itemBuilder: (context, index) {
        final order = _orders[index];
        return ListTile(
          onTap: () => _showDetail(order),
          title: Text(
            '#${order.orderNumber} • ${order.orderTypeLabel}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '${order.tableNumber ?? '-'} • ${DateFormatter.formatShortDateTime(order.createdAt)} • ${order.status}/${order.paymentStatus}',
            style: const TextStyle(color: LpColors.textMuted),
          ),
          trailing: Text(
            CurrencyFormatter.format(order.total),
            style: LpTypography.dataCurrencySm.copyWith(color: Colors.white),
          ),
        );
      },
    );
  }

  Future<void> _showDetail(OrderRecord summary) async {
    final repo = _repository;
    if (repo == null) return;

    OrderRecord order = summary;
    try {
      order = await repo.fetchOrder(summary.id);
    } catch (_) {
      // fall back to the list row (already has items from findAll)
    }
    if (!mounted) return;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: LpColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Pesanan #${order.orderNumber}',
                      style: LpTypography.headlineSm.copyWith(color: Colors.white),
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(order.total),
                    style: LpTypography.dataCurrencySm.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
            ...order.items.map(
              (item) => ListTile(
                dense: true,
                title: Text('${item.qty}x ${item.productName}', style: const TextStyle(color: Colors.white)),
                subtitle: item.notes != null
                    ? Text(item.notes!, style: const TextStyle(color: LpColors.textMuted))
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(CurrencyFormatter.format(item.unitPrice * item.qty), style: const TextStyle(color: Colors.white70)),
                    IconButton(
                      icon: const Icon(Icons.call_split_rounded, size: 18, color: LpColors.accentAmber),
                      tooltip: 'Split item',
                      onPressed: () => _splitItem(ctx, order.id, item),
                    ),
                    IconButton(
                      icon: const Icon(Icons.block_rounded, size: 18, color: LpColors.critical),
                      tooltip: 'Void item',
                      onPressed: () => _voidItem(ctx, order.id, item.id),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: LpColors.borderDark),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: () => _reprint(order),
                    icon: const Icon(Icons.print_rounded, color: LpColors.primaryLight),
                    label: const Text('Cetak Ulang'),
                  ),
                  if (order.paymentStatus == 'credit')
                    TextButton.icon(
                      onPressed: () => _settleCredit(ctx, order.id),
                      icon: const Icon(Icons.price_check_rounded, color: LpColors.accentAmber),
                      label: const Text('Pelunasan'),
                    ),
                  TextButton.icon(
                    onPressed: () => _mergeOrder(order),
                    icon: const Icon(Icons.merge_type_rounded, color: LpColors.primaryLight),
                    label: const Text('Gabung'),
                  ),
                  TextButton.icon(
                    onPressed: () => _voidOrder(ctx, order.id),
                    icon: const Icon(Icons.delete_forever_rounded, color: LpColors.critical),
                    label: const Text('Void Pesanan'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _voidOrder(BuildContext ctx, String orderId) async {
    final navigator = Navigator.of(ctx);
    final reason = await _askReason(ctx, 'Void Pesanan', 'Alasan void pesanan');
    if (reason == null || reason.isEmpty) return;
    try {
      await _repository!.voidOrder(orderId, reason);
      navigator.pop();
      _load();
    } catch (e) {
      _snack('Gagal void: $e');
    }
  }

  Future<void> _voidItem(BuildContext ctx, String orderId, String itemId) async {
    final navigator = Navigator.of(ctx);
    final reason = await _askReason(ctx, 'Void Item', 'Alasan void item');
    if (reason == null || reason.isEmpty) return;
    try {
      await _repository!.voidOrderItem(orderId, itemId, reason);
      navigator.pop();
      _load();
    } catch (e) {
      _snack('Gagal void item: $e');
    }
  }

  Future<void> _settleCredit(BuildContext ctx, String orderId) async {
    final navigator = Navigator.of(ctx);
    try {
      await _repository!.settleCredit(orderId);
      navigator.pop();
      _load();
      _snackOk('Piutang berhasil dilunasi.');
    } catch (e) {
      _snack('Gagal pelunasan: $e');
    }
  }

  Future<void> _splitItem(
    BuildContext ctx,
    String orderId,
    OrderItemLine item,
  ) async {
    final navigator = Navigator.of(ctx);
    final controller = TextEditingController(text: item.qty.toString());
    final qtyStr = await showDialog<String>(
      context: ctx,
      builder: (dctx) => AlertDialog(
        backgroundColor: LpColors.surfaceCard,
        title: Text('Split ${item.productName}', style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(hintText: 'Qty (maks ${item.qty})'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dctx).pop(), child: const Text('Batal')),
          FilledButton(
            onPressed: () => Navigator.of(dctx).pop(controller.text.trim()),
            child: const Text('Split'),
          ),
        ],
      ),
    );
    final qty = int.tryParse(qtyStr ?? '') ?? 0;
    if (qty <= 0 || qty > item.qty) {
      if (qtyStr != null) _snack('Qty split tidak valid (1..${item.qty}).');
      return;
    }
    try {
      await _repository!.splitOrder(orderId, [(itemId: item.id, qty: qty)]);
      navigator.pop();
      _load();
      _snackOk('Item di-split ke order baru.');
    } catch (e) {
      _snack('Gagal split: $e');
    }
  }

  Future<void> _mergeOrder(OrderRecord order) async {
    final navigator = Navigator.of(context);
    final repo = _repository!;

    List<OrderRecord> targets;
    try {
      final all = await repo.fetchOrders();
      const openStatuses = {'confirmed', 'held', 'in_kitchen', 'ready'};
      targets = all
          .where((o) => o.id != order.id && openStatuses.contains(o.status))
          .toList();
    } catch (e) {
      _snack('Gagal memuat order target: $e');
      return;
    }
    if (!mounted) return;
    if (targets.isEmpty) {
      _snack('Tidak ada order terbuka untuk digabung.');
      return;
    }

    final targetId = await showDialog<String>(
      context: context,
      builder: (dctx) => SimpleDialog(
        backgroundColor: LpColors.surfaceCard,
        title: const Text('Gabung ke Order', style: TextStyle(color: Colors.white)),
        children: targets
            .map((o) => SimpleDialogOption(
                  onPressed: () => Navigator.of(dctx).pop(o.id),
                  child: Text('#${o.orderNumber} • ${o.status}',
                      style: const TextStyle(color: Colors.white)),
                ))
            .toList(),
      ),
    );
    if (targetId == null) return;

    try {
      await repo.mergeOrder(order.id, targetId);
      navigator.pop();
      _load();
      _snackOk('Order digabung.');
    } catch (e) {
      _snack('Gagal gabung: $e');
    }
  }

  Future<String?> _askReason(BuildContext context, String title, String handler) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LpColors.surfaceCard,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(hintText: handler),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Konfirmasi'),
          ),
        ],
      ),
    );
  }

  void _reprint(OrderRecord order) {
    final lines = order.items
        .map((i) => '${i.qty}x ${i.productName}  ${CurrencyFormatter.format(i.unitPrice * i.qty)}')
        .join('\n');
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LpColors.surfaceCard,
        title: Text('Cetak Ulang #${order.orderNumber}', style: const TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Text(
            '$lines\n\nTOTAL  ${CurrencyFormatter.format(order.total)}',
            style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Tutup')),
        ],
      ),
    );
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: LpColors.critical),
    );
  }

  void _snackOk(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: LpColors.primary),
    );
  }
}
