class TransactionsController < ApplicationController
  before_action :require_login
  before_action :require_fingerprint
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

    inv = TransactionItem.invoice
    transactions.each do |trx_item|
    
    if inv.include? "c"
         
    end
    
    
    respond_to do |format|
      format.html
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

    transactions = transactions_profit_graph "day"
    gon.grand_totals = transactions[0]
    gon.hpp_totals = transactions[1]
    gon.profits = transactions[2]
    gon.days = transactions[3]

  end

  def daily_recap
    curr_date = DateTime.now
    end_day = (params[:date].to_s + " 00:00:00 +0700").to_time.end_of_day
    start_day = end_day.beginning_of_day
    @end = end_day
    @start = start_day
    cirata = Store.find_by(id: 2)
    plered = Store.find_by(id: 3)

    cash_flow = CashFlow.where("created_at >= ? AND created_at <= ?", start_day, end_day)
    trx = Transaction.where("created_at >= ? AND created_at <= ?", start_day, end_day)
    
    grand_total_plered = trx.where(store: plered).sum(:grand_total)
    hpp_total_plered = trx.where(store: plered).sum(:hpp_total)
    grand_total_cirata = trx.where(store: cirata).sum(:grand_total)
    hpp_total_cirata = trx.where(store: cirata).sum(:hpp_total)

    @margin_plered = grand_total_plered - hpp_total_plered
    @margin_cirata = grand_total_cirata - hpp_total_cirata
    @supplier_income = 0
    @bonus = cash_flow.where(finance_type: CashFlow::BONUS).sum(:nominal)
    @other_income = cash_flow.where(finance_type: CashFlow::INCOME).sum(:nominal)

    @total_income = @margin_plered + @margin_cirata + @supplier_income + @bonus + @other_income
  
    cash_flow = CashFlow.where("created_at >= ? AND created_at <= ?", start_day, end_day)
    @operational = cash_flow.where(finance_type: [CashFlow::OPERATIONAL, CashFlow::TAX]).sum(:nominal)
    @fix_cost = cash_flow.where(finance_type: CashFlow::FIX_COST).sum(:nominal)
    
    @total_outcome = @operational + @fix_cost


    start_day = (params[:date].to_s + " 00:00:00 +0700").to_time
    end_day = start_day.end_of_day
    @transactions = Transaction.where("created_at >= ? AND created_at <= ?", start_day, end_day)
    @transactions = @transactions.order("created_at DESC")
    @start_day = start_day
    @kriteria = "Rekap Harian - "+Date.today.to_s
    @cashiers = @transactions.pluck(:user_id)
    render pdf: DateTime.now.to_i.to_s,
      layout: 'pdf_layout.html.erb',
      template: "transactions/print_recap.html.slim"
  end

  def daily_recap_item
    start_day = params[:date].to_time
    end_day = start_day.end_of_day
    @transaction_items = TransactionItem.where("created_at >= ? AND created_at <= ?", start_day, end_day).group(:item_id).count
    @transaction_items = @transaction_items.sort_by(&:last).reverse
    @item_cats = {}
    @transaction_items.each do |trx_item|
      item = Item.find_by(id: trx_item.first)
      item_cat = item.item_cat
      @item_cats[item_cat.name] = trx_item[1] if @item_cats[item_cat.name].nil?
      @item_cats[item_cat.name] = @item_cats[item_cat.name] + trx_item[1] if  @item_cats[item_cat.name].present?
    end
    @item_cats = Hash[@item_cats.sort_by{|k, v| v}.reverse]
    @departments = {}
    @item_cats.each do |item_cat|
      cat = ItemCat.find_by(name: item_cat.first)
      department = cat.department
      @departments[department.name] = item_cat.second if @departments[department.name].nil?
      @departments[department.name] = @departments[department.name] + item_cat[1] if  @departments[department.name].present?
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
    render pdf: DateTime.now.to_i.to_s,
      layout: 'pdf_layout.html.erb',
      template: "transactions/print_item_recap.html.slim"
  end

  def show
    return redirect_back_data_error transactions_path, "Data Transaksi Tidak Ditemukan" if params[:id].nil?
    @transaction_items = TransactionItem.where(transaction_id: params[:id])
    return redirect_back_data_error transactions_path, "Data Transaksi Tidak Ditemukan" if @transaction_items.empty?
  end

  def new
    gon.invoice = Time.now.to_i.to_s + "-" + current_user.store.id.to_s + "-" + current_user.id.to_s
    gon.cashier = current_user.name.upcase
    gon.current_time = DateTime.now.to_s

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
    trx.invoice = "TRX-" + params[:invoice]
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

    if params[:payment] != 1
      trx.bank = params[:bank].to_i
      trx.edc_inv = params[:edc].to_s
      trx.card_number = params[:card].to_s
    end
    trx.save!
    
    trx_total_for_point = 0
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
      price: item_par[2].to_f,
      discount: item_par[3],
      date_created: DateTime.now

      if trx_item.price == 0
        promo = item_par[5]
        trx_item.reason = promo
        trx_item.save!
      end
      store_stock = StoreItem.find_by(store: current_user.store, item: item)
      next if store_stock.nil?
      hpp_total += (item_par[1].to_i * item.buy).round if !item.local_item
      hpp_total += (item_par[1].to_i * store_stock.buy).round if item.local_item
      store_stock.stock = store_stock.stock.to_f - item_par[1].to_f
      store_stock.save!
    end
    trx.hpp_total = hpp_total
    new_point = trx_total_for_point / @@point
    trx.point = new_point
    trx.save!

    render status: 200, json: {
      message: "Transaksi Berhasil"
    }.to_json

  end

  private
    def transactions_profit_graph group
      transaction_datas = []
      if group == "day" 
        transaction_datas = Transaction.where("created_at >= ? AND created_at <= ?", DateTime.now.beginning_of_month, DateTime.now.end_of_month).group_by{ |m| m.created_at.beginning_of_day}
      end

      grand_totals = []
      hpp_totals = []
      profits = []
      days = []


      Time.days_in_month(Date.today.month.to_i).times do |idx|
        grand_totals << 0
        hpp_totals << 0
        profits << 0
        days << idx
      end

      transaction_datas.each do |trxs|
        grand_total = 0
        hpp_total = 0
        day_idx = trxs[0].day.to_i - 1
        trxs[1].each do |trx|
          grand_total += trx.grand_total
          hpp_total += trx.hpp_total
        end
        profit = grand_total - hpp_total
        grand_totals[day_idx] = grand_total
        hpp_totals[day_idx] = hpp_total
        profits[day_idx] = profit
      end


      return [grand_totals, hpp_totals, profits, days]
    end

    def filter_search params, r_type
      results = []
      @transactions = Transaction.all.order("created_at DESC")
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
      @transactions = @transactions.where(store: current_user.store) if  !["owner", "super_admin", "finance"].include? current_user.level
      
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
