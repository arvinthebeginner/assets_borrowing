require "application_system_test_case"

# Alur peminjaman aset dari awal sampai akhir, termasuk pengajuan, 
# persetujuan, pencatatan pengambilan dan pengembalian, serta laporan.
class BorrowFlowTest < ApplicationSystemTestCase
  setup do
    @unit = asset_units(:kamera_satu)
    @start_on = 30.days.from_now.to_date
    @end_on = 32.days.from_now.to_date
    @purpose = "Pemotretan katalog untuk demo."
  end

  test "karyawan mengajukan, admin menyetujui, mencatat ambil dan kembali" do
    masuk_sebagai users(:karyawan)

    click_on "Sony Alpha 7 IV"
    click_on "Ajukan peminjaman"

    fill_in "start_on", with: @start_on
    fill_in "end_on", with: @end_on
    click_on "Cek ketersediaan"

    assert_text "1 unit tersedia"
    assert_text @unit.asset_tag

    fill_in "Keperluan", with: @purpose
    click_on "Ajukan peminjaman"

    assert_text "Pengajuan terkirim"
    assert_text "Menunggu"
    keluar

    masuk_sebagai users(:admin_aset)
    click_on "Antrian"

    within "article", text: @purpose do
      click_on "Setujui"
    end
    assert_text "disetujui"

    click_on "Disetujui"
    within "article", text: @purpose do
      click_on "Catat pengambilan"
    end

    choose "Baik"
    click_on "Simpan catatan pengambilan"
    assert_text "Pengambilan dicatat"
    assert_text "Sedang dipinjam"

    click_on "Catat pengembalian"
    choose "Rusak"
    fill_in "Catatan", with: "Lensa tergores saat pemotretan."
    click_on "Simpan catatan pengembalian"

    assert_text "Pengembalian dicatat"
    assert_text "Dikembalikan"
    assert_predicate @unit.reload, :maintenance?

    # Unit yang masuk perbaikan tidak lagi ditawarkan di rentang tanggal mana pun.
    click_on "Katalog"
    click_on "Sony Alpha 7 IV"
    click_on "Ajukan peminjaman"
    fill_in "start_on", with: 60.days.from_now.to_date
    fill_in "end_on", with: 61.days.from_now.to_date
    click_on "Cek ketersediaan"

    assert_text "Tidak ada unit"
  end

  test "manajer melihat laporan" do
    masuk_sebagai users(:manajer)

    click_on "Laporan"

    assert_text "Aset paling sering dipinjam"
    assert_text "Peminjaman terlambat"
    assert_text "Unit di luar peredaran"
  end
end
