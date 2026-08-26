module Admin
  class BorrowRequestsController < ApplicationController
    # Manajer boleh melihat antriannya, tapi hanya Admin Aset yang memutuskan.
    before_action :require_reports_access, only: :index
    before_action :require_asset_admin, only: %i[approve reject]
    before_action :set_borrow_request, only: %i[approve reject]

    # Daftar status peminjaman yang bisa dipilih di tab.
    TABS = %w[pending approved picked_up overdue returned rejected cancelled].freeze

    def index
      @tab = TABS.include?(params[:status]) ? params[:status] : "pending"
      @counts = BorrowRequest.group(:status).count.merge("overdue" => BorrowRequest.overdue.count)
      @borrow_requests = requests_for_tab
                           .includes(:user, :decided_by, asset_unit: :asset)
                           .by_start_date
    end

    def approve
      if @borrow_request.approve(by: current_user)
        redirect_back_to_queue notice: "Pengajuan #{@borrow_request.user.name} disetujui."
      else
        redirect_back_to_queue alert: @borrow_request.errors.full_messages.to_sentence
      end
    end

    def reject
      if @borrow_request.reject(by: current_user, reason: params[:rejection_reason])
        redirect_back_to_queue notice: "Pengajuan #{@borrow_request.user.name} ditolak."
      else
        redirect_back_to_queue alert: @borrow_request.errors.full_messages.to_sentence
      end
    end

    private
      def requests_for_tab
        @tab == "overdue" ? BorrowRequest.overdue : BorrowRequest.where(status: @tab)
      end

      def set_borrow_request
        @borrow_request = BorrowRequest.find(params[:id])
      end

      def redirect_back_to_queue(flash_message)
        redirect_to admin_borrow_requests_path, **flash_message
      end
  end
end
