import 'package:flutter/material.dart';
import '../../../../shared/math/order_math.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';
import '../../data/models/owner_dashboard_model.dart';

class OwnerReportsView extends StatelessWidget {
  final OwnerKpiData kpiData;
  final List<TopProductItem> topProducts;
  final List<PaymentMethodShare> paymentShares;
  final String selectedDateRange;
  final ValueChanged<String> onDateRangeChanged;

  const OwnerReportsView({
    super.key,
    required this.kpiData,
    required this.topProducts,
    required this.paymentShares,
    required this.selectedDateRange,
    required this.onDateRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: [
        // 1. Date Range Filter Pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildDatePill('Hari Ini'),
              const SizedBox(width: 8),
              _buildDatePill('Kemarin'),
              const SizedBox(width: 8),
              _buildDatePill('7 Hari Terakhir'),
              const SizedBox(width: 8),
              _buildDatePill('Bulan Ini'),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 2. Net Sales & P&L Statement Card
        Container(
          decoration: BoxDecoration(
            color: LpColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: LpColors.outlineVariant.withAlpha(120)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(6),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.receipt_long, size: 16, color: LpColors.primary),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'PENJUALAN BERSIH (NET SALES)',
                            style: LpTypography.labelSm.copyWith(
                              color: LpColors.outline,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: LpColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '+${kpiData.growthVsYesterdayPct}%',
                      style: LpTypography.mono.copyWith(
                        color: LpColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: Text(
                      OrderMath.formatCurrency(kpiData.todayRevenue),
                      style: LpTypography.mono.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: LpColors.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${kpiData.transactionCount} Transaksi',
                    style: LpTypography.mono.copyWith(
                      color: LpColors.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, color: LpColors.outlineVariant),

              // P&L Breakdown
              _buildPlRow(
                title: 'HPP Bahan Baku (Food Cost 33.9%)',
                badgeText: 'Margin Sehat',
                badgeColor: Colors.green.shade700,
                badgeBg: Colors.green.shade50,
                amountText: '-Rp 5.030.000',
                isNegative: true,
              ),
              const SizedBox(height: 10),
              _buildPlRow(
                title: 'Laba Kotor Operasional (Gross Profit 66.1%)',
                amountText: OrderMath.formatCurrency(kpiData.grossProfit),
                isHighlight: true,
              ),
              const SizedBox(height: 10),
              _buildPlRow(
                title: 'Pajak Restoran (PB1 10% Terkumpul)',
                amountText: '+Rp 1.485.000',
              ),
              const SizedBox(height: 10),
              _buildPlRow(
                title: 'Biaya Operasional / Petty Cash',
                subtitle: 'Pembelian Es Batu & Gas LPG',
                amountText: '-Rp 350.000',
                isNegative: true,
              ),
              const SizedBox(height: 14),

              // Net Cash Flow Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: LpColors.primaryContainer.withAlpha(40),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: LpColors.primaryContainer.withAlpha(80)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: LpColors.primaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet,
                              color: LpColors.onPrimaryContainer,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Uang Masuk Bersih',
                                  style: LpTypography.bodySm.copyWith(
                                    color: LpColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '(Net Cash Flow Hari Ini)',
                                  style: LpTypography.bodySm.copyWith(
                                    color: LpColors.outline,
                                    fontSize: 10,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Rp 15.985.000',
                      style: LpTypography.mono.copyWith(
                        color: LpColors.primary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 3. Payment Method Share
        Container(
          decoration: BoxDecoration(
            color: LpColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: LpColors.outlineVariant.withAlpha(120)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Breakdown Metode Pembayaran',
                style: LpTypography.labelLg.copyWith(
                  fontWeight: FontWeight.bold,
                  color: LpColors.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              ...paymentShares.map((ps) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              ps.method,
                              style: LpTypography.bodySm.copyWith(
                                fontWeight: FontWeight.w600,
                                color: LpColors.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                OrderMath.formatCurrency(ps.totalAmount),
                                style: LpTypography.mono.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: LpColors.onSurface,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '(${ps.percentage.toInt()}%)',
                                style: LpTypography.mono.copyWith(
                                  color: LpColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ps.percentage / 100,
                          minHeight: 6,
                          backgroundColor: LpColors.surfaceContainerHigh,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            ps.method.contains('QRIS')
                                ? LpColors.primary
                                : ps.method.contains('Tunai')
                                    ? Colors.amber.shade700
                                    : Colors.blue.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 4. Top 5 Produk Terlaris
        Container(
          decoration: BoxDecoration(
            color: LpColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: LpColors.outlineVariant.withAlpha(120)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Top 5 Produk Terlaris',
                style: LpTypography.labelLg.copyWith(
                  fontWeight: FontWeight.bold,
                  color: LpColors.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              ...topProducts.asMap().entries.map((entry) {
                final index = entry.key;
                final prod = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: index == 0
                              ? LpColors.primaryContainer
                              : LpColors.surfaceContainerHigh,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: LpTypography.mono.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: index == 0
                                  ? LpColors.onPrimaryContainer
                                  : LpColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              prod.name,
                              style: LpTypography.bodySm.copyWith(
                                fontWeight: FontWeight.bold,
                                color: LpColors.onSurface,
                              ),
                            ),
                            Text(
                              '${prod.soldCount} terjual • Margin ${prod.marginPct.toInt()}%',
                              style: LpTypography.bodySm.copyWith(
                                color: LpColors.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        OrderMath.formatCurrency(prod.totalRevenue),
                        style: LpTypography.mono.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: LpColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 5. Shift Audit Summary
        Container(
          decoration: BoxDecoration(
            color: LpColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: LpColors.outlineVariant.withAlpha(120)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Audit Shift Hari Ini',
                style: LpTypography.labelLg.copyWith(
                  fontWeight: FontWeight.bold,
                  color: LpColors.onSurface,
                ),
              ),
              const SizedBox(height: 12),

              // Shift 1
              _buildShiftCard(
                shiftTitle: 'Shift 1 (Pagi)',
                cashierName: 'Rama',
                timeRange: '07:00 - 15:00',
                modalAwal: 'Rp 200.000',
                totalCash: 'Rp 1.850.000',
                status: 'Selesai • Selisih Rp 0 (Tepat)',
                isClosed: true,
              ),
              const SizedBox(height: 10),

              // Shift 2
              _buildShiftCard(
                shiftTitle: 'Shift 2 (Sore - Sedang Berjalan)',
                cashierName: 'Dika',
                timeRange: '15:00 - 23:00',
                modalAwal: 'Rp 200.000',
                totalCash: 'Rp 1.400.000',
                status: 'Live Aktif',
                isClosed: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDatePill(String label) {
    final isSelected = selectedDateRange == label;
    return InkWell(
      onTap: () => onDateRangeChanged(label),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? LpColors.primary : LpColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? LpColors.primary : LpColors.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: LpTypography.labelSm.copyWith(
            color: isSelected ? LpColors.onPrimary : LpColors.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildPlRow({
    required String title,
    String? subtitle,
    String? badgeText,
    Color? badgeColor,
    Color? badgeBg,
    required String amountText,
    bool isNegative = false,
    bool isHighlight = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: LpTypography.bodySm.copyWith(
                        color: isHighlight ? LpColors.onSurface : LpColors.onSurfaceVariant,
                        fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  if (badgeText != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: badgeBg ?? Colors.green.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badgeText,
                        style: LpTypography.labelSm.copyWith(
                          fontSize: 8,
                          color: badgeColor ?? Colors.green.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: LpTypography.bodySm.copyWith(
                    color: LpColors.outline,
                    fontSize: 9,
                  ),
                ),
            ],
          ),
        ),
        Text(
          amountText,
          style: LpTypography.mono.copyWith(
            color: isNegative
                ? LpColors.error
                : isHighlight
                    ? LpColors.primary
                    : LpColors.onSurface,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildShiftCard({
    required String shiftTitle,
    required String cashierName,
    required String timeRange,
    required String modalAwal,
    required String totalCash,
    required String status,
    required bool isClosed,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LpColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LpColors.outlineVariant.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                shiftTitle,
                style: LpTypography.bodySm.copyWith(
                  fontWeight: FontWeight.bold,
                  color: LpColors.onSurface,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isClosed ? Colors.green.shade50 : LpColors.primaryContainer.withAlpha(30),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status,
                  style: LpTypography.labelSm.copyWith(
                    color: isClosed ? Colors.green.shade800 : LpColors.primary,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Kasir: $cashierName • $timeRange',
            style: LpTypography.bodySm.copyWith(
              color: LpColors.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Modal Awal: $modalAwal',
                style: LpTypography.mono.copyWith(fontSize: 10, color: LpColors.outline),
              ),
              Text(
                'Tunai Kasir: $totalCash',
                style: LpTypography.mono.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: LpColors.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
