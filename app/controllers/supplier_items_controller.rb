class SupplierItemsController < ApplicationController
  before_action :require_login
  before_action :require_fingerprint
  def index
    return redirect_back_data_error suppliers_path, "Data Barang Suplier Tidak Ditemukan" unless params[:id].present?
    @supplier = Supplier.find_by_id params[:id]
    @order_items = OrderItem.where(order: Order.where(supplier: @supplier).pluck(:id))
    if params[:search].present?
      @search = "Pencarian '" + params[:search].downcase + "'"
      search = "%"+@search+"%"
      items = Item.where('lower(name) like ? OR lower(code) like ?', search, search).pluck(:id)
      @order_items = @order_items.where(item_id: items)
    end
    @order_items = @order_items.select(:item_id, :quantity).page param_page
    @inventories = @order_items.group(:item_id).sum(:quantity)
    @inventories = @inventories.sort_by(&:last).reverse
    

    respond_to do |format|
      format.html
      format.pdf do
        @order_items = OrderItem.where(order: Order.where(supplier: @supplier).pluck(:id)).select(:item_id, :quantity)
        @inventories = @order_items.group(:item_id).sum(:quantity)
        @inventories = @inventories.sort_by(&:last).reverse
        render pdf: DateTime.now.to_i.to_s,
          layout: 'pdf_layout.html.erb',
          template: "supplier_items/print.html.slim"
      end
    end
  end

  private
    def supplier_item_params
      params.require(:supplier_item).permit(
        :item_id
      )
    end

    def param_page
      params[:page]
    end
end
