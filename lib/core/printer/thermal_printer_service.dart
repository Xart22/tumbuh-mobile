import 'dart:convert';
import 'dart:typed_data';
import '../../data/models/cart_item.dart';
import '../../data/models/payment_model.dart';
import '../../data/models/pos_product.dart';
import '../../data/models/printer_config.dart';

import '../../shared/formatters/currency_formatter.dart';
import '../../shared/formatters/date_formatter.dart';
import '../../shared/math/order_math.dart';

class ThermalPrinterService {
  // ESC/POS Command Constants
  static const List<int> escInit = [0x1B, 0x40]; // ESC @
  static const List<int> escAlignLeft = [0x1B, 0x61, 0x00];
  static const List<int> escAlignCenter = [0x1B, 0x61, 0x01];
  static const List<int> escAlignRight = [0x1B, 0x61, 0x02];
  static const List<int> escBoldOn = [0x1B, 0x45, 0x01];
  static const List<int> escBoldOff = [0x1B, 0x45, 0x00];
  static const List<int> escDoubleSize = [0x1D, 0x21, 0x11];
  static const List<int> escNormalSize = [0x1D, 0x21, 0x00];
  static const List<int> escFeedLine = [0x0A];
  static const List<int> escCutPaper = [0x1D, 0x56, 0x41, 0x03]; // GS V A 3 (feed and cut)
  static const List<int> escDrawerKick = [0x1B, 0x70, 0x00, 0x19, 0xFA]; // ESC p 0 pin 2 pulse

  /// Store metadata
  String storeName;
  String storeAddress;
  String storePhone;
  String storeTaxId;

  ThermalPrinterService({
    this.storeName = 'KOPI KITA TEBET',
    this.storeAddress = 'Jl. Tebet Raya No. 42, Jakarta Selatan',
    this.storePhone = '0812-3456-7890',
    this.storeTaxId = '01.345.678.9-012.000',
  });

  /// Build a 2-column justified line (Left text + spaces + Right text = width)
  String _justify(String left, String right, int width) {
    final available = width - right.length;
    if (available <= 0) return left + right;
    if (left.length > available) {
      left = '${left.substring(0, available - 1)} ';
    }
    return left.padRight(available) + right;
  }

  /// Generate Plain Text Receipt representation for UI preview
  String generateReceiptText({
    required String orderId,
    required String tableNumber,
    required String cashierName,
    required String customerName,
    required String orderType,
    required List<CartItem> items,
    required OrderTotals totals,
    required OrderPaymentDetails payment,
    PrinterPaperWidth width = PrinterPaperWidth.mm80,
  }) {
    final cols = width.columns;
    final divider = '-' * cols;
    final doubleDivider = '=' * cols;
    final sb = StringBuffer();

    // Header
    sb.writeln('[TUMBUH]'.padLeft((cols + 8) ~/ 2));
    sb.writeln(storeName.padLeft((cols + storeName.length) ~/ 2));
    sb.writeln(storeAddress.padLeft((cols + storeAddress.length) ~/ 2));
    sb.writeln('Telp / WA: $storePhone'.padLeft((cols + 11 + storePhone.length) ~/ 2));
    sb.writeln('PB1: $storeTaxId'.padLeft((cols + 5 + storeTaxId.length) ~/ 2));
    sb.writeln(divider);

    // Metadata
    sb.writeln(_justify('No: $orderId', 'Meja: $tableNumber', cols));
    sb.writeln(_justify('Kasir: $cashierName', DateFormatter.formatShortDateTime(payment.paidAt), cols));
    sb.writeln(_justify('Tamu: $customerName', orderType.toUpperCase(), cols));
    sb.writeln(divider);

    // Items
    for (final item in items) {
      final lineLeft = '${item.quantity}x ${item.product.name}';
      final lineRight = CurrencyFormatter.format(item.netTotal);
      sb.writeln(_justify(lineLeft, lineRight, cols));

      // Modifiers
      if (item.selectedModifiers.isNotEmpty) {
        final mods = item.selectedModifiers
            .map((m) => m.priceDelta > 0
                ? '${m.name} (+${CurrencyFormatter.format(m.priceDelta)})'
                : m.name)
            .join(', ');
        sb.writeln('  * $mods');
      }

      // Notes
      if (item.notes != null && item.notes!.isNotEmpty) {
        sb.writeln('  # ${item.notes}');
      }
    }
    sb.writeln(divider);

    // Totals
    sb.writeln(_justify('Subtotal', CurrencyFormatter.format(totals.subtotal), cols));
    if (totals.voucherDiscount > 0) {
      sb.writeln(_justify('Diskon Voucher', '-${CurrencyFormatter.format(totals.voucherDiscount)}', cols));
    }
    if (totals.serviceCharge > 0) {
      sb.writeln(_justify('Biaya Layanan (${totals.serviceChargePercent}%)', CurrencyFormatter.format(totals.serviceCharge), cols));
    }
    if (totals.tax > 0) {
      sb.writeln(_justify('PB1 Restoran (${totals.taxPercent}%)', CurrencyFormatter.format(totals.tax), cols));
    }
    sb.writeln(doubleDivider);
    sb.writeln(_justify('TOTAL TAGIHAN', CurrencyFormatter.format(totals.grandTotal), cols));
    sb.writeln(doubleDivider);

    // Payment details
    if (payment.isSplitPayment) {
      sb.writeln('PEMBAYARAN SPLIT:');
      for (final split in payment.splits) {
        sb.writeln(_justify('  ${split.method.label}', CurrencyFormatter.format(split.amount), cols));
        if (split.method == PosPaymentMethod.cash && split.cashGiven > split.amount) {
          sb.writeln(_justify('    Uang Diterima', CurrencyFormatter.format(split.cashGiven), cols));
          sb.writeln(_justify('    Kembalian', CurrencyFormatter.format(split.change), cols));
        }
      }
    } else {
      sb.writeln(_justify('BAYAR (${payment.primaryMethod.label})', CurrencyFormatter.format(payment.totalPaid), cols));
      if (payment.primaryMethod == PosPaymentMethod.cash) {
        sb.writeln(_justify('Kembalian', CurrencyFormatter.format(payment.change), cols));
      }
    }

    sb.writeln(divider);
    sb.writeln('Terima kasih atas kunjungan Anda!'.padLeft((cols + 33) ~/ 2));
    sb.writeln('Kritik & Saran: feedback@kopikita.id'.padLeft((cols + 35) ~/ 2));
    sb.writeln('Powered by Tumbuh POS • www.tumbuh.id'.padLeft((cols + 36) ~/ 2));

    return sb.toString();
  }

  /// Generate ESC/POS Binary Bytes for real thermal printer dispatch
  Uint8List generateEscPosReceiptBytes({
    required String orderId,
    required String tableNumber,
    required String cashierName,
    required String customerName,
    required String orderType,
    required List<CartItem> items,
    required OrderTotals totals,
    required OrderPaymentDetails payment,
    required PrinterDeviceConfig config,
  }) {
    final bytes = BytesBuilder();

    // 1. Initialize
    bytes.add(escInit);

    // 2. Open Cash Drawer if enabled and cash payment
    if (config.kickCashDrawer &&
        (payment.primaryMethod == PosPaymentMethod.cash ||
            payment.splits.any((s) => s.method == PosPaymentMethod.cash))) {
      bytes.add(escDrawerKick);
    }

    // 3. Header
    bytes.add(escAlignCenter);
    if (config.printHeaderLogo) {
      bytes.add(escBoldOn);
      bytes.add(escDoubleSize);
      bytes.add(utf8.encode('TUMBUH POS\n'));
      bytes.add(escNormalSize);
      bytes.add(utf8.encode('$storeName\n'));
      bytes.add(escBoldOff);
      bytes.add(utf8.encode('$storeAddress\n'));
      bytes.add(utf8.encode('Telp: $storePhone • NPWP: $storeTaxId\n'));
    }

    // 4. Separator
    final cols = config.paperWidth.columns;
    bytes.add(escAlignLeft);
    bytes.add(utf8.encode('${'-' * cols}\n'));

    // 5. Metadata
    bytes.add(utf8.encode('${_justify('No: $orderId', 'Meja: $tableNumber', cols)}\n'));
    bytes.add(utf8.encode('${_justify('Kasir: $cashierName', DateFormatter.formatShortDateTime(payment.paidAt), cols)}\n'));
    bytes.add(utf8.encode('${_justify('Tamu: $customerName', orderType.toUpperCase(), cols)}\n'));
    bytes.add(utf8.encode('${'-' * cols}\n'));

    // 6. Items
    for (final item in items) {
      bytes.add(escBoldOn);
      bytes.add(utf8.encode('${_justify('${item.quantity}x ${item.product.name}', CurrencyFormatter.format(item.netTotal), cols)}\n'));
      bytes.add(escBoldOff);

      if (item.selectedModifiers.isNotEmpty) {
        final mods = item.selectedModifiers
            .map((m) => m.priceDelta > 0
                ? '${m.name} (+${CurrencyFormatter.format(m.priceDelta)})'
                : m.name)
            .join(', ');
        bytes.add(utf8.encode('  * $mods\n'));
      }

      if (item.notes != null && item.notes!.isNotEmpty) {
        bytes.add(utf8.encode('  # Catatan: ${item.notes}\n'));
      }
    }

    // 7. Totals
    bytes.add(utf8.encode('${'-' * cols}\n'));
    bytes.add(utf8.encode('${_justify('Subtotal', CurrencyFormatter.format(totals.subtotal), cols)}\n'));
    if (totals.voucherDiscount > 0) {
      bytes.add(utf8.encode('${_justify('Diskon Member', '-${CurrencyFormatter.format(totals.voucherDiscount)}', cols)}\n'));
    }
    if (totals.tax > 0) {
      bytes.add(utf8.encode('${_justify('PB1 Restoran (10%)', CurrencyFormatter.format(totals.tax), cols)}\n'));
    }

    bytes.add(escBoldOn);
    bytes.add(utf8.encode('${'=' * cols}\n'));
    bytes.add(utf8.encode('${_justify('TOTAL TAGIHAN', CurrencyFormatter.format(totals.grandTotal), cols)}\n'));
    bytes.add(utf8.encode('${'=' * cols}\n'));
    bytes.add(escBoldOff);

    // 8. Payment
    if (payment.isSplitPayment) {
      bytes.add(utf8.encode('PEMBAYARAN SPLIT:\n'));
      for (final split in payment.splits) {
        bytes.add(utf8.encode('${_justify('  ${split.method.label}', CurrencyFormatter.format(split.amount), cols)}\n'));
        if (split.method == PosPaymentMethod.cash && split.cashGiven > split.amount) {
          bytes.add(utf8.encode('${_justify('    Kembalian', CurrencyFormatter.format(split.change), cols)}\n'));
        }
      }
    } else {
      bytes.add(utf8.encode('${_justify('BAYAR (${payment.primaryMethod.label})', CurrencyFormatter.format(payment.totalPaid), cols)}\n'));
      if (payment.primaryMethod == PosPaymentMethod.cash) {
        bytes.add(utf8.encode('${_justify('Kembalian', CurrencyFormatter.format(payment.change), cols)}\n'));
      }
    }

    // 9. Footer
    bytes.add(utf8.encode('${'-' * cols}\n'));
    bytes.add(escAlignCenter);
    bytes.add(utf8.encode('Terima kasih atas kunjungan Anda!\n'));
    if (config.printFooterQr) {
      bytes.add(utf8.encode('Scan struk untuk feedback / e-receipt\n'));
      bytes.add(utf8.encode('[$orderId]\n'));
    }
    bytes.add(utf8.encode('Powered by Tumbuh POS\n'));

    // Feed lines & cut
    bytes.add(escFeedLine);
    bytes.add(escFeedLine);
    bytes.add(escFeedLine);
    if (config.autoCut) {
      bytes.add(escCutPaper);
    }

    return bytes.toBytes();
  }

  /// Generate Kitchen/Bar Order Ticket Bytes (for KDS / Kitchen Printer)
  Uint8List generateKitchenTicketBytes({
    required String orderId,
    required String tableNumber,
    required String orderType,
    required List<CartItem> items,
    required PrinterDeviceConfig config,
  }) {
    final bytes = BytesBuilder();
    final cols = config.paperWidth.columns;

    bytes.add(escInit);
    bytes.add(escAlignCenter);
    bytes.add(escBoldOn);
    bytes.add(escDoubleSize);
    bytes.add(utf8.encode('TIKET PESANAN DAPUR / BAR\n'));
    bytes.add(utf8.encode('MEJA: $tableNumber ($orderType)\n'));
    bytes.add(escNormalSize);
    bytes.add(utf8.encode('Order #$orderId • ${DateFormatter.formatShortDateTime(DateTime.now())}\n'));
    bytes.add(escBoldOff);

    bytes.add(escAlignLeft);
    bytes.add(utf8.encode('${'=' * cols}\n'));

    for (final item in items) {
      bytes.add(escBoldOn);
      bytes.add(utf8.encode('${item.quantity}x ${item.product.name}\n'));
      bytes.add(escBoldOff);

      if (item.selectedModifiers.isNotEmpty) {
        for (final mod in item.selectedModifiers) {
          bytes.add(utf8.encode('   > ${mod.name}\n'));
        }
      }
      if (item.notes != null && item.notes!.isNotEmpty) {
        bytes.add(escBoldOn);
        bytes.add(utf8.encode('   [!] CATATAN: ${item.notes}\n'));
        bytes.add(escBoldOff);
      }
      bytes.add(utf8.encode('${'-' * cols}\n'));
    }

    bytes.add(escFeedLine);
    bytes.add(escFeedLine);
    if (config.autoCut) {
      bytes.add(escCutPaper);
    }

    return bytes.toBytes();
  }

  /// Test Print method
  Future<bool> testPrint({
    required PrinterDeviceConfig config,
  }) async {
    // In production mobile, write bytes to Bluetooth Socket or Network Socket (Port 9100)
    // For local simulation, verify byte generation succeeds
    final sampleItems = [
      CartItem.create(
        product: const PosProduct(
          id: 'test-1',
          name: 'Kopi Susu Aren',
          sku: 'KOP-01',
          price: 22000,
          categoryId: 'cat-1',
          categoryName: 'Kopi Espresso',
        ),
        quantity: 2,
      ),
    ];
    final sampleTotals = OrderMath.calculateDraft(
      items: [
        const OrderItemDraft(id: 'test-1', price: 22000, quantity: 2),
      ],
      taxPercent: 10,
    );
    final samplePayment = OrderPaymentDetails(
      grandTotal: sampleTotals.grandTotal,
      totalPaid: sampleTotals.grandTotal,
      paidAt: DateTime.now(),
    );

    final bytes = generateEscPosReceiptBytes(
      orderId: 'TEST-PRINTER',
      tableNumber: '00',
      cashierName: 'Tester',
      customerName: 'Test Print',
      orderType: 'Dine-In',
      items: sampleItems,
      totals: sampleTotals,
      payment: samplePayment,
      config: config,
    );

    return bytes.isNotEmpty;
  }
}
