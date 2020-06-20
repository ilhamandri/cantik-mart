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
    @suppliers = SupplierItem.where(item: @item)

    @bundlings = PredictCategory.where(buy: @item.item_cat).order("percentage DESC").limit(10)
    losses = Loss.where(id: LossItem.where(item: @item).pluck(:loss_id)).where("created_at >= ?", DateTime.now-13.months).group_by { |m| m.created_at.beginning_of_month }

    @item = Item.find_by_id params[:id]
    graphs_buy_sell = {}
    graphs_losses = {}
    13.times do |i|
      date = Date.today - i.month
      month = date.strftime("%B %Y")
      graphs_buy_sell[month] = [0,0,0,0,0]
      graphs_losses[month] = 0
    end
    @losses = graphs_losses
    losses.each do |r_loss|
      month = r_loss.first.to_date.strftime("%B %Y")
      loss_items = LossItem.where(loss_id: r_loss.second.pluck(:id), item: @item).sum(:quantity)
      graphs_losses[month] = loss_items
    end
    gon.loss_vals = graphs_losses.values.reverse
    raw_trx_items = TransactionItem.where(item: @item).where("created_at >= ?", DateTime.now-13.months).group_by { |m| m.created_at.beginning_of_month }
    raw_trx_items.each do |trx_items|
      month = trx_items.first.to_date.strftime("%B %Y")
      sell = 0
      trx_items[1].each do |trx_item|
        sell += trx_item.quantity.to_i
      end
      next if graphs_buy_sell[month].nil?
      graphs_buy_sell[month] = [0, sell, 0,0,0]
    end

    raw_order_items = OrderItem.where(item: @item).where("created_at >= ?", DateTime.now-13.months).group_by { |m| m.created_at.beginning_of_month }
    raw_order_items.each do |order_items|
      month = order_items.first.to_date.strftime("%B %Y")
      buy = 0
      order_items[1].each do |order_item|
        buy += order_item.quantity.to_i
      end
      data = graphs_buy_sell[month]
      next if graphs_buy_sell[month].nil?
      data[0] = buy
      graphs_buy_sell[month] = data
    end

    raw_prices = ItemPrice.where(item: @item).where("created_at >= ?", DateTime.now-13.months).group(:month, :year).average(:buy)
    raw_prices.each do |item_price|
      month = Date::MONTHNAMES[item_price[0][0]] + " " + item_price[0][1].to_s
      b = item_price[1]

      next if graphs_buy_sell[month].nil?
      data = graphs_buy_sell[month]
      data[2] = b
      graphs_buy_sell[month] = data
    end

    raw_prices = ItemPrice.where(item: @item).where("created_at >= ?", DateTime.now-13.months).group(:month, :year).average(:sell)
    raw_prices.each do |item_price|
      month = Date::MONTHNAMES[item_price[0][0]] + " " + item_price[0][1].to_s
      s = item_price[1]

      next if graphs_buy_sell[month].nil?
      data = graphs_buy_sell[month]
      data[3] = s
      graphs_buy_sell[month] = data
    end

    gon.month = graphs_buy_sell.keys.reverse

    graphs_buy_sell_val = graphs_buy_sell.values
    sell = graphs_buy_sell_val.collect{|ind| ind[1]}.reverse
    gon.sell = sell
    buy = graphs_buy_sell_val.collect{|ind| ind[0]}.reverse
    gon.buy = graphs_buy_sell_val.collect{|ind| ind[0]}.reverse 
    
    b_prices = graphs_buy_sell_val.collect{|ind| ind[2]}.reverse
    before = 0
    b_prices.each_with_index do |price, idx|
      if price == 0
        b_prices[idx] = before
      else
        before = price
      end
    end
    gon.buy_price = b_prices
    
    s_prices = graphs_buy_sell_val.collect{|ind| ind[3]}.reverse
    before = 0
    s_prices.each_with_index do |price, idx|
      if price == 0
        s_prices[idx] = before
      else
        before = price
      end
    end
    gon.sell_price = s_prices

    @buy_sell = graphs_buy_sell

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

    ItemPrice.create item: item, buy: item.buy, sell: item.sell, month: Date.today.month.to_i, year: Date.today.year.to_i, created_at: DateTime.now - 1.month
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
      # if item.sell <= item.buy
      #   return redirect_back_data_error item_path(id: item.id), "Silahkan Set Harga Jual Lebih Besar dari Harga Beli"
      # end
      margin = ( (item.sell - item.buy ) / item.buy) * 100;
      item.margin = margin
    end
    
    if item.changed?
      ItemPrice.create item: item, buy: item.buy, sell: item.sell, month: Date.today.month.to_i, year: Date.today.year.to_i
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
    trx_items = TransactionItem.where("created_at >= ?", DateTime.now.beginning_of_day-1.days)
    trx_items.each do |trx_item|
      # data_item << trx_item.id
      data << trx_item.item.item_cat.id
    end
    # data = [[1,2,3,4], [1,2,4,5], [2,3,4,5]]
    # item_set = Apriori::ItemSet.new(data_item)
    item_cat_set = Apriori::ItemSet.new(data)
    support = 1
    confidence = 1
    # minings_item = item_set.mine(support, confidence)
    # minings_item.each do |mining|
    #   percentage = mining[1]
    #   items = mining[0].split("=>")
    #   buy = Item.find_by(id: items[0])
    #   usually = Item.find_by(id: items[1])
    #   predict = PredictItem.find_by(buy: buy, usually: usually)
    #   if predict.present?
    #     predict.percentage = percentage
    #     predict.save!
    #   else
    #     predict = PredictItem.create percentage: percentage, buy: buy, usually: usually
    #   end
    # end

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

    def param_loss_page
      params[:loss_page]
    end
end
