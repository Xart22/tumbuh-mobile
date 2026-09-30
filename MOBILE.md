# MOBILE.md — Aplikasi Android (Flutter) Tumbuh POS

Rencana lengkap aplikasi mobile hingga **siap live production**. Tidak ada fase "MVP":
semua item di bawah adalah syarat rilis. Urutan kerja (bagian 9) hanya soal *eksekusi*,
bukan pemangkasan fitur.

---

## 1. Prinsip

- **Satu aplikasi, multi-role** (kasir, dapur/KDS, owner/manager) dengan role-gate +
  **device binding**. Self-order pelanggan = **PWA web**, bukan aplikasi.
- **Offline-first.** Operasi kasir wajib jalan saat internet mati; sinkronisasi saat online.
- **Server otoritatif** untuk pajak, service charge, rounding, dan total akhir
  (`computeOrderTotals`, `roundingBase`). Klien hanya menghitung total draft untuk preview.
- **Honest UI.** Data absen tampil sebagai ketiadaan, bukan `0`/nilai karangan.
- **Paritas kontrak** dengan `tumbuh-be` (NestJS). Model Dart digenerate dari Swagger BE,
  bukan ditulis manual.
- **DESIGN.md = SSOT visual.** Token `lp-*` dipetakan ke `ThemeData`/`ColorScheme` Flutter.

---

## 2. Platform & Stack

- Flutter (stable channel), target **Android 8.0+** (minSdk 26, targetSdk terbaru Play).
- **Tablet landscape** untuk kasir; HP untuk owner & KDS; layout responsif per breakpoint.
- State: **Bloc/Cubit** (`flutter_bloc`). Routing: **go_router** (deep link QR meja).
- HTTP: **Dio** (+ interceptor auth, 401 → logout global, retry GET, **Idempotency-Key** untuk POST)
  atau klien generated dari Swagger.
- Model: **freezed** + **json_serializable** (generated dari OpenAPI BE).
- DB lokal: **Drift** (SQLite) + tabel antrean sync + outbox.
- Secure storage: **flutter_secure_storage**; biometric: **local_auth**.
- Printer: **esc_pos_utils_plus** + **flutter_pos_printer_platform_image_3** (BT/USB/LAN).
- Scan: **mobile_scanner** (kamera; juga scanner HID hardware).
- QR display (QRIS dinamis): **qr_flutter**.
- Push: **firebase_messaging** (FCM). Background sync: **workmanager**.
- Observability: **Sentry Flutter** (crash + perf) + analytics event.
- i18n: **flutter_localizations** (locale `id-ID` default), format duit `Rp` + `intl`,
  timezone **Asia/Jakarta**.

---

## 3. Arsitektur

```
lib/
  core/        env, dio client, interceptor auth/idempotency, error mapping, secure storage
  data/
    models/     generated (freezed) dari Swagger BE
    local/      drift schema + dao + outbox queue
    remote/     repository per domain
  features/
    auth/ shift/ pos/ kds/ owner/ inventory/ customers/ settings/
  shared/      order_math.dart (port lib/order-math.ts), theme (lp-*), widgets, formatters
  routing/     go_router + deep links
```

- Repository pattern: remote (Dio) + local (Drift) + **sync engine** (outbox → BE, idempotent).
- Konflik: serah-terima `updated_at`; operasi kasir berbasis append-only event (order, payment,
  void) → aman di-replay dengan `Idempotency-Key`.
- Cache read-model (menu, stok, pelanggan) di Drift untuk offline browse.

---

## 4. Fitur per Mode

### 4.1 Mode Kasir (tablet)
- **Auth**: login PIN kasir (`POST /v1/auth/login-kasir`) + biometric unlock; **device binding**
  (aktivasi device oleh owner; 1 device ↔ 1 shift aktif).
- **Shift**: current shift, buka/tutup (`/v1/shifts/*`), modal awal, hitung pecahan,
  rekap penjualan shift, **variance** + alasan, setoran, riwayat shift.
- **POS**: kategori + grid menu (`loadMenu`), cari, **scan barcode/SKU** (`lookupProductByCode`),
  opsi produk (`loadProductOptions`: varian + modifier), catatan per item, tipe order
  (dine-in/take-away/delivery).
- **Bill Parkir**: parkir/hold, resume, edit isi (`replaceItems`), daftar tagihan berjalan,
  durasi, penanda tagihan lama.
- **Pindah meja** (`moveOrderTable`), merge/split order (`/merge`, `/split`).
- **Pembayaran**: tunai (pecahan cepat + kembalian), **split bayar** (2 metode), QRIS statis,
  **QRIS dinamis** (tampil QR + poll status webhook), debit/kredit, deposit/piutang,
  `credit-settle` (pelunasan piutang).
- **Diskon & voucher**: diskon manual (`/discount`), voucher (`/voucher` apply/remove + validate),
  pasang **pelanggan** ke order.
- **Void/refund**: void item/order + alasan (`/items/:id/void`, `/void`), cetak ulang bukti.
- **Printer thermal**: struk pelanggan (`/v1/printers/receipt/:id`) & tiket dapur
  (`/kitchen-ticket/:id`), **auto-print saat bayar**, pilih printer (58/80mm), cetak ulang.
- **Multi-outlet**: ganti outlet aktif bila user punya akses.
- **Offline**: seluruh transaksi masuk outbox; status sinkron terlihat (pending/terkirim/gagal).

### 4.2 Mode Dapur / KDS (tablet dinding / HP)
- Antrean tiket real-time (`kitchenQueue` poll/WS), ringkasan (`kitchenSummary`).
- Bump item, **serve order**, recall item/order.
- Filter station dinamis, tiket urut waktu, **chime + toggle audio**, penanda urgensitas.
- Mode selalu-nyala (kiosk), reconnect otomatis, degradasi saat offline.

### 4.3 Mode Owner / Manager (HP)
- **Dashboard KPI** (paritas `/dashboard`): penjualan, marga, top produk, per metode bayar,
  sales per jam, target.
- **Notifikasi push**: order baru, stok kritis, stok habis, selisih setoran, voucher mendekati limit.
- **Laporan** (`/reports`): sales, menu, operations, profit, pajak — ringkas + filter tanggal.
- **Bill Parkir berjalan**: pantau tagihan terbuka + total.
- **Inventory**: lihat stok & status material, opname, waste, PO (buat/terima/approve),
  reorder.
- **CRM**: pelanggan (cari/detail/analytics/stamp/kartu/segmen/birthday), voucher (buat/ubah).
- **Keuangan**: daftar expense (+kategori & berkala), supplier invoice.
- **Kelola**: outlet, employee (+jadwal, absensi clock-in/out), tabel/meja + QR, settings
  (jam operasional, target food cost, pengiriman/ongkir, loyalty, branding storefront).
- **Approve**: diskon/void di atas ambang, PO, koreksi shift.

### 4.4 Self-Order (pelanggan) — PWA web, bukan app
- Scan QR meja → `/order/<tableId>` (`GET /v1/self-order/tables/:tableId/menu`,
  `POST .../order`, publik + throttle + approve kasir). Deep link dari app kasir untuk cetak QR.

---

## 5. Fitur Platform Lintas-Mode
- Push FCM + deep link (order baru, shift, stok).
- **Deep link QR meja** (`/order/:tableId`) & QR printer pairing.
- Background sync (`workmanager`) + foreground sync saat app aktif.
- **In-app update** (Play Core) + update printer firmware opsional.
- Mode kiosk (screen pin) untuk KDS/kasir.
- Export/share (PDF laporan/struk, share ke WA).
- Bluetooth pairing manager (printer, scanner).

---

## 6. Non-Functional (syarat live)

- **Offline & sync**: outbox persisten, idempoten, retry backoff, dedup, indikator status,
  rekonsiliasi saat online, tanpa kehilangan/duplikasi order.
- **Keamanan**: secure storage untuk token, TLS pinning opsional, 401 → logout global,
  device binding, tidak menyimpan PIN plaintext, ProGuard/R8, sembunyikan data sensitif di
  app switcher.
- **Performa**: cold start < 2s di perangkat kelas menengah, list menu >100 item lancar
  (lazy + cache), gambar produk lazy + cache.
- **Observability**: Sentry (crash + breadcrumb), log terstruktur, event analytics kunci
  (login, buka shift, transaksi, sinkron gagal), health-check konektivitas BE.
- **i18n & format**: `id-ID`, `Rp`, timezone Asia/Jakarta, angka & tanggal konsisten.
- **Aksesibilitas**: target sentuh ≥44dp, kontras sesuai DESIGN.md, label screen-reader.
- **Reliabilitas printer**: antre cetak, fallback, pesan gagal jelas, cetak ulang.
- **Testing**: unit (order_math, sync engine, formatter), widget (layar kritis), integrasi
  (mock BE), **E2E** alur kasir→bayar→cetak di perangkat nyata.
- **CI/CD**: lint (`flutter analyze`) + test + build APK/AAB per PR; rilis bertanda tangan.

---

## 7. Integrasi Backend (kontrak)

- Base URL `NEXT_PUBLIC_API_URL` (mis. `https://api...`), semua `/v1/*`.
- Endpoint inti:
  - Auth: `POST /v1/auth/login-kasir`, `/v1/auth/login-owner`, refresh.
  - Orders: `GET/POST /v1/orders`, `GET /v1/orders/:id`, `hold/unhold`, `items/replace`,
    `voucher`, `discount`, `move-table`, `merge`, `split`, `credit-settle`, `void`,
    `items/:id/void`, `confirm`, `cancel`.
  - Payments: create (single/split), status poll (QRIS).
  - Shifts: current/open/close/list.
  - Kitchen: `queue`, `summary`, bump/serve/recall.
  - Printers: `GET /v1/printers`, `receipt/:id`, `kitchen-ticket/:id`.
  - Tables: CRUD + status (+ QR).
  - Menu: `loadMenu`, `loadProductOptions`, `lookupProductByCode`.
  - Reports: sales-summary, top-products, payment-methods, hourly-sales, menu-engineering,
    product-margins, material-status, stock-levels, by-table.
  - CRM: customers CRUD + loyalty/stamp/segments/birthdays; vouchers CRUD + validate.
  - Keuangan: expenses (+kategori, berkala), supplier invoices.
  - Org: outlets, employees, attendances (clock-in/out), settings, tenant branding.
  - Self-order: menu + create (publik).
- **Normalisasi payload** di repository Dart (BE tidak 1:1 dengan bentuk FE lama).
- POST selalu `Idempotency-Key`; GET retry; 401 → logout.

---

## 8. Rilis Production

- Play Console: **AAB**, signing key di secure CI, Play App Signing.
- Versi `versionName`/`versionCode` naik per rilis; changelog.
- Production keystore + `key.properties` di luar repo (CI secret).
- Crash-free rate target ≥ 99.5% sebelum promote; staged rollout (5% → 100%).
- Kebijakan privasi + data safety form (Play) — selaras `/privacy`.
- Backup & restore: kredensial device binding, konfigurasi printer ikut device.
- SOP ops: pairing printer, aktivasi device, prosedur saat BE down (mode offline).

---

## 9. Urutan Kerja (eksekusi, bukan pemangkasan)

1. Fondasi: repo, theme `lp-*`, Dio + auth + secure storage, model generated, Drift + outbox.
2. Auth + shift + device binding.
3. POS core: menu/scan/cart/modifier + printer + bayar (tunai/QRIS/split) + offline sync.
4. Bill Parkir + pindah meja + void + diskon/voucher/pelanggan.
5. KDS.
6. Owner: dashboard, notif, laporan, inventory, CRM, keuangan, kelola, approve.
7. PWA self-order + QR.
8. Hardening: observability, E2E, performa, aksesibilitas, uji offline, SOP.
9. Rilis: signing, CI/CD, staged rollout, monitoring pasca-rilis.

---

## 10. Checklist Siap-Live

- [ ] Semua endpoint kontrak terverifikasi lawan BE produksi.
- [ ] Uji offline→online: tidak ada order hilang/duplikat (idempotensi terbukti).
- [ ] Printer BT/LAN teruji (58 & 80mm, struk + tiket dapur, gagal-ulang).
- [ ] QRIS dinamis: tampil QR + status terkonfirmasi.
- [ ] Device binding + biometric + logout 401 berfungsi.
- [ ] Push notifikasi terkirim di perangkat nyata.
- [ ] Crash-free ≥ 99.5%, tidak ada crash awal sesi di rilis kandidat.
- [ ] `flutter analyze` & test hijau di CI; build AAB bertanda tangan.
- [ ] Laporan/struk benar (pajak, service, rounding, pembulatan kas).
- [ ] Aksesibilitas & target sentuh memadai; kontras sesuai DESIGN.md.
- [ ] SOP operator + prosedur degradasi BE-down terdokumentasi.
