require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "nama wajib diisi" do
    user = build_user(name: "")

    assert_not user.valid?
    assert_includes user.errors[:name], "can't be blank"
  end

  test "peran default adalah employee" do
    assert_equal "employee", build_user.role
  end

  test "menolak peran di luar daftar" do
    user = build_user(role: "superadmin")

    assert_not user.valid?
    assert_includes user.errors[:role], "is not included in the list"
  end

  test "hanya admin aset dan manajer yang boleh melihat laporan" do
    assert users(:admin_aset).can_view_reports?
    assert users(:manajer).can_view_reports?
    assert_not users(:karyawan).can_view_reports?
  end

  test "most_active_borrowers mengurutkan peminjam berdasarkan jumlah peminjaman" do
    2.times do |index|
      BorrowRequest.create!(user: users(:manajer), asset_unit: asset_units(:kamera_satu),
                            purpose: "Keperluan uji.", status: :approved,
                            start_on: (10 + index * 10).days.from_now.to_date,
                            end_on: (11 + index * 10).days.from_now.to_date)
    end

    top = User.most_active_borrowers

    assert_equal users(:manajer), top.first
    assert_equal 3, top.first.borrow_count # sudah ada 1 peminjaman di fixtures
  end

  private
    def build_user(**attributes)
      User.new({
        name: "Uji Coba",
        email_address: "uji@kantor.co.id",
        password: "rahasia123"
      }.merge(attributes))
    end
end
