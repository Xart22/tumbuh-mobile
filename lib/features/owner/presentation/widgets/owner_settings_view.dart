import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';

class OwnerSettingsView extends StatelessWidget {
  final String currentOutlet;
  final List<String> availableOutlets;
  final ValueChanged<String> onOutletChanged;

  const OwnerSettingsView({
    super.key,
    required this.currentOutlet,
    required this.availableOutlets,
    required this.onOutletChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        // 1. Profile Section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: LpColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: LpColors.outlineVariant.withAlpha(120)),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: LpColors.primary,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: LpColors.primaryContainer, width: 2),
                ),
                child: Center(
                  child: Text(
                    'AD',
                    style: LpTypography.mono.copyWith(
                      color: LpColors.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Agus Darmawan',
                      style: LpTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: LpColors.onSurface,
                      ),
                    ),
                    Text(
                      'Owner & Pengelola Utama',
                      style: LpTypography.bodySm.copyWith(
                        color: LpColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: LpColors.primaryContainer.withAlpha(30),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Akses Penuh Seluruh Cabang',
                        style: LpTypography.labelSm.copyWith(
                          color: LpColors.primary,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2. Mode Peralihan Cepat (Fast Switch to POS / KDS)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: LpColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: LpColors.outlineVariant.withAlpha(120)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Peralihan Antar Layar POS',
                style: LpTypography.labelLg.copyWith(
                  fontWeight: FontWeight.bold,
                  color: LpColors.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Beralih ke tampilan terminal kasir atau dapur',
                style: LpTypography.bodySm.copyWith(
                  color: LpColors.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: LpColors.primary,
                        side: const BorderSide(color: LpColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.point_of_sale, size: 18),
                      label: const Text('Mode Kasir'),
                      onPressed: () {
                        context.go('/pos');
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: LpColors.primaryContainer,
                        foregroundColor: LpColors.onPrimaryContainer,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.soup_kitchen, size: 18),
                      label: const Text('Mode KDS'),
                      onPressed: () {
                        context.go('/kds');
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 3. Outlet Switcher Section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: LpColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: LpColors.outlineVariant.withAlpha(120)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kelola Outlet Aktif',
                style: LpTypography.labelLg.copyWith(
                  fontWeight: FontWeight.bold,
                  color: LpColors.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              ...availableOutlets.map((outlet) {
                final isSelected = outlet == currentOutlet;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? LpColors.primaryContainer.withAlpha(30)
                        : LpColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? LpColors.primary : Colors.transparent,
                    ),
                  ),
                  child: ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.store,
                      color: isSelected ? LpColors.primary : LpColors.onSurfaceVariant,
                    ),
                    title: Text(
                      outlet,
                      style: LpTypography.bodySm.copyWith(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? LpColors.primary : LpColors.onSurface,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: LpColors.primary, size: 20)
                        : TextButton(
                            onPressed: () => onOutletChanged(outlet),
                            child: const Text('Pilih'),
                          ),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 4. Security & Biometrics
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: LpColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: LpColors.outlineVariant.withAlpha(120)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Keamanan & Otorisasi',
                style: LpTypography.labelLg.copyWith(
                  fontWeight: FontWeight.bold,
                  color: LpColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.fingerprint, color: LpColors.primary),
                title: Text(
                  'Biometrik Sidik Jari / FaceID',
                  style: LpTypography.bodySm.copyWith(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Otorisasi instan tanpa ketik PIN 6-digit',
                  style: LpTypography.bodySm.copyWith(color: LpColors.outline, fontSize: 10),
                ),
                trailing: Switch(
                  value: true,
                  onChanged: (val) {},
                  activeThumbColor: LpColors.primary,
                ),
              ),
              const Divider(color: LpColors.outlineVariant),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.pin, color: LpColors.primary),
                title: Text(
                  'Ubah PIN Otorisasi 6-Digit',
                  style: LpTypography.bodySm.copyWith(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'PIN terakhir diperbarui 14 hari lalu',
                  style: LpTypography.bodySm.copyWith(color: LpColors.outline, fontSize: 10),
                ),
                trailing: const Icon(Icons.chevron_right, color: LpColors.outline),
                onTap: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 5. Version tag
        Center(
          child: Text(
            'Tumbuh POS v3.4.1 • Mobile Backoffice\nClean Architecture • Drift SQLite Idempotent Sync',
            textAlign: TextAlign.center,
            style: LpTypography.bodySm.copyWith(
              color: LpColors.outline,
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }
}
