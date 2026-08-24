module Authorization
  extend ActiveSupport::Concern

  included do
    helper_method :current_user
  end

  private
    def current_user
      Current.user
    end

    def require_asset_admin
      deny_access unless current_user&.asset_admin?
    end

    def require_reports_access
      deny_access unless current_user&.can_view_reports?
    end

    def deny_access
      redirect_to root_path, alert: "Kamu tidak punya akses ke halaman itu."
    end
end
