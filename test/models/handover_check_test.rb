require "test_helper"

class HandoverCheckTest < ActiveSupport::TestCase
  setup do
    @admin = users(:admin_aset)
    @disetujui = borrow_requests(:kamera_disetujui)  # kamera_satu, belum diambil
    @dipinjam = borrow_requests(:laptop_terlambat)   # macbook_satu, sudah diambil
  end

  test "pengambilan memindahkan peminjaman ke sedang dipinjam" do
    check = record(@disetujui, kind: :pickup, condition: :minor_damage)

    assert_predicate @disetujui.reload, :picked_up?
    assert_equal check.checked_at, @disetujui.picked_up_at
    assert_predicate @disetujui.asset_unit.reload, :minor_damage?
  end

  test "pengambilan tidak mengubah status unit" do
    record(@disetujui, kind: :pickup, condition: :good)

    assert_predicate @disetujui.asset_unit.reload, :available?
  end

  test "waktu pemeriksaan terisi otomatis" do
    check = record(@disetujui, kind: :pickup, condition: :good)

    assert_not_nil check.checked_at
    assert_equal @admin, check.checked_by
  end

  test "pengambilan hanya untuk peminjaman yang sudah disetujui" do
    check = build(borrow_requests(:laptop_menunggu), kind: :pickup, condition: :good)

    assert_not check.valid?
    assert_includes check.errors[:base],
      "Pengambilan hanya bisa dicatat untuk peminjaman yang sudah disetujui."
  end

  test "pengambilan tidak bisa dicatat dua kali" do
    record(@disetujui, kind: :pickup, condition: :good)
    kedua = build(@disetujui.reload, kind: :pickup, condition: :good)

    assert_not kedua.valid?
    assert_includes kedua.errors[:kind], "sudah pernah dicatat untuk peminjaman ini"
  end

  test "pengembalian tidak bisa mendahului pengambilan" do
    check = build(@disetujui, kind: :dropoff, condition: :good)

    assert_not check.valid?
    assert_includes check.errors[:base],
      "Pengembalian hanya bisa dicatat untuk barang yang sedang dipinjam."
  end

  test "pengembalian menutup peminjaman" do
    check = record(@dipinjam, kind: :dropoff, condition: :good)

    assert_predicate @dipinjam.reload, :returned?
    assert_equal check.checked_at, @dipinjam.returned_at
    assert_not_predicate @dipinjam, :overdue?
  end

  test "pengembalian dalam kondisi rusak memindahkan unit ke perbaikan" do
    unit = @dipinjam.asset_unit

    record(@dipinjam, kind: :dropoff, condition: :damaged)

    assert_predicate unit.reload, :maintenance?
    assert_predicate unit, :damaged?
    assert_not_includes AssetUnit.available_between(Date.current, 3.days.from_now.to_date), unit
  end

  test "pengembalian dalam kondisi hilang memindahkan unit ke tidak dipakai" do
    unit = @dipinjam.asset_unit

    record(@dipinjam, kind: :dropoff, condition: :lost)

    assert_predicate unit.reload, :retired?
    assert_predicate unit, :lost?
  end

  test "pengembalian dalam kondisi baik mengembalikan unit ke tersedia" do
    unit = @dipinjam.asset_unit
    unit.update!(status: :maintenance, condition: :minor_damage)

    record(@dipinjam, kind: :dropoff, condition: :good)

    assert_predicate unit.reload, :available?
    assert_predicate unit, :good?
  end

  test "jenis serah-terima harus dikenali" do
    check = build(@disetujui, kind: "titip", condition: :good)

    assert_not check.valid?
    assert_includes check.errors[:kind], "is not included in the list"
  end

  test "catatan dibatasi 500 karakter" do
    check = build(@disetujui, kind: :pickup, condition: :good, notes: "a" * 501)

    assert_not check.valid?
  end

  private
    def build(borrow_request, **attributes)
      borrow_request.handover_checks.new({ checked_by: @admin }.merge(attributes))
    end

    def record(borrow_request, **attributes)
      build(borrow_request, **attributes).tap(&:save!)
    end
end
