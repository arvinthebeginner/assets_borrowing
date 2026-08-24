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

  private
    def build_user(**attributes)
      User.new({
        name: "Uji Coba",
        email_address: "uji@kantor.co.id",
        password: "rahasia123"
      }.merge(attributes))
    end
end
