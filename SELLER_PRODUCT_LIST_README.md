# Seller Product List - Shoozie

Halaman khusus untuk penjual mengelola produk mereka sendiri dengan kemampuan edit status produk.

## 🎯 Fitur Utama

### 1. **Daftar Produk Penjual**
- Menampilkan semua produk yang dimiliki penjual
- Layout card yang bersih dan mudah dibaca
- Informasi lengkap: gambar, nama, brand, harga, lokasi, dan status

### 2. **Edit Status Produk**
- **Tap sekali pada status** untuk mengubah status produk
- Toggle antara "Ready" dan "Sold Out"
- Konfirmasi dialog sebelum mengubah status
- Feedback visual dengan warna yang berbeda:
  - 🟢 **Ready**: Hijau dengan ikon check
  - 🔴 **Sold Out**: Merah dengan ikon cancel

### 3. **Pencarian & Filter**
- **Pencarian real-time** berdasarkan nama produk, brand, atau lokasi
- **Filter berdasarkan brand** dengan dropdown
- **Sorting options**:
  - Terbaru / Terlama
  - Harga: Rendah ke Tinggi / Tinggi ke Rendah
  - Nama: A ke Z / Z ke A

### 4. **Manajemen Produk**
- **Lihat detail produk** dengan tap pada card
- **Hapus produk** melalui menu popup
- **Tambah produk baru** dengan tombol "+" di AppBar
- **Refresh data** dengan pull-to-refresh atau tombol refresh

## 🚀 Cara Penggunaan

### Mengakses Halaman
1. **Dari AppBar**: Klik ikon inventory di pojok kanan atas
2. **Dari Bottom Navigation**: Klik ikon shop di navigation bar bawah
3. **Hanya muncul jika user sudah login**

### Mengubah Status Produk
1. **Tap pada status badge** di card produk
2. **Dialog konfirmasi** akan muncul
3. **Pilih "Update"** untuk mengkonfirmasi perubahan
4. **Status otomatis berubah** dan data di-refresh

### Menu Popup Actions
- **Edit Status**: Alternatif cara untuk mengubah status
- **Delete**: Menghapus produk dengan konfirmasi

## 🎨 UI/UX Features

### Design Elements
- **Modern Card Layout**: Card bersih dengan shadow halus
- **Color-coded Status**: Warna berbeda untuk setiap status
- **Interactive Elements**: Feedback visual saat disentuh
- **Responsive Design**: Bekerja di mobile dan web

### User Experience
- **One-tap Status Change**: Ubah status hanya dengan satu tap
- **Clear Visual Feedback**: Ikon dan warna yang jelas
- **Loading States**: Indikator loading saat API call
- **Error Handling**: Pesan error yang user-friendly
- **Empty States**: Pesan helpful saat tidak ada produk

## 📡 API Integration

### Endpoints yang Digunakan:
- `GET /product` - Mengambil semua produk
- `GET /product?id_brand={id}` - Filter produk berdasarkan brand
- `GET /brands` - Mengambil semua brand
- `PUT /product/{id}/status` - Update status produk
- `DELETE /product/{id}` - Hapus produk

### Request untuk Update Status:
```json
{
  "product_status": "Ready" // atau "Sold Out"
}
```

## 🔧 Struktur File

```
lib/
├── seller_product_list.dart    # Halaman utama seller product list
├── product_page.dart          # Updated dengan navigasi ke seller list
├── input_product.dart         # Form tambah produk
└── detail_product.dart        # Detail produk
```

## 💡 Fitur Status Edit

### Visual Status Indicators:
- **Ready Status**:
  - 🟢 Background hijau muda
  - ✅ Ikon check circle
  - Border hijau
  - Text hijau tua

- **Sold Out Status**:
  - 🔴 Background merah muda
  - ❌ Ikon cancel
  - Border merah  
  - Text merah tua

### Interactive Elements:
- **Hover Effect**: Card sedikit naik saat di-hover
- **Tap Feedback**: Ripple effect saat di-tap
- **Loading State**: Spinner saat update status
- **Success Feedback**: SnackBar hijau saat berhasil

## 🎯 Benefits

### Untuk Penjual:
- **Manajemen mudah**: Update status produk dengan cepat
- **Visibilitas jelas**: Status produk langsung terlihat
- **Organisasi baik**: Semua produk dalam satu tempat
- **Kontrol penuh**: Edit dan hapus produk sesuai kebutuhan

### Untuk User Experience:
- **Intuitive**: Interface yang mudah dipahami
- **Efficient**: Proses update yang cepat
- **Responsive**: Feedback langsung untuk setiap aksi
- **Professional**: Tampilan yang clean dan modern

## 🔄 Navigation Flow

```
Product Page (Main)
    ├── AppBar: Inventory Icon → Seller Product List
    └── Bottom Nav: Shop Icon → Seller Product List

Seller Product List
    ├── Search & Filter Products
    ├── Tap Status → Update Status Dialog
    ├── Popup Menu → Edit Status / Delete
    ├── Add Button → Input Product Page
    └── Product Card → Product Detail Page
```

## 🚀 Future Enhancements

- **Bulk Status Update**: Select multiple products untuk update bersamaan
- **Sales Analytics**: Statistik penjualan per produk
- **Inventory Management**: Stock management untuk setiap produk
- **Price History**: Riwayat perubahan harga produk
- **Product Performance**: Metrics untuk setiap produk
- **Quick Actions**: Shortcut untuk aksi yang sering dilakukan

## 🎯 Tips Penggunaan

1. **Quick Status Toggle**: Tap langsung pada status badge untuk perubahan cepat
2. **Use Search**: Gunakan search untuk menemukan produk tertentu dengan cepat
3. **Sort by Status**: Sort untuk melihat semua produk Ready atau Sold Out
4. **Pull to Refresh**: Tarik ke bawah untuk refresh data terbaru
5. **Long Press**: Untuk akses menu popup dengan lebih banyak opsi
