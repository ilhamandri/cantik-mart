class TransactionsController < ApplicationController
  before_action :require_login
  before_action :require_fingerprint
  skip_before_action :verify_authenticity_token, :if => Proc.new { |c| c.request.format == 'application/json' }

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

    transactions = transactions_profit_graph "month"
    gon.grand_totals = transactions[0]
    gon.hpp_totals = transactions[1]
    gon.profits = transactions[2]

  end

  def show
    return redirect_back_data_error transactions_path, "Data Transaksi Tidak Ditemukan" if params[:id].nil?
    @transaction_items = TransactionItem.where(transaction_id: params[:id])
    return redirect_back_data_error transactions_path, "Data Transaksi Tidak Ditemukan" if @transaction_items.empty?
  end

  def new
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

    items.each do |trx_item|
      item += trx_item[1].to_i
      discount += trx_item[1].to_i * trx_item[3].to_i
      total += trx_item[1].to_i * trx_item[2].to_i
      grand_total += trx_item[4].to_i
    end

    trx = Transaction.new
    trx.invoice = "TRX-" + Time.now.to_i.to_s + "-" + current_user.store.id.to_s + "-" + current_user.id.to_s
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
    
    items.each do |item_par|
      item = Item.find_by(code: item_par[0])
      next if item.nil?
      TransactionItem.create item: item,  
      transaction_id: trx.id,
      quantity: item_par[1], 
      price: item_par[2],
      discount: item_par[3],
      date_created: DateTime.now
      store_stock = StoreItem.find_by(store: current_user.store, item: item)
      hpp_total += (item_par[1].to_i * item.buy).round.to_f
      next if store_stock.nil?
      store_stock.stock = store_stock.stock.to_i - item_par[1].to_i
      store_stock.save!
    end
    trx.hpp_total = hpp_total
    trx.save!

    render status: 200, json: {
      message: "Transaksi Berhasil"
    }.to_json
  end

  private
    def transactions_profit_graph group
      transaction_datas = nil
      if group == "month" 
        transaction_datas = Transaction.where("created_at >= ? AND created_at <= ?", DateTime.now.beginning_of_year, DateTime.now.end_of_year).group_by{ |m| m.created_at.beginning_of_month}
      end

      grand_totals = [0,0,0,0,0,0,0,0,0,0,0,0]
      hpp_totals = [0,0,0,0,0,0,0,0,0,0,0,0]
      profits = [0,0,0,0,0,0,0,0,0,0,0,0]

      transaction_datas.each do |trxs|
        grand_total = 0
        hpp_total = 0
        month_idx = trxs[0].month.to_i - 1
        trxs[1].each do |trx|
          grand_total += trx.grand_total
          hpp_total += trx.hpp_total
        end
        profit = grand_total - hpp_total
        grand_totals[month_idx] = grand_total
        hpp_totals[month_idx] = hpp_total
        profits[month_idx] = profit
      end

      return [grand_totals, hpp_totals, profits]
    end

    def filter_search params, r_type
      results = []
      @transactions = Transaction.all
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

      before_months = params["months"].to_i
      if before_months != 0
        @search += before_months.to_s + " bulan terakhir "
        start_months = (DateTime.now - before_months.months).beginning_of_month.beginning_of_day 
        @transactions = @transactions.where("created_at >= ?", start_months)
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
