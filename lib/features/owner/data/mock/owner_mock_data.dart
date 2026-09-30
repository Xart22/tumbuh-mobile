import '../models/approval_model.dart';
import '../models/inventory_stock_model.dart';
import '../models/owner_dashboard_model.dart';

class OwnerMockData {
  OwnerMockData._();

  static const OwnerKpiData kpiData = OwnerKpiData(
    todayRevenue: 14850000,
    targetRevenue: 20000000,
    growthVsYesterdayPct: 18.4,
    grossProfit: 9820000,
    grossMarginPct: 66.1,
    transactionCount: 148,
    avgTicket: 100300,
    openBillsCount: 6,
    openBillsValue: 820000,
    cashierDeposit: 3250000,
    cashVariance: 0,
  );

  static const List<HourlySalesPoint> hourlySales = [
    HourlySalesPoint(hour: 11, label: '11', amount: 450000, heightFactor: 0.25),
    HourlySalesPoint(hour: 12, label: '12', amount: 1750000, heightFactor: 0.70),
    HourlySalesPoint(hour: 13, label: '13', amount: 1350000, heightFactor: 0.55),
    HourlySalesPoint(hour: 14, label: '14', amount: 850000, heightFactor: 0.35),
    HourlySalesPoint(hour: 15, label: '15', amount: 1100000, heightFactor: 0.45),
    HourlySalesPoint(hour: 16, label: '16', amount: 1950000, heightFactor: 0.80),
    HourlySalesPoint(hour: 17, label: '17', amount: 2450000, heightFactor: 1.00, isPeak: true),
    HourlySalesPoint(hour: 18, label: '18', amount: 1850000, heightFactor: 0.75),
    HourlySalesPoint(hour: 19, label: '19', amount: 1450000, heightFactor: 0.60),
    HourlySalesPoint(hour: 20, label: '20', amount: 950000, heightFactor: 0.40),
    HourlySalesPoint(hour: 21, label: '21', amount: 650000, heightFactor: 0.25),
  ];

  static const List<TopProductItem> topProducts = [
    TopProductItem(
      id: 'p1',
      name: 'Kopi Susu Aren',
      category: 'Coffee',
      soldCount: 48,
      totalRevenue: 1056000,
      marginPct: 68.0,
    ),
    TopProductItem(
      id: 'p2',
      name: 'Creamy Truffle Fettuccine',
      category: 'Food',
      soldCount: 26,
      totalRevenue: 1508000,
      marginPct: 64.0,
    ),
    TopProductItem(
      id: 'p3',
      name: 'Iced Matcha Latte',
      category: 'Non-Coffee',
      soldCount: 24,
      totalRevenue: 672000,
      marginPct: 65.0,
    ),
    TopProductItem(
      id: 'p4',
      name: 'Almond Butter Croissant',
      category: 'Pastry',
      soldCount: 22,
      totalRevenue: 616000,
      marginPct: 70.0,
    ),
    TopProductItem(
      id: 'p5',
      name: 'Wagyu Beef Burger',
      category: 'Food',
      soldCount: 18,
      totalRevenue: 1044000,
      marginPct: 62.0,
    ),
  ];

  static const List<PaymentMethodShare> paymentShares = [
    PaymentMethodShare(
      method: 'QRIS (Dinamis & Statis)',
      totalAmount: 8613000,
      percentage: 58.0,
      transactionCount: 86,
    ),
    PaymentMethodShare(
      method: 'Tunai (Cash)',
      totalAmount: 4752000,
      percentage: 32.0,
      transactionCount: 48,
    ),
    PaymentMethodShare(
      method: 'Kartu Debit / EDC',
      totalAmount: 1485000,
      percentage: 10.0,
      transactionCount: 14,
    ),
  ];

  static List<ApprovalRequest> getInitialApprovals() {
    final now = DateTime.now();

    return [
      ApprovalRequest(
        id: 'app-01',
        type: ApprovalType.voidOrder,
        title: 'Void Transaksi #TB-240502',
        requestedBy: 'Barista Rama',
        shiftName: 'Shift Pagi',
        ticketNumber: '#TB-240502',
        tableNumber: 'Meja 04',
        amount: 85000,
        requestedItemsSummary: '2x Kopi Susu Aren (Less Sugar, Oat Milk), 1x Croissant Almond',
        reason: 'Tamu pindah ke meja outdoor dan barista salah input varian sirup.',
        requestedAt: now.subtract(const Duration(minutes: 3)),
        status: ApprovalStatus.pending,
      ),
      ApprovalRequest(
        id: 'app-02',
        type: ApprovalType.specialDiscount,
        title: 'Diskon Manual 30% #TB-240506',
        requestedBy: 'Kasir Dika',
        shiftName: 'Shift Pagi',
        ticketNumber: '#TB-240506',
        tableNumber: 'Meja 08',
        amount: 135000,
        requestedItemsSummary: 'Total Bill: Rp 450.000 (Diskon diajukan 30% = -Rp 135.000)',
        reason: 'Keluarga owner berkunjung untuk jamuan makan siang, minta diskon pertemanan.',
        requestedAt: now.subtract(const Duration(minutes: 18)),
        status: ApprovalStatus.pending,
      ),
      ApprovalRequest(
        id: 'app-03',
        type: ApprovalType.purchaseOrder,
        title: 'PO Biji Kopi Arabica Blend',
        requestedBy: 'Manager Dapur',
        shiftName: 'Shift Pagi',
        ticketNumber: '#PO-2605-04',
        amount: 2400000,
        supplierName: 'PT Java Coffee Roastery',
        requestedItemsSummary: '15 kg Biji Kopi Arabica Blend @ Rp 160.000/kg (Term: COD 7 Hari)',
        reason: 'Biji kopi tersisa 0.8 kg (~28 cup), butuh approval owner sebelum pengiriman sore ini.',
        requestedAt: now.subtract(const Duration(minutes: 45)),
        status: ApprovalStatus.pending,
      ),
    ];
  }

  static const List<StockAlertItem> stockAlerts = [
    StockAlertItem(
      id: 'stk-01',
      name: 'Sirup Karamel Monin',
      category: 'Sirup & Saus',
      currentStock: 1.0,
      unit: 'botol',
      minStock: 3.0,
      supplierName: 'PT Sukanda Djaya',
      isCritical: true,
      suggestedReorderQuantity: 6.0,
      estimatedPricePerUnit: 145000,
    ),
    StockAlertItem(
      id: 'stk-02',
      name: 'Biji Kopi Arabica Blend',
      category: 'Bahan Baku',
      currentStock: 0.8,
      unit: 'kg',
      minStock: 5.0,
      supplierName: 'PT Java Coffee Roastery',
      isCritical: true,
      suggestedReorderQuantity: 15.0,
      estimatedPricePerUnit: 160000,
    ),
    StockAlertItem(
      id: 'stk-03',
      name: 'Oatside Oat Milk Barista',
      category: 'Bahan Baku',
      currentStock: 2.0,
      unit: 'liter',
      minStock: 6.0,
      supplierName: 'PT Sumber Pangan Prima',
      isCritical: false,
      suggestedReorderQuantity: 12.0,
      estimatedPricePerUnit: 38000,
    ),
    StockAlertItem(
      id: 'stk-04',
      name: 'Paper Cup Cold 16oz',
      category: 'Kemasan',
      currentStock: 45.0,
      unit: 'pcs',
      minStock: 100.0,
      supplierName: 'CV Kemasan Nusantara',
      isCritical: false,
      suggestedReorderQuantity: 500.0,
      estimatedPricePerUnit: 650,
    ),
  ];

  static const List<String> availableOutlets = [
    'Kopi Kita – Cabang Tebet',
    'Kopi Kita – Cabang Senopati',
    'Kopi Kita – Cabang Bintaro',
  ];
}
