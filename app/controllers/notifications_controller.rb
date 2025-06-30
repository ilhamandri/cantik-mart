class NotificationsController < ApplicationController
  before_action :require_login
  before_action :screening
  

  def index
    
    UpdateData.delete_unused_notification
    
    date_start = DateTime.now - 2.weeks
    date_end = DateTime.now
    @notifications = Notification.where(to_user: current_user, created_at: date_start..date_end ).includes(:from_user).order("date_created DESC")
    @notifications.update_all(read: 0)
    @notifications = @notifications.page param_page
  end

  private
    def param_page
      params[:page]
    end
  
end
