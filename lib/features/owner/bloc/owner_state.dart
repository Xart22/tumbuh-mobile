import 'package:equatable/equatable.dart';
import '../data/mock/owner_mock_data.dart';
import '../data/models/approval_model.dart';
import '../data/models/inventory_stock_model.dart';
import '../data/models/owner_dashboard_model.dart';

class OwnerState extends Equatable {
  final int currentTabIndex;
  final String selectedOutlet;
  final OwnerKpiData kpiData;
  final List<HourlySalesPoint> hourlySales;
  final List<TopProductItem> topProducts;
  final List<PaymentMethodShare> paymentShares;
  final List<ApprovalRequest> approvals;
  final List<StockAlertItem> stockAlerts;
  final List<String> availableOutlets;
  final ApprovalStatus approvalFilter;
  final String reportDateRange;
  final String? lastDecisionMessage;
  final bool isLoading;

  const OwnerState({
    this.currentTabIndex = 0,
    this.selectedOutlet = 'Kopi Kita – Cabang Tebet',
    this.kpiData = OwnerMockData.kpiData,
    this.hourlySales = OwnerMockData.hourlySales,
    this.topProducts = OwnerMockData.topProducts,
    this.paymentShares = OwnerMockData.paymentShares,
    this.approvals = const [],
    this.stockAlerts = OwnerMockData.stockAlerts,
    this.availableOutlets = OwnerMockData.availableOutlets,
    this.approvalFilter = ApprovalStatus.pending,
    this.reportDateRange = 'Hari ini',
    this.lastDecisionMessage,
    this.isLoading = false,
  });

  int get pendingApprovalsCount =>
      approvals.where((a) => a.status == ApprovalStatus.pending).length;

  int get approvedCount =>
      approvals.where((a) => a.status == ApprovalStatus.approved).length;

  int get rejectedCount =>
      approvals.where((a) => a.status == ApprovalStatus.rejected).length;

  List<ApprovalRequest> get filteredApprovals =>
      approvals.where((a) => a.status == approvalFilter).toList();

  int get criticalStockCount =>
      stockAlerts.where((s) => s.isCritical).length;

  OwnerState copyWith({
    int? currentTabIndex,
    String? selectedOutlet,
    OwnerKpiData? kpiData,
    List<HourlySalesPoint>? hourlySales,
    List<TopProductItem>? topProducts,
    List<PaymentMethodShare>? paymentShares,
    List<ApprovalRequest>? approvals,
    List<StockAlertItem>? stockAlerts,
    List<String>? availableOutlets,
    ApprovalStatus? approvalFilter,
    String? reportDateRange,
    String? lastDecisionMessage,
    bool? isLoading,
  }) {
    return OwnerState(
      currentTabIndex: currentTabIndex ?? this.currentTabIndex,
      selectedOutlet: selectedOutlet ?? this.selectedOutlet,
      kpiData: kpiData ?? this.kpiData,
      hourlySales: hourlySales ?? this.hourlySales,
      topProducts: topProducts ?? this.topProducts,
      paymentShares: paymentShares ?? this.paymentShares,
      approvals: approvals ?? this.approvals,
      stockAlerts: stockAlerts ?? this.stockAlerts,
      availableOutlets: availableOutlets ?? this.availableOutlets,
      approvalFilter: approvalFilter ?? this.approvalFilter,
      reportDateRange: reportDateRange ?? this.reportDateRange,
      lastDecisionMessage: lastDecisionMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
        currentTabIndex,
        selectedOutlet,
        kpiData,
        hourlySales,
        topProducts,
        paymentShares,
        approvals,
        stockAlerts,
        availableOutlets,
        approvalFilter,
        reportDateRange,
        lastDecisionMessage,
        isLoading,
      ];
}
