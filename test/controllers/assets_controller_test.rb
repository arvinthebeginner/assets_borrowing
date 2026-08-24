require "test_helper"

class AssetsControllerTest < ActionDispatch::IntegrationTest
  test "tamu diarahkan ke halaman masuk" do
    get assets_path

    assert_redirected_to new_session_path
  end

  test "karyawan bisa melihat katalog" do
    sign_in_as users(:karyawan)

    get assets_path

    assert_response :success
    assert_select "h1", "Katalog aset"
  end

  test "katalog bisa disaring per kategori" do
    sign_in_as users(:karyawan)

    get assets_path(kategori: "kamera")

    assert_response :success
    assert_select "h2", "Sony Alpha 7 IV"
    assert_select "h2", { text: "Apple MacBook Pro 14 M3", count: 0 }
  end

  test "karyawan bisa melihat detail aset beserta unitnya" do
    sign_in_as users(:karyawan)

    get asset_path(assets(:macbook))

    assert_response :success
    assert_select "td", "IT-LP-001"
  end

  test "admin aset bisa membuka form tambah dan ubah aset" do
    sign_in_as users(:admin_aset)

    get new_asset_path
    assert_response :success

    get edit_asset_path(assets(:macbook))
    assert_response :success
    assert_select "input[name=?][value=?]", "asset[brand]", "Apple"
  end

  test "karyawan tidak boleh membuka form tambah aset" do
    sign_in_as users(:karyawan)

    get new_asset_path

    assert_redirected_to root_path
  end

  test "karyawan tidak boleh membuat aset" do
    sign_in_as users(:karyawan)

    assert_no_difference -> { Asset.count } do
      post assets_path, params: { asset: valid_params }
    end
    assert_redirected_to root_path
  end

  test "admin aset bisa membuat aset" do
    sign_in_as users(:admin_aset)

    assert_difference -> { Asset.count }, 1 do
      post assets_path, params: { asset: valid_params }
    end
    assert_redirected_to Asset.last
  end

  test "aset dengan data tidak lengkap tidak tersimpan" do
    sign_in_as users(:admin_aset)

    assert_no_difference -> { Asset.count } do
      post assets_path, params: { asset: valid_params.merge(model: "") }
    end
    assert_response :unprocessable_entity
  end

  test "menghapus aset ikut menghapus unitnya" do
    sign_in_as users(:admin_aset)

    assert_difference -> { AssetUnit.count }, -2 do
      delete asset_path(assets(:macbook))
    end
    assert_redirected_to assets_path
  end

  private
    def valid_params
      { asset_category_id: asset_categories(:laptop).id, brand: "Dell", model: "XPS 13" }
    end
end
