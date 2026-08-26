require "test_helper"

class AssetTest < ActiveSupport::TestCase
  test "model harus unik dalam satu merek" do
    duplicate = Asset.new(asset_category: asset_categories(:laptop),
                          brand: "Apple", model: "MacBook Pro 14 M3")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:model], "sudah terdaftar untuk merek ini"
  end

  test "model yang sama boleh dipakai merek berbeda" do
    other_brand = Asset.new(asset_category: asset_categories(:laptop),
                            brand: "Dell", model: "MacBook Pro 14 M3")

    assert_predicate other_brand, :valid?
  end

  test "nama menggabungkan merek dan model" do
    assert_equal "Apple MacBook Pro 14 M3", assets(:macbook).name
  end

  test "menolak lampiran foto yang bukan gambar" do
    asset = assets(:macbook)
    asset.photo.attach(io: StringIO.new("bukan gambar"), filename: "catatan.txt", content_type: "text/plain")

    assert_not asset.valid?
    assert_includes asset.errors[:photo], "harus berformat PNG, JPEG, atau WebP"
  end

  test "menyaring aset berdasarkan slug kategori" do
    assert_equal [ assets(:sony_a7) ], Asset.in_category("kamera").to_a
  end

  test "slug kosong mengembalikan semua aset" do
    assert_equal Asset.count, Asset.in_category(nil).count
  end

  test "most_borrowed mengurutkan berdasarkan jumlah peminjaman yang jadi" do
    2.times { |index| booking(asset_units(:kamera_satu), 10 + index * 10) }

    top = Asset.most_borrowed

    assert_equal assets(:sony_a7), top.first
    assert_equal 3, top.first.borrow_count # dua di atas + satu dari fixture
  end

  test "most_borrowed tidak menghitung pengajuan yang ditolak atau dibatalkan" do
    booking(asset_units(:kamera_satu), 10, status: :rejected, rejection_reason: "Dipakai tim lain.")
    booking(asset_units(:kamera_satu), 20, status: :cancelled)

    assert_equal 1, Asset.most_borrowed.find { |asset| asset == assets(:sony_a7) }.borrow_count
  end

  private
    def booking(unit, offset, **attributes)
      BorrowRequest.create!({
        user: users(:karyawan), asset_unit: unit, purpose: "Keperluan uji.",
        start_on: offset.days.from_now.to_date, end_on: (offset + 1).days.from_now.to_date,
        status: :approved
      }.merge(attributes))
    end
end
