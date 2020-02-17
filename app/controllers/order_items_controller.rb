class OrderItemsController < ApplicationController
  before_action :require_login
  before_action :require_fingerprint
  def index
  end

  private
    def param_page
      params[:page]
    end
end
