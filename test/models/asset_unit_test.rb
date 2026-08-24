require "test_helper"

class AssetUnitTest < ActiveSupport::TestCase
  test "tag aset harus unik" do
    duplicate = build_unit(asset_tag: "IT-LP-001")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:asset_tag], "has already been taken"
  end

  test "nomor seri harus unik" do
    duplicate = build_unit(serial_number: "SN-MBP-001")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:serial_number], "has already been taken"
  end

  test "tag dan nomor seri dinormalkan ke huruf kapital tanpa spasi tepi" do
    unit = build_unit(asset_tag: "  it-lp-999  ", serial_number: " sn-x-999 ")

    assert_equal "IT-LP-999", unit.asset_tag
    assert_equal "SN-X-999", unit.serial_number
  end

  test "unit baru berstatus tersedia dan berkondisi baik" do
    unit = AssetUnit.new

    assert_predicate unit, :available?
    assert_predicate unit, :good?
  end

  test "menolak status di luar daftar" do
    unit = build_unit(status: "hilang-entah-kemana")

    assert_not unit.valid?
    assert_includes unit.errors[:status], "is not included in the list"
  end

  private
    def build_unit(**attributes)
      AssetUnit.new({
        asset: assets(:macbook),
        asset_tag: "IT-LP-100",
        serial_number: "SN-MBP-100"
      }.merge(attributes))
    end
end
