class ItemsController < ApplicationController
  include ActionView::Helpers::NumberHelper
  before_action :require_login
  require 'apriori'
  
  def index
    @items = Item.all
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
    @items = @items.page param_page
  end

  def item_recaps
    item = Item.find_by(id: params[:id])
    return redirect_back_data_error items_path, "Item tidak ditemukan" if item.nil?
    start_params = params[:date_start]
    end_params = params[:date_end]
    return redirect_back_data_error item_path(id: item.id), "Silahkan cek tanggal kembali" if start_params.empty? || end_params.empty? 
    date_from = start_params.to_date
    date_to = end_params.to_date
    dates = []
    buy_sell = []
    (date_from..date_to).each { |date| dates << date}
    dates.each do |date| 
      buy_sell << [date, 0, 0]
    end
    dates.each_with_index do |date, idx| 
      buy = OrderItem.where(item: item, created_at: date.beginning_of_day..date.end_of_day).sum(:receive)
      sell = TransactionItem.where(item: item, created_at: date.beginning_of_day..date.end_of_day).sum(:quantity)
      buy_sell[idx][1] = buy
      buy_sell[idx][2] = sell
    end
    @buy_sell = buy_sell
    @description = "Rekap jual-beli " + item.name.upcase + " ( " + date_from.to_s + " ... " + date_to.to_s + " )"

    filename = "./report/item/" + "ITEM-" + DateTime.now.to_i.to_s + ".xlsx"
    
    order_item = OrderItem.where(item: item).last
    supplier = "-"
    harga_beli = "-"
    if order_item.present?
      order = order_item.order
      supplier = order.supplier.name
      harga_beli = number_with_delimiter(order_item.price, delimiter: ".")
    end
    
    p = Axlsx::Package.new
    wb = p.workbook 
    
    wb.add_worksheet(:name => "INFO")do |sheet|
      sheet.add_row ["Dekripsi", @description]
      sheet.add_row ["Suplier", supplier]
      sheet.add_row ["Harga Beli Terakhir", harga_beli]

    end
    
    wb.add_worksheet(:name => "TRX") do |sheet|
      sheet.add_row ["Tanggal", "Order", "Terjual"]
      @buy_sell.each do |buy_sell|
        d = buy_sell[0].to_date.strftime("%d / %m / %y")
        b = buy_sell[1]
        s = buy_sell[2]
        sheet.add_row [d,b,s]
      end
    end

    p.serialize(filename)
    send_file(filename)
  end

  def show
    return redirect_back_data_error items_path, "Data Barang Tidak Ditemukan" unless params[:id].present?
    @item = Item.find_by_id params[:id]
    return redirect_back_data_error items_path, "Data Barang Tidak Ditemukan" unless @item.present?
    @suppliers = SupplierItem.where(item: @item)

    # @bundlings = PredictCategory.where(buy: @item.item_cat).order("percentage DESC").limit(10)
    losses = Loss.where(id: LossItem.where(item: @item).pluck(:loss_id)).where("created_at >= ?", DateTime.now-13.months).group_by { |m| m.created_at.beginning_of_month }
    store_items = @item.store_items
    # if store_items.count != Store.all.count
    #   Store.all.each do |store|
    #     if store_items.find_by(store: store).nil?
    #       StoreItem.create item: @item, store: store
    #     end
    #   end
    # end
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
        buy += order_item.receive.to_i
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

    # calculate_kpi @item
    respond_to do |format|
      format.html
      format.pdf do
        Print.create item: @item, store: current_user.store
        return redirect_success items_path, "Data Barang Telah Ditambahkan di Daftar Cetak"
      end
    end

    @loss_ids = LossItem.where(item: @item).pluck(:loss_id).uniq
    @losses = Loss.where(id: @loss_ids)

    @retur_ids = ReturItem.where(item: @item).pluck(:retur_id).uniq
    @returs = Retur.where(id: @retur_ids)
  end

  def calculate_kpi item
    date_end = DateTime.now
    order_3months = OrderItem.where(item: item, created_at: (DateTime.now-3.months)..date_end).sum(:receive).to_f
    order_6months = OrderItem.where(item: item, created_at: (DateTime.now-6.months)..date_end).sum(:receive).to_f

    sell_3months = TransactionItem.where(item: item, created_at: (DateTime.now-3.months)..date_end).sum(:quantity).to_f
    sell_6months = TransactionItem.where(item: item, created_at: (DateTime.now-6.months)..date_end).sum(:quantity).to_f

    kpi_3month = 0.01
    kpi_6month = 0.01
    kpi_3month = (sell_3months / order_3months) * 100 if order_3months > 0 && sell_3months > 0
    kpi_6month = (sell_6months / order_6months) * 100 if order_6months > 0 && sell_6months > 0
    
    kpi = (kpi_3month*0.75) + (kpi_6month*0.25) 
    item.kpi = kpi.ceil(2)
    item.save!
  end

  def new
    @item_cats = ItemCat.all
  end

  def create
    code = params[:item][:code]
    exist = Item.find_by(code: code)

    return redirect_back_data_error new_item_path, "Kode  "+code.to_s+" telah terdaftar." if exist.present?
    item = Item.new item_params
    item.code = code.gsub(" ", "")
    item.brand = "-" if params[:item][:brand].nil?
    item.buy = 0
    item.sell = 0
    item.local_item = params[:item][:local_item]
    item.price_updated = DateTime.now
    item.margin = params[:item][:margin]

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
    item.sell = params[:item][:sell].gsub(".","").to_f
    changes = item.changes
    item.sell_member = item.sell

    if item.discount < 100
      item.discount = item.buy * item.discount / 100.0
    end

    base_price = item.buy - item.discount  
    price_before_tax = base_price + (base_price*item.margin/100.0)
    item.ppn = price_before_tax * item.tax / 100.0
    item.selisih_pembulatan = item.sell - price_before_tax - item.ppn
    item.save!

    if changes["sell"].present?
      item.price_updated = DateTime.now
      to_users = User.where(level: ["owner", "super_admin", "super_visi"])
      Store.all.each do |store|
        Print.create item: item, store: store
      end
      message = "Terdapat perubahan harga. Segera cetak label harga "+item.name
      to_users.each do |to_user|
        set_notification current_user, to_user, "info", message, prints_path
      end

      ItemPrice.create item: item, buy: item.buy, sell: item.sell, month: Date.today.month.to_i, year: Date.today.year.to_i
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
    trxs = Transaction.where("created_at >= ?", DateTime.now.beginning_of_day-30.days)
    trxs.each do |trx|
      trx_items_id = trx.transaction_items.pluck(:item_id)
      item_cats_id = Item.where(id: trx_items_id).pluck(:item_cat_id)
      # data_item << trx_items_id
      data << item_cats_id
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
      next if items[1] == 134 || items[0] == 134
      usually = ItemCat.find_by(id: items[1])
      predict_cat = PredictCategory.find_by(buy: buy, usually: usually)
      if predict_cat.present?
        predict_cat.percentage = ( percentage.to_f + predict_cat.percentage) / 2
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
        :name, :code, :item_cat_id, :margin, :brand, :sell, :discount, :local_item, :buy
      )
    end

    def item_params_edit
      params.require(:item).permit(
        :name, :code, :item_cat_id, :margin, :brand, :sell, :discount, :local_item
      )
    end

    def param_page
      params[:page]
    end

    def param_loss_page
      params[:loss_page]
    end
end
