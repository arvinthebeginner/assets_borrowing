class User < ApplicationRecord
  ROLES = {
    employee: "employee",       # mengajukan peminjaman
    asset_admin: "asset_admin", # menyetujui, mengelola aset, serah-terima
    manager: "manager"          # melihat laporan
  }.freeze

  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :borrow_requests, dependent: :restrict_with_error

  enum :role, ROLES, validate: true

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :name, presence: true

  # Manajer ikut melihat halaman admin yang bersifat baca-saja (dashboard).
  def can_view_reports?
    asset_admin? || manager?
  end

  def to_s
    name
  end
end
