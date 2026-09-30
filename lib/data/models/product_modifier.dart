import 'package:equatable/equatable.dart';

enum ModifierSelectionType { singleRequired, multiOptional }

class ModifierOption extends Equatable {
  final String id;
  final String name;
  final int priceDelta; // in IDR (e.g. 0, 5000, 6000)
  final String? subtitle;
  final bool isDefault;

  const ModifierOption({
    required this.id,
    required this.name,
    this.priceDelta = 0,
    this.subtitle,
    this.isDefault = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'priceDelta': priceDelta,
    'subtitle': subtitle,
    'isDefault': isDefault,
  };

  factory ModifierOption.fromJson(Map<String, dynamic> json) => ModifierOption(
    id: json['id'] as String,
    name: json['name'] as String,
    priceDelta: (json['priceDelta'] as num?)?.toInt() ?? 0,
    subtitle: json['subtitle'] as String?,
    isDefault: json['isDefault'] as bool? ?? false,
  );

  @override
  List<Object?> get props => [id, name, priceDelta, subtitle, isDefault];
}

class ModifierGroup extends Equatable {
  final String id;
  final String name;
  final String? subtitle;
  final ModifierSelectionType selectionType;
  final bool isRequired;
  final int minSelection;
  final int maxSelection;
  final List<ModifierOption> options;

  const ModifierGroup({
    required this.id,
    required this.name,
    this.subtitle,
    required this.selectionType,
    this.isRequired = false,
    this.minSelection = 0,
    this.maxSelection = 1,
    required this.options,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'subtitle': subtitle,
    'selectionType': selectionType.name,
    'isRequired': isRequired,
    'minSelection': minSelection,
    'maxSelection': maxSelection,
    'options': options.map((o) => o.toJson()).toList(),
  };

  factory ModifierGroup.fromJson(Map<String, dynamic> json) => ModifierGroup(
    id: json['id'] as String,
    name: json['name'] as String,
    subtitle: json['subtitle'] as String?,
    selectionType: ModifierSelectionType.values.firstWhere(
      (e) => e.name == json['selectionType'],
      orElse: () => ModifierSelectionType.singleRequired,
    ),
    isRequired: json['isRequired'] as bool? ?? false,
    minSelection: (json['minSelection'] as num?)?.toInt() ?? 0,
    maxSelection: (json['maxSelection'] as num?)?.toInt() ?? 1,
    options: (json['options'] as List<dynamic>)
        .map((e) => ModifierOption.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  @override
  List<Object?> get props => [id, name, subtitle, selectionType, isRequired, minSelection, maxSelection, options];
}
