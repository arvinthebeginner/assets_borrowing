class AssetUnitsController < ApplicationController
  before_action :require_asset_admin
  before_action :set_asset
  before_action :set_asset_unit, only: %i[edit update destroy]

  def new
    @asset_unit = @asset.asset_units.new
  end

  def create
    @asset_unit = @asset.asset_units.new(asset_unit_params)

    if @asset_unit.save
      redirect_to @asset, notice: "Unit #{@asset_unit.asset_tag} ditambahkan."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @asset_unit.update(asset_unit_params)
      redirect_to @asset, notice: "Unit #{@asset_unit.asset_tag} diperbarui."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @asset_unit.destroy
    redirect_to @asset, notice: "Unit #{@asset_unit.asset_tag} dihapus.", status: :see_other
  end

  private
    def set_asset
      @asset = Asset.find(params[:asset_id])
    end

    def set_asset_unit
      @asset_unit = @asset.asset_units.find(params[:id])
    end

    def asset_unit_params
      params.expect(asset_unit: %i[asset_tag serial_number status condition notes])
    end
end
