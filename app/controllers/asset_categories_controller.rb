class AssetCategoriesController < ApplicationController
  before_action :require_asset_admin
  before_action :set_asset_category, only: %i[edit update destroy]

  def index
    @asset_categories = AssetCategory.alphabetical.left_joins(:assets)
                                     .group(:id).select("asset_categories.*, COUNT(assets.id) AS assets_count")
  end

  def new
    @asset_category = AssetCategory.new
  end

  def create
    @asset_category = AssetCategory.new(asset_category_params)

    if @asset_category.save
      redirect_to asset_categories_path, notice: "Kategori #{@asset_category.name} ditambahkan."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @asset_category.update(asset_category_params)
      redirect_to asset_categories_path, notice: "Kategori #{@asset_category.name} diperbarui."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @asset_category.destroy
      redirect_to asset_categories_path, notice: "Kategori dihapus.", status: :see_other
    else
      redirect_to asset_categories_path, alert: @asset_category.errors.full_messages.to_sentence,
        status: :see_other
    end
  end

  private
    def set_asset_category
      @asset_category = AssetCategory.find_by!(slug: params[:id])
    end

    def asset_category_params
      params.expect(asset_category: [ :name ])
    end
end
