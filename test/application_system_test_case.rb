require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # Testing memakai driver rack_test
  driven_by :rack_test

  private
    def masuk_sebagai(user)
      visit new_session_path
      fill_in "email_address", with: user.email_address
      fill_in "password", with: "rahasia123"
      click_on "Masuk"
    end

    def keluar
      click_on "Keluar"
    end
end
