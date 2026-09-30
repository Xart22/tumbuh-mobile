import 'package:flutter/material.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';

class OwnerTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String currentOutlet;
  final List<String> availableOutlets;
  final int pendingApprovalsCount;
  final ValueChanged<String> onOutletSelected;
  final VoidCallback onApprovalsTap;
  final VoidCallback? onNotificationsTap;

  const OwnerTopBar({
    super.key,
    required this.currentOutlet,
    required this.availableOutlets,
    required this.pendingApprovalsCount,
    required this.onOutletSelected,
    required this.onApprovalsTap,
    this.onNotificationsTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(116);

  void _showOutletPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: LpColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: LpColors.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Pilih Cabang Gerai',
                  style: LpTypography.titleMedium.copyWith(
                    color: LpColors.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ganti outlet aktif untuk memantau performa & otorisasi',
                  style: LpTypography.bodySm.copyWith(
                    color: LpColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                ...availableOutlets.map((outlet) {
                  final isSelected = outlet == currentOutlet;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSelected ? LpColors.primaryContainer.withAlpha(50) : LpColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.storefront,
                        color: isSelected ? LpColors.primary : LpColors.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      outlet,
                      style: LpTypography.bodyMd.copyWith(
                        color: isSelected ? LpColors.primary : LpColors.onSurface,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: LpColors.primary, size: 20)
                        : null,
                    onTap: () {
                      Navigator.pop(ctx);
                      onOutletSelected(outlet);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: LpColors.surface,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Row 1: Brand & Actions
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: LpColors.outlineVariant, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: LpColors.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.storefront,
                            color: LpColors.onPrimaryContainer,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Tumbuh Backoffice',
                            style: LpTypography.titleMedium.copyWith(
                              color: LpColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: LpColors.secondaryContainer.withAlpha(40),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'OWNER VIEW',
                      style: LpTypography.labelSm.copyWith(
                        color: LpColors.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined, size: 22),
                        color: LpColors.onSurfaceVariant,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        onPressed: onNotificationsTap ?? () {},
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: LpColors.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Row 2: Outlet Selector Sub-bar
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: LpColors.outlineVariant, width: 0.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Outlet Dropdown Button
                  Flexible(
                    child: InkWell(
                      onTap: () => _showOutletPicker(context),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    currentOutlet,
                                    style: LpTypography.labelLg.copyWith(
                                      color: LpColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.expand_more,
                                  color: LpColors.primary,
                                  size: 18,
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: LpColors.primaryContainer,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'Live POS • Shift 2 (Rama & Dika)',
                                    style: LpTypography.bodySm.copyWith(
                                      color: LpColors.onSurfaceVariant,
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Actions: Approvals Pill & Owner Avatar
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Pending Approvals Quick Pill
                      InkWell(
                        onTap: onApprovalsTap,
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: LpColors.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Icon(
                                Icons.fact_check_outlined,
                                color: LpColors.onSurfaceVariant,
                                size: 18,
                              ),
                            ),
                            if (pendingApprovalsCount > 0)
                              Positioned(
                                top: -2,
                                right: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: LpColors.error,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$pendingApprovalsCount',
                                      style: LpTypography.mono.copyWith(
                                        color: LpColors.onError,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Owner Avatar
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: LpColors.primary,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: LpColors.primaryContainer, width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            'AD',
                            style: LpTypography.mono.copyWith(
                              color: LpColors.onPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
