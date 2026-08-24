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
end
