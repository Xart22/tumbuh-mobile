class OutletSummary {
  final String id;
  final String name;
  final String? address;
  final String? city;

  const OutletSummary({
    required this.id,
    required this.name,
    this.address,
    this.city,
  });

  factory OutletSummary.fromJson(Map<String, dynamic> json) {
    return OutletSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
      city: json['city'] as String?,
    );
  }
}
