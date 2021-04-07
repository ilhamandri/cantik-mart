class StocksController < ApplicationController
  before_action :require_login
  
  def index
    filter = filter_search params, "html"
    @search = filter[0]
    @inventories = filter[1]

    @params = params.to_s
    respond_to do |format|
      format.html
      format.pdf do
        new_params = eval(params[:option])
        filter = filter_search new_params, "pdf"
        @search = filter[0]
        @inventories = filter[1]
        @store_name= filter[2]
        render pdf: DateTime.now.to_i.to_s,
          layout: 'pdf_layout.html.erb',
          template: "stocks/print.html.slim"
      end
    end    
  end

  def filter_search params, respond_type
    results = []
    @inventories = StoreItem.all
    @inventories = @inventories.where(store: current_user.store) if !["owner", "super_admin", "super_finance"].include? current_user.level
    @inventories = @inventories.page param_page if respond_type != "pdf"
    @search = ""

    items = nil

    if params[:search].present?
      @search = "Pencarian '"+params[:search]+"'"
      lower_search = params[:search].downcase
      search = "%"+lower_search+"%"
      items = Item.where('lower(name) like ? OR lower(code) like ?', search, search)
      @inventories = @inventories.where(item: items)
    end
    store_name = "SEMUA TOKO"
    if params["store_id"].present?
      store = Store.find_by(id: params["store_id"])
      if store.present?
        @inventories = @inventories.where(store: store)
        @search += "Pencarian " if @search==""
        @search += " di Toko "+store.name
        store_name = store.name
      else
        @search += "Pencarian " if @search==""
        @search += " di Semua Toko" 
      end
    end

    if params["item_cat_id"].present?
      item_cat = ItemCat.find_by(id: params["item_cat_id"])
      if item_cat.present?
        items = Item.all if items.nil?
        items = items.where(item_cat: item_cat)
        @inventories = @inventories.where(item: items)
        @search += "Pencarian " if @search==""
        @search += " pada kategori "+item_cat.name
      else
        @search += "Pencarian " if @search==""
        @search += " pada Semua Kategori"
      end
    end

    results << @search
    results << @inventories
    results << store_name
    return results
  end

  def edit
    return redirect_back_data_error stocks_path, "Data Stok Barang Tidak Ditemukan" unless params[:id].present?
    @stock = StoreItem.find_by_id params[:id]
    return redirect_back_data_error stocks_path, "Data Stok Barang Tidak Ditemukan" unless @stock.present?
    @item = @stock.item
    @item_cats = ItemCat.all
  end

  def update
    return redirect_back_data_error stocks_path, "Data Stok Barang Tidak Ditemukan" unless params[:id].present?
    store_item = StoreItem.find_by_id params[:id]
    item = store_item.item
    curr_stock = store_item.stock
    store_item.assign_attributes edit_stock_params
    store_item.stock = curr_stock if !["super_admin", 'owner', 'stock_admin'].include? current_user.level
    # if ['super_visi'].include? current_user.level
    #   newbuy = params[:item][:buy].to_i
    #   newstock = (params[:item][:stock].to_i - curr_stock).abs
    #   buy_price = newbuy * newstock
    #   stocks = StoreItem.where(item: item).sum(:stock)
    #   old_buy_price = item.buy * curr_stock
    #   new_buy_price = (old_buy_price + buy_price) / (curr_stock + newstock)
    #   item.buy = new_buy_price
    #   item.save!
    # end
    changes = store_item.changes
    store_item.save! if store_item.changed?
    if changes.include? "min_stock"
      if store_item.stock <= store_item.min_stock
        set_notification current_user, current_user, "warning", store_item.item.name + " berada dibawah limit", warning_items_path
      end
    end
    store_item.create_activity :edit, owner: current_user, parameters: changes
    return redirect_success item_path(id: item.id), "Data Stok Barang Berhasil Diubah"
  end

  def show
    return redirect_back_data_error stocks_path, "Data Stok Barang Tidak Ditemukan" unless params[:id].present?
    @stock = StoreItem.find_by_id params[:id]
    return redirect_back_data_error stocks_path, "Data Stok Barang Tidak Ditemukan" unless @stock.present?
    @item = @stock.item
  end

  private
    def stock_params
      {
        stock: params[:item][:stock],
        limit: params[:item][:limit],
        ideal_stock: params[:item][:ideal_stock]
      }
    end

    def edit_stock_params
      {
        stock: params[:item][:stock],
        limit: params[:item][:limit],
        ideal_stock: params[:item][:ideal_stock]
      }
    end

    def param_page
      params[:page]
    end
end
