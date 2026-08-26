class BorrowRequestsController < ApplicationController
  before_action :set_asset, only: %i[new create]
  before_action :set_visible_borrow_request, only: :show

  def index
    @borrow_requests = current_user.borrow_requests
                                   .includes(asset_unit: :asset)
                                   .latest_first
  end

  def show
    @handover_checks = @borrow_request.handover_checks.includes(:checked_by).chronological
  end

  def new
    @borrow_request = current_user.borrow_requests.new(
      start_on: params[:start_on], end_on: params[:end_on]
    )
    @available_units = available_units
  end

  def create
    @borrow_request = current_user.borrow_requests.new(borrow_request_params)

    if @borrow_request.save
      redirect_to borrow_requests_path,
        notice: "Pengajuan terkirim. Tunggu persetujuan Admin Aset."
    else
      @available_units = available_units
      render :new, status: :unprocessable_entity
    end
  end

  def cancel
    @borrow_request = current_user.borrow_requests.find(params[:id])

    if @borrow_request.cancel
      redirect_to borrow_requests_path, notice: "Peminjaman dibatalkan."
    else
      redirect_to borrow_requests_path, alert: @borrow_request.errors.full_messages.to_sentence
    end
  end

  private
    # Set peminjaman yang bisa dilihat oleh pengguna saat ini.
    def set_visible_borrow_request
      @borrow_request = BorrowRequest.includes(:user, :decided_by, asset_unit: :asset)
                                     .find(params[:id])

      deny_access unless @borrow_request.user == current_user || current_user.can_view_reports?
    end

    # Set asset yang sedang dipinjam.
    def set_asset
      @asset = Asset.find(params[:asset_id])
    end

    # Daftar unit yang tersedia untuk dipinjam di rentang tanggal yang diminta.
    def available_units
      from = @borrow_request.start_on
      to = @borrow_request.end_on
      return AssetUnit.none if from.blank? || to.blank? || to < from

      @asset.asset_units.available_between(from, to).ordered
    end

    def borrow_request_params
      params.expect(borrow_request: %i[asset_unit_id start_on end_on purpose])
    end
end
