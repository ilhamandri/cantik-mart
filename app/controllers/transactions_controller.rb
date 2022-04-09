class TransactionsController < ApplicationController
  before_action :require_login
  
  skip_before_action :verify_authenticity_token, :if => Proc.new { |c| c.request.format == 'application/json' }

  @@point = 10000

  def index
    check_duplicate
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

        transactions = transactions_profit_graph start_day, end_day
        gon.grand_totals = transactions[0]
        gon.hpp_totals = transactions[1]
        gon.profits = transactions[2]
        gon.days = transactions[3]
      end
      format.pdf do
        new_params = eval(params[:option])
        filter = filter_search new_params, "pdf"
        @search = filter[0]
        @transactions = filter[1]
        @store_name= filter[2]
        render pdf: DateTime.now.to_i.to_s,
          layout: 'pdf_layout.html.erb',
          template: "transactions/print_all.html.slim"
      end
    end
  end


  def check_duplicate
    duplicate_trxs = Transaction.select(:invoice).group(:invoice).having("count(*) > 1").size
    duplicate_trxs.each do |trx_data|
      trx = Transaction.find_by(invoice: trx_data[0])
      store = trx.store
      if trx.transaction_items.present?
        trx.transaction_items.each do |trx_item|
          store_item = StoreItem.find_by(item: trx_item.item, store: store)
          store_item.stock = store_item.stock + trx_item.quantity
          store_item.save!
        end
        trx.transaction_items.destroy_all
      end
      trx.destroy
    end
  end

  def monthly_recap
    start_day = (params[:month] + params[:year]).to_datetime
    end_day = start_day.end_of_month
    @desc = "Rekap bulanan - "+ start_day.month.to_s + "/" + start_day.year.to_s
    trx = nil
    if current_user.level == "candy_dream"
      trx = Transaction.where(has_coin: true) 
    else
      trx = Transaction.where(has_coin: false) 
    end
    @month = start_day.month
    @transaction_datas = trx.where(created_at: start_day..end_day).order("created_at ASC").group_by{ |m| m.created_at.beginning_of_day}
    render pdf: DateTime.now.to_i.to_s,
      layout: 'pdf_layout.html.erb',
      template: "transactions/print_recap_monthly.html.slim"
  end


  def daily_recap
    end_day = params[:date].to_s.to_datetime.end_of_day
    start_day = end_day.beginning_of_day
    @end = end_day
    @start = start_day
    trx = Transaction.where(date_created: start_day..end_day)

    cash_flow = CashFlow.where(created_at: start_day..end_day)
    
    if current_user.level == "candy_dream"
      trx = trx.where(has_coin: true) 
    else
      trx = trx.where(has_coin: false) 
    end
    @transactions = trx

    @profits = []

    @total_income = 0

    Store.all.each do |store|
      grand_total = trx.where(store: store).sum(:grand_total)
      hpp_total = trx.where(store: store).sum(:hpp_total)
      ppn = trx.where(store: store).sum(:tax)
      profit = grand_total - hpp_total - ppn
      pembulatan = trx.where(store: store).sum(:pembulatan)
      @total_income += profit
      @profits << [store.name, grand_total, profit, ppn, pembulatan]
    end

    @supplier_income = 0
    @bonus = cash_flow.where(finance_type: CashFlow::BONUS).sum(:nominal)
    @other_income = cash_flow.where(finance_type: CashFlow::INCOME).sum(:nominal)
    @total_income += @supplier_income + @bonus + @other_income
  
    @operational = cash_flow.where(finance_type: [CashFlow::OPERATIONAL, CashFlow::TAX]).sum(:nominal)
    @fix_cost = cash_flow.where(finance_type: CashFlow::FIX_COST).sum(:nominal)
    @total_outcome = @operational + @fix_cost
    
    @search = "Rekap Harian - "+Date.today.to_s
    render pdf: DateTime.now.to_i.to_s,
      layout: 'pdf_layout.html.erb',
      template: "transactions/print_recap.html.slim"
  end

  def daily_recap_item
    start_day = params[:start_date].to_time
    end_day = params[:end_date].to_time.end_of_day
    store_id = params["store_id"]
    return redirect_back_data_error transactions_path, "Silahkan untuk memilih toko di rekap penjualan item" if store_id.nil?
    store = Store.find_by(id: store_id)
    return redirect_back_data_error transactions_path, "Data tidak Ditemukan" if store.nil?
    @transactions = Transaction.where(store: store,created_at: start_day..end_day)
    return redirect_back_data_error transactions_path, "Data tidak Ditemukan" if @transactions.nil?
    @trx_items =  TransactionItem.where(transaction_id:  @transactions.pluck(:id))
    @transaction_items = TransactionItem.where(transaction_id:  @transactions.pluck(:id)).group(:item_id).sum(:quantity)
    @transaction_items = @transaction_items.sort_by(&:last).reverse
    @item_cats = {}
    @transaction_items.each do |trx_item|
      item = Item.find_by(id: trx_item.first)
      item_cat = item.item_cat
      if  @item_cats[item_cat.name].present?
        @item_cats[item_cat.name] = @item_cats[item_cat.name] + trx_item[1] 
      else
        @item_cats[item_cat.name] = trx_item[1] if @item_cats[item_cat.name].nil?
      end
    end
    @item_cats = Hash[@item_cats.sort_by{|k, v| v}.reverse]
    @departments = {}
    @item_cats.each do |item_cat|
      cat = ItemCat.find_by(name: item_cat.first)
      department = cat.department
      if @departments[department.name].nil?
        @departments[department.name] = item_cat.second 
      else
        @departments[department.name] = @departments[department.name] + item_cat[1] 
      end
    end
    @supplier_items = {}
    @transaction_items.each do |trx_item|
      item = Item.find_by(id: trx_item[0])
      supplier_item = SupplierItem.find_by(item: item)
      supplier_id = 0 if supplier_item.nil?
      supplier_id = supplier_item.supplier.id if supplier_item.present?
      if @supplier_items[supplier_id].present?
        temp = @supplier_items[supplier_id]
        temp << trx_item
        @supplier_items[supplier_id] = temp
      else
        temp = []
        temp << trx_item
        @supplier_items[supplier_id] = temp 
      end
    end
    @departments = Hash[@departments.sort_by{|k, v| v}.reverse]
    @start_day = start_day
    @kriteria = "Rekap Item Terjual - "+Date.today.to_s

    respond_to do |format|
      format.html
      format.xlsx do
        filename = "./report/trxs/"+store.name+"_trx_items_"+DateTime.now.to_i.to_s+".xlsx"
        p = Axlsx::Package.new
        wb = p.workbook
        wb.add_worksheet(:name => "SUPPLIER ITEMS") do |sheet|
          @supplier_items.each do |supplier_item|
            profits = 0
            taxs = 0
            items = 0
            omzets = 0
            supplier_name = "TIDAK ADA SUPPLIER"
            if supplier_item[0] != 0
              supplier = Supplier.find_by(id: supplier_item[0])
              supplier_name = supplier.name + " ( " + supplier.phone.to_s + " )"
            end
            sheet.add_row [supplier_name.upcase]
            sheet.add_row ["No", "Kode", "Nama", "Status", "Margin", "Beli", "Jual", "Profit", "Terjual", "Omzet", "Total Profit", "Total Pajak"]
            idx = 1
            supplier_item[1].each do |trx_item|
              item_id = trx_item[0]
              sell_qty = 0
              sell = 0
              item =  Item.find_by(id: item_id)
              if item.present?
                trx_items = @trx_items.where(item: item).group(:price).sum(:quantity)
                trx_items.each_with_index do |trx_item|
                  sell = trx_item.first
                  sell_qty = trx_item.second
                  items += sell_qty
                  profit = (sell - item.buy - item.ppn)*sell_qty
                  profits += profit
                  omzet = sell * sell_qty
                  omzets += omzet
                  tax =  omzet -  ( ( 100.0 / (100.0 + item.tax) ) * omzet )  
                  taxs += tax
                  if trx_items.first == trx_item
                    sheet.add_row [idx.to_s, item.code, item.name, item.local_item, item.margin, item.buy.to_i, sell.to_i, (sell-item.buy).to_i, sell_qty.to_i, omzet.to_i, profit.to_i, tax.to_i]
                  else
                    sheet.add_row ["", "", "", "", "", "", sell.to_i, (sell-item.buy).to_i, sell_qty.to_i, omzet.to_i, profit.to_i, tax.to_i]
                  end
                  idx+=1
                end
              end
            end
            sheet.add_row ["","","","","","","","", items.to_i, omzets.to_i, profits.to_i, taxs.to_i]
          end
          
          sheet.add_row [""]
        end
        wb.add_worksheet(:name => "DEPARTEMEN") do |sheet|
          sheet.add_row ["Departemen", "Jumlah"]
          totals = 0
          @departments.each do |dept|
            sheet.add_row [dept.first, dept.second]
            totals += dept.second
          end
          sheet.add_row ["",totals.to_i]
        end

        wb.add_worksheet(:name => "KATEGORI") do |sheet|
          sheet.add_row ["Kategori", "Jumlah"]
          totals = 0
          @item_cats.each do |item_cat|
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
    @transaction_items = TransactionItem.where(transaction_id: params[:id])
    return redirect_back_data_error transactions_path, "Data Transaksi Tidak Ditemukan" if @transaction_items.empty?
  end

  def new
    gon.store_id = current_user.store.id
    gon.cashier_name = current_user.name.upcase.split(" ")[0]
    trx_last_store_id = Transaction.last.store.id
    if !current_user.store.online_store
      return redirect_back_data_error root_path, "ID kasir tidak terdaftar." if trx_last_store_id != current_user.store.id
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
    member_card = nil
    if params[:member] != ""
      member = Member.find_by(card_number: params[:member].to_i)
      if member.present?
        member_card = member.card_number
      end
    end
    trx.member_card = member_card
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

      if item.id == 30331
        trx.has_coin = true
      end
      
      tax += item.ppn * item_par[1].to_f
      pembulatan += item.selisih_pembulatan * item_par[1].to_f

      if trx_item.price == 0
        promo = item_par[5]
        trx_item.reason = promo
        trx_item.save!
      end
      store_stock = StoreItem.find_by(store: current_user.store, item: item)
      hpp_total += (item_par[1].to_i * item.buy).round
      next if store_stock.nil?
      store_stock.stock = store_stock.stock.to_i - item_par[1].to_i
      store_stock.save!
    end
    trx.tax = tax
    trx.pembulatan = pembulatan
    trx.hpp_total = hpp_total
    new_point = trx_total_for_point / @@point
    trx.point = new_point
    trx.save!
    render status: 200, json: {
      invoice: trx.invoice.to_s,
      time: trx.created_at.strftime("%d/%m/%Y %H:%M:%S"),
      
    }.to_json
  end

  private
    def transactions_profit_graph start_day, end_day
      trx = nil
      if current_user.level == "candy_dream"
        trx = Transaction.where(has_coin: true) 
      else
        trx = Transaction.where(has_coin: false) 
      end
      transaction_datas = trx.where("created_at >= ? AND created_at <= ?", start_day, end_day).group_by{ |m| m.created_at.beginning_of_day}
      
      graphs = {}

      transaction_datas.each do |trxs|
        grand_total = 0
        hpp_total = 0
        day_idx = trxs[0].day.to_i - 1
        trxs[1].each do |trx|
          grand_total += trx.grand_total
          hpp_total += trx.hpp_total
        end
        profit = grand_total - hpp_total
        graphs[trxs[0].to_date] = [grand_total, hpp_total, profit]
      end
      graphs = graphs.sort.to_h
      vals = graphs.values
      grand_totals = vals.collect {|ind| ind[0]}
      hpp_totals = vals.collect {|ind| ind[1]}
      profits = vals.collect {|ind| ind[2]}
      days = graphs.keys
      days.each_with_index do |day, idx|
        days[idx] = day.to_date.to_s
      end

      return grand_totals, hpp_totals, profits, days
    end

    def filter_search params, r_type
      results = []
      trx = nil
      if current_user.level == "candy_dream"
        trx = Transaction.where(has_coin: true) 
      else
        trx = Transaction.where(has_coin: false) 
      end
      @transactions = trx.order("created_at DESC")
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
      @transactions = @transactions.where(store: current_user.store) if  !["owner", "super_admin", "finance", "candy_dream"].include? current_user.level
      @transactions = @transactions.where(has_coin: true) if current_user.level == "candy_dream"
      
      @search = ""
      if params["search"].present?
        @search += "Pencarian "+params["search"]
        search = params["search"].downcase
        @transactions =@transactions.where("invoice like ?", "%"+ search+"%")
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


