class ItemsController < ApplicationController
  include ActionView::Helpers::NumberHelper
  before_action :require_login
  before_action :screening
  require 'apriori'
  
  def index
    UpdateData.updateStockCandyDream
    UpdateData.updateDuplicateItem
    @search = params[:search]
    s = "%#{@search}%".upcase
    @items = Item.where("name like ? OR code like ?", s, s).order(name: :asc).includes(:item_cat, :item_cat => :department).page param_page
  end

  def item_recaps
    item = Item.find_by(id: params[:id])
    return redirect_back_data_error items_path, "Item tidak ditemukan" if item.nil?
    start_params = params[:date_start]
    end_params = params[:date_end]
    return redirect_back_data_error item_path(id: item.id), "Silahkan cek tanggal kembali" if start_params.empty? || end_params.empty? 
    date_from = start_params.to_date
    date_to = end_params.to_date
    datas = {}
    stores = Store.all
    stores = [current_user.store] if current_user.level == "super_visi"
    stores.each do |store|
      datas[store.name] = Serve.item_trx_order item, store, date_from, date_to
    end

    description = "Rekap jual-beli " + item.name.upcase + " ( " + date_from.to_s + " ... " + date_to.to_s + " )"

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
      sheet.add_row ["Dekripsi", description]
      sheet.add_row ["Suplier", supplier]
      sheet.add_row ["Harga Beli Terakhir", harga_beli]

    end

    datas.each do |store_name, data|
      wb.add_worksheet(:name => store_name) do |sheet|
        sheet.add_row ["Tanggal", "Order", "Terjual"]
        data.each do |buy_sell|
          d = buy_sell[0]
          b = buy_sell[1]
          s = buy_sell[2]
          sheet.add_row [d,b,s]
        end
      end
    end
    
    p.serialize(filename)
    send_file(filename)
  end

  def show
    return redirect_back_data_error items_path, "Data Barang Tidak Ditemukan" unless params[:id].present?
    @item = Item.find_by_id params[:id]
    return redirect_back_data_error items_path, "Data Barang Tidak Ditemukan" unless @item.present?
    suppliers_id = SupplierItem.where(item: @item).pluck(:supplier_id).uniq
    @suppliers = Supplier.where(id: suppliers_id)


    # @bundlings = PredictCategory.where(buy: @item.item_cat).order("percentage DESC").limit(10)
    losses = Loss.where(id: LossItem.where(item: @item).pluck(:loss_id)).where("created_at >= ?", DateTime.now-13.months).group_by { |m| m.created_at.beginning_of_month }
    store_items = @item.store_items
    
    loss_items = Serve.loss_item_graph_monthly dataFilter, @item
    gon.loss_label = loss_items["label"]
    gon.loss_item = loss_items["loss_item"]

    transaction_order = Serve.graph_item_order_sell dataFilter, @item
    gon.label = transaction_order["label"]
    gon.order = transaction_order["order"]
    gon.transaction = transaction_order["transaction"]

    item_prices = Serve.graph_item_price @item
    gon.price_label = item_prices["label"]
    gon.buy = item_prices["buy"]
    gon.sell = item_prices["sell"]

    # calculate_kpi @item
    respond_to do |format|
      format.html
      format.pdf do
        exist = Print.find_by(item: @item)
        if exist.nil?
          Print.create item: @item, store: current_user.store
          return redirect_success items_path, "Data Barang Telah Ditambahkan di Daftar Cetak"
        end
        return redirect_back_data_error items_path, "Data Barang Sudah Ada di Daftar Cetak"
      end
    end

    @loss_ids = LossItem.where(item: @item).pluck(:loss_id).uniq
    @losses = Loss.where(id: @loss_ids)

    @retur_ids = ReturItem.where(item: @item).pluck(:retur_id).uniq
    @returs = Retur.where(id: @retur_ids)
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
    item.edited_by = current_user
    item.name = item.name.upcase

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
    item.name = item.name.upcase
    code = params[:item][:code].gsub(" ","")
    item.assign_attributes item_params
    item.sell = params[:item][:sell].gsub(".","").to_f
    item.price_before = params[:item][:sell_normal].gsub(".","").to_f
    changes = item.changes
    item.sell_member = item.sell

    if item.discount < 100
      item.discount = item.buy * item.discount / 100.0
    end

    item.ppn = item.sell - ((item.sell) / ((item.tax/100.0)+1))
    item.selisih_pembulatan = item.sell - (((item.sell) / ((item.tax/100.0)+1)) + item.ppn)
    item.save!

    item.grocer_items.each do |grocer_item|
      grocer_item.price = item.sell + item.discount - grocer_item.discount
      grocer_item.ppn = grocer_item.price - ((grocer_item.price) / ((item.tax/100.0)+1))
      grocer_item.selisih_pembulatan = grocer_item.price - (((grocer_item.price) / ((item.tax/100.0)+1)) + grocer_item.ppn)
      grocer_item.save!
    end

    item.edited_by = current_user
    item.save!

    if changes["sell"].present?
      item.price_updated = DateTime.now
      to_users = User.where(level: ["owner", "super_admin", "super_visi"])
      Store.all.each do |store|
        Print.create item: item, store: store
      end
      message = "Harga SATUAN - "+item.name
      to_users.each do |to_user|
        set_notification current_user, to_user, "primary", message, prints_path
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
