class ItemsController < ApplicationController
  before_action :require_login
  before_action :require_fingerprint
  require 'apriori'
  
  def index
    # items = Item.all
    # items.each do |item|
    #   buy = item.buy
    #   sell = item.sell
    #   next if sell == 0 || buy == 0
    #   margin = ((sell.to_f-buy.to_f) / buy)*100
    #   item.margin = margin.ceil.to_i
    #   item.save!
    # end

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
    code = params[:item][:code]
    exist = Item.find_by(code: code)

    return redirect_back_data_error new_item_path, "Kode  "+code.to_s+" telah terdaftar." if exist.present?
    return redirect_back_data_error new_item_path, "Silahkan cek kembali harga beli dan harga jual" if params[:item][:buy].to_i == 0 || params[:item][:sell].to_i == 0
    item = Item.new item_params
    item.code = code.gsub(" ", "")
    item.brand = "-" if params[:item][:brand].nil?
    item.buy = params[:item][:buy]
    item.sell = params[:item][:sell]
    item.local_item = params[:item][:local_item]
    item.price_updated = DateTime.now
    item.margin = 100*((item.sell - item.buy) / item.buy)
    return redirect_back_data_error new_item_path, "Data Barang Tidak Valid" if item.invalid?
    item.save!
    Store.all.each do |store|
      a = StoreItem.create item: item, stock: 0, store: store
    end
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
    code = params[:item][:code].gsub(" ","")
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
        return redirect_back_data_error item_path(id: item.id), "Silahkan Set Ulang Margin Supaya Harga JUAL Lebih Besar dari Harga Beli"
      end
      item.sell = new_price
      change = true
    end

    if changes["sell_member"].present?
      if item.sell_member <= item.buy
        return redirect_back_data_error item_path(id: item.id), "Silahkan Ulang Set Harga Jual MEMBER Lebih Besar dari Harga Beli"
      end
      change = true if item.sell_member != 0 && item.sell_member != item.sell
    end


    if changes["discount"].present?
      new_price = item.sell - (item.sell * item.discount / 100) if item.discount < 100
      new_price = item.sell - item.discount if item.discount > 100
      if new_price <= item.buy
        return redirect_back_data_error item_path(id: item.id), "Silahkan Ulang Set DISKON Supaya Harga Jual Lebih Besar dari Harga Beli"
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


    if changes["sell"].present?
      if item.sell <= item.buy
        return redirect_back_data_error item_path(id: item.id), "Silahkan Set Harga Jual Lebih Besar dari Harga Beli"
      end
      margin = ( (item.sell - item.buy ) / item.buy) * 100;
      item.margin = margin
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

  def refresh_predict
    data_item = []
    data = []
    trxs = Transaction.where("created_at >= ?", DateTime.now.beginning_of_day-120.days)
    trxs.each do |trx|
      trx_items_id = trx.transaction_items.pluck(:item_id)
      item_cats_id = Item.where(id: trx_items_id).pluck(:item_cat_id)
      data_item << trx_items_id
      data << item_cats_id
    end
    # data = [[1,2,3,4], [1,2,4,5], [2,3,4,5]]
    item_set = Apriori::ItemSet.new(data_item)
    item_cat_set = Apriori::ItemSet.new(data)
    support = 1
    confidence = 1
    minings_item = item_set.mine(support, confidence)
    minings_item.each do |mining|
      percentage = mining[1]
      items = mining[0].split("=>")
      buy = Item.find_by(id: items[0])
      usually = Item.find_by(id: items[1])
      predict = PredictItem.find_by(buy: buy, usually: usually)
      if predict.present?
        predict.percentage = percentage
        predict.save!
      else
        predict = PredictItem.create percentage: percentage, buy: buy, usually: usually
      end
    end

    minings_item_cats = item_cat_set.mine(support, confidence)
    minings_item_cats.each do |mining|
      percentage = mining[1]
      items = mining[0].split("=>")
      buy = ItemCat.find_by(id: items[0])
      usually = ItemCat.find_by(id: items[1])
      predict_cat = PredictCategory.find_by(buy: buy, usually: usually)
      if predict_cat.present?
        predict_cat.percentage = percentage
        predict_cat.save!
      else
        predict_cat = PredictCategory.create percentage: percentage, buy: buy, usually: usually
      end
    end

    return redirect_success predict_item_path, "Refresh Prediksi Item Selesai" 
  end

  def predict
    @predicts = PredictItem.order("percentage DESC").page param_page
    @predicts_cat = PredictCategory.order("percentage DESC").page param_page
  end

  private
    def item_params
      params.require(:item).permit(
        :name, :code, :item_cat_id, :margin, :brand, :sell, :discount, :local_item, :sell_member, :buy
      )
    end

    def item_params_edit
      params.require(:item).permit(
        :name, :code, :item_cat_id, :margin, :brand, :sell, :discount, :local_item, :sell_member
      )
    end

    def param_page
      params[:page]
    end
end
