require "test_helper"

class BorrowRequestsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @kamera = assets(:sony_a7)
    @kamera_unit = asset_units(:kamera_satu)
  end

  test "tamu diarahkan ke halaman masuk" do
    get borrow_requests_path

    assert_redirected_to new_session_path
  end

  test "halaman peminjaman saya hanya menampilkan milik sendiri" do
    sign_in_as users(:karyawan)

    get borrow_requests_path

    assert_response :success
    assert_select "article", 2
    assert_select "body", text: /Dokumentasi kunjungan klien/
    assert_select "body", text: /Uji coba perangkat baru/, count: 0
  end

  test "form pengajuan menampilkan unit yang kosong di rentang yang dipilih" do
    sign_in_as users(:karyawan)

    get new_borrow_request_path(asset_id: @kamera.id, start_on: days(9), end_on: days(11))

    assert_response :success
    assert_select "input[type=radio][value=?]", @kamera_unit.id.to_s
  end

  test "form pengajuan tidak menawarkan unit yang sudah dipesan" do
    sign_in_as users(:karyawan)

    get new_borrow_request_path(asset_id: @kamera.id, start_on: days(5), end_on: days(8))

    assert_response :success
    assert_select "input[type=radio]", false
    assert_select "body", text: /Tidak ada unit/
  end

  test "karyawan bisa mengirim pengajuan" do
    sign_in_as users(:karyawan)

    assert_difference -> { BorrowRequest.count }, 1 do
      post borrow_requests_path, params: request_params(start_on: days(9), end_on: days(11))
    end

    assert_redirected_to borrow_requests_path
    assert_predicate BorrowRequest.last, :pending?
    assert_equal users(:karyawan), BorrowRequest.last.user
  end

  test "pengajuan yang bentrok ditolak dan formnya ditampilkan ulang" do
    sign_in_as users(:karyawan)

    assert_no_difference -> { BorrowRequest.count } do
      post borrow_requests_path, params: request_params(start_on: days(6), end_on: days(7))
    end

    assert_response :unprocessable_entity
    assert_select "body", text: /sudah dipesan/
  end

  test "pemilik bisa membuka detail peminjamannya" do
    sign_in_as users(:karyawan)

    get borrow_request_path(borrow_requests(:kamera_disetujui))

    assert_response :success
    assert_select "body", text: /Dokumentasi kunjungan klien/
  end

  test "karyawan lain tidak bisa membuka detail peminjaman orang" do
    sign_in_as users(:karyawan)

    get borrow_request_path(borrow_requests(:laptop_terlambat))

    assert_redirected_to root_path
  end

  test "manajer bisa membuka detail peminjaman siapa pun" do
    sign_in_as users(:manajer)

    get borrow_request_path(borrow_requests(:kamera_disetujui))

    assert_response :success
  end

  test "peminjam bisa membatalkan pengajuannya sendiri" do
    sign_in_as users(:karyawan)
    request = borrow_requests(:laptop_menunggu)

    patch cancel_borrow_request_path(request)

    assert_redirected_to borrow_requests_path
    assert_predicate request.reload, :cancelled?
  end

  test "peminjaman orang lain tidak bisa dibatalkan" do
    sign_in_as users(:karyawan)
    request = borrow_requests(:laptop_terlambat)

    patch cancel_borrow_request_path(request)

    assert_response :not_found
    assert_predicate request.reload, :picked_up?
  end

  private
    def days(count)
      count.days.from_now.to_date.to_s
    end

    def request_params(start_on:, end_on:)
      {
        asset_id: @kamera.id,
        borrow_request: {
          asset_unit_id: @kamera_unit.id, start_on: start_on, end_on: end_on,
          purpose: "Pemotretan produk."
        }
      }
    end
end
