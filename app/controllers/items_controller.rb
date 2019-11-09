class ItemsController < ApplicationController
  # before_action :require_login
  # before_action :require_fingerprint
  
  def index
    items = Item.all
    items.each do |item|
      buy = item.buy
      sell = item.sell
      next if sell == buy
      margin = ((sell.to_f-buy.to_f) / buy)*100
      item.margin = margin.ceil.to_i
      item.save!
    end

    @items = Item.page param_page
    if params[:search].present?
      @search = params[:search].downcase
      search = "%"+@search+"%"
      @items = @items.where("lower(name) like ? OR lower(code) like ?", search, search)
    end
    if params[:order_by].present? && params[:order_type].present?
      @order_by = params[:order_by].downcase
      order_type = params[:order_type].upcase
      if order_type == "ASC" 
        @order_type = "menaik (A - Z)"
      else
        @order_type = "menurun (Z - A)"
      end
          
      order = @order_by+" "+order_type
      @items = @items.order(order)
    end
  end

  def show
    return redirect_back_data_error items_path, "Data Barang Tidak Ditemukan" unless params[:id].present?
    @item = Item.find_by_id params[:id]
    return redirect_back_data_error items_path, "Data Barang Tidak Ditemukan" unless @item.present?
    respond_to do |format|
      format.html
      format.pdf do
        Print.create item: @item, store: current_user.store
        return redirect_success items_path, "Data Barang Telah Ditambahkan di Daftar Cetak"
      end
    end
  end

  def new
    @item_cats = ItemCat.all
  end

  def create
    item = Item.new item_params
    item.brand = "-" if params[:item][:brand].nil?
    item.buy = 0
    item.local_item = params[:item][:local_item]
    item.price_updated = DateTime.now
    return redirect_back_data_error new_item_path, "Data Barang Tidak Valid" if item.invalid?
    item.save!
    item.create_activity :create, owner: current_user
    urls = item_path id: item.id
    return redirect_success urls, "Data Barang Berhasil Ditambahkan"

  end

  def edit
    return redirect_back_data_error items_path, "Data Barang Tidak Ditemukan" unless params[:id].present?
    @item = Item.find_by_id params[:id]
    return redirect_back_data_error items_path, "Data Barang Tidak Ditemukan" unless @item.present?
    @item_cats = ItemCat.all
  end

  def update
    return redirect_back_data_error items_path, "Data Barang Tidak Ditemukan" unless params[:id].present?
    item = Item.find_by_id params[:id]
    item.image = params[:item][:image]
    item.assign_attributes item_params
    changes = item.changes
    change = false

    if params[:item][:sell_member].to_i <= 0
      item.sell_member = item.sell
    end

    if changes["margin"].present?
      margin = (item.buy.round * item.margin / 100)
      new_price = item.buy.round + margin 
      new_price = new_price.ceil(-2)
      if new_price <= item.buy
        return redirect_back_data_error item_path(id: item.id), "Silahkan Set Margin Supaya Harga Jual Lebih Besar dari Harga Beli"
      end
      item.sell = new_price
      change = true
    end

    if changes["sell_member"].present?
      if item.sell_member <= item.buy
        return redirect_back_data_error item_path(id: item.id), "Silahkan Set Harga Jual MEMBER Lebih Besar dari Harga Beli"
      end
      change = true if item.sell_member != 0 && item.sell_member != item.sell
    end

    if changes["sell"].present?
      if item.sell <= item.buy
        return redirect_back_data_error item_path(id: item.id), "Silahkan Set Harga Jual Lebih Besar dari Harga Beli"
      end
    end


    if changes["discount"].present?
      new_price = item.sell - (item.sell * item.discount / 100) if item.discount < 100
      new_price = item.sell - (item.sell - item.discount) if item.discount > 100
      if new_price <= item.buy
        return redirect_back_data_error item_path(id: item.id), "Silahkan Set Diskon Supaya Harga Jual Lebih Besar dari Harga Beli"
      end
    end


    if change == true ||changes["sell"].present? || changes["discount"].present?
      item.price_updated = DateTime.now
      to_users = User.where(level: ["owner", "super_admin", "super_visi"])
      Store.all.each do |store|
        Print.create item: item, store: store
      end
      message = "Terdapat perubahan harga. Segera cetak label harga "+item.name
      to_users.each do |to_user|
        set_notification current_user, to_user, "info", message, prints_path
      end
    end
    if item.changed?
      item.save! 
      item.create_activity :edit, owner: current_user, params: changes
    end
    urls = item_path id: item.id
    return redirect_success urls, "Data Barang - " + item.name + " - Berhasil Diubah"
  end

  def destroy
    return redirect_back_data_error items_path, "Data Barang Tidak Ditemukan" unless params[:id].present?
    item = Item.find_by_id params[:id]
    return redirect_back_data_error items_path, "Data Barang Tidak Ditemukan" unless item.present?
    if item.store_items.present? || item.supplier_items.present?
      return redirect_back_data_error items_path, "Data Barang Tidak Valid"
    else
      item.destroy
      return redirect_success items_path, "Data Barang - " + item.name + " - Berhasil Dihapus"
    end
  end

  private
    def item_params
      params.require(:item).permit(
        :name, :code, :item_cat_id, :margin, :brand, :sell, :discount, :local_item, :sell_member
      )
    end

    def param_page
      params[:page]
    end
end
