class AssetsController < ApplicationController
  before_action :require_asset_admin, except: %i[index show]
  before_action :set_asset, only: %i[show edit update destroy]

  def index
    @categories = AssetCategory.alphabetical
    @category = @categories.find_by(slug: params[:kategori])
    @assets = Asset.in_category(params[:kategori])
                   .includes(:asset_category, :asset_units, photo_attachment: :blob)
                   .alphabetical
  end

  def show
    @asset_units = @asset.asset_units.ordered
  end

  def new
    @asset = Asset.new
  end

  def create
    @asset = Asset.new(asset_params)

    if @asset.save
      redirect_to @asset, notice: "Aset #{@asset.name} ditambahkan."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @asset.update(asset_params)
      redirect_to @asset, notice: "Aset #{@asset.name} diperbarui."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @asset.destroy
    redirect_to assets_path, notice: "Aset #{@asset.name} dihapus.", status: :see_other
  end

  private
    def set_asset
      @asset = Asset.find(params[:id])
    end

    def asset_params
      params.expect(asset: %i[asset_category_id brand model description photo])
    end
end
