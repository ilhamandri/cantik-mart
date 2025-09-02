class TransactionsController < ApplicationController
  before_action :require_login
  before_action :screening
  
  skip_before_action :verify_authenticity_token, :if => Proc.new { |c| c.request.format == 'application/json' }

  @@point = 10000

  def index
    filter = filter_search params, "html"
    @search = "Rekap transaksi " + filter[0]
    @transactions = filter[1]
    @params = params.to_s

    if params[:member_card].present?
      @member = Member.find_by(card_number: params[:member_card])
      @member_name = " - "+@member.name
      @transactions = @transactions.where(member_card: params[:member_card])
    end
  
    respond_to do |format|
      format.html do
        start_day = DateTime.now.beginning_of_month
        end_day = DateTime.now.end_of_day

        if params["date_start"].present?
          start_day = params["date_start"].to_datetime.beginning_of_day
          if params["date_end"].present?
            end_day = params["date_end"].to_datetime.end_of_day
          else
            end_day = (start_day + 7.days).end_of_day
          end 
        end

        if ["finance", "super_admin", "owner","developer"].include? current_user.level
          trxs = Serve.graph_transaction dataFilter
          gon.transaction_label = trxs["label"]
          gon.transaction_omzet = trxs["grand_total"]
          gon.transaction_hpp = trxs["hpp"]
          gon.transaction_tax = trxs["tax"]
          gon.transaction_profit = trxs["profit"]
        elsif ["candy_dream", "super_visi"].include? current_user.level
          trxs = Serve.transactions_graph_manual DateTime.now.beginning_of_month-1.year, DateTime.now, "monthly", current_user, dataFilter
          gon.transaction_label = trxs["label"]
          gon.transaction_omzet = trxs["grand_total"]
        end
        
      end
      format.pdf do
        new_params = eval(params[:option])
        filter = filter_search new_params, "pdf"
        @search = filter[0]
        @transactions = filter[1]
        @store_name= filter[2]
        render pdf: DateTime.now.to_i.to_s,
          layout: 'pdf_layout',
          template: "transactions/print_all", 
          formats: [:html], 
          disposition: :inline
      end
    end
  end

  def monthly_recap
    start_day = (params[:month] + params[:year]).to_datetime.beginning_of_month
    end_day = start_day.end_of_month
    @desc = "Rekap bulanan - "+ start_day.month.to_s + "/" + start_day.year.to_s
    
    trx = Transaction.where(created_at: start_day..end_day)

    if current_user.level == "candy_dream"
      trx = trx.where(has_coin: true) 
    end
    
    @month = start_day.month
    @transaction_datas = trx.order("created_at ASC").group_by{ |m| m.created_at.beginning_of_day}
    render pdf: DateTime.now.to_i.to_s,
      layout: 'pdf_layout',
      template: "transactions/print_recap_monthly", 
      formats: [:html], 
      disposition: :inline
  end

  def daily_recap
    end_day = params[:date].to_s.to_time.end_of_day
    start_day = end_day.beginning_of_day
    @end = end_day
    @start = start_day
    trx = Transaction.where(created_at: start_day..end_day)
   
    cash_flow = CashFlow.where(created_at: start_day..end_day)
    cash_flow = cash_flow.where(store: current_user.store) if ["super_visi"].include? current_user.level
    
    if current_user.level == "candy_dream"
      trx = trx.where(has_coin: true) 
    end

    @transactions = trx
    @profits = []

    @total_income = 0

    Store.where.not(store_type: "warehouse").each do |store|
      grand_total = trx.where(store: store).sum(:grand_total) - trx.where(store: store).sum(:grand_total_coin)
      hpp_total = trx.where(store: store).sum(:hpp_total) - trx.where(store: store).sum(:hpp_total_coin)
      ppn = trx.where(store: store).sum(:tax) - trx.where(store: store).sum(:tax_coin)
      profit = grand_total - hpp_total - ppn
      @total_income += profit
      @profits << [store.name, grand_total, profit, ppn]
    end

    @supplier_income = 0
    @bonus = cash_flow.where(finance_type: CashFlow::BONUS).sum(:nominal)
    @other_income = cash_flow.where(finance_type: CashFlow::INCOME).sum(:nominal)
    @total_income += @supplier_income + @bonus + @other_income
  
    @operational = cash_flow.where(finance_type: [CashFlow::OPERATIONAL, CashFlow::TAX]).sum(:nominal)
    @fix_cost = cash_flow.where(finance_type: CashFlow::FIX_COST).sum(:nominal)
    @total_outcome = @operational + @fix_cost
    
    @search = "Rekap Harian - " + start_day.to_date.to_s
    render pdf: DateTime.now.to_i.to_s,
      layout: 'pdf_layout',
      template: "transactions/print_recap", 
      formats: [:html], 
      disposition: :inline
  end

  def daily_recap_item
    start_day = params[:start_date].to_time.beginning_of_day
    end_day = params[:end_date].to_time.end_of_day
    store_id = params["store_id"]
    return redirect_back_data_error transactions_path, "Silahkan untuk memilih toko di rekap penjualan item" if store_id.nil?
    store = Store.find_by(id: store_id)
    return redirect_back_data_error transactions_path, "Data tidak Ditemukan (D1)" if store.nil?

    transaction_items = TransactionItem.where(created_at: start_day..end_day, store: store)

    return redirect_back_data_error transactions_path, "Data tidak Ditemukan (D2)" if transaction_items.nil?
    
    if current_user.level == "candy_dream"
      transaction_items = transaction_items.where(item_id: 30331)
    else
      transaction_items = transaction_items.where.not(item_id: 30331)
    end


    global_trx_items = transaction_items.group(:item_id).sum(:quantity).sort_by(&:last).reverse

    # Penjualan berdasar kategori
    item_cats = {}
    global_trx_items.each do |trx_item|
      item = Item.find_by(id: trx_item[0])
      item_cat = item.item_cat
      if  item_cats[item_cat.name].present?
        item_cats[item_cat.name] = item_cats[item_cat.name] + trx_item[1] 
      else
        item_cats[item_cat.name] = trx_item[1] if item_cats[item_cat.name].nil?
      end
    end
    item_cats = Hash[item_cats.sort_by{|k, v| v}.reverse]


    # Penjualan berdasar departemen
    departments = {}
    item_cats.each do |item_cat|
      cat = ItemCat.find_by(name: item_cat.first)
      department = cat.department
      if departments[department.name].nil?
        departments[department.name] = item_cat.second 
      else
        departments[department.name] = departments[department.name] + item_cat[1] 
      end
    end
    
    departments = Hash[departments.sort_by{|k, v| v}.reverse]

    respond_to do |format|
      format.html
      format.xlsx do
        filename = "./report/trxs/"+store.name+"_trx_items_"+DateTime.now.to_i.to_s+".xlsx"
        p = Axlsx::Package.new
        wb = p.workbook
        wb.add_worksheet(:name => "SUPPLIER ITEMS") do |sheet|
          suppliers_id = transaction_items.pluck(:supplier_id).uniq
          suppliers_id.each do |supplier_id|
            supplier = Supplier.find_by(id: supplier_id)
            supplier_name = "TIDAK ADA SUPPLIER"
            supplier_name = supplier.name + " (" + supplier.phone.to_s + ")" if supplier_id.present?
            sheet.add_row [supplier_name.upcase]
            if ["super_visi", "stock_admin"].include? current_user.level
              sheet.add_row ["Kode", "Nama", "Terjual"]
            else
              sheet.add_row ["Kode", "Nama", "Terjual", "Omzet", "Pajak Keluaran", "Profit"]
            end
            trx_supplier_items = transaction_items.where(supplier_id: supplier_id)
            trx_supplier_items.pluck(:item_id).uniq.each do |item_id|
              item = Item.find_by(id: item_id)
              trx_items = trx_supplier_items.where(item_id: item_id)

              if ["super_visi", "stock_admin"].include? current_user.level
                sheet.add_row [item.code, item.name, trx_items.sum(:quantity).to_i ]
              else
                sheet.add_row [item.code, item.name, trx_items.sum(:quantity).to_i, trx_items.sum(:total).to_i, trx_items.sum(:ppn).to_i, trx_items.sum(:profit).to_i ]
              end
            end
            if ["super_visi", "stock_admin"].include? current_user.level
              sheet.add_row ["","", trx_supplier_items.sum(:quantity).to_i]
            else
              sheet.add_row ["","", trx_supplier_items.sum(:quantity).to_i, trx_supplier_items.sum(:total).to_i, trx_supplier_items.sum(:ppn).to_i, trx_supplier_items.sum(:profit).to_i]
            end
          end
        end

        wb.add_worksheet(:name => "DEPARTEMEN") do |sheet|
          sheet.add_row ["Departemen", "Jumlah"]
          totals = 0
          departments.each do |dept|
            sheet.add_row [dept.first, dept.second]
            totals += dept.second
          end
          sheet.add_row ["",totals.to_i]
        end

        wb.add_worksheet(:name => "KATEGORI") do |sheet|
          sheet.add_row ["Kategori", "Jumlah"]
          totals = 0
          item_cats.each do |item_cat|
            sheet.add_row [item_cat.first, item_cat.second]
            totals += item_cat.second
          end
          sheet.add_row ["",totals.to_i]
        end

        p.serialize(filename)
        send_file(filename)
      end
    end

  end

  def show
    return redirect_back_data_error transactions_path, "Data Transaksi Tidak Ditemukan" if params[:id].nil?
    @transaction_items = TransactionItem.where(transaction_id: params[:id]).includes(:item)
    return redirect_back_data_error transactions_path, "Data Transaksi Tidak Ditemukan" if @transaction_items.empty?
  end

  def new
    gon.store_id = current_user.store.id
    gon.cashier_name = current_user.name.upcase.split(" ")[0]
    
    if current_user.level != "developer"
      trx_last_store_id = Transaction.last.store.id
      if !current_user.store.online_store 
        return redirect_back_data_error root_path, "ID kasir tidak terdaftar." if trx_last_store_id != current_user.store.id
      end
    end
    respond_to do |format|
      format.html { render "transactions/new", :layout => false  } 
    end
  end

  def create_trx
    items = trx_items
    
    item = 0
    discount = 0
    total = 0
    grand_total = 0
    hpp_total = 0

    promotions_code  = []
    items.each do |trx_item|
      item += trx_item[1].to_i
      discount += trx_item[1].to_i * trx_item[3].to_i
      total += trx_item[1].to_i * trx_item[2].to_i
      grand_total += trx_item[4].to_i
      promo = trx_item[5]
      promotions_code << promo if promo.include? "PROMO-"
    end

    trx = Transaction.new
    trx.invoice = "TRX-"+DateTime.now.to_i.to_s+"-"+current_user.store.id.to_s+"-"+current_user.id.to_s
    trx.user = current_user
    member = nil
    if params[:member] != ""
      member = Member.find_by(id: params[:member])
      trx.member_card = member if member.present?
    end
    trx.date_created = Time.now
    trx.payment_type = params[:payment].to_i
    trx.store = current_user.store
    trx.voucher = params[:voucher]

    trx.items = item.to_i
    trx.discount = discount.to_i
    trx.total = total.to_i
    trx.grand_total = grand_total.to_i
    trx.tax = 0

    if params[:payment] != 1
      trx.bank = params[:bank].to_i
      trx.edc_inv = params[:edc].to_s
      trx.card_number = params[:card].to_s
    end
    trx.save!
    
    trx_total_for_point = 0
    tax = 0
    pembulatan = 0
    items.each do |item_par|
      item = Item.find_by(code: item_par[0])
      next if item.nil?

      item_cats = ItemCat.where(use_in_point: true).pluck(:id)

      if item_cats.include? item.item_cat.id 
        trx_total_for_point += item_par[2].to_i
      end

      trx_item = TransactionItem.create item: item,  
      transaction_id: trx.id,
      quantity: item_par[1], 
      price: item_par[2],
      discount: item_par[3],
      date_created: DateTime.now
      
      if trx_item.quantity > 1
        grocer_item = GrocerItem.find_by(item: item, price: trx_item.price-trx_item.discount)
        if grocer_item.present?
          tax += grocer_item.ppn * trx_item.quantity
          trx_item.ppn = grocer_item.ppn * trx_item.quantity
          pembulatan += grocer_item.selisih_pembulatan * trx_item.quantity
        else
          tax += item.ppn * trx_item.quantity
          trx_item.ppn = item.ppn * trx_item.quantity
          pembulatan += item.selisih_pembulatan * trx_item.quantity
        end
      else
        tax += item.ppn * trx_item.quantity
        trx_item.ppn = item.ppn * trx_item.quantity
        pembulatan += item.selisih_pembulatan * trx_item.quantity
      end
      
      trx_item.store = trx.store
      item_suppliers = SupplierItem.where(item: trx_item.item)
      trx_item.supplier = item_suppliers.first.supplier if item_suppliers.present?
      trx_item.total = trx_item.quantity * (trx_item.price-trx_item.discount)
      trx_item.profit = trx_item.total - trx_item.ppn - (trx_item.item.buy * trx_item.quantity)

      trx_item.save!

      if trx_item.price == 0
        promo = item_par[5]
        trx_item.reason = promo
        trx_item.save!
      end

      if item.item_cat == 179
        trx.has_coin = true
        trx.grand_total_coin = trx.grand_total_coin + trx_item.total
        trx.hpp_total_coin = trx.hpp_total_coin + (trx_item.item.buy * trx_item.quantity)
        trx.profit_coin = trx.profit_coin + trx_item.profit
        trx.quantity_coin = trx.quantity_coin + trx_item.quantity
        trx.tax_coin = trx.tax_coin + trx_item.ppn
        trx.save!
      end

      store_stock = StoreItem.find_by(store: current_user.store, item: item)
      hpp_total += (trx_item.quantity * item.buy).round
      next if store_stock.nil?
      store_stock.stock = store_stock.stock.to_i - trx_item.quantity
      store_stock.save!
    end
    trx.tax = tax
    trx.pembulatan = pembulatan
    trx.hpp_total = hpp_total
    new_point = trx_total_for_point / @@point
    trx.point = new_point
    trx.save!

    if trx.member_card.present?
      member = trx.member_card
      member.point = member.point + trx.point

      Point.create member: member, point: trx.point, point_type: Point::GET, transaction_id: trx.id
      
      member.save!
    end
    
    render status: 200, json: {
      invoice: trx.invoice.to_s,
      time: trx.created_at.strftime("%d/%m/%Y %H:%M:%S"),
      
    }.to_json
  end

  private

    def filter_search params, r_type
      results = []
      trx = Transaction.all

      if current_user.level == "candy_dream"
        trx = Transaction.where(has_coin: true) 
      end

      @transactions = trx.order("created_at DESC").includes(:user, :user => :store)
      @transactions = @transactions.where.not("invoice like '%/TP'")

      if params[:from].present?
        if params[:from] == "complain"
          curr_date = Date.today - 3.days
          @from = " Komplain ("+curr_date.to_s+" - "+Date.today.to_s+")"
          @transactions = @transactions.where("created_at > ?", curr_date)
        end
      end

      if r_type == "html"
        @transactions = @transactions.page param_page if r_type=="html"
      end
      @transactions = @transactions.where(store: current_user.store) if  !["owner", "super_admin", "finance", "candy_dream", "developer"].include? current_user.level
      @transactions = @transactions.where(has_coin: true) if current_user.level == "candy_dream"

      @search = ""
      if params["search"].present?
        @search += "Pencarian "+params["search"]
        search_query = params["search"].gsub("TRX-","")
        search = "TRX-"+search_query
        @transactions = @transactions.search_by_invoice search
      end

      date_start = params["date_start"]
      date_end = params["date_end"]
      if date_start.present?
        date_start += " " + params["hour_start"]
        date_end += " " + params["hour_end"]
        @search += " pada " + params["date_start"] + " hingga " + params["date_end"]
        @transactions = @transactions.where("created_at >= ? AND created_at <= ?", date_start.to_time ,date_end.to_time)
      end

      if params["user_id"].present?
        user = User.find_by(id: params["user_id"].to_i)
        if user.present?
          @search += " dengan user '" + user.name + "'"
          @transactions = @transactions.where(user: user)
        end
      end 

      store_name = "SEMUA TOKO"
      if params["store_id"].present?
        store = Store.find_by(id: params["store_id"])
        if store.present?
          @transactions = @transactions.where(store: store)
          store_name = store.name
          @search += "Pencarian" if @search==""
          @search += " di Toko '"+store.name+"'"
        else
          @search += "Pencarian" if @search==""
          @search += " di Semua Toko"
        end
      end

      results << @search
      results << @transactions
      results << store_name
      return results
    end

    def trx_items
      items = []
      par_items = params[:items].values
      par_items.each do |item|
        items << item.values
      end
      items
    end

    def param_page
      params[:page]
    end
end 


