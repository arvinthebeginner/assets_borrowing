module Admin
  class DashboardsController < ApplicationController
    before_action :require_reports_access

    def show
      @unit_counts = AssetUnit.group(:status).count
      @request_counts = BorrowRequest.group(:status).count

      @active_units = @unit_counts.except("retired").values.sum
      @units_in_hand = @request_counts.fetch("picked_up", 0)
      @utilization = percentage(@units_in_hand, @active_units)

      @overdue = BorrowRequest.overdue.includes(:user, asset_unit: :asset).by_start_date
      @most_borrowed = Asset.most_borrowed
      @top_borrowers = User.most_active_borrowers
      @units_out_of_service = AssetUnit.where.not(status: :available).includes(:asset).ordered
    end

    private
      def percentage(part, total)
        return 0 if total.zero?

        (part * 100.0 / total).round
      end
  end
end
