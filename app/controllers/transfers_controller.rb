class TransfersController < ApplicationController
  before_action :require_login
  before_action :require_fingerprint
  def index
    @transfers = Transfer.order("date_created DESC").page param_page
    if params[:search].present?
      search = params[:search].downcase
      @search = search
      search_arr = search.split(":")
      if search_arr.size > 2
        return redirect_back_data_error transfers_path, "Data Transfer Tidak Ditemukan"
      elsif search_arr.size == 2
        store = Store.where('lower(name) like ?', "%"+search_arr[1].downcase+"%").pluck(:id)
        if store.present?
          if search_arr[0]== "to"
            @transfers = @transfers.where(to_store_id: store)
          elsif search_arr[1]== "from"
            @transfers = @transfers.where(from_store_id: store)
          else
            @transfers = @transfers.where("invoice like ?", "%"+ search_arr[1]+"%")
          end
        end
      else
        @transfers = @transfers.where("invoice like ?", "%"+ search+"%")
      end
    end
  end

  def new
    @stores = Store.all
    @inventories = StoreItem.page param_page
    all_options = ""
    @inventories.each do |inventory|
      stock = inventory.item
      all_options+= "<option value="+stock.id.to_s+" data-subtext='"+stock.item_cat.name+"'>"+stock.name+"</option>"
    end
    gon.select_options = all_options
    gon.inv_count = 2
  end

  def create
    invoice = "TRF-" + Time.now.to_i.to_s
    items = transfer_items
    total_item = items.size
    to_store = params[:transfer][:store_id]

    return redirect_back_data_error transfers_path, "Data Transfer Tidak Ditemukan" unless items.present?
    
    transfer = Transfer.create invoice: invoice,
      total_items: total_item,
      from_store_id: current_user.store.id,
      date_created: Time.now,
      to_store_id: to_store,
      user: current_user

    trf_status = false
    items.each do |item|
      check_item = Item.find item[0]
      next if check_item.nil?
      qty = item[1].to_i
      next if qty < 1
      TransferItem.create item_id: item[0], transfer_id: transfer.id, request_quantity: qty, description: item[2]
      if !check_item.local_item
        trf_status = true
      end
    end


    transfer.create_activity :create, owner: current_user
    urls = transfer_items_path id: transfer.id

    if !trf_status
      transfer.date_approve = "01-01-1999".to_date
      transfer.date_picked = "01-01-1999".to_date
      transfer.status = "01-01-1999".to_date
      transfer.description = "Dibatalkan otomatis oleh sistem (terdapat local item)" 
      transfer.save!
      return redirect_back_data_error urls, "Dibatalkan otomatis oleh sistem (tidak ada barang yang dikirim / terdapat item dengan local item)"
    else
      return redirect_success urls, "Data Transfer - " + transfer.invoice + " - Berhasil Disimpan"
    end
    
  end

  def confirmation
    return redirect_back_data_error transfers_path unless params[:id].present?
    @transfer = Transfer.find params[:id]
    return redirect_back_data_error transfers_path unless @transfer.present?
    return redirect_back_data_error transfers_path if @transfer.date_approve.present?
    @transfer_items = TransferItem.where(transfer_id: @transfer.id)
  end

  def accept
    return redirect_back_data_error transfers_path, "Data Transfer Tidak Ditemukan" unless params[:id].present?
    transfer = Transfer.find params[:id]
    return redirect redirect_back_data_error transfers_path, "Data Transfer Tidak Ditemukan" unless transfer.present?
    return redirect_back_data_error transfers_path "Data Transfer Tidak Valid" if transfer.date_confirm.present? || transfer.date_picked.present?
    if params[:transfer][:status]=="0"
      transfer.description = "Dibatalkan oleh " + current_user.name + "("+current_user.store.name+") pada "+DateTime.now.to_date.to_s
      transfer.date_approve = "01-01-1999".to_date
      transfer.date_picked = "01-01-1999".to_date
      transfer.status = "01-01-1999".to_date
    else
      transfer.date_approve = DateTime.now
      transfer.approved_by = current_user
    end
    
    transfer.save!
    urls = transfer_items_path id: params[:id]
    return redirect_success urls, "Data Transfer " + transfer.invoice + " Telah Dikonfirmasi"
  end

  def picked
    return redirect_back_data_error transfers_path, "Data Transfer Tidak Ditemukan" unless params[:id].present?
    @transfer = Transfer.find params[:id]
    return redirect_back_data_error transfers_path, "Data Transfer Tidak Ditemukan" unless @transfer.present?
    return redirect_back_data_error transfers_path, "Data Transfer Tidak Valid" if @transfer.date_approve.nil? || @transfer.date_picked.present?
    @transfer_items = TransferItem.where(transfer_id: @transfer.id)
  end

  def sent
    return redirect_back_data_error transfers_path, "Data Transfer Tidak Ditemukan" unless params[:id].present?
    transfer = Transfer.find params[:id]
    return redirect_back_data_error transfers_path, "Data Transfer Tidak Ditemukan" if transfer.nil?
    return redirect_back_data_error transfers_path, "Data Transfer Tidak Valid" unless transfer.to_store_id == current_user.store.id
    return redirect_back_data_error transfers_path, "Data Transfer Tidak Valid" if transfer.date_picked.present? || transfer.status.present?
    status = sent_items params[:id] 
    transfer.date_picked = DateTime.now
    transfer.picked_by = current_user
    if status==false
      transfer.status = "01-01-1999".to_date
      transfer.description = "Dibatalkan otomatis oleh sistem (tidak ada barang yang dikirim)" 
      transfer.save!
      return redirect_back_data_error transfers_path, "Dibatalkan otomatis oleh sistem (tidak ada barang yang dikirim)"
    else
      transfer.save!
      return redirect_success transfers_path, "Item Transfer Telah Disimpan"
    end
    
    return redirect_success transfers_path, "Item Transfer Telah Disimpan"
  end

  def receive
    return redirect_back_data_error transfers_path, "Data Transfer Tidak Ditemukan" unless params[:id].present?
    @transfer = Transfer.find params[:id]
    return redirect_back_data_error transfers_path, "Data Transfer Tidak Ditemukan" unless @transfer.present?
    return redirect_back_data_error transfers_path, "Data Transfer Tidak Valid" if @transfer.date_approve.nil? || @transfer.date_picked.nil?|| @transfer.status.present?
    @transfer_items = TransferItem.where(transfer_id: @transfer.id)
  end

  def received
    return redirect_back_data_error, "Data Transfer Tidak Ditemukan" unless params[:id].present?
    transfer = Transfer.find params[:id]
    return redirect_back_data_error transfers_path, "Data Transfer Tidak Ditemukan" if transfer.nil?
    return redirect_back_data_error transfers_path, "Data Transfer Tidak Valid" unless transfer.from_store_id == current_user.store.id
    return redirect_back_data_error transfers_path, "Data Transfer Tidak Valid" if transfer.date_picked.nil? || transfer.date_approve.nil? || transfer.status.present?
    receive_items params[:id]
    transfer.status = DateTime.now
    transfer.confirmed_by = current_user
    transfer.save!
    return redirect_success transfers_path, "Transfer Telah Diterima"
  end

  def destroy
    return redirect_back_data_error transfers_path, "Transfer Telah Diterima" unless params[:id].present?
    transfer = Transfer.find params[:id]
    return redirect_back_data_error transfers_path, "Data Transfer Tidak Ditemukan" unless transfer.present?
    return redirect_back_data_error transfers_path, "Data Transfer Tidak Ditemukan" if transfer.date_approve.present?
    TransferItem.where(transfer_id: params[:id]).destroy_all
    transfer.destroy
    return redirect_success transfers_path, "Transfer Telah Dihapus"
  end

  def show
    return redirect_back_data_error transfers_path, "Data Transfer Tidak Ditemukan" unless params[:id].present?
    @transfer = Transfer.find_by_id params[:id]
    return redirect_back_data_error transfers_path, "Data Transfer Tidak Ditemukan" unless @transfer.present?
    respond_to do |format|
      format.html
      format.pdf do
        render pdf: @transfer.invoice,
          layout: 'pdf_layout.html.erb',
          template: "transfers/print.html.slim"
      end
    end
  end

  private
    def transfer_items
      items = []
      return items if params[:transfer][:transfer_items].nil?
      params[:transfer][:transfer_items].each do |item|
        items << item[1].values
      end
      items
    end

    def sent_items transfer_id
      status = false
      transfer_items.each do |item|
        transfer_item = TransferItem.find item[2]
        store_item = StoreItem.find_by(item_id: item[0], store_id: current_user.store.id)
        qty = item[1].to_i
        
        next if store_item.nil?

        next if store_item.stock <= 0

        if store_item.present?
          if transfer_item.request_quantity < qty
            qty = transfer_item.request_quantity
          end
          status = true if store_item.stock >= qty 
        else
          qty = 0
        end
            
        transfer_item.sent_quantity = qty
        transfer_item.save!
        new_stock = store_item.stock.to_i - qty
        store_item.stock = new_stock
        store_item.save!
      end
      return status
    end

    def receive_items transfer_id
      transfer = Transfer.find transfer_id
      from_store = transfer.from_store
      to_store = transfer.to_store
      status = true
      transfer_items.each do |item|
        transfer_item = TransferItem.find item[2]
        qty = item[1].to_i.abs
        transfer_item.receive_quantity = qty
        transfer_item.save!
        store_item = StoreItem.find_by(item_id: item[0], store_id: current_user.store.id)
        
        buy = store_item.item.buy

        if store_item.nil?
          StoreItem.create store: current_user.store, item_id: item[0], stock: qty
        else
          sent_qty = transfer_item.sent_quantity
          if qty != sent_qty 
            status = false
          end 
          store_item.stock =  store_item.stock.to_i + qty
          from_store.equity = from_store.equity + (buy * qty)
          to_store.equity = to_store.equity - (buy * qty)
          from_store.save!
          to_store.save!
          store_item.save!
        end
      end
      return status
    end

    def param_page
      params[:page]
    end

end
