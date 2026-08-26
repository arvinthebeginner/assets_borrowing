class BorrowRequest < ApplicationRecord
  STATUSES = {
    pending: "pending",     # baru diajukan, menunggu admin
    approved: "approved",   # disetujui, unit terkunci untuk rentang ini
    rejected: "rejected",   # ditolak admin
    cancelled: "cancelled", # dibatalkan peminjam
    picked_up: "picked_up", # barang sudah diambil
    returned: "returned"    # barang sudah kembali
  }.freeze

  # Status yang mengunci unit sehingga peminjam lain tidak bisa meminjamnya
  BLOCKING_STATUSES = %w[approved picked_up].freeze

  # Status yang menandakan peminjaman sudah selesai, sehingga bisa dihitung di laporan
  FULFILLED_STATUSES = %w[approved picked_up returned].freeze

  MAX_DURATION_DAYS = 30

  belongs_to :user
  belongs_to :asset_unit
  belongs_to :decided_by, class_name: "User", optional: true

  has_one :asset, through: :asset_unit
  has_many :handover_checks, dependent: :destroy
  has_one :pickup_check, -> { pickup }, class_name: "HandoverCheck", inverse_of: :borrow_request
  has_one :dropoff_check, -> { dropoff }, class_name: "HandoverCheck", inverse_of: :borrow_request

  enum :status, STATUSES, validate: true

  validates :purpose, presence: true, length: { maximum: 500 }
  validates :start_on, presence: true
  validates :end_on, presence: true
  validates :rejection_reason, presence: true, if: :rejected?
  validate :end_on_not_before_start_on
  validate :duration_within_limit
  validate :unit_must_be_free, if: :conflict_check_needed?

  scope :blocking, -> { where(status: BLOCKING_STATUSES) }
  scope :fulfilled, -> { where(status: FULFILLED_STATUSES) }
  scope :overlapping, ->(from, to) { where("start_on <= ? AND end_on >= ?", to, from) }
  scope :overdue, -> { picked_up.where(end_on: ...Date.current) }
  scope :latest_first, -> { order(created_at: :desc) }
  scope :by_start_date, -> { order(:start_on) }

  # Peminjaman lain yang mengunci unit yang sama di rentang tanggal yang sama
  def conflicting_requests
    self.class.where(asset_unit_id: asset_unit_id)
              .blocking
              .overlapping(start_on, end_on)
              .where.not(id: id)
  end

  # Menandai peminjaman ini sudah disetujui oleh admin
  def approve(by:)
    transaction do
      lock!

      unless pending?
        errors.add(:base, "Pengajuan ini sudah diproses.")
        next false
      end

      assign_attributes(status: :approved, decided_by: by, decided_at: Time.current)
      save
    end
  end

  def reject(by:, reason:)
    transaction do
      lock!

      unless pending?
        errors.add(:base, "Pengajuan ini sudah diproses.")
        next false
      end

      assign_attributes(status: :rejected, decided_by: by, decided_at: Time.current,
                        rejection_reason: reason)
      save
    end
  end

  def cancel
    unless cancellable?
      errors.add(:base, "Peminjaman ini tidak bisa dibatalkan lagi.")
      return false
    end

    update(status: :cancelled)
  end

  def cancellable?
    pending? || approved?
  end

  # Jenis serah terima berikutnya yang harus dilakukan, atau `nil` kalau tidak ada.
  def next_handover_kind
    return "pickup" if approved?
    return "dropoff" if picked_up?

    nil
  end

  def blocking?
    BLOCKING_STATUSES.include?(status)
  end

  def overdue?
    picked_up? && end_on.before?(Date.current)
  end

  def duration_days
    return 0 unless dates_ordered?

    (end_on - start_on).to_i + 1
  end

  private
    def dates_ordered?
      start_on.present? && end_on.present? && end_on >= start_on
    end

    def end_on_not_before_start_on
      return if start_on.blank? || end_on.blank?

      errors.add(:end_on, "tidak boleh lebih awal dari tanggal mulai") if end_on < start_on
    end

    def duration_within_limit
      return unless dates_ordered?

      if duration_days > MAX_DURATION_DAYS
        errors.add(:end_on, "membuat peminjaman lebih dari #{MAX_DURATION_DAYS} hari")
      end
    end

    # apakah perlu memeriksa bentrok dengan peminjaman lain? Tidak perlu kalau tanggal belum diisi, atau kalau tidak ada perubahan yang relevan.
    def conflict_check_needed?
      return false unless dates_ordered?

      new_record? || asset_unit_id_changed? || start_on_changed? || end_on_changed? ||
        (status_changed? && blocking?)
    end

    def unit_must_be_free
      return if asset_unit.blank?

      unless asset_unit.available?
        errors.add(:asset_unit, "sedang tidak bisa dipinjam")
        return
      end

      if conflicting_requests.exists?
        errors.add(:base, "Unit #{asset_unit.asset_tag} sudah dipesan pada rentang tanggal itu.")
      end
    end
end
