require "test_helper"

class BorrowRequestTest < ActiveSupport::TestCase
  setup do
    @kamera = asset_units(:kamera_satu)
    @booked = borrow_requests(:kamera_disetujui) 
  end

  test "pengajuan yang wajar tersimpan" do
    request = build_request(start_on: days(1), end_on: days(2))

    assert request.valid?, request.errors.full_messages.to_sentence
    assert_predicate request, :pending?
  end

  test "keperluan wajib diisi" do
    request = build_request(start_on: days(1), end_on: days(2), purpose: " ")

    assert_not request.valid?
    assert_includes request.errors[:purpose], "can't be blank"
  end

  test "tanggal selesai tidak boleh mendahului tanggal mulai" do
    request = build_request(start_on: days(3), end_on: days(1))

    assert_not request.valid?
    assert_includes request.errors[:end_on], "tidak boleh lebih awal dari tanggal mulai"
  end

  test "durasi dibatasi 30 hari" do
    laptop = asset_units(:macbook_satu) 
    assert build_request(unit: laptop, start_on: days(1), end_on: days(30)).valid?

    request = build_request(unit: laptop, start_on: days(1), end_on: days(31))
    assert_not request.valid?
    assert_includes request.errors[:end_on], "membuat peminjaman lebih dari 30 hari"
  end

  test "durasi dihitung inklusif" do
    assert_equal 1, build_request(start_on: days(1), end_on: days(1)).duration_days
    assert_equal 4, @booked.duration_days
  end

  # Deteksi bentrok

  test "rentang yang persis sama dengan peminjaman disetujui ditolak" do
    assert_conflict build_request(start_on: days(5), end_on: days(8))
  end

  test "tumpang tindih di awal ditolak" do
    assert_conflict build_request(start_on: days(3), end_on: days(6))
  end

  test "tumpang tindih di akhir ditolak" do
    assert_conflict build_request(start_on: days(7), end_on: days(10))
  end

  test "rentang yang menelan peminjaman lain ditolak" do
    assert_conflict build_request(start_on: days(1), end_on: days(12))
  end

  test "rentang yang berada di dalam peminjaman lain ditolak" do
    assert_conflict build_request(start_on: days(6), end_on: days(7))
  end

  test "bersinggungan tepat di hari terakhir ditolak" do
    assert_conflict build_request(start_on: days(8), end_on: days(9))
  end

  test "bersinggungan tepat di hari pertama ditolak" do
    assert_conflict build_request(start_on: days(4), end_on: days(5))
  end

  test "berdekatan tapi tidak bersinggungan diterima" do
    assert_predicate build_request(start_on: days(2), end_on: days(4)), :valid?
    assert_predicate build_request(start_on: days(9), end_on: days(11)), :valid?
  end

  test "pengajuan berstatus menunggu tidak memblokir orang lain" do
    pending_request = borrow_requests(:laptop_menunggu)
    rival = build_request(unit: pending_request.asset_unit,
                          start_on: pending_request.start_on, end_on: pending_request.end_on)

    assert rival.valid?, rival.errors.full_messages.to_sentence
  end

  test "status yang sudah selesai tidak memblokir" do
    %w[rejected cancelled returned].each do |status|
      @booked.update_column(:status, status)

      request = build_request(start_on: days(5), end_on: days(8))
      assert request.valid?, "status #{status} seharusnya tidak memblokir"
    end
  end

  test "unit yang sedang perbaikan tidak bisa dipinjam" do
    request = build_request(unit: asset_units(:macbook_dua), start_on: days(1), end_on: days(2))

    assert_not request.valid?
    assert_includes request.errors[:asset_unit], "sedang tidak bisa dipinjam"
  end

  test "peminjaman sendiri tidak dihitung sebagai bentrok saat disimpan ulang" do
    @booked.purpose = "Keperluan diperbarui."

    assert @booked.valid?, @booked.errors.full_messages.to_sentence
  end

  # Scope

  test "scope blocking hanya berisi disetujui dan sedang dipinjam" do
    assert_equal %w[approved picked_up].to_set, BorrowRequest.blocking.pluck(:status).to_set
  end

  test "scope overdue hanya berisi yang sudah lewat tanggal kembali" do
    assert_includes BorrowRequest.overdue, borrow_requests(:laptop_terlambat)
    assert_not_includes BorrowRequest.overdue, @booked
    assert_predicate borrow_requests(:laptop_terlambat), :overdue?
    assert_not_predicate @booked, :overdue?
  end

  test "unit yang sudah dipesan hilang dari daftar ketersediaan" do
    assert_not_includes AssetUnit.available_between(days(5), days(8)), @kamera
    assert_includes AssetUnit.available_between(days(9), days(11)), @kamera
  end

  test "unit berstatus perbaikan tidak pernah muncul di daftar ketersediaan" do
    assert_not_includes AssetUnit.available_between(days(1), days(2)), asset_units(:macbook_dua)
  end

  # Persetujuan

  test "persetujuan mencatat siapa dan kapan" do
    request = borrow_requests(:laptop_menunggu)
    admin = users(:admin_aset)

    assert request.approve(by: admin)
    assert_predicate request.reload, :approved?
    assert_equal admin, request.decided_by
    assert_not_nil request.decided_at
  end

  test "persetujuan ditolak kalau unit keburu dipesan orang lain" do
    admin = users(:admin_aset)
    duluan = create_request(start_on: days(20), end_on: days(22))
    belakangan = create_request(start_on: days(21), end_on: days(23))

    assert duluan.approve(by: admin)
    assert_not belakangan.approve(by: admin)
    assert_predicate belakangan.reload, :pending?
    assert_match(/sudah dipesan/, belakangan.errors.full_messages.to_sentence)
  end

  test "pengajuan yang sudah diproses tidak bisa disetujui lagi" do
    assert_not @booked.approve(by: users(:admin_aset))
    assert_includes @booked.errors[:base], "Pengajuan ini sudah diproses."
  end

  test "penolakan wajib menyertakan alasan" do
    request = borrow_requests(:laptop_menunggu)

    assert_not request.reject(by: users(:admin_aset), reason: " ")
    assert_predicate request.reload, :pending?

    assert request.reject(by: users(:admin_aset), reason: "Dipakai tim lain.")
    assert_predicate request.reload, :rejected?
    assert_equal "Dipakai tim lain.", request.rejection_reason
  end

  # Pembatalan

  test "peminjaman menunggu dan disetujui bisa dibatalkan" do
    assert borrow_requests(:laptop_menunggu).cancel
    assert @booked.cancel
    assert_predicate @booked.reload, :cancelled?
  end

  test "peminjaman yang sedang berjalan tidak bisa dibatalkan" do
    request = borrow_requests(:laptop_terlambat)

    assert_not request.cancel
    assert_predicate request.reload, :picked_up?
    assert_includes request.errors[:base], "Peminjaman ini tidak bisa dibatalkan lagi."
  end

  private
    def days(count)
      count.days.from_now.to_date
    end

    def build_request(start_on:, end_on:, unit: @kamera, user: users(:karyawan), **attributes)
      BorrowRequest.new({
        user: user, asset_unit: unit, purpose: "Keperluan uji.",
        start_on: start_on, end_on: end_on
      }.merge(attributes))
    end

    def create_request(**attributes)
      build_request(unit: asset_units(:macbook_satu), **attributes).tap(&:save!)
    end

    def assert_conflict(request)
      assert_not request.valid?, "rentang #{request.start_on}–#{request.end_on} seharusnya bentrok"
      assert_match(/sudah dipesan/, request.errors.full_messages.to_sentence)
    end
end
