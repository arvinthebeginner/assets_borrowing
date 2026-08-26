require "test_helper"

module Admin
  class BorrowRequestsControllerTest < ActionDispatch::IntegrationTest
    setup { @pending = borrow_requests(:laptop_menunggu) }

    test "karyawan tidak boleh membuka antrian" do
      sign_in_as users(:karyawan)

      get admin_borrow_requests_path

      assert_redirected_to root_path
    end

    test "manajer boleh melihat antrian tapi tidak memutuskan" do
      sign_in_as users(:manajer)

      get admin_borrow_requests_path
      assert_response :success

      patch approve_admin_borrow_request_path(@pending)
      assert_redirected_to root_path
      assert_predicate @pending.reload, :pending?
    end

    test "antrian menampilkan pengajuan yang menunggu" do
      sign_in_as users(:admin_aset)

      get admin_borrow_requests_path

      assert_response :success
      assert_select "body", text: /Presentasi ke kantor pusat/
    end

    test "antrian bisa disaring per status" do
      sign_in_as users(:admin_aset)

      get admin_borrow_requests_path(status: "approved")

      assert_response :success
      assert_select "body", text: /Dokumentasi kunjungan klien/
      assert_select "body", text: /Presentasi ke kantor pusat/, count: 0
    end

    test "admin aset bisa menyetujui" do
      sign_in_as users(:admin_aset)

      patch approve_admin_borrow_request_path(@pending)

      assert_redirected_to admin_borrow_requests_path
      assert_predicate @pending.reload, :approved?
      assert_equal users(:admin_aset), @pending.decided_by
    end

    test "admin aset bisa menolak dengan alasan" do
      sign_in_as users(:admin_aset)

      patch reject_admin_borrow_request_path(@pending), params: { rejection_reason: "Dipakai tim lain." }

      assert_redirected_to admin_borrow_requests_path
      assert_predicate @pending.reload, :rejected?
      assert_equal "Dipakai tim lain.", @pending.rejection_reason
    end

    test "penolakan tanpa alasan gagal" do
      sign_in_as users(:admin_aset)

      patch reject_admin_borrow_request_path(@pending), params: { rejection_reason: "" }

      assert_redirected_to admin_borrow_requests_path
      assert_predicate @pending.reload, :pending?
    end

    test "pengajuan yang sudah diputuskan tidak bisa disetujui ulang" do
      sign_in_as users(:admin_aset)
      approved = borrow_requests(:kamera_disetujui)

      patch approve_admin_borrow_request_path(approved)

      assert_redirected_to admin_borrow_requests_path
      assert_equal "Pengajuan ini sudah diproses.", flash[:alert]
    end
  end
end
