class AssetCategory < ApplicationRecord
  has_many :assets, dependent: :restrict_with_error

  before_validation :derive_slug

  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true

  scope :alphabetical, -> { order(:name) }

  def to_param
    slug
  end

  def to_s
    name
  end

  private
    # Slug dipakai sebagai parameter filter di katalog (?kategori=laptop),
    # jadi ia mengikuti nama dan tidak perlu diisi manual.
    def derive_slug
      self.slug = name.to_s.parameterize
    end
end
