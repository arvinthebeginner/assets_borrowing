class HandoverChecksController < ApplicationController
  before_action :require_asset_admin
  before_action :set_borrow_request

  def new
    kind = @borrow_request.next_handover_kind

    if kind.nil?
      redirect_to @borrow_request, alert: "Tidak ada serah-terima yang perlu dicatat."
      return
    end

    @handover_check = @borrow_request.handover_checks.new(
      kind: kind, condition: @borrow_request.asset_unit.condition
    )
  end

  def create
    @handover_check = @borrow_request.handover_checks.new(handover_check_params)
    @handover_check.checked_by = current_user

    if @handover_check.save
      redirect_to @borrow_request, notice: confirmation_message
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def set_borrow_request
      @borrow_request = BorrowRequest.find(params[:borrow_request_id])
    end

    def handover_check_params
      params.expect(handover_check: %i[kind condition notes])
    end

    def confirmation_message
      unit = @borrow_request.asset_unit.reload

      if @handover_check.pickup?
        "Pengambilan dicatat. Unit #{unit.asset_tag} dipegang #{@borrow_request.user.name}."
      else
        "Pengembalian dicatat. Unit #{unit.asset_tag} sekarang berstatus " \
          "#{t("asset_unit.statuses.#{unit.status}").downcase}."
      end
    end
end
