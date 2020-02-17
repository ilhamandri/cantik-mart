class ItemSuppliersController < ApplicationController
  before_action :require_login
  before_action :require_fingerprint
  def index
    return redirect_back_data_error suppliers_path unless params[:id].present?
    @suppliers = SupplierItem.page param_page
    @item = Item.find_by_id params[:id]
    return redirect_back_data_error suppliers_path unless @item.present?
    @suppliers = @suppliers.where(item_id: @item.id)
    if params[:search].present?
      @search = params[:search].downcase
      search = "%"+@search+"%"
      supplier = Supplier.where('lower(name) like ?', search).pluck(:id)
      @suppliers = @inventories.where(supplier_id: supplier)
    end
  end

  private
    def param_page
      params[:page]
    end
end
