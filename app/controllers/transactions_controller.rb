class TransactionsController < ApplicationController
  before_action :require_login
  before_action :require_fingerprint
  skip_before_action :verify_authenticity_token, :if => Proc.new { |c| c.request.format == 'application/json' }

  def index
    @transactions = Transaction.page param_page
    if params[:search].present?
      search = params[:search].downcase
      @search = search
      search_arr = search.split(":")
      if search_arr.size > 2
        return redirect_back_data_error transactions_path, "Data Tidak Valid"
      elsif search_arr.size == 2
        store = Store.where('lower(store) like ?', "%"+search_arr[1].downcase+"%").pluck(:id)
          if search_arr[0]== "store" && store.present?
            @transactions = @transactions.where(store_id: store)
          else
            @transactions = @transactions.where("invoice like ?", "%"+ search_arr[1]+"%")
          end
      else
        @transactions = @transactions.where("invoice like ?", "%"+ search+"%")
      end
    end
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
    trx.invoice = "TRX-" + Time.now.to_i.to_s
    trx.user = current_user
    member_id = nil
    if params[:member] != ""
      member = Member.find_by(card_number: params[:member].to_i)
      if member.nil?
        member_id = nil
      else
        member_id = member.id
      end
    end
    trx.member_id = member_id
    trx.date_created = Time.now
    trx.payment_type = params[:payment]

    trx.items = item.to_i
    trx.discount = discount.to_i
    trx.total = total.to_i
    trx.grand_total = grand_total.to_i

    if params[:payment] != 1
      trx.bank = params[:bank]
      trx.edc_inv = params[:edc]
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
      hpp_total += item_par[1].to_i * item.buy.to_i
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
