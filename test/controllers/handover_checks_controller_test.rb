require "test_helper"

class HandoverChecksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @disetujui = borrow_requests(:kamera_disetujui)
    @dipinjam = borrow_requests(:laptop_terlambat)
  end

  test "karyawan tidak boleh mencatat serah-terima" do
    sign_in_as users(:karyawan)

    get new_borrow_request_handover_check_path(@disetujui)
    assert_redirected_to root_path

    assert_no_difference -> { HandoverCheck.count } do
      post borrow_request_handover_checks_path(@disetujui),
        params: { handover_check: { kind: "pickup", condition: "good" } }
    end
    assert_redirected_to root_path
  end

  test "manajer juga tidak boleh mencatat serah-terima" do
    sign_in_as users(:manajer)

    get new_borrow_request_handover_check_path(@disetujui)

    assert_redirected_to root_path
  end

  test "form pengambilan terbuka untuk peminjaman yang disetujui" do
    sign_in_as users(:admin_aset)

    get new_borrow_request_handover_check_path(@disetujui)

    assert_response :success
    assert_select "input[name=?][value=?]", "handover_check[kind]", "pickup"
  end

  test "form pengembalian terbuka untuk barang yang sedang dipinjam" do
    sign_in_as users(:admin_aset)

    get new_borrow_request_handover_check_path(@dipinjam)

    assert_response :success
    assert_select "input[name=?][value=?]", "handover_check[kind]", "dropoff"
  end

  test "peminjaman yang belum disetujui tidak punya form serah-terima" do
    sign_in_as users(:admin_aset)
    menunggu = borrow_requests(:laptop_menunggu)

    get new_borrow_request_handover_check_path(menunggu)

    assert_redirected_to menunggu
    assert_equal "Tidak ada serah-terima yang perlu dicatat.", flash[:alert]
  end

  test "admin aset bisa mencatat pengambilan" do
    sign_in_as users(:admin_aset)

    assert_difference -> { HandoverCheck.count }, 1 do
      post borrow_request_handover_checks_path(@disetujui),
        params: { handover_check: { kind: "pickup", condition: "good", notes: "Charger lengkap." } }
    end

    assert_redirected_to @disetujui
    assert_predicate @disetujui.reload, :picked_up?
  end

  test "pengembalian rusak memindahkan unit ke perbaikan" do
    sign_in_as users(:admin_aset)
    unit = @dipinjam.asset_unit

    post borrow_request_handover_checks_path(@dipinjam),
      params: { handover_check: { kind: "dropoff", condition: "damaged", notes: "Engsel patah." } }

    assert_redirected_to @dipinjam
    assert_predicate @dipinjam.reload, :returned?
    assert_predicate unit.reload, :maintenance?
  end

  test "kondisi wajib dipilih" do
    sign_in_as users(:admin_aset)

    assert_no_difference -> { HandoverCheck.count } do
      post borrow_request_handover_checks_path(@disetujui),
        params: { handover_check: { kind: "pickup", condition: "" } }
    end

    assert_response :unprocessable_entity
  end
end
