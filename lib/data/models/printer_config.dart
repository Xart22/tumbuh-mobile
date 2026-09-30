import 'package:equatable/equatable.dart';

enum PrinterPaperWidth {
  mm58(32, '58 mm (Kompak/Mobile)'),
  mm80(48, '80 mm (Standar Resto)');

  final int columns;
  final String label;
  const PrinterPaperWidth(this.columns, this.label);
}

enum PrinterConnectionType {
  bluetooth('Bluetooth BLE'),
  network('Network LAN / Ethernet'),
  usb('USB Direct');

  final String label;
  const PrinterConnectionType(this.label);
}

enum PrinterRole {
  cashier('Struk Kasir Pelanggan Utama'),
  kitchen('Tiket Pesanan Dapur & Bar');

  final String label;
  const PrinterRole(this.label);
}

class PrinterDeviceConfig extends Equatable {
  final String id;
  final String name;
  final PrinterRole role;
  final PrinterConnectionType connectionType;
  final String connectionAddress; // MAC address or IP address:port
  final PrinterPaperWidth paperWidth;
  final bool autoPrintOnPayment;
  final bool autoCut;
  final bool kickCashDrawer;
  final bool printHeaderLogo;
  final bool printFooterQr;
  final bool isConnected;
  final int batteryPercent;

  const PrinterDeviceConfig({
    required this.id,
    required this.name,
    required this.role,
    required this.connectionType,
    required this.connectionAddress,
    this.paperWidth = PrinterPaperWidth.mm80,
    this.autoPrintOnPayment = true,
    this.autoCut = true,
    this.kickCashDrawer = true,
    this.printHeaderLogo = true,
    this.printFooterQr = true,
    this.isConnected = true,
    this.batteryPercent = 95,
  });

  PrinterDeviceConfig copyWith({
    String? id,
    String? name,
    PrinterRole? role,
    PrinterConnectionType? connectionType,
    String? connectionAddress,
    PrinterPaperWidth? paperWidth,
    bool? autoPrintOnPayment,
    bool? autoCut,
    bool? kickCashDrawer,
    bool? printHeaderLogo,
    bool? printFooterQr,
    bool? isConnected,
    int? batteryPercent,
  }) {
    return PrinterDeviceConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      connectionType: connectionType ?? this.connectionType,
      connectionAddress: connectionAddress ?? this.connectionAddress,
      paperWidth: paperWidth ?? this.paperWidth,
      autoPrintOnPayment: autoPrintOnPayment ?? this.autoPrintOnPayment,
      autoCut: autoCut ?? this.autoCut,
      kickCashDrawer: kickCashDrawer ?? this.kickCashDrawer,
      printHeaderLogo: printHeaderLogo ?? this.printHeaderLogo,
      printFooterQr: printFooterQr ?? this.printFooterQr,
      isConnected: isConnected ?? this.isConnected,
      batteryPercent: batteryPercent ?? this.batteryPercent,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'role': role.name,
    'connectionType': connectionType.name,
    'connectionAddress': connectionAddress,
    'paperWidth': paperWidth.columns,
    'autoPrintOnPayment': autoPrintOnPayment,
    'autoCut': autoCut,
    'kickCashDrawer': kickCashDrawer,
    'printHeaderLogo': printHeaderLogo,
    'printFooterQr': printFooterQr,
    'isConnected': isConnected,
    'batteryPercent': batteryPercent,
  };

  factory PrinterDeviceConfig.fromJson(Map<String, dynamic> json) => PrinterDeviceConfig(
    id: json['id'] as String,
    name: json['name'] as String,
    role: PrinterRole.values.firstWhere(
      (r) => r.name == json['role'],
      orElse: () => PrinterRole.cashier,
    ),
    connectionType: PrinterConnectionType.values.firstWhere(
      (c) => c.name == json['connectionType'],
      orElse: () => PrinterConnectionType.bluetooth,
    ),
    connectionAddress: json['connectionAddress'] as String,
    paperWidth: (json['paperWidth'] as num?)?.toInt() == 32
        ? PrinterPaperWidth.mm58
        : PrinterPaperWidth.mm80,
    autoPrintOnPayment: json['autoPrintOnPayment'] as bool? ?? true,
    autoCut: json['autoCut'] as bool? ?? true,
    kickCashDrawer: json['kickCashDrawer'] as bool? ?? true,
    printHeaderLogo: json['printHeaderLogo'] as bool? ?? true,
    printFooterQr: json['printFooterQr'] as bool? ?? true,
    isConnected: json['isConnected'] as bool? ?? true,
    batteryPercent: (json['batteryPercent'] as num?)?.toInt() ?? 95,
  );

  @override
  List<Object?> get props => [
    id,
    name,
    role,
    connectionType,
    connectionAddress,
    paperWidth,
    autoPrintOnPayment,
    autoCut,
    kickCashDrawer,
    printHeaderLogo,
    printFooterQr,
    isConnected,
    batteryPercent,
  ];
}
