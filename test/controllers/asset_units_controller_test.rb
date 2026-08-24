require "test_helper"

class AssetUnitsControllerTest < ActionDispatch::IntegrationTest
  setup { @asset = assets(:macbook) }

  test "karyawan tidak boleh menambah unit" do
    sign_in_as users(:karyawan)

    assert_no_difference -> { AssetUnit.count } do
      post asset_asset_units_path(@asset), params: { asset_unit: valid_params }
    end
    assert_redirected_to root_path
  end

  test "admin aset bisa menambah unit" do
    sign_in_as users(:admin_aset)

    assert_difference -> { AssetUnit.count }, 1 do
      post asset_asset_units_path(@asset), params: { asset_unit: valid_params }
    end
    assert_redirected_to @asset
  end

  test "admin aset bisa membuka form tambah dan ubah unit" do
    sign_in_as users(:admin_aset)

    get new_asset_asset_unit_path(@asset)
    assert_response :success

    get edit_asset_asset_unit_path(@asset, asset_units(:macbook_satu))
    assert_response :success
    assert_select "input[name=?][value=?]", "asset_unit[asset_tag]", "IT-LP-001"
  end

  test "tag aset ganda ditolak" do
    sign_in_as users(:admin_aset)

    assert_no_difference -> { AssetUnit.count } do
      post asset_asset_units_path(@asset), params: { asset_unit: valid_params.merge(asset_tag: "IT-LP-001") }
    end
    assert_response :unprocessable_entity
  end

  test "admin aset bisa memindahkan unit ke status perbaikan" do
    sign_in_as users(:admin_aset)
    unit = asset_units(:macbook_satu)

    patch asset_asset_unit_path(@asset, unit), params: { asset_unit: { status: "maintenance" } }

    assert_redirected_to @asset
    assert_predicate unit.reload, :maintenance?
  end

  test "unit dari aset lain tidak bisa diubah lewat aset ini" do
    sign_in_as users(:admin_aset)
    unit = asset_units(:kamera_satu)

    patch asset_asset_unit_path(@asset, unit), params: { asset_unit: { status: "retired" } }

    assert_response :not_found
    assert_predicate unit.reload, :available?
  end

  private
    def valid_params
      { asset_tag: "IT-LP-050", serial_number: "SN-MBP-050", status: "available", condition: "good" }
    end
end
