require "test_helper"

# Skenario integrasi untuk alur peminjaman lengkap: ajukan, setujui, ambil, lalu kembalikan.
class BorrowCycleTest < ActionDispatch::IntegrationTest
  setup do
    @asset = assets(:sony_a7)
    @unit = asset_units(:kamera_satu)
    @start_on = 20.days.from_now.to_date
    @end_on = 22.days.from_now.to_date
  end

  test "ajukan, setujui, ambil, lalu kembalikan dalam kondisi rusak" do
    sign_in_as users(:karyawan)

    get new_borrow_request_path(asset_id: @asset.id, start_on: @start_on, end_on: @end_on)
    assert_select "input[type=radio][value=?]", @unit.id.to_s

    assert_difference -> { BorrowRequest.count }, 1 do
      post borrow_requests_path, params: {
        asset_id: @asset.id,
        borrow_request: {
          asset_unit_id: @unit.id, start_on: @start_on, end_on: @end_on,
          purpose: "Pemotretan produk untuk katalog."
        }
      }
    end

    borrow_request = BorrowRequest.last
    assert_predicate borrow_request, :pending?

    sign_in_as users(:admin_aset)
    patch approve_admin_borrow_request_path(borrow_request)
    assert_predicate borrow_request.reload, :approved?

    # Setelah disetujui, unitnya terkunci untuk rentang itu.
    sign_in_as users(:manajer)
    get new_borrow_request_path(asset_id: @asset.id, start_on: @start_on, end_on: @end_on)
    assert_select "input[type=radio][value=?]", @unit.id.to_s, count: 0

    sign_in_as users(:admin_aset)
    post borrow_request_handover_checks_path(borrow_request),
      params: { handover_check: { kind: "pickup", condition: "good", notes: "Baterai dua." } }
    assert_predicate borrow_request.reload, :picked_up?
    assert_predicate @unit.reload, :available?

    post borrow_request_handover_checks_path(borrow_request),
      params: { handover_check: { kind: "dropoff", condition: "damaged", notes: "Lensa tergores." } }
    assert_predicate borrow_request.reload, :returned?
    assert_predicate @unit.reload, :maintenance?

    # Unit yang masuk perbaikan tidak lagi ditawarkan, bahkan di tanggal kosong.
    sign_in_as users(:karyawan)
    get new_borrow_request_path(asset_id: @asset.id,
          start_on: 40.days.from_now.to_date, end_on: 41.days.from_now.to_date)
    assert_select "input[type=radio]", false

    assert_equal 2, borrow_request.handover_checks.count
  end
end
