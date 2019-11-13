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
    
    respond_to do |format|
      format.html
      format.xlsx do
        filename = "./report/opname/"+DateTime.now.to_i.to_s+".xlsx"
        p = Axlsx::Package.new
        wb = p.workbook

        wb.add_worksheet(:name => "OPNAME") do |sheet|
          items = StoreItem.where(store: current_user.store).where("stock < 0")
          sheet.add_row ["Kode", "Nama", "STOK SISTEM", "OPNAME"]
          items.each do |store_item|
            item = store_item.item
            sheet.add_row [item.code, item.name, store_item.stock]
          end
        end

        p.serialize(filename)
        send_file(filename)
      end
    end
  end

  def opname
  end

  def update_stock
    binding.pry
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
