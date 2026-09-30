import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tumbuh_mobile/data/models/printer_config.dart';
import 'package:tumbuh_mobile/features/pos/bloc/pos_bloc.dart';
import 'package:tumbuh_mobile/features/pos/bloc/pos_event.dart';
import 'package:tumbuh_mobile/shared/theme/app_colors.dart';
import 'package:tumbuh_mobile/shared/theme/app_typography.dart';



class PrinterManagementScreen extends StatefulWidget {
  const PrinterManagementScreen({super.key});

  @override
  State<PrinterManagementScreen> createState() => _PrinterManagementScreenState();
}

class _PrinterManagementScreenState extends State<PrinterManagementScreen> {
  late PrinterDeviceConfig _config;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final stateConfig = context.read<PosBloc>().state.printerConfig;
      _config = stateConfig;
      _isInitialized = true;
    }
  }

  void _saveConfig() {
    context.read<PosBloc>().add(PosUpdatePrinterConfig(_config));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Konfigurasi printer berhasil disimpan!'),
        backgroundColor: LpColors.primaryGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LpColors.surfaceDark,
      body: Column(
        children: [
          // Top Header
          _buildHeader(),
          // Main Body: 55% / 45% Split
          Expanded(
            child: Row(
              children: [
                // Left Panel (55%): Device list & Discovery
                Expanded(
                  flex: 55,
                  child: _buildLeftPanel(),
                ),
                // Right Panel (45%): Config & Simulation Receipt
                Expanded(
                  flex: 45,
                  child: _buildRightPanel(),
                ),
              ],
            ),
          ),
          // Diagnostic Footer
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: LpColors.surfacePanel,
        border: Border(bottom: BorderSide(color: LpColors.borderDark)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Kasir POS (Esc)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: LpColors.borderDark),
                ),
              ),
              const SizedBox(width: 16),
              Container(width: 1, height: 28, color: LpColors.borderDark),
              const SizedBox(width: 16),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: LpColors.primaryGreen.withAlpha(50),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: LpColors.primaryGreen.withAlpha(100)),
                ),
                child: const Icon(Icons.print, size: 20, color: LpColors.primaryLight),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Text(
                        'Manajemen Printer Thermal & Hardware POS',
                        style: LpTypography.bodyMd.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF064E3B),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'ANDROID STATION #01',
                          style: LpTypography.labelSm.copyWith(color: LpColors.primaryLight, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Konfigurasi printer kasir, tiket dapur/bar, Bluetooth BLE & LAN Network',
                    style: LpTypography.bodySm.copyWith(color: LpColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          // Badges
          Row(
            children: [
              // Bluetooth badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A).withAlpha(120),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF3B82F6).withAlpha(100)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bluetooth, size: 16, color: Color(0xFF60A5FA)),
                    const SizedBox(width: 4),
                    Text('Bluetooth ON (BLE 5.2)', style: LpTypography.labelSm.copyWith(color: const Color(0xFF93C5FD), fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // LAN badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF064E3B).withAlpha(120),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: LpColors.primaryGreen.withAlpha(100)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lan, size: 16, color: LpColors.primaryLight),
                    const SizedBox(width: 4),
                    Text('2 Printer Terhubung', style: LpTypography.labelSm.copyWith(color: LpColors.primaryLight, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeftPanel() {
    return Container(
      decoration: const BoxDecoration(
        color: LpColors.surfaceDark,
        border: Border(right: BorderSide(color: LpColors.borderDark)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PRINTER TERKONFIGURASI & AKTIF (2 PERANGKAT)', style: LpTypography.labelSm.copyWith(color: LpColors.textMuted, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            // Card 1: Epson TM-T82X
            _buildActivePrinterCard(),
            const SizedBox(height: 16),
            // Card 2: Xprinter Kitchen
            _buildKitchenPrinterCard(),
            const SizedBox(height: 24),
            // Discovery Section
            Text('PINDAI & DETEKSI HARDWARE SEKITAR', style: LpTypography.labelSm.copyWith(color: LpColors.textMuted, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildDiscoveryBanner(),
            const SizedBox(height: 12),
            _buildDetectedDevices(),
          ],
        ),
      ),
    );
  }

  Widget _buildActivePrinterCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LpColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LpColors.primaryGreen, width: 2),
        boxShadow: [
          BoxShadow(
            color: LpColors.primaryGreen.withAlpha(40),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: LpColors.surfacePanel,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: LpColors.borderDark),
                    ),
                    child: const Icon(Icons.receipt_long, color: LpColors.primaryLight, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Epson TM-T82X (Thermal 80mm)', style: LpTypography.bodyMd.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF064E3B),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: LpColors.primaryGreen),
                            ),
                            child: Text(
                              'Struk Kasir Utama',
                              style: LpTypography.labelSm.copyWith(color: LpColors.primaryLight, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bluetooth BLE (MAC: 68:C6:3A:88:01) • Baterai 95% • Buffer 4KB',
                        style: LpTypography.bodySm.copyWith(color: LpColors.textMuted, fontSize: 11),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(width: 6, height: 6, decoration: const BoxDecoration(color: LpColors.primaryLight, shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          Text('Terhubung & Siap Cetak (Feed Normal)', style: LpTypography.labelSm.copyWith(color: LpColors.primaryLight, fontWeight: FontWeight.bold)),
                          Text(' • Latency: 14ms', style: LpTypography.labelSm.copyWith(color: LpColors.textMuted)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const Divider(color: LpColors.borderDark, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Lebar: 80mm Standar • Drawer Kick: ON', style: LpTypography.bodySm.copyWith(color: LpColors.textMuted, fontSize: 11)),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Test print struk berhasil dikirim ke printer kasir!'), backgroundColor: LpColors.primaryGreen),
                  );
                },
                icon: const Icon(Icons.print, size: 16),
                label: const Text('Test Print Struk (F7)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: LpColors.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKitchenPrinterCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LpColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LpColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: LpColors.surfacePanel,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: LpColors.borderDark),
                ),
                child: const Icon(Icons.restaurant, color: LpColors.accentAmber, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Xprinter XP-Q800 (Thermal 80mm LAN)', style: LpTypography.bodyMd.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF451A03),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFD97706)),
                          ),
                          child: Text(
                            'Tiket Dapur & Bar',
                            style: LpTypography.labelSm.copyWith(color: const Color(0xFFFCD34D), fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Network LAN / IP Ethernet (192.168.1.150:9100) • Wi-Fi Dapur',
                      style: LpTypography.bodySm.copyWith(color: LpColors.textMuted, fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(width: 6, height: 6, decoration: const BoxDecoration(color: LpColors.primaryLight, shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        Text('Online di Jaringan Wi-Fi Dapur', style: LpTypography.labelSm.copyWith(color: LpColors.primaryLight, fontWeight: FontWeight.bold)),
                        Text(' • Ping: 3ms', style: LpTypography.labelSm.copyWith(color: LpColors.textMuted)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: LpColors.borderDark, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Target Item: Coffee Bar + Hot Kitchen + Pastry', style: LpTypography.bodySm.copyWith(color: LpColors.textMuted, fontSize: 11)),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Test print tiket dapur berhasil dikirim!'), backgroundColor: LpColors.primaryGreen),
                  );
                },
                icon: const Icon(Icons.soup_kitchen, size: 16, color: LpColors.accentAmber),
                label: const Text('Test Print Dapur (F8)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFCD34D),
                  side: const BorderSide(color: Color(0xFFD97706)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoveryBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LpColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LpColors.borderDark),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A).withAlpha(120),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.bluetooth_searching, color: Color(0xFF60A5FA), size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pencarian Bluetooth BLE & Port 9100 Raw', style: LpTypography.bodyMd.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text('Mendeteksi printer thermal kasir portabel, barcode scanner, atau drawer.', style: LpTypography.bodySm.copyWith(color: LpColors.textMuted, fontSize: 11)),
                ],
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Cari Perangkat Baru'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectedDevices() {
    return Column(
      children: [
        _buildDeviceRow('POS-Printer-58-BT', 'Thermal 58mm Mobile • MAC: DC:0D:30:1A:4F:92', 'Sinyal Kuat (-48 dBm)', 'Pasangkan (Pair)'),
        const SizedBox(height: 8),
        _buildDeviceRow('Barcode-Scanner-HID-02', 'Protokol: HID Keyboard Emulation • Scan SKU Kasir', 'Paired (Siap Pakai)', 'Aktif di POS'),
      ],
    );
  }

  Widget _buildDeviceRow(String name, String sub, String status, String btnText) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LpColors.surfacePanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LpColors.borderDark),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: LpTypography.bodySm.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(sub, style: LpTypography.bodySm.copyWith(color: LpColors.textMuted, fontSize: 11)),
            ],
          ),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF93C5FD),
              side: const BorderSide(color: Color(0xFF3B82F6)),
            ),
            child: Text(btnText, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildRightPanel() {
    return Container(
      color: LpColors.surfacePanel,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PENGATURAN FORMAT CETAK & HARDWARE', style: LpTypography.labelSm.copyWith(color: LpColors.primaryLight, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Konfigurasi ${_config.name}', style: LpTypography.headlineSm.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  // Paper Width
                  Text('UKURAN LEBAR KERTAS THERMAL:', style: LpTypography.labelSm.copyWith(color: LpColors.textMuted, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => setState(() => _config = _config.copyWith(paperWidth: PrinterPaperWidth.mm58)),
                          icon: const Icon(Icons.receipt),
                          label: const Text('58 mm (Kompak/Mobile)'),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: _config.paperWidth == PrinterPaperWidth.mm58 ? LpColors.primaryGreen.withAlpha(50) : LpColors.surfaceCard,
                            side: BorderSide(color: _config.paperWidth == PrinterPaperWidth.mm58 ? LpColors.primaryLight : LpColors.borderDark),
                            foregroundColor: _config.paperWidth == PrinterPaperWidth.mm58 ? LpColors.primaryLight : LpColors.textMuted,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => setState(() => _config = _config.copyWith(paperWidth: PrinterPaperWidth.mm80)),
                          icon: const Icon(Icons.receipt_long),
                          label: const Text('80 mm (Standar Resto)'),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: _config.paperWidth == PrinterPaperWidth.mm80 ? LpColors.primaryGreen.withAlpha(50) : LpColors.surfaceCard,
                            side: BorderSide(color: _config.paperWidth == PrinterPaperWidth.mm80 ? LpColors.primaryLight : LpColors.borderDark),
                            foregroundColor: _config.paperWidth == PrinterPaperWidth.mm80 ? LpColors.primaryLight : LpColors.textMuted,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Toggles
                  _buildToggle(
                    title: 'Auto-Print saat Pembayaran Lunas',
                    subtitle: 'Cetak struk otomatis tanpa konfirmasi tambahan',
                    value: _config.autoPrintOnPayment,
                    onChanged: (val) => setState(() => _config = _config.copyWith(autoPrintOnPayment: val)),
                  ),
                  _buildToggle(
                    title: 'Auto-Cut (Potong Kertas Otomatis)',
                    subtitle: 'Kirim ESC/POS partial cut setelah footer selesai dicetak',
                    value: _config.autoCut,
                    onChanged: (val) => setState(() => _config = _config.copyWith(autoCut: val)),
                  ),
                  _buildToggle(
                    title: 'Kick Cash Drawer (Buka Laci Kasir)',
                    subtitle: 'Kirim sinyal pulsa pin laci saat bayar tunai (RJ11)',
                    value: _config.kickCashDrawer,
                    onChanged: (val) => setState(() => _config = _config.copyWith(kickCashDrawer: val)),
                  ),
                  _buildToggle(
                    title: 'Cetak Header Logo Toko & Alamat',
                    subtitle: 'Sertakan logo monokrom & alamat cabang Tebet',
                    value: _config.printHeaderLogo,
                    onChanged: (val) => setState(() => _config = _config.copyWith(printHeaderLogo: val)),
                  ),
                  _buildToggle(
                    title: 'Cetak Footer QR & WhatsApp',
                    subtitle: 'QR klaim e-receipt & nomor aduan kepuasan',
                    value: _config.printFooterQr,
                    onChanged: (val) => setState(() => _config = _config.copyWith(printFooterQr: val)),
                  ),
                  const SizedBox(height: 24),
                  // Realistic Thermal Paper Simulation (White Paper with monospace font)
                  Text('SIMULASI PREVIEW STRUK THERMAL FISIK (80MM)', style: LpTypography.labelSm.copyWith(color: LpColors.textMuted, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildRealisticReceiptPreview(),
                ],
              ),
            ),
          ),
          // Action Buttons
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: LpColors.surfaceCard,
              border: Border(top: BorderSide(color: LpColors.borderDark)),
            ),
            child: Row(
              children: [
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _config = const PrinterDeviceConfig(
                        id: 'print-01',
                        name: 'Epson TM-T82X (Thermal 80mm)',
                        role: PrinterRole.cashier,
                        connectionType: PrinterConnectionType.bluetooth,
                        connectionAddress: '68:C6:3A:88:01',
                        paperWidth: PrinterPaperWidth.mm80,
                      );
                    });
                  },
                  child: const Text('Reset Default'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _saveConfig,
                      icon: const Icon(Icons.save),
                      label: const Text('Simpan Konfigurasi Printer (Enter)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: LpColors.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: LpColors.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: LpColors.borderDark),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: LpTypography.bodySm.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                Text(subtitle, style: LpTypography.bodySm.copyWith(color: LpColors.textMuted, fontSize: 10)),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: LpColors.primaryLight,
            activeTrackColor: LpColors.primaryGreen,
            onChanged: onChanged,
          ),

        ],
      ),
    );
  }

  Widget _buildRealisticReceiptPreview() {
    return Center(
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(150),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            const Center(
              child: Text(
                'KOPI KITA TEBET',
                style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w900, fontSize: 14, color: Colors.black),
              ),
            ),
            const Center(
              child: Text(
                'Jl. Tebet Raya No. 42, Jakarta Selatan\nTelp / WA: 0812-3456-7890\nPB1: 01.345.678.9-012.000',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'monospace', fontSize: 9, color: Colors.black87),
              ),
            ),
            const Divider(color: Colors.black, height: 16),
            const Text(
              'No: #TB-240502-04       Meja: 04\nKasir: Barista Rama      14:18 WIB\nTamu: Dian P. (2 Orang)  DINE-IN',
              style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.black),
            ),
            const Divider(color: Colors.black, height: 16),
            const Text(
              '2x Kopi Susu Aren        Rp 44.000\n  * Less Sugar 50%, Oat Milk\n1x Croissant Almond       Rp 28.000\n  * Hangatkan / Toasting',
              style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.black),
            ),
            const Divider(color: Colors.black, height: 16),
            const Text(
              'Subtotal                 Rp 72.000\nPB1 Pajak Restoran (10%) Rp  7.200\nDiskon Member Gold      -Rp  4.400\n----------------------------------\nTOTAL TAGIHAN            Rp 74.800',
              style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black),
            ),
            const Divider(color: Colors.black, height: 16),
            const Text(
              'BAYAR (QRIS Dinamis)     Rp 74.800\nKembalian                Rp      0\nRef: QRIS-BCA-9938201948102',
              style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.black),
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'Terima kasih atas kunjungan Anda!\nPowered by Tumbuh POS',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'monospace', fontSize: 9, color: Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: LpColors.surfaceCard,
        border: Border(top: BorderSide(color: LpColors.borderDark)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.verified, size: 14, color: LpColors.primaryLight),
              const SizedBox(width: 6),
              Text('Spooler Service: Running (0 in Queue) • ESC/POS Command Set v2.4 • Port RJ11 Pin 2 Ready', style: LpTypography.labelSm.copyWith(color: LpColors.textMuted, fontSize: 11)),
            ],
          ),
          Text('Shortcut: F7 Test Kasir • F8 Test Dapur • Enter Simpan • Esc Kembali', style: LpTypography.labelSm.copyWith(color: LpColors.textMuted, fontSize: 11)),
        ],
      ),
    );
  }
}
