class AssetUnit < ApplicationRecord
  STATUSES = {
    available: "available",     # boleh dipinjam
    maintenance: "maintenance", # sedang diperbaiki
    retired: "retired"          # sudah tidak dipakai / hilang
  }.freeze

  CONDITIONS = {
    good: "good",
    minor_damage: "minor_damage",
    damaged: "damaged",
    lost: "lost"
  }.freeze

  belongs_to :asset

  enum :status, STATUSES, validate: true
  enum :condition, CONDITIONS, validate: true

  normalizes :asset_tag, with: ->(tag) { tag.strip.upcase }
  normalizes :serial_number, with: ->(sn) { sn.strip.upcase }

  validates :asset_tag, presence: true, uniqueness: true
  validates :serial_number, presence: true, uniqueness: true

  scope :ordered, -> { order(:asset_tag) }

  def to_s
    asset_tag
  end
end
