require "test_helper"

class AssetCategoryTest < ActiveSupport::TestCase
  test "slug dibuat otomatis dari nama" do
    category = AssetCategory.create!(name: "Proyektor & Layar")

    assert_equal "proyektor-layar", category.slug
  end

  test "slug ikut berubah ketika nama diubah" do
    category = asset_categories(:laptop)
    category.update!(name: "Laptop Kantor")

    assert_equal "laptop-kantor", category.slug
  end

  test "nama harus unik" do
    duplicate = AssetCategory.new(name: "Laptop")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  test "kategori yang masih punya aset tidak bisa dihapus" do
    category = asset_categories(:laptop)

    assert_no_difference -> { AssetCategory.count } do
      assert_not category.destroy
    end
    assert_predicate category.errors[:base], :any?
  end
end
