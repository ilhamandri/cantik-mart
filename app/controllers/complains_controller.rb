class ComplainsController < ApplicationController
  before_action :require_login
  before_action :require_fingerprint
  def index
    @complains = Complain.page param_page
    @complains = @complains.where(store: current_user.store) if  !["owner", "super_admin", "finance"].include? current_user.level
    if params[:search].present?
      search = params[:search].downcase
      @search = search
      search_arr = search.split(":")
      if search_arr.size > 2
        complainn redirect_back_no_access_right
      elsif search_arr.size == 2
        store = Store.where('lower(name) like ?', "%"+search_arr[1].downcase+"%").pluck(:id)
        member = Member.where('lower(pic) like ?', "%"+search_arr[1].downcase+"%").pluck(:id)
          if search_arr[0]== "to" && member.present?
            @complains = @complains.where(member: member)
          elsif search_arr[0]== "from" && store.present?
            @complains = @complains.where(store_id: store)
          else
            @complains = @complains.where("invoice like ?", "%"+ search_arr[1]+"%")
          end
      else
        @complains = @complains.where("invoice like ?", "%"+ search+"%")
      end
    end
  end

  def new
    return redirect_back_data_error complains_path, "Data tidak ditemukan" unless params[:id].present?
    id = params[:id]
    @transaction = Transaction.find id
    return redirect_back_data_error complains_path, "Data tidak ditemukan" if @transaction.nil?
    return redirect_back_data_error complains_path, "Data tidak valid" if @transaction.user.store != current_user.store
    @transaction_items = @transaction.transaction_items
    return redirect_back_data_error complains_path, "Tidak dapat melakukan komplain" if Complain.find_by(transaction_id: @transaction).present?
  end

  def create
    return redirect_back_data_error complains_path, "Data tidak ditemukan" unless params[:id].present?
    id = params[:id]
    @transaction = Transaction.find id
    return redirect_back_data_error complains_path, "Data tidak ditemukan" if @transaction.nil?
    return redirect_back_data_error complains_path, "Data tidak valid" if @transaction.user.store != current_user.store
    return redirect_back_data_error complains_path, "Tidak dapat melakukan komplain" if Complain.find_by(transaction_id: @transaction).present?
    invoice = "CMP-" + Time.now.to_i.to_s
    items = complain_items
    total_item = items.size
    new_items = new_complain_items
    complain = Complain.create invoice: invoice,
      total_items: total_item,
      store_id: current_user.store.id,
      date_created: Time.now,
      member_id: @transaction.member,
      user_id: current_user.id,
      transaction_id: @transaction.id

    complain_items.each do |complain_item|
      item = Item.find complain_item[0]
      if item.nil?
        complain.delete
        return redirect_back_data_error returs_path, "Data tidak valid"
      else
        store_stock = StoreItem.find_by(item_id: item.id)
        if store_stock.nil?
          complain.delete
          return redirect_back_data_error returs_path, "Data tidak valid"
        end

        reason = complain_item[5]
        retur = complain_item[3].to_i
        replace = complain_item[4].to_i

        transaction_items = @transaction.transaction_items.find_by(item: item)
        transaction_items.retur = retur
        transaction_items.replace = replace
        transaction_items.reason = reason
        
        new_stock = store_stock.stock + retur - replace
        next if (retur - replace) <= 0
        item.buy = ( (item.buy*store_stock.stock) + ( (transaction_items.price-transaction_items.discount) * (retur-replace) ) ) / new_stock
        item.save!
        store_stock.save!
        transaction_items.save!
      end      
    end

    additional_total = 0
    additional_discount = 0
    new_items.each do |new_item|
      item = Item.find_by(id: new_item[0])
      trx_item = TransactionItem.create item: item,  
      transaction_id: @transaction.id,
      quantity: new_item[1], 
      price: new_item[2],
      discount: 0,
      date_created: DateTime.now
      additional_total+= new_item[1].to_i * new_item[2].to_i
      additional_discount+= new_item[1].to_i * new_item[3].to_i
    end

    @transaction.total = @transaction.total + additional_total
    @transaction.discount = @transaction.discount + additional_discount
    @transaction.grand_total = @transaction.grand_total + (additional_total - additional_discount)
    @transaction.save!

    # ubah data transaksi di hari trx ini

    complain.create_activity :create, owner: current_user

    return redirect_success complains_path, "Komplain "+@transaction.invoice+" selesai"
  end

  def show
    return redirect_back_data_error, "Data tidak ditemukan" unless params[:id].present?
    id = params[:id]
    @complain = Complain.find_by(id: id)
    @transaction = Transaction.find_by(id: @complain.transaction_id)
    return redirect_back_data_error complains_path, "Data tidak ditemukan" if @transaction.nil?
    return redirect_back_data_error complains_path, "Tidak memiliki hak akses" if @transaction.user.store != current_user.store
    @transaction_items = @transaction.transaction_items
  end

  private
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
