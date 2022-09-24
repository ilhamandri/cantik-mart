class ComplainItemsController < ApplicationController
  before_action :require_login
  before_action :screening
  
  def index
    return redirect_back_data_error complains_path unless params[:id].present?
    @complain_items = ComplainItem.page param_page
    @complain_items = @complain_items.where(store: current_user.store) if  !["owner", "super_admin", "finance"].include? current_user.level
    @complain_items = @complain_items.where(complain_id: params[:id])
  end

  private
    def param_page
      params[:page]
    end
end
