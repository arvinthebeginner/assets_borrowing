ActiveRecord::Base.transaction do
  HandoverCheck.delete_all
  BorrowRequest.delete_all
  AssetUnit.delete_all
  Asset.delete_all
  AssetCategory.delete_all
  Session.delete_all
  User.delete_all

  # Pengguna 

  bagas = User.create!(name: "Bagas Pratama", email_address: "bagas@kantor.co.id",
                       password: "rahasia123", role: :asset_admin, department: "IT")
  rina  = User.create!(name: "Rina Wijaya", email_address: "rina@kantor.co.id",
                       password: "rahasia123", role: :manager, department: "Operasional")
  dewi  = User.create!(name: "Dewi Lestari", email_address: "dewi@kantor.co.id",
                       password: "rahasia123", role: :employee, department: "Marketing")
  andi  = User.create!(name: "Andi Saputra", email_address: "andi@kantor.co.id",
                       password: "rahasia123", role: :employee, department: "Sales")
  sinta = User.create!(name: "Sinta Rahayu", email_address: "sinta@kantor.co.id",
                       password: "rahasia123", role: :employee, department: "Keuangan")

  # Katalog

  categories = {
    laptop: AssetCategory.create!(name: "Laptop"),
    kamera: AssetCategory.create!(name: "Kamera"),
    proyektor: AssetCategory.create!(name: "Proyektor"),
    audio: AssetCategory.create!(name: "Audio"),
    aksesori: AssetCategory.create!(name: "Aksesori")
  }

  # [kategori, merek, model, kode tag, jumlah unit, deskripsi]
  catalog = [
    [ :laptop, "Apple", "MacBook Pro 14 M3", "LP", 3, "Untuk kebutuhan desain dan pengembangan." ],
    [ :laptop, "Dell", "Latitude 5450", "LD", 4, "Laptop kerja harian, ringan dibawa." ],
    [ :laptop, "Lenovo", "ThinkPad T14", "LT", 3, "Cadangan untuk karyawan baru dan magang." ],
    [ :kamera, "Sony", "Alpha 7 IV", "CM", 2, "Kamera utama untuk dokumentasi acara." ],
    [ :kamera, "Canon", "EOS R50", "CR", 2, "Kamera ringkas untuk konten media sosial." ],
    [ :proyektor, "Epson", "EB-X51", "PR", 3, "Proyektor ruang rapat besar." ],
    [ :proyektor, "BenQ", "MW550", "PB", 2, "Proyektor portabel untuk kunjungan klien." ],
    [ :audio, "Rode", "Wireless GO II", "AU", 2, "Mikrofon nirkabel dua kanal." ],
    [ :audio, "Zoom", "H6", "AZ", 2, "Perekam suara untuk wawancara dan podcast." ],
    [ :aksesori, "Anker", "555 USB-C Hub", "AC", 4, "Hub untuk presentasi di ruang rapat." ]
  ]

  units = {}

  catalog.each do |category_key, brand, model, code, count, description|
    asset = Asset.create!(asset_category: categories.fetch(category_key),
                          brand: brand, model: model, description: description)

    count.times do |index|
      number = format("%03d", index + 1)
      unit = asset.asset_units.create!(asset_tag: "IT-#{code}-#{number}",
                                       serial_number: "SN-#{code}-#{number}")
      units[unit.asset_tag] = unit
    end
  end

  # Peminjaman 

  ajukan = lambda do |user, tag, purpose, from, to|
    BorrowRequest.create!(user: user, asset_unit: units.fetch(tag), purpose: purpose,
                          start_on: Date.current + from, end_on: Date.current + to)
  end

  serah = lambda do |borrow_request, kind, condition, notes|
    borrow_request.handover_checks.create!(kind: kind, condition: condition,
                                           notes: notes, checked_by: bagas)
  end

  # Peminjaman yang sudah tuntas — ini yang mengisi grafik "paling sering dipinjam".
  [
    [ dewi,  "IT-LP-001", "Presentasi kuartal ke kantor pusat.", -40, -35, :good ],
    [ andi,  "IT-CM-001", "Dokumentasi peluncuran produk.",      -30, -27, :minor_damage ],
    [ sinta, "IT-PR-001", "Rapat audit internal.",               -25, -22, :good ],
    [ dewi,  "IT-LP-001", "Pelatihan tim konten.",               -20, -16, :good ],
    [ andi,  "IT-CM-001", "Liputan pameran dagang.",             -14, -10, :damaged ]
  ].each do |user, tag, purpose, from, to, condition|
    request = ajukan.call(user, tag, purpose, from, to)
    request.approve(by: bagas)
    serah.call(request, :pickup, :good, nil)
    serah.call(request, :dropoff, condition, condition == :good ? nil : "Perlu dicek teknisi.")
  end

  # Sedang dipinjam, sudah lewat tanggal kembali.
  terlambat = ajukan.call(rina, "IT-AU-001", "Liputan acara tahunan perusahaan.", -9, -2)
  terlambat.approve(by: bagas)
  serah.call(terlambat, :pickup, :good, "Tas dan dua baterai lengkap.")

  # Sedang dipinjam, masih dalam tenggat.
  berjalan = ajukan.call(sinta, "IT-LD-001", "Kunjungan ke cabang Surabaya.", -1, 3)
  berjalan.approve(by: bagas)
  serah.call(berjalan, :pickup, :good, nil)

  # Sudah disetujui, menunggu diambil.
  ajukan.call(dewi, "IT-CR-001", "Pemotretan katalog produk baru.", 2, 5).approve(by: bagas)
  ajukan.call(andi, "IT-PB-001", "Presentasi ke klien di Bandung.", 3, 6).approve(by: bagas)

  # Masih menunggu keputusan Admin Aset.
  ajukan.call(dewi, "IT-LT-001", "Workshop internal tim desain.", 4, 7)
  ajukan.call(sinta, "IT-AC-001", "Rapat gabungan dengan vendor.", 6, 9)

  # Ditolak dan dibatalkan.
  ditolak = ajukan.call(andi, "IT-LP-002", "Dipakai di rumah selama cuti.", 2, 4)
  ditolak.reject(by: bagas, reason: "Peminjaman untuk keperluan pribadi tidak disetujui.")

  dibatalkan = ajukan.call(rina, "IT-AZ-001", "Rekaman podcast internal.", 10, 12)
  dibatalkan.cancel
end

puts "Selesai. #{User.count} pengguna, #{AssetCategory.count} kategori, " \
     "#{Asset.count} aset, #{AssetUnit.count} unit, " \
     "#{BorrowRequest.count} peminjaman, #{HandoverCheck.count} catatan serah-terima."
puts "Masuk dengan bagas@kantor.co.id / rina@kantor.co.id / dewi@kantor.co.id, kata sandi rahasia123."
