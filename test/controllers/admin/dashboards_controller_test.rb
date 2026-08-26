require "test_helper"

module Admin
  class DashboardsControllerTest < ActionDispatch::IntegrationTest
    test "karyawan tidak boleh membuka laporan" do
      sign_in_as users(:karyawan)

      get admin_dashboard_path

      assert_redirected_to root_path
    end

    test "manajer bisa membuka laporan" do
      sign_in_as users(:manajer)

      get admin_dashboard_path

      assert_response :success
      assert_select "h1", "Laporan"
    end

    test "laporan menampilkan peminjaman yang terlambat" do
      sign_in_as users(:admin_aset)

      get admin_dashboard_path

      assert_response :success
      assert_select "body", text: /IT-LP-001 · Rina Wijaya/
      assert_select "body", text: /jatuh tempo/
    end

    test "laporan menampilkan unit yang sedang di luar peredaran" do
      sign_in_as users(:admin_aset)

      get admin_dashboard_path

      assert_response :success
      assert_select "body", text: /IT-LP-002/ # unit fixture berstatus perbaikan
    end
  end
end
