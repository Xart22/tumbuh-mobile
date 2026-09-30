import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/remote/owner_repository.dart';
import '../data/mock/owner_mock_data.dart';
import '../data/models/approval_model.dart';
import 'owner_event.dart';
import 'owner_state.dart';

class OwnerBloc extends Bloc<OwnerEvent, OwnerState> {
  final OwnerRepository? _ownerRepository;

  OwnerBloc({OwnerRepository? ownerRepository})
      : _ownerRepository = ownerRepository,
        super(const OwnerState()) {
    on<OwnerLoadData>(_onLoadData);
    on<OwnerSelectTab>(_onSelectTab);
    on<OwnerSelectOutlet>(_onSelectOutlet);
    on<OwnerApproveRequest>(_onApproveRequest);
    on<OwnerRejectRequest>(_onRejectRequest);
    on<OwnerFilterApprovalStatus>(_onFilterApprovalStatus);
    on<OwnerChangeReportDateRange>(_onChangeReportDateRange);
    on<OwnerQuickReorderItem>(_onQuickReorderItem);

    // Initial load
    add(const OwnerLoadData());
  }

  Future<void> _onLoadData(OwnerLoadData event, Emitter<OwnerState> emit) async {
    final repo = _ownerRepository;
    if (repo != null) {
      try {
        final snapshot = await repo.fetchDashboard();
        emit(state.copyWith(
          isLoading: false,
          kpiData: snapshot.kpi,
          hourlySales: snapshot.hourlySales,
          topProducts: snapshot.topProducts,
          paymentShares: snapshot.paymentShares,
          approvals: OwnerMockData.getInitialApprovals(),
          stockAlerts: OwnerMockData.stockAlerts,
          availableOutlets: OwnerMockData.availableOutlets,
        ));
        return;
      } catch (_) {
        // Fall through to mock data so the dashboard still renders offline.
      }
    }

    emit(state.copyWith(
      isLoading: false,
      kpiData: OwnerMockData.kpiData,
      hourlySales: OwnerMockData.hourlySales,
      topProducts: OwnerMockData.topProducts,
      paymentShares: OwnerMockData.paymentShares,
      approvals: OwnerMockData.getInitialApprovals(),
      stockAlerts: OwnerMockData.stockAlerts,
      availableOutlets: OwnerMockData.availableOutlets,
    ));
  }

  void _onSelectTab(OwnerSelectTab event, Emitter<OwnerState> emit) {
    emit(state.copyWith(currentTabIndex: event.tabIndex));
  }

  void _onSelectOutlet(OwnerSelectOutlet event, Emitter<OwnerState> emit) {
    emit(state.copyWith(selectedOutlet: event.outlet));
  }

  void _onApproveRequest(OwnerApproveRequest event, Emitter<OwnerState> emit) {
    final updatedApprovals = state.approvals.map((req) {
      if (req.id == event.requestId) {
        return req.copyWith(
          status: ApprovalStatus.approved,
          decisionAt: DateTime.now(),
          decisionNotes: 'Disetujui via PIN Otorisasi Remote ($event.pin)',
        );
      }
      return req;
    }).toList();

    final approvedReq = state.approvals.firstWhere(
      (a) => a.id == event.requestId,
      orElse: () => state.approvals.first,
    );

    emit(state.copyWith(
      approvals: updatedApprovals,
      lastDecisionMessage: '${approvedReq.title} berhasil disetujui.',
    ));
  }

  void _onRejectRequest(OwnerRejectRequest event, Emitter<OwnerState> emit) {
    final updatedApprovals = state.approvals.map((req) {
      if (req.id == event.requestId) {
        return req.copyWith(
          status: ApprovalStatus.rejected,
          decisionAt: DateTime.now(),
          decisionNotes: event.reason,
        );
      }
      return req;
    }).toList();

    final rejectedReq = state.approvals.firstWhere(
      (a) => a.id == event.requestId,
      orElse: () => state.approvals.first,
    );

    emit(state.copyWith(
      approvals: updatedApprovals,
      lastDecisionMessage: '${rejectedReq.title} telah ditolak: ${event.reason}',
    ));
  }

  void _onFilterApprovalStatus(OwnerFilterApprovalStatus event, Emitter<OwnerState> emit) {
    emit(state.copyWith(approvalFilter: event.status));
  }

  void _onChangeReportDateRange(OwnerChangeReportDateRange event, Emitter<OwnerState> emit) {
    emit(state.copyWith(reportDateRange: event.dateRange));
  }

  void _onQuickReorderItem(OwnerQuickReorderItem event, Emitter<OwnerState> emit) {
    final item = state.stockAlerts.firstWhere(
      (s) => s.id == event.itemId,
      orElse: () => state.stockAlerts.first,
    );

    emit(state.copyWith(
      lastDecisionMessage: 'PO Cepat ${item.name} (${event.quantity} ${item.unit}) telah diteruskan ke ${item.supplierName}.',
    ));
  }
}
