class StocksController < ApplicationController
  before_action :require_login
  before_action :screening
  
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
    if item.local_item
      item.sell = params[:item][:sell]
      item.margin = (((item.sell-item.buy)/item.buy)*100).to_i
      item.save!
    end
    changes = store_item.changes
    if store_item.changed?
      store_item.edited_by = current_user
      store_item.save!
      store_item.save! 
    end
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
        ideal_stock: params[:item][:ideal_stock],
        sell: params[:item][:sell]
      }
    end

    def edit_stock_params
      {
        stock: params[:item][:stock],
        limit: params[:item][:limit],
        ideal_stock: params[:item][:ideal_stock],
        sell: params[:item][:sell]
      }
    end

    def param_page
      params[:page]
    end
end
