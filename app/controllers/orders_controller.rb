include ActionView::Helpers::NumberHelper
class OrdersController < ApplicationController
  before_action :require_login
  before_action :require_fingerprint
  def index
    @orders = Order.order("date_created DESC").page param_page
    @search = ""
    @orders = @orders.where(store: current_user.store) if  !["owner", "super_admin", "super_finance"].include? current_user.level

    if params[:search].present?
      search = params[:search].downcase
      search_arr = search.split(":")
      if search_arr.size > 2
        return redirect_back_data_error orders_path, "Data Tidak Valid"
      elsif search_arr.size == 2
        supplier = Supplier.where('lower(pic) like ?', "%"+search_arr[1].downcase+"%").pluck(:id)
        if search_arr[0]== "supplier" && supplier.present?
          @orders = @orders.where(supplier_id: supplier)
        else
          @orders = @orders.where("lower(invoice) like ?", "%"+ search_arr[1]+"%")
          @search_text += "Pencarian " + search_arr[1].upcase + " "
        end
      else
        @orders = @orders.where("lower(invoice) like ?", "%"+ search+"%")
        @search += "Pencarian " + search.upcase + " "
      end
    end


    if params[:type].present?
      @color = ""
      @search += "Pencarian " if @search==""
      type = params[:type]
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

    if params["store_id"].present?
      store = Store.find_by(id: params["store_id"])
      if store.present?
        @orders = @orders.where(store: store)
        @search += "Pencarian" if @search==""
        @search += " di Toko '"+store.name+"'"
      else
        @search += "Penacarian" if @search==""
        @search += " di Semua Toko"
      end
    end
    
  end

  def new
    return redirect_back_data_error suppliers_path, "Data Supplier Belum Tersedia, Silahkan Menambahkan Data Supplier" if Supplier.count <= 0
    @suppliers = Supplier.select(:id, :name, :address).order("supplier_type DESC").all
    if params[:item_id].present?
      @add_item = Item.find_by(id: params[:item_id])
      # return redirect_back_data_error new_order_path if @add_items.nil?
    end
    if params[:supplier_id].present?
      @supplier = Supplier.find params[:supplier_id]
      return redirect_back_data_error new_order_path if @supplier.nil?
    end

    ongoing_order_ids = Order.where('date_receive is null and date_paid_off is null').pluck(:id)
    @ongoing_order_items = OrderItem.where(order_id: ongoing_order_ids)
    @items = Item.all.limit(50)
    @inventories = StoreItem.where(store: current_user.store).where('stock < min_stock').page param_page

    gon.inv_count = @inventories.count+3
  end

  def create
    invoice = "ORD-" + Time.now.to_i.to_s
    ordered_items = order_items
    return redirect_back_data_error orders_path, "Data Item Tidak Valid (Tidak Boleh Kosong)" if ordered_items.empty?
    total_item = ordered_items.size
    address_to = params[:order][:supplier_id]
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
      supplier_item = SupplierItem.find_by(item_id: item_arr[0])
      SupplierItem.create supplier_id: address_to, item: item if supplier_item.nil?
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
    return redirect_back_data_error orders_path, "Data Order Tidak Dapat Dihapus" if order.date_receive.present?
    OrderItem.where(order_id: params[:id]).destroy_all
    order.destroy
    return redirect_success orders_path, "Data Order Behasil Dihapus"
  end

  def confirmation
    return redirect_back_data_error orders_path unless params[:id].present?
    @order = Order.find params[:id]
    @order_items = OrderItem.where(order_id: @order.id)
    return redirect_back_data_error orders_path, "Data Order Tidak Valid" if @order.date_receive.present? || @order.date_paid_off.present?
    return redirect_back_data_error orders_path, "Data Order Tidak Ditemukan" if @order.nil?
  end

  def edit_confirmation
    return redirect_back_data_error orders_path unless params[:id].present?
    @order = Order.find params[:id]
    return redirect_back_data_error orders_path unless @order.present? || @order.editable == false
    return redirect_back_data_error orders_path if @order.date_paid_off.present? || @order.date_receive.nil?
    @order_items = OrderItem.where(order_id: @order.id)
  end

  def edit_receive
    return redirect_back_data_error orders_path, "Data Order Tidak Ditemukan" unless params[:id].present?
    order = Order.find params[:id]
    return redirect_success redirect_back_data_error orders_path unless order.present? || order.editable == false
    return redirect_back_data_error orders_path, "Data Order Tidak Ditemukan" if order.date_paid_off.present? || order.date_receive.nil?
    items = edit_order_items
    return redirect_back_data_error orders_path, "Data Order Tidak Ditemukan" if items.empty?
    new_grand_total = 0
    new_total = 0
    disc_percentage = order.discount_percentage.to_f
    items.each do |item|
      order_item = OrderItem.find item[0]
      break if order_item.nil?
      new_receive = item[1].to_i.abs
      next if new_receive <= 0

      price = order_item.price
      disc_1 = order_item.discount_1.to_f
      disc_2 = order_item.discount_2.to_f
      ppn = order_item.ppn.to_f

      price_1 = price - (price*disc_1/100) 
      price_2 = price_1 - (price_1*disc_2/100)
      price_3 = (price_2 + (price_2*ppn/100)).to_i
      based_item_price = (price_3 - (price_3 * disc_percentage / 100)).to_i
      new_grand_total_item = based_item_price * new_receive
      total_item_without_disc_global = (price_3 * new_receive).to_i

      order_item.new_receive = new_receive
      order_item.discount_1 = disc_1
      order_item.discount_2 = disc_2
      order_item.ppn = ppn
      order_item.price = price
      order_item.total = total_item_without_disc_global
      order_item.grand_total = new_grand_total_item.to_i
      order_item.save!

      this_item = Item.find order_item.item.id
      store_stock = StoreItem.find_by(item_id: order_item.item.id, store_id: current_user.store)
      store_stock = StoreItem.create store: current_user.store, item: this_item, stock: 0, min_stock: 5 if store_stock.nil?
      store_stock.stock = store_stock.stock - order_item.receive + new_receive
      store_stock.save!
      new_grand_total +=  new_grand_total_item.to_i
      new_total += total_item_without_disc_global
    end
    order.old_total = order.grand_total
    order.total = new_total
    order.grand_total = new_total - ( new_total * disc_percentage / 100).to_i
    order.discount = ( new_total * disc_percentage / 100).to_i
    order.date_change = DateTime.now
    order.editable = false

    changes = order.changes
    order.save!
    payment = edit_payment new_grand_total, order

    order.create_activity :edit, owner: current_user, parameters: changes

    if payment
      order.date_paid_off = DateTime.now 
      order.save!
      debt = Debt.find_by(finance_type: Debt::ORDER, ref_id: order.id)
      debt.deficiency = 0
      debt.save!
    end
    urls = order_path(id: params[:id])
    return redirect_success urls, "Order " + order.invoice + " Telah Diterima"
  end

  def receive
    return redirect_back_data_error orders_path, "Data Order Tidak Ditemukan" unless params[:id].present?
    order = Order.find params[:id]
    return redirect_back_data_error orders_path unless order.present?
    return redirect_back_data_error orders_path, "Order Tidak Dapat Diubah" if order.date_receive.present? || order.date_paid_off.present?
    order_from_retur = order.from_retur
    due_date = params[:order][:due_date]
    urls = order_path(id: params[:id])
    return redirect_back_data_error order_confirmation_path(id: order.id), "Tanggal Jatuh Tempo Harus Diisi" if due_date.nil?
    items = order_items
    new_total = 0
    receivable = nil
    disc_percentage = 0
    disc_percentage = params[:order][:discount].to_i if params[:order][:discount].present?
    disc = 0

    items.each do |item|
      order_item = OrderItem.find item[0]
      break if order_item.nil?
      qty_order = order_item.quantity
      receive_qty = item[1].to_i
      
      price = item[2].to_f
      disc_1 = item[3].to_f
      disc_2 = item[4].to_f
      ppn = item[5].to_f
      

      if qty_order < receive_qty
          receive_qty = qty_order
      end


      if order_from_retur
        buy = order_item.item.buy if !order_item.item.local_item
        buy = StoreItem.find_by(store: order.store, item: order_item.item).buy.to_f if order_item.item.local_item
        nominal_value = buy * (qty_order-receive_qty)
        if receive_qty <= 0 || qty_order > receive_qty
          if receivable.nil?
            receivable = Receivable.create user: current_user, store: current_user.store, nominal: nominal_value, date_created: DateTime.now, 
                          description: "RECEIVABLE FROM RETUR #"+order.invoice, finance_type: Receivable::RETUR, deficiency:nominal_value, to_user: order.supplier_id,
                          ref_id: urls, due_date: DateTime.now + 2.months
          else
            receivable.nominal += receivable.nominal+nominal_value
            receivable.deficiency += receivable.deficiency+nominal_value
            receivable.save!
            next
          end          
        end
      end


      this_item = order_item.item
      store_stock = StoreItem.find_by(item: this_item, store_id: current_user.store)
      store_stock = StoreItem.create store: current_user.store, item: this_item, stock: 0, min_stock: 5 if store_stock.nil?


      price_1 = price - (price*disc_1/100) 
      price_2 = price_1 - (price_1*disc_2/100)
      price_3 = price_2 + (price_2*ppn/100)
      based_item_price = price_3 - (price_3 * disc_percentage / 100)
      new_buy_total = based_item_price * receive_qty


      profit_margin = this_item.margin
      new_price = based_item_price + (based_item_price * profit_margin / 100).round(-2)
      if this_item.local_item
        last_price = store_stock.buy
        if new_price > last_price
          store_stock.sell = new_price
          store_stock.save!
        end
      else
        last_price = this_item.sell
        if new_price > last_price
          this_item.sell = new_price
          this_item.save!
        end
      end

      order_item.receive = receive_qty
      order_item.discount_1 = disc_1
      order_item.discount_2 = disc_2
      order_item.ppn = ppn
      order_item.price = price
      order_item.grand_total = new_buy_total
      order_item.save!


      store_stock.stock = store_stock.stock + receive_qty
      store_stock.save!

      old_buy_total = store_stock.stock.to_i * store_stock.buy.to_f if this_item.local_item
      old_buy_total = store_stock.stock.to_i * this_item.buy.to_f if !this_item.local_item
      new_buy = 0
      new_buy = (new_buy_total + old_buy_total) / (receive_qty + store_stock.stock.to_i) if (receive_qty + store_stock.stock.to_i) > 0

      if !this_item.local_item
        store_stock.buy = new_buy
        store_stock.save!
      else
        this_item.buy = new_buy
        this_item.save!
      end
      new_total +=  new_buy_total
    end

    order.total = new_total
    order.discount_percentage = disc_percentage
    order.discount = (new_total*disc_percentage/100)
    order.date_receive = DateTime.now
    order.received_by = current_user
    order.grand_total = order.total - order.discount
    order.save!
    
    if order.total == 0
      order.date_paid_off = DateTime.now
      order.save!
      return redirect_success urls, "Order " + order.invoice + " Telah Diterima"
    end

    if !order_from_retur
      Debt.create user: current_user, store: current_user.store, nominal: new_total, 
                deficiency: new_total, date_created: DateTime.now, ref_id: order.id,
                description: order.invoice, finance_type: Debt::ORDER, due_date: due_date

      set_notification(current_user, User.find_by(store: current_user.store, level: User::FINANCE), 
        Notification::INFO, "Pembayaran "+order.invoice+" sebesar "+number_to_currency(new_total, unit: "Rp. "), urls)
    end
    description = order.invoice + " (" + new_total.to_s + ")"
    urls = order_path(id: params[:id])
    return redirect_success urls, "Order " + order.invoice + " Telah Diterima"
  end

  def pay
    return redirect_back_data_error orders_path, "Data Order Tidak Ditemukan" unless params[:id].present?
    @order = Order.find params[:id]
    return redirect_back_data_error orders_path, "Data Order Tidak Ditemukan" if @order.nil?
    return redirect_back_data_error orders_path, "Data Order Tidak Valid"if @order.date_receive.nil? || @order.date_paid_off.present?
    @order_invs = InvoiceTransaction.where(invoice: @order.invoice)
    @pay = @order.total.to_i - @order_invs.sum(:nominal) 
  end

  def paid
    return redirect_back_data_error orders_path, "Data Order Tidak Ditemukan" unless params[:id].present?
    order = Order.find params[:id]
    return redirect_back_data_error orders_path, "Data Order Tidak Ditemukan" if order.nil?
    return redirect_back_data_error orders_path, "Data Order Tidak Valid" if order.date_receive.nil? || order.date_paid_off.present?
    order_invs = InvoiceTransaction.where(invoice: order.invoice)
    totals = order.total.to_f 
    paid = totals- order_invs.sum(:nominal) 
    nominal = params[:order_pay][:nominal].to_i 
    nominal = params[:order_pay][:receivable_nominal].to_i if params[:order_pay][:user_receivable] == "on"
    return redirect_back_data_error orders_path, 
      "Data Order Tidak Valid (Pembayaran > Jumlah / Pembayaran < 100 )" if (totals-paid+nominal) > totals || nominal < 100 || ( ((totals - nominal) < 100) && ((totals - nominal) > 1))
    order_inv = InvoiceTransaction.new 
    order_inv.invoice = order.invoice
    order_inv.transaction_type = 0
    order_inv.transaction_invoice = "PAID-" + Time.now.to_i.to_s
    order_inv.date_created = params[:order_pay][:date_paid]
    order_inv.nominal = nominal.to_f
    order_inv.user_id = current_user.id
    order_inv.save!
    deficiency = paid - nominal
    debt = Debt.find_by(finance_type: Debt::ORDER, ref_id: order.id)
    if params[:order_pay][:user_receivable] == "on"
      dec_receivable = decrease_receivable order.supplier_id, nominal, order
      return redirect_back_data_error orders_path, "Data Order Tidak Valid" unless dec_receivable
    else
      CashFlow.create user: current_user, store: current_user.store, description: order.invoice, nominal: order_inv.nominal, 
                    date_created: params[:order_pay][:date_paid], finance_type: CashFlow::OUTCOME, ref_id: order.id, payment: "order"
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
    return redirect_success urls, "Pembayaran Order " + order.invoice + " Sebesar " + nominal.to_s + " Telah Dikonfirmasi"
  end

  def show
    return redirect_back_data_error orders_path, "Data Order Tidak Ditemukan" unless params[:id].present?
    @order = Order.find_by(id: params[:id])
    return redirect_back_data_error orders_path, "Data Order Tidak Ditemukan" unless @order.present?
    @order_items = OrderItem.where(order_id: params[:id]).page param_page
    @order_invs = InvoiceTransaction.where(invoice: @order.invoice)
    @pay = @order.grand_total.to_i - @order_invs.sum(:nominal) 
    respond_to do |format|
      format.html
      format.pdf do
        render pdf: @order.invoice,
          layout: 'pdf_layout.html.erb',
          template: "orders/print.html.slim"
      end
    end
  end

  private
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
      receivable_nominal = Receivable.where("to_user=? AND deficiency > 0", supplier_id).group(:to_user).sum(:deficiency).values.first
      if receivable_nominal >= nominal
        receivables = Receivable.where("to_user=? AND deficiency > 0", supplier_id).order("date_created ASC")
        receivables.each do |receivable|
          curr_receivable = receivable.deficiency.to_i
          if curr_receivable >= nominal
            curr_receivable = curr_receivable - nominal
            receivable.deficiency = curr_receivable
            receivable.save!
            CashFlow.create user: current_user, store: current_user.store, description: order.invoice, nominal: nominal, 
                    date_created: params[:order_pay][:date_paid], finance_type: CashFlow::INCOME, ref_id: order.id
            CashFlow.create user: current_user, store: current_user.store, description: order.invoice, nominal: nominal*-1, 
                    date_created: params[:order_pay][:date_paid], finance_type: CashFlow::OUTCOME, ref_id: order.id
            return true
          else
            CashFlow.create user: current_user, store: current_user.store, description: order.invoice, nominal: curr_receivable, 
                    date_created: params[:order_pay][:date_paid], finance_type: CashFlow::INCOME, ref_id: order.id
            CashFlow.create user: current_user, store: current_user.store, description: order.invoice, nominal: curr_receivable*-1, 
                    date_created: params[:order_pay][:date_paid], finance_type: CashFlow::OUTCOME, ref_id: order.id
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
