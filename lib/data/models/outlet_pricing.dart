/// Pricing rules that drive tax / service charge / rounding.
/// Mirrors `parseOutletSettings` + `computeOrderTotals` in tumbuh-be
/// (`src/common/utils/outlet-settings.ts`). Server remains authoritative.
class OutletPricing {
  final bool taxEnabled;
  final double taxRate; // percent, e.g. 11
  final String taxName;
  final bool serviceChargeEnabled;
  final double serviceChargeRate; // percent
  final int roundingBase; // 0 disables rounding

  const OutletPricing({
    required this.taxEnabled,
    required this.taxRate,
    required this.taxName,
    required this.serviceChargeEnabled,
    required this.serviceChargeRate,
    required this.roundingBase,
  });

  /// Backend `DEFAULT_OUTLET_SETTINGS`.
  static const OutletPricing defaultBackend = OutletPricing(
    taxEnabled: true,
    taxRate: 11,
    taxName: 'PPN',
    serviceChargeEnabled: false,
    serviceChargeRate: 0,
    roundingBase: 100,
  );

  /// Used only when no outlet settings have been cached yet (e.g. tests),
  /// preserving the app's previous tax preview behaviour.
  static const OutletPricing legacy = OutletPricing(
    taxEnabled: true,
    taxRate: 10,
    taxName: 'PB1',
    serviceChargeEnabled: false,
    serviceChargeRate: 0,
    roundingBase: 0,
  );

  factory OutletPricing.fromOutletJson(Map<String, dynamic> json) {
    final settings = (json['settings'] as Map?)?.cast<String, dynamic>() ?? {};
    final tax = (settings['tax'] as Map?)?.cast<String, dynamic>() ?? {};
    final service =
        (settings['serviceCharge'] as Map?)?.cast<String, dynamic>() ?? {};
    final rounding = (settings['roundingBase'] as num?)?.toInt();

    return OutletPricing(
      taxEnabled: tax['enabled'] as bool? ?? defaultBackend.taxEnabled,
      taxRate: (tax['rate'] as num?)?.toDouble() ?? defaultBackend.taxRate,
      taxName: tax['name'] as String? ?? defaultBackend.taxName,
      serviceChargeEnabled:
          service['enabled'] as bool? ?? defaultBackend.serviceChargeEnabled,
      serviceChargeRate: (service['rate'] as num?)?.toDouble() ??
          defaultBackend.serviceChargeRate,
      roundingBase: (rounding == null || rounding <= 0)
          ? defaultBackend.roundingBase
          : rounding,
    );
  }

  Map<String, dynamic> toJson() => {
        'taxEnabled': taxEnabled,
        'taxRate': taxRate,
        'taxName': taxName,
        'serviceChargeEnabled': serviceChargeEnabled,
        'serviceChargeRate': serviceChargeRate,
        'roundingBase': roundingBase,
      };

  factory OutletPricing.fromJson(Map<String, dynamic> json) => OutletPricing(
        taxEnabled: json['taxEnabled'] as bool? ?? defaultBackend.taxEnabled,
        taxRate: (json['taxRate'] as num?)?.toDouble() ?? defaultBackend.taxRate,
        taxName: json['taxName'] as String? ?? defaultBackend.taxName,
        serviceChargeEnabled: json['serviceChargeEnabled'] as bool? ??
            defaultBackend.serviceChargeEnabled,
        serviceChargeRate: (json['serviceChargeRate'] as num?)?.toDouble() ??
            defaultBackend.serviceChargeRate,
        roundingBase: (json['roundingBase'] as num?)?.toInt() ??
            defaultBackend.roundingBase,
      );
}
