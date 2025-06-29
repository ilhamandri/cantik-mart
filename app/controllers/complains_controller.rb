class ComplainsController < ApplicationController
  before_action :require_login
  before_action :screening
  

  @@max_complain = 30
  
  def index
    filter = filter_search params, "html"
    @search = filter[0]
    @finances = filter[1]
    @params = params.to_s

    complains = Serve.complain_graph_monthly dataFilter
    gon.loss_label = complains["label"]
    gon.complain = complains["complain"]
    gon.complain_item = complains["complain_item"]

    respond_to do |format|
      format.html
      format.pdf do
        new_params = eval(params[:option])
        filter = filter_search new_params, "pdf"
        @search = filter[0]
        @finances = filter[1]
        @store_name= filter[2]
        render pdf: DateTime.now.to_i.to_s,
          layout: 'pdf_layout',
          template: "complains/print_all", 
          formats: [:html], 
          disposition: :inline
      end
    end
  end

  def new
    return redirect_back_data_error complains_path, "Data tidak ditemukan" unless params[:id].present?
    id = params[:id]
    @transaction = Transaction.find id
    return redirect_back_data_error complains_path, "Data tidak ditemukan" if @transaction.nil?
    complain = (@transaction.created_at >= (DateTime.now - @@max_complain.days))
    return redirect_back_data_error complains_path, "Data tidak valid" if !complain
    return redirect_back_data_error complains_path, "Data tidak valid" if @transaction.user.store != current_user.store
    @transaction_items = @transaction.transaction_items
    return redirect_back_data_error complains_path, "Tidak dapat melakukan komplain" if Complain.find_by(transaction_id: @transaction).present?
  end

  def create
    return redirect_back_data_error complains_path, "Data tidak ditemukan" unless params[:id].present?
    id = params[:id]
    transaction = Transaction.find id
    return redirect_back_data_error complains_path, "Data tidak ditemukan" if transaction.nil?
    complain = (transaction.created_at >= (DateTime.now - @@max_complain.days))
    return redirect_back_data_error complains_path, "Data tidak valid" if !complain
    return redirect_back_data_error complains_path, "Data tidak valid" if transaction.user.store != current_user.store
    return redirect_back_data_error complains_path, "Tidak dapat melakukan komplain" if Complain.find_by(transaction_id: transaction).present?
    invoice = "CMP-" + Time.now.to_i.to_s
    items = complain_items
    total_item = items.size
    new_items = new_complain_items
    complain = Complain.create invoice: invoice,
      total_items: total_item,
      store_id: current_user.store.id,
      date_created: Time.now,
      member_card: transaction.member_card,
      user_id: current_user.id,
      transaction_id: transaction.id

    items_retur_total = 0
    nominal = 0

    items.each do |complain_item|
      trx_item = TransactionItem.find_by(id: complain_item[0])
      item = trx_item.item
      store_stock = StoreItem.find_by(item: item, store: transaction.store)

      reason = complain_item[5]
      retur = complain_item[3].to_i
      replace = complain_item[4].to_i

      next if retur == 0

      next if (retur - replace) < 0

      nominal += (retur - replace) * (trx_item.price-trx_item.discount)
      trx_item.retur = retur
      trx_item.replace = replace
      trx_item.reason = reason

      store_stock.stock = store_stock.stock + retur - replace
      item.counter += retur - replace
      item.save!
      store_stock.save!
      trx_item.save!
      items_retur_total += retur

      transaction.grand_total = transaction.grand_total - ((retur-replace) * (trx_item.price-trx_item.discount))
      transaction.tax = transaction.tax - ((retur-replace) * (trx_item.item.ppn))
      transaction.hpp_total = transaction.hpp_total - ((retur-replace) * (trx_item.item.buy))
      transaction.save!
    end
    
    complain.total_items = items_retur_total
    complain.nominal = nominal
    complain.save!

    if new_items.count > 0
      new_trx = Transaction.new
      new_trx.invoice = "TRX-" + Time.now.to_i.to_s + "-" + current_user.store.id.to_s + "-" + current_user.id.to_s
      new_trx.user = current_user
      member_card = nil
      if params[:member] != ""
        member = Member.find_by(card_number: params[:member].to_i)
        if member.present?
          member_card = member.card_number
        end
      end

      total = 0
      discount = 0
      hpp = 0

      new_trx.member_card = member_card
      new_trx.date_created = Time.now
      new_trx.payment_type = 1
      new_trx.store = current_user.store
      new_trx.from_complain = true
      new_trx.complain_id = complain.id
      new_trx.sub_from_complain = nominal
      new_trx.items = new_items.count
      new_trx.discount = discount
      new_trx.total = total
      new_trx.hpp_total = hpp
      new_trx.grand_total = total - discount
      new_trx.save!
      tax = 0
      pembulatan = 0
      new_items.each do |new_item|
        item = Item.find_by(id: new_item[0])
        buy = item.buy
        store_item = StoreItem.find_by(item: item, store: current_user.store)
        if item.local_item?
          buy = store_item.buy
        end

        qty = new_item[1].to_i
        price = new_item[2].to_f
        disc = new_item[3].to_f
        
        store_item.stock = store_item.stock - qty
        store_item.save!

        hpp += (buy * qty).round
        discount += disc * qty
        total += price * qty

        trx_item = TransactionItem.create item: item,  
        transaction_id: new_trx.id,
        quantity: qty, 
        price: price,
        discount: disc,
        date_created: DateTime.now,
        store: current_user.store

        if trx_item.quantity > 1
          grocer_item = GrocerItem.find_by(item: item, price: trx_item.price-trx_item.discount)
          
          if grocer_item.present?
            trx_item.ppn = grocer_item.ppn * new_item[1].to_f
            tax += grocer_item.ppn * new_item[1].to_f
            pembulatan += grocer_item.selisih_pembulatan * new_item[1].to_f
          else
            trx_item.ppn = item.ppn * new_item[1].to_f
            tax += item.ppn * new_item[1].to_f
            pembulatan += item.selisih_pembulatan * new_item[1].to_f
          end
        else
          trx_item.ppn = item.ppn * new_item[1].to_f
          tax += item.ppn * new_item[1].to_f
          pembulatan += item.selisih_pembulatan * new_item[1].to_f
        end

        item_suppliers = SupplierItem.where(item: trx_item.item)
        trx_item.supplier = item_suppliers.first.supplier if item_suppliers.present?
        trx_item.total = trx_item.quantity * (trx_item.price-trx_item.discount)
        trx_item.profit = trx_item.total - trx_item.ppn - (trx_item.item.buy * trx_item.quantity)
        
        trx_item.save!
      end
      
      new_trx.discount = discount
      new_trx.total = total
      new_trx.hpp_total = hpp
      new_trx.grand_total = total - discount
      new_trx.tax = tax
      new_trx.pembulatan = pembulatan
      new_trx.save!

      complain.nominal = new_trx.grand_total - complain.nominal
      complain.save!

      new_trx.create_activity :create, owner: current_user
    end

    complain.create_activity :create, owner: current_user

    return redirect_success complains_path, "Komplain "+transaction.invoice+" selesai"
  end

  def show
    return redirect_back_data_error complains_path, "Data tidak ditemukan" unless params[:id].present?
    id = params[:id]
    @complain = Complain.find_by(id: id)
    @transaction = Transaction.find_by(id: @complain.transaction_id)
    return redirect_back_data_error complains_path, "Data tidak ditemukan" if @transaction.nil?
    return redirect_back_data_error complains_path, "Tidak memiliki hak akses" if (@transaction.user.store != current_user.store)
    @transaction_items = @transaction.transaction_items

    respond_to do |format|
      format.html
      format.pdf do
        render pdf: DateTime.now.to_i.to_s,
          layout: 'pdf_layout',
          template: "complains/print", 
          formats: [:html], 
          disposition: :inline
      end
    end
  end

  private
    def filter_search params, r_type
      results = []
      @complains = Complain.includes(:store, :user).all.order("created_at DESC")
      if r_type=="html"
        @complains = @complains.includes(:store, :user).page param_page
      end
      @complains = @complains.where(store: current_user.store) if  !["owner", "super_admin", "finance"].include? current_user.level
      @search = ""
      if params["search"].present?
        @search += "Pencarian "+params["search"]
        search = "CMP-"+params["search"].gsub("CMP-","")
        @complains =@complains.search_by_invoice search
      end

      before_months = params["months"].to_i
      if before_months != 0
        @search += before_months.to_s + " bulan terakhir "
        start_months = (DateTime.now - before_months.months).beginning_of_month.beginning_of_day 
        @complains = @complains.where("created_at >= ?", start_months)
      end
      
      store_name = "SEMUA TOKO"
      if params["store_id"].present?
        store = Store.find_by(id: params["store_id"])
        if store.present?
          @complains = @complains.where(store: store)
          store_name = store.name
          @search += "Pencarian" if @search==""
          @search += " di Toko '"+store.name+"'"
        else
          @search += "Pencarian" if @search==""
          @search += " di Semua Toko"
        end
      end

      results << @search
      results << @complains
      results << store_name
      return results
    end
    
    def complain_items
      items = []
      retur_qty_status = false
      params[:complain][:complain_items].each do |item|
        complain_items_value = item[1].values
        
        qty = complain_items_value[2].to_i
        retur = complain_items_value[3].to_i
        replace = complain_items_value[4].to_i

        if qty < retur
          items = []
          break
        else
          if retur < replace
            items = []
            break
          end
        end

        items << complain_items_value
        retur_qty_status = true if retur_qty_status==false && retur>0
      end
      items
    end

    def new_complain_items
      items = []
      return items if  params[:complain][:new_complain_items].nil?
      params[:complain][:new_complain_items].each do |item|
        items << item[1].values
      end
      items
    end

    def param_page
      params[:page]
    end

end
