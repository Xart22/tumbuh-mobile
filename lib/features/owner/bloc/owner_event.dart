import 'package:equatable/equatable.dart';
import '../data/models/approval_model.dart';

abstract class OwnerEvent extends Equatable {
  const OwnerEvent();

  @override
  List<Object?> get props => [];
}

class OwnerLoadData extends OwnerEvent {
  const OwnerLoadData();
}

class OwnerSelectTab extends OwnerEvent {
  final int tabIndex;

  const OwnerSelectTab(this.tabIndex);

  @override
  List<Object?> get props => [tabIndex];
}

class OwnerSelectOutlet extends OwnerEvent {
  final String outlet;

  const OwnerSelectOutlet(this.outlet);

  @override
  List<Object?> get props => [outlet];
}

class OwnerApproveRequest extends OwnerEvent {
  final String requestId;
  final String pin;

  const OwnerApproveRequest({
    required this.requestId,
    required this.pin,
  });

  @override
  List<Object?> get props => [requestId, pin];
}

class OwnerRejectRequest extends OwnerEvent {
  final String requestId;
  final String reason;

  const OwnerRejectRequest({
    required this.requestId,
    required this.reason,
  });

  @override
  List<Object?> get props => [requestId, reason];
}

class OwnerFilterApprovalStatus extends OwnerEvent {
  final ApprovalStatus status;

  const OwnerFilterApprovalStatus(this.status);

  @override
  List<Object?> get props => [status];
}

class OwnerChangeReportDateRange extends OwnerEvent {
  final String dateRange;

  const OwnerChangeReportDateRange(this.dateRange);

  @override
  List<Object?> get props => [dateRange];
}

class OwnerQuickReorderItem extends OwnerEvent {
  final String itemId;
  final double quantity;

  const OwnerQuickReorderItem({
    required this.itemId,
    required this.quantity,
  });

  @override
  List<Object?> get props => [itemId, quantity];
}
