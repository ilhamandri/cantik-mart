class WarningItemsController < ApplicationController
  before_action :require_login
  before_action :require_fingerprint

  def index
    @inventories = StoreItem.page param_page
    store_id = current_user.store.id
    @inventories = @inventories.where(store_id: store_id).where('stock < min_stock')
    if params[:search].present?
      @search = params[:search].downcase
      search = "%"+@search+"%"
      items = Item.where('lower(name) like ? OR code like ?', search, search).pluck(:id)
      @inventories = @inventories.where(item_id: items)
    end
    @ongoing_orders = Order.where('date_receive is null and date_paid_off is null')
  end

  private
    def stock_params
      {
        stock: params[:item][:stock][:stock]
      }
    end

    def param_page
      params[:page]
    end
end
