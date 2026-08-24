require "test_helper"

class AssetCategoriesControllerTest < ActionDispatch::IntegrationTest
  test "karyawan tidak boleh membuka daftar kategori" do
    sign_in_as users(:karyawan)

    get asset_categories_path

    assert_redirected_to root_path
    assert_equal "Kamu tidak punya akses ke halaman itu.", flash[:alert]
  end

  test "manajer juga tidak boleh mengelola kategori" do
    sign_in_as users(:manajer)

    get asset_categories_path

    assert_redirected_to root_path
  end

  test "admin aset melihat daftar kategori beserta jumlah asetnya" do
    sign_in_as users(:admin_aset)

    get asset_categories_path

    assert_response :success
    assert_select "td", "Laptop"
  end

  test "admin aset bisa menambah kategori" do
    sign_in_as users(:admin_aset)

    assert_difference -> { AssetCategory.count }, 1 do
      post asset_categories_path, params: { asset_category: { name: "Proyektor" } }
    end
    assert_redirected_to asset_categories_path
    assert_equal "proyektor", AssetCategory.last.slug
  end

  test "admin aset bisa membuka form tambah dan ubah kategori" do
    sign_in_as users(:admin_aset)

    get new_asset_category_path
    assert_response :success

    get edit_asset_category_path(asset_categories(:laptop))
    assert_response :success
    assert_select "input[name=?][value=?]", "asset_category[name]", "Laptop"
  end

  test "kategori yang masih dipakai tidak bisa dihapus" do
    sign_in_as users(:admin_aset)

    assert_no_difference -> { AssetCategory.count } do
      delete asset_category_path(asset_categories(:laptop))
    end
    assert_redirected_to asset_categories_path
    assert_predicate flash[:alert], :present?
  end
end
