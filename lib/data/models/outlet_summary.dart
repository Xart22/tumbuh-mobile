class OutletSummary {
  final String id;
  final String name;
  final String? address;
  final String? city;
  final String? phone;

  const OutletSummary({
    required this.id,
    required this.name,
    this.address,
    this.city,
    this.phone,
  });

  factory OutletSummary.fromJson(Map<String, dynamic> json) {
    return OutletSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
      city: json['city'] as String?,
      phone: json['phone'] as String?,
    );
  }
}
