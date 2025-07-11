require 'chunky_png'
require 'barby'
require 'barby/barcode/code_128'    
require 'barby/outputter/png_outputter'  

include ActionView::Helpers::NumberHelper
class OrdersController < ApplicationController
  before_action :require_login
  before_action :screening
  
  def index
    filter = filter_search params, "html"
    @search = filter[0]
    @orders = filter[1]
    @params = params.to_s

    orders = Serve.order_graph_monthly dataFilter, nil
    gon.loss_label = orders["label"]
    gon.order = orders["order"]
    gon.order_nominal = orders["order_nominal"]

    respond_to do |format|
      format.html
        # @holds = Order.where('date_receive is null')
        # @holds = @holds.where(store: current_user.store) if !["owner", "super_admin", "finance"].include? current_user.level

        # @debts = Order.where('date_receive is not null and date_paid_off is null')
        # @debts = @debts.where(store: current_user.store) if !["owner", "super_admin", "finance"].include? current_user.level
      
      format.pdf do
        new_params = eval(params[:option])
        filter = filter_search new_params, "pdf"
        @search = filter[0]
        @orders = filter[1]
        @store_name= filter[2]
        render pdf: DateTime.now.to_i.to_s,
          layout: 'pdf_layout',
          template: "orders/print_all", 
          formats: [:html], 
          disposition: :inline
      end
    end
  end

  def recap
    @date_start = params[:date_start] 
    @date_end = params[:date_end]
    @orders = Order.where(date_created: @date_start..@date_end)
    @store_name = "Semua Toko"
    store_id = params[:store_id].to_i
    if Store.all.pluck(:id).include? store_id
      @orders = @orders.where(store_id: store_id)
      @store_name = Store.find(store_id).name
    end
    @grouped_by = params[:grouped_by]
    @lunas = []
    @cicilan = []
    @supplier_order_total = 0
    @supplier_tax_total = 0
    if @grouped_by == "supplier"
      ids = @orders.pluck(:supplier_id).uniq
      @suppliers = {}
      ids.each do |id|
        supplier = Supplier.find id
        ords = @orders.where(supplier: supplier)
        @suppliers[supplier.name] = [ords.count, ords.sum(:grand_total), ords.sum(:tax)]
        @supplier_tax_total += ords.sum(:tax)
        @supplier_order_total += ords.sum(:grand_total)
      end
      @suppliers = @suppliers.sort
    elsif @grouped_by == "item"
      ids = @orders.pluck(:id)
      order_items = OrderItem.where(order_id: ids)
      item_ids = order_items.pluck(:item_id).uniq
      @items = {}
      item_ids.each do |item_id|
        item = Item.find item_id
        ordering_item = order_items.where(item: item)
        buy = ordering_item.sum(:receive)
        supplier = ordering_item.first.order.supplier
        @items[item.code] = [item.name, item.item_cat.name, buy]
      end
    else
      # tunai / cicilan
      @order_invs = InvoiceTransaction.where(invoice: @orders.pluck(:invoice)).group(:invoice).count
      @order_invs.each do |ord_inv|
        ord = Order.find_by(invoice: ord_inv[0])
        if ord_inv[1] >= 2
          @cicilan << [ord.invoice, ord.created_at.to_date, ord.store.name, ord.grand_total, ord.tax]
        else
          @lunas << [ord.invoice, ord.created_at.to_date, ord.store.name, ord.grand_total, ord.tax]
        end
      end
    end
    render pdf: DateTime.now.to_i.to_s,
      layout: 'pdf_layout',
      template: "orders/recap", 
      formats: [:html], 
      disposition: :inline
  end

  def new
    return redirect_back_data_error suppliers_path, "Data Supplier Belum Tersedia, Silahkan Menambahkan Data Supplier" if Supplier.count <= 0
    @suppliers = Supplier.select(:id, :name, :address).order("supplier_type DESC").all
    if params[:item_id].present?
      @add_item = Item.find_by(id: params[:item_id])
      supplier_items = SupplierItem.where(item: @add_item).includes([:item]).pluck(:supplier_id)
      @suppliers = @suppliers.where(id: supplier_items)
      # return redirect_back_data_error new_order_path if @add_items.nil?
    end
    if params[:supplier_id].present?
      @supplier = Supplier.find params[:supplier_id]
      return redirect_back_data_error new_order_path if @supplier.nil?
    end

    ongoing_order_ids = Order.where('date_receive is null and date_paid_off is null').pluck(:id)
    @ongoing_order_items = OrderItem.where(order_id: ongoing_order_ids).includes([:item])
    @items = Item.all.limit(50)
    @inventories = StoreItem.where(store: current_user.store).where('stock < min_stock').includes([:item]).page param_page

    gon.inv_count = @inventories.count+3
  end

  def create
    ordered_items = order_items
    return redirect_back_data_error orders_path, "Data Item Tidak Valid (Tidak Boleh Kosong)" if ordered_items.empty?
    total_item = ordered_items.size
    address_to = params[:order][:supplier_id]
    supplier = Supplier.find_by_id params[:order][:supplier_id]
    invoice = "ORD-" + Time.now.to_i.to_s + address_to.to_s + current_user.id.to_s
    order = Order.create invoice: invoice,
      total_items: total_item,
      store_id: current_user.store.id,
      date_created: Time.now,
      supplier_id: address_to,
      total: 0,
      user: current_user

    total = 0
    ordered_items.each do |item_arr|
      item = Item.find item_arr[0]
      if item.nil?
        order.delete
        break
      end
      
      supplier_item = SupplierItem.find_by(item_id: item_arr[0], supplier: supplier)
      supplier_item.destroy if supplier_item.present?
      SupplierItem.create supplier_id: address_to, item: item 
      is_local = item.local_item
      supplier.local = is_local
      supplier.save!

      order_item = OrderItem.create item_id: item_arr[0], order_id: order.id, quantity: item_arr[4], price: 0, description: item_arr[5]
      total+= (item_arr[5].to_i*item_arr[4].to_i)
    end

    order.total = total
    order.create_activity :create, owner: current_user
    order.save!
    urls = order_path id: order.id
    return redirect_success urls, "Order Berhasil Disimpan"
  end

  def destroy
    return redirect_back_data_error orders_path, "Data Order Tidak Ditemukan" unless params[:id].present?
    order = Order.find params[:id]
    return redirect_back_data_error orders_path, "Data Order Tidak Dapat Dihapus" unless order.present?
    return redirect_back_data_error orders_path, "Data Tidak Ditemukan" unless checkAccessStore order
    return redirect_back_data_error orders_path, "Data Order Tidak Dapat Dihapus, FeedBack dari Retur" if order.from_retur
    order_invs = InvoiceTransaction.where(invoice: order.invoice)
    return redirect_back_data_error orders_path, "Data Order Tidak Dapat Dihapus" if order_invs.present?
    if order.date_receive.present?
      order.order_items.each do |order_item|
        item = order_item.item
        store_item = StoreItem.find_by(item: item, store: order.user.store)
        store_item.stock = store_item.stock - order_item.receive
        if item.local_item
          store_item.buy = order_item.last_buy
        else
          item.buy = order_item.last_buy
        end

        item.sell = order_item.last_sell
        store_item.save!
        item.save!
      end
    end

    debt = Debt.find_by(finance_type: Debt::ORDER, ref_id: order.id)
    debt.destroy if debt.present?
    order.order_items.destroy_all
    order.destroy
    return redirect_success orders_path, "Data Order Behasil Dihapus"
  end

  def confirmation
    return redirect_back_data_error orders_path unless params[:id].present?
    @order = Order.find params[:id]
    return redirect_back_data_error orders_path, "Data Tidak Ditemukan" unless checkAccessStore @order
    @order_items = OrderItem.where(order_id: @order.id).includes([:item])
    @order_items.each do |order_item|
      Store.all.each do |store|
        store_item = StoreItem.find_by(store: store, item: order_item.item)
        if store_item.nil?
          StoreItem.create store: store, item: order_item.item, stock: 0
        end
      end
    end
    gon.ids = @order_items.pluck(:id)
    return redirect_back_data_error orders_path, "Data Order Tidak Valid" if @order.date_receive.present? || @order.date_paid_off.present?
    return redirect_back_data_error orders_path, "Data Order Tidak Ditemukan" if @order.nil?
  end

  def receive
    return redirect_back_data_error orders_path, "Data Order Tidak Ditemukan" unless params[:id].present?
    order = Order.find params[:id]
    return redirect_back_data_error orders_path unless order.present?
    return redirect_back_data_error orders_path, "Data Tidak Ditemukan" unless checkAccessStore order
    return redirect_back_data_error orders_path, "Order Tidak Dapat Diubah" if order.date_receive.present? || order.date_paid_off.present?
    order_from_retur = order.from_retur
    due_date = params[:order][:due_date]
    due_date = DateTime.now if order_from_retur
    urls = order_path(id: params[:id])
    return redirect_back_data_error order_confirmation_path(id: order.id), "Tanggal Jatuh Tempo Harus Diisi" if due_date.nil? 
    items = order_items
    new_total = 0
    receivable = nil
    tax = params[:order][:ppn].to_f
    ppn_type = params[:order][:ppn_type].to_i
    new_grand_total = 0
    items.each do |item|
      margin = item.last(2).first.to_f
      order_item = OrderItem.find item[0]
      break if order_item.nil?
      this_item = order_item.item
      break if this_item.nil?

      qty_order = order_item.quantity
      receive_qty = item[1].to_i
      
      price = item[2].to_f
      disc_1 = item[3].to_f
      disc_2 = item[4].to_f
      
      if !order_from_retur && (receive_qty <= 0 || price <= 0)
        order_item.receive = 0
        order_item.discount_1 = 0
        order_item.discount_2 = 0
        order_item.ppn = 0
        order_item.price = 0
        order_item.total = 0
        order_item.grand_total = 0
        order_item.save!
        next
      end

      if qty_order < receive_qty
        receive_qty = qty_order
      end


      if order_from_retur
        receive_qty = qty_order
      end


      store_stock = StoreItem.find_by(item: this_item, store_id: current_user.store)
      if store_stock.nil?
        store_stock = StoreItem.create store: current_user.store, item: this_item, stock: 0, min_stock: 5 
      end
      store_stock.stock = store_stock.stock + receive_qty
      store_stock.save!

      this_item.counter -= receive_qty
      this_item.save!

      price_0 = price*receive_qty
      disc_1 = (price_0)*disc_1/100 if  disc_1 < 99
      price_1 = price_0 - disc_1

      disc_2 = price_1*disc_2/100 if  disc_2 < 99
      price_2 = price_1 - disc_2

      total_item_without_disc_global = price_2

      if ppn_type == 2
        item_grand_total = (price_2 + (price_2*tax/100)).round
      else
        item_grand_total = price_2
      end

      based_item_price = total_item_without_disc_global / receive_qty;

      sell_price = item.last.gsub(".","").to_i - this_item.discount
  
      old_sell = this_item.sell
      this_item.buy = based_item_price 
      item_price = ItemPrice.create item: this_item, buy: this_item.buy, sell: 0, month: Date.today.month.to_i, year: Date.today.year.to_i
      this_item.margin = margin
      sell_before_tax = based_item_price + ( based_item_price * this_item.margin / 100 )


      this_item.save!

      if old_sell != sell_price
        this_item.sell = sell_price
        item_price.sell = this_item.sell
        item_price.save!
        Store.all.each do |store|
          Print.create item: this_item, store: store
        end
        message = "Terdapat perubahan harga jual. Segera cetak label harga "+this_item.name
        to_users = User.where(level: ["owner", "super_admin", "super_visi"])
        to_users.each do |to_user|
          set_notification current_user, to_user, "info", message, prints_path
        end
      end

      this_item.tax = tax
      this_item.ppn = this_item.sell - ((this_item.sell) / ((this_item.tax/100.0)+1))
      this_item.selisih_pembulatan = this_item.sell - (((this_item.sell) / ((this_item.tax/100.0)+1)) + this_item.ppn)
      this_item.save!

      this_item.grocer_items.each do |grocer_item|
        grocer_item.price = this_item.sell + this_item.discount - grocer_item.discount
        grocer_item.ppn = grocer_item.price - ((grocer_item.price) / ((this_item.tax/100.0)+1))
        grocer_item.selisih_pembulatan = grocer_item.price - (((grocer_item.price) / ((this_item.tax/100.0)+1)) + grocer_item.ppn)
        grocer_item.save!
      end

      order_item.receive = receive_qty
      order_item.discount_1 = disc_1
      order_item.discount_2 = disc_2
      order_item.ppn = tax if ppn_type == 2
      order_item.price = price
      order_item.total = total_item_without_disc_global
      order_item.grand_total = item_grand_total
      order_item.last_sell = this_item.sell
      order_item.save!

      this_item.edited_by = current_user
      this_item.save!

      new_total +=  total_item_without_disc_global
      new_grand_total += item_grand_total
      order_item.save!
    end

    disc_supp = 0
    disc_supp = params[:order][:discount].to_f if params[:order][:discount].present?
    
    order.total = new_total
    order.discount_percentage = 0
    order.discount = disc_supp
    order.date_receive = DateTime.now
    order.received_by = current_user
    order.grand_total = new_grand_total - disc_supp

    if (tax > 0) && (ppn_type == 2) 
      order.tax = tax * order.total / 100
      order.save!

      order.supplier.update(tax: tax)
    end
    
    order.save!
    
    if disc_supp > 0
      user = current_user
      store = current_user.store
      invoice = "IN-OR-SUP-" + DateTime.now.to_i.to_s
      cash_flow = CashFlow.create user: user, store: store, nominal: disc_supp, date_created: DateTime.now, description: order.invoice, 
                      finance_type: CashFlow::INCOME, invoice: invoice, ref_id: order.id
      
      store.cash = store.cash + disc_supp
      store.save!
    end

    if order.total == 0
      order.date_paid_off = DateTime.now
      order.save!
      return redirect_success urls, "Order " + order.invoice + " Telah Diterima"
    end

    if !order_from_retur
      Debt.create user: current_user, store: current_user.store, nominal: order.grand_total, 
                deficiency: order.grand_total, date_created: DateTime.now, ref_id: order.id,
                description: order.invoice, finance_type: Debt::ORDER, due_date: due_date, supplier_id: order.supplier.id

      set_notification(current_user, User.find_by(store: current_user.store, level: User::FINANCE), 
        Notification::INFO, "Pembayaran "+order.invoice+" sebesar "+number_to_currency(new_total, unit: "Rp. "), urls)
    end
    description = order.invoice + " (" + order.grand_total.to_s + ")"
    urls = order_path(id: params[:id])
    return redirect_success urls, "Order " + order.invoice + " Telah Diterima"
  end

  def pay
    return redirect_back_data_error orders_path, "Data Order Tidak Ditemukan" unless params[:id].present?
    @order = Order.find params[:id]
    return redirect_back_data_error orders_path, "Data Order Tidak Ditemukan" if @order.nil?
    return redirect_back_data_error orders_path, "Data Tidak Ditemukan" unless checkAccessStore @order
    return redirect_back_data_error orders_path, "Data Order Tidak Valid"if @order.date_receive.nil? || @order.date_paid_off.present?
    @order_invs = InvoiceTransaction.where(invoice: @order.invoice)
    @pay = @order.grand_total.to_i - @order_invs.sum(:nominal) 
  end

  def paid
    return redirect_back_data_error orders_path, "Data Order Tidak Ditemukan" unless params[:id].present?
    order = Order.find params[:id]
    return redirect_back_data_error orders_path, "Data Order Tidak Ditemukan" if order.nil?
    return redirect_back_data_error orders_path, "Data Tidak Ditemukan" unless checkAccessStore order
    return redirect_back_data_error orders_path, "Data Order Tidak Valid" if order.date_receive.nil? || order.date_paid_off.present?
    order_invs = InvoiceTransaction.where(invoice: order.invoice)
    totals = order.grand_total.to_f 
    paid = totals- order_invs.sum(:nominal) 
    
    nominal = params[:order_pay][:nominal].to_i 
    nominal = params[:order_pay][:receivable_nominal].to_i if params[:order_pay][:user_receivable] == "on"
    return redirect_back_data_error orders_path, "Nominal harus lebih besar atau sama dengan 1" if nominal == 0
    return redirect_back_data_error orders_path, 
      "Data Order Tidak Valid (Pembayaran > Jumlah / Pembayaran < 100 )" if (totals-paid+nominal) > totals || nominal < 0 || ( ((totals - nominal) < 0) && ((totals - nominal) > 0))
    return redirect_back_data_error orders_path, "Tanggal pembayaran harus diisi." if params[:order_pay][:date_paid].nil?
    order_inv = InvoiceTransaction.new 
    order_inv.store = current_user.store
    order_inv.invoice = order.invoice
    order_inv.transaction_type = 0
    order_inv.transaction_invoice = "PAID-" + Time.now.to_i.to_s
    order_inv.date_created = params[:order_pay][:date_paid]
    order_inv.nominal = nominal.to_f
    desc = params[:order_pay][:description]
    desc = "Menggunakan piutang" if params[:order_pay][:user_receivable] == "on"
    order_inv.description = desc
    order_inv.user_id = current_user.id
    order_inv.save!
    deficiency = paid - nominal
    debt = Debt.find_by(finance_type: Debt::ORDER, ref_id: order.id)

    if params[:order_pay][:user_receivable] == "on"
      dec_receivable = decrease_receivable order.supplier_id, nominal, order
      return redirect_back_data_error orders_path, "Data Order Tidak Valid" unless dec_receivable
    else
      CashFlow.create user: current_user, store: current_user.store, description: order.invoice, nominal: order_inv.nominal, 
                    date_created: params[:order_pay][:date_paid], finance_type: CashFlow::OUTCOME, ref_id: order.id, payment: "order", invoice: order_inv.transaction_invoice
      store = current_user.store
      store.cash = store.cash - nominal
      store.save!
    end

    debt.deficiency = deficiency
    if deficiency <= 0
      order.date_paid_off = DateTime.now 
      order.save!
      debt.deficiency = 0
    end
    debt.save!
    urls = order_path(id: params[:id])
    user = User.find_by(store: current_user.store, level: User::FINANCE)
    if user.present?
      set_notification(current_user, user, 
        Notification::INFO, "Pembayaran "+order.invoice+" sebesar "+number_to_currency(nominal, unit: "Rp. ")+ " Telah Dikonfirmasi", urls)
    end
    return redirect_success urls, "Pembayaran Order " + order.invoice + " Sebesar " + nominal.to_s + " Telah Dikonfirmasi"
  end

  def show
    return redirect_back_data_error orders_path, "Data Order Tidak Ditemukan" unless params[:id].present?
    @order = Order.find_by(id: params[:id])
    return redirect_back_data_error orders_path, "Data Order Tidak Ditemukan" unless @order.present?
    return redirect_back_data_error orders_path, "Data Tidak Ditemukan" unless checkAccessStore @order
    @order_items = OrderItem.where(order_id: params[:id]).includes([:item])
    @order_invs = InvoiceTransaction.where(invoice: @order.invoice)
    @pay = @order.grand_total.to_i - @order_invs.sum(:nominal) 

    respond_to do |format|
      format.html
      format.pdf do
        @barcode = barcode_output @order
        @recap_type = "order"
        @order_items = OrderItem.where(order_id: params[:id])
        if @order.date_receive.nil?
          render pdf: @order.invoice,
            layout: 'pdf_layout',
            template: "orders/print_sup", 
            formats: [:html], 
            disposition: :inline
        else
          render pdf: @order.invoice,
            layout: 'pdf_layout',
            template: "orders/print", 
            formats: [:html], 
            disposition: :inline
        end
      end
    end
  end

  private

    def barcode_output order
      barcode_string = order.invoice      
      barcode = Barby::Code128B.new(barcode_string)

      # PNG OUTPUT
      data = barcode.to_image(height: 15, margin: 5) .to_data_url
      return data
    end

    def filter_search params, r_type
      results = []
      @orders = Order.all
      if r_type == "html"
        @orders = @orders.includes(:supplier, :user).page param_page if r_type=="html"
      end
      @orders = @orders.where(store: current_user.store) if  !isAdmin
      @search = ""
      if params["search"].present?
        @search += "Pencarian "+params["search"]
        search = "ORD-"+params["search"].gsub("ORD-","")
        @orders =@orders.search_by_invoice search
      end

      before_months = params["months"].to_i
      if before_months != 0
        @search += before_months.to_s + " bulan terakhir "
        start_months = (DateTime.now - before_months.months).beginning_of_month.beginning_of_day 
        @orders = @orders.where("created_at >= ?", start_months)
      end

      store_name = "SEMUA TOKO"
      if params["store_id"].present?
        store = Store.find_by(id: params["store_id"])
        if store.present?
          @orders = @orders.where(store: store)
          store_name = store.name
          @search += "Pencarian" if @search==""
          @search += " di Toko '"+store.name+"'"
        else
          @search += "Pencarian" if @search==""
          @search += " di Semua Toko"
        end
      end

      if params["type"].present?
        @color = ""
        @search += "Pencarian " if @search==""
        type = params["type"]
        if type == "ongoing" 
          @color = "warning"
          @search += "dengan status sedang dalam proses"
          @orders = @orders.where(store_id: current_user.store.id).where('date_receive is null')
        elsif type == "payment"
          @color = "danger"
          @search += "dengan status belum lunas"
          @orders = @orders.where(store_id: current_user.store.id).where('date_receive is not null and date_paid_off is null')
         elsif type == "complete"
          @color = "success"
          @search += "dengan status lunas"
          @orders = @orders.where("date_paid_off  is not null").order("date_created DESC")
        end
      end

      @orders = @orders.order("date_receive DESC, created_at DESC, date_paid_off DESC")

      results << @search
      results << @orders
      results << store_name
      return results
    end

    
    def paid_params
      params.require(:order_pay).permit(
        :nominal, :date_paid
      )
    end

    def order_items
      items = []
      if params[:order][:order_items].present?
        params[:order][:order_items].each do |item|
          items << item[1].values
        end
      end
      items
    end

    def edit_order_items
      items = []
      if params[:order][:order_items].present?
        params[:order][:order_items].each do |item|
          item_id = item[1][:item_id].to_i
          order_item = OrderItem.find item_id
          if order_item.present?
            if order_item.receive < item[1][:total].to_i
              items << item[1].values
            else
              return []
            end
          end
        end
      end
      items
    end

    def edit_payment nominal, order
      paid = InvoiceTransaction.where(invoice: order.invoice).sum(:nominal) 
      if paid > nominal
        over = paid - nominal
        Receivable.create user: current_user, store: current_user.store, nominal: over, date_created: DateTime.now, 
                        description: "OVER PAYMENT #"+order.invoice, finance_type: Receivable::OVER, deficiency:over, to_user: order.supplier_id,
                        ref_id: order_path(id: order.id)
        return true
      else
        debt = Debt.find_by(finance_type: 'ORDER', ref_id: 14)
        debt.deficiency = paid
        debt.nominal = nominal
        debt.save!
      end
      return false
    end

    def decrease_stock retur_id
      retur_items = ReturItem.where(retur_id: retur_id)
      retur_items.each do |retur_item|
        confirmation = retur_item.accept_item
        item = StoreItem.find_by(item_id: retur_item.item.id, store_id: current_user.store.id)
        new_stock = item.stock.to_i - confirmation.to_i
        item.stock = new_stock
        item.save!
      end
    end

    def decrease_receivable supplier_id, nominal, order
      receivable_nominal = Receivable.where(finance_type: "RETUR").where("to_user=? AND deficiency > 0", supplier_id).group(:to_user).sum(:deficiency).values.first
      if receivable_nominal >= nominal
        receivables = Receivable.where(finance_type: "RETUR").where("to_user=? AND deficiency > 0", supplier_id).order("date_created ASC")
        receivables.each do |receivable|
          curr_receivable = receivable.deficiency.to_i
          if curr_receivable >= nominal
            curr_receivable = curr_receivable - nominal
            receivable.deficiency = curr_receivable
            receivable.save!
            return true
          else
            nominal -= curr_receivable
            receivable.deficiency = 0
            receivable.save!
          end
        end
      end
      return false
    end

    def param_page
      params[:page]
    end

end
