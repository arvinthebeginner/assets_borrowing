# PinjamAset

Aplikasi peminjaman aset IT kantor: laptop, kamera, proyektor, audio, aksesori.
Karyawan memesan unit untuk rentang tanggal tertentu, Admin Aset menyetujui dan
mencatat serah-terima, Manajer melihat laporan.

Dibuat sebagai project portofolio dengan Rails 8.

## Fitur

- Login dengan 3 peran: karyawan, Admin Aset, Manajer
- Katalog aset 2 tingkat: jenis barang dan unit fisiknya (tag aset, nomor seri, foto)
- Pengajuan peminjaman per rentang tanggal, lengkap dengan deteksi bentrok
- Antrian persetujuan dengan alasan penolakan
- Catatan serah-terima pengambilan dan pengembalian beserta kondisi barang
- Laporan: aset paling sering dipinjam, peminjam paling aktif, utilisasi, keterlambatan

## Aturan bentrok

1 unit tidak boleh dipesan 2 orang 
pada rentang tanggal yang bersinggungan, walau cuma 1 hari.

```ruby
BLOCKING_STATUSES = %w[approved picked_up].freeze

scope :blocking,    -> { where(status: BLOCKING_STATUSES) }
scope :overlapping, ->(from, to) { where("start_on <= ? AND end_on >= ?", to, from) }
```

Pengajuan yang masih `pending` sengaja tidak mengunci unit, jadi 2 orang boleh
mengajukan tanggal yang sama dan admin yang memilih. Karena itu pengecekan
bentrok jalan 2 kali: saat pengajuan dibuat, dan sekali lagi saat disetujui.

Keterlambatan tidak disimpan sebagai status, tapi dihitung dari `picked_up` yang
tanggal kembalinya sudah lewat.

Alur statusnya:

```
pending -> approved -> picked_up -> returned
        -> rejected
        -> cancelled
```

Pengembalian dengan kondisi rusak memindahkan unit ke status perbaikan, dan
kondisi hilang memindahkannya ke tidak dipakai. Keduanya langsung hilang dari
pencarian ketersediaan.

## Menjalankan

Butuh Ruby 3.3.

```bash
bundle install
bin/rails db:setup
bin/dev
```

Buka http://localhost:3000. Untuk mengisi ulang data contoh: `bin/rails db:seed`.

Catatan buat pengguna Windows: `bin/rails db:reset` gagal karena Ruby tidak bisa
menghapus berkas SQLite yang masih terbuka. Hapus `storage/*.sqlite3` manual
kalau memang mau bikin ulang database dari nol.

## Akun demo

Kata sandi general `rahasia123`.

- `bagas@kantor.co.id` — Admin Aset
- `rina@kantor.co.id` — Manajer
- `dewi@kantor.co.id` — Karyawan

## Test

```bash
bin/rails test:all
bin/rubocop
bin/brakeman
```

System test pakai driver `rack_test`, bukan browser, karena tidak ada
alur yang butuh JavaScript.

## Teknologi

Rails 8.1, SQLite, Hotwire, Tailwind CSS, Minitest. Autentikasi memakai generator
bawaan Rails, bukan Devise. Otorisasi cukup `before_action` karena perannya cuma
3.
