class HandoverCheck < ApplicationRecord
  KINDS = {
    pickup: "pickup",   # barang diserahkan ke peminjam
    dropoff: "dropoff"  # barang dikembalikan ke Admin Aset
  }.freeze

  belongs_to :borrow_request
  belongs_to :checked_by, class_name: "User"

  delegate :asset_unit, to: :borrow_request

  enum :kind, KINDS, validate: true
  enum :condition, AssetUnit::CONDITIONS, validate: true

  validates :notes, length: { maximum: 500 }
  validates :kind, uniqueness: {
    scope: :borrow_request_id, message: "sudah pernah dicatat untuk peminjaman ini"
  }
  validate :borrow_request_must_be_ready

  before_validation :stamp_checked_at, on: :create
  after_create :apply_to_borrow_request_and_unit

  scope :chronological, -> { order(:checked_at) }

  private
    def stamp_checked_at
      self.checked_at ||= Time.current
    end

    def borrow_request_must_be_ready
      return if borrow_request.blank? || kind.blank?

      if pickup? && !borrow_request.approved?
        errors.add(:base, "Pengambilan hanya bisa dicatat untuk peminjaman yang sudah disetujui.")
      elsif dropoff? && !borrow_request.picked_up?
        errors.add(:base, "Pengembalian hanya bisa dicatat untuk barang yang sedang dipinjam.")
      end
    end

    # Update status peminjaman dan unit sesuai jenis serah terima dan kondisi unit.
    def apply_to_borrow_request_and_unit
      if pickup?
        borrow_request.update!(status: :picked_up, picked_up_at: checked_at)
      else
        borrow_request.update!(status: :returned, returned_at: checked_at)
      end

      asset_unit.update!(condition: condition, status: unit_status_after_check)
    end

    # Kalau serah terima adalah pengambilan, status unit tidak berubah. 
    # Kalau serah terima adalah pengembalian, status unit tergantung kondisi unit.
    def unit_status_after_check
      return asset_unit.status if pickup?

      case condition
      when "damaged" then "maintenance"
      when "lost" then "retired"
      else "available"
      end
    end
end
