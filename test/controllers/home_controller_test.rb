require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "tamu diarahkan ke halaman masuk" do
    get root_path

    assert_redirected_to new_session_path
  end

  test "pengguna yang sudah masuk melihat beranda" do
    sign_in_as users(:karyawan)

    get root_path

    assert_response :success
    assert_select "h1", /Dewi Lestari/
  end
end
