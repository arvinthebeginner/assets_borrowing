class Asset < ApplicationRecord
  PHOTO_CONTENT_TYPES = %w[image/png image/jpeg image/webp].freeze
  PHOTO_MAX_SIZE = 5.megabytes

  belongs_to :asset_category
  has_many :asset_units, dependent: :destroy

  has_one_attached :photo

  validates :brand, presence: true
  validates :model, presence: true,
    uniqueness: { scope: :brand, message: "sudah terdaftar untuk merek ini" }
  validate :photo_must_be_a_reasonable_image

  scope :alphabetical, -> { order(:brand, :model) }
  # Unit yang paling sering dipinjam, diurutkan dari yang terbanyak.
  scope :most_borrowed, ->(limit = 5) {
    joins(asset_units: :borrow_requests)
      .where(borrow_requests: { status: BorrowRequest::FULFILLED_STATUSES })
      .group(:id)
      .select("assets.*, COUNT(borrow_requests.id) AS borrow_count")
      .order(Arel.sql("COUNT(borrow_requests.id) DESC"), :brand, :model)
      .limit(limit)
  }

  scope :in_category, ->(slug) {
    slug.present? ? joins(:asset_category).where(asset_categories: { slug: slug }) : all
  }

  def name
    "#{brand} #{model}"
  end
  alias to_s name

  private
    # Rails tidak punya validator bawaan untuk Active Storage, jadi ditulis manual.
    def photo_must_be_a_reasonable_image
      return unless photo.attached?

      unless PHOTO_CONTENT_TYPES.include?(photo.content_type)
        errors.add(:photo, "harus berformat PNG, JPEG, atau WebP")
      end

      if photo.byte_size > PHOTO_MAX_SIZE
        errors.add(:photo, "maksimal 5 MB")
      end
    end
end
