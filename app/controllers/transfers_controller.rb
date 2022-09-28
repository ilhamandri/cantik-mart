class TransfersController < ApplicationController
  before_action :require_login
  before_action :screening
  
  def index
    filter = filter_search params, "html"
    @search = filter[0]
    @transfers = filter[1]
    @params = params.to_s

    respond_to do |format|
      format.html
      format.pdf do
        new_params = eval(params[:option])
        filter = filter_search new_params, "pdf"
        @search = filter[0]
        @transfers = filter[1]
        @store_name= filter[2]
        render pdf: DateTime.now.to_i.to_s,
          layout: 'pdf_layout.html.erb',
          template: "transfers/print_all.html.slim"
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
    urls = transfer_path id: transfer.id

    if !trf_status
      transfer.date_approve = "01-01-1999".to_date
      transfer.date_picked = "01-01-1999".to_date
      transfer.status = "01-01-1999".to_date
      transfer.description = "Dibatalkan otomatis oleh sistem (terdapat local item)" 
      transfer.save!
      return redirect_back_data_error urls, "Dibatalkan otomatis oleh sistem (tidak ada barang yang dikirim / terdapat item dengan local item)"
    else
      users = User.where(store: transfer.to_store, level: User::SUPERVISI)
      users.each do |user|
        set_notification(current_user, user, 
          Notification::INFO, "Permintaan transfer"+transfer.invoice, urls)
      end
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
      transfer.approved_by = current_user
      transfer.description = "Dibatalkan oleh " + current_user.name + "("+current_user.store.name+") pada "+DateTime.now.to_date.to_s
      transfer.date_approve = "01-01-1999".to_date
      transfer.date_picked = "01-01-1999".to_date
      transfer.status = "01-01-1999".to_date
      set_notification current_user, transfer.user, "danger", "Transfer #"+transfer.invoice+" dibatalkan oleh " + current_user.name + "("+current_user.store.name+") pada "+DateTime.now.to_date.to_s, transfer_path(id: transfer.id)
    else
      transfer.date_approve = DateTime.now
      transfer.approved_by = current_user
      set_notification current_user, transfer.user, "success", "Transfer #"+transfer.invoice+" diterima oleh " + current_user.name + "("+current_user.store.name+") pada "+DateTime.now.to_date.to_s, transfer_path(id: transfer.id)
    
    end
    
    transfer.save!
    urls = transfer_path id: params[:id]
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
    return redirect_back_data_error transfers_path, "Data Transfer Tidak Valid (1)" if transfer.to_store_id == current_user.store.id
    return redirect_back_data_error transfers_path, "Data Transfer Tidak Valid (2)" if transfer.date_picked.present? || transfer.status.present?
    status = sent_items params[:id] 
    binding.pry
    transfer.date_picked = DateTime.now
    transfer.picked_by = current_user
    transfer.save!
    if status==false
      transfer.status = "01-01-1999".to_date
      transfer.description = "Dibatalkan otomatis oleh sistem (tidak ada barang yang dikirim)" 
      transfer.save!
      set_notification current_user, transfer.approved_by, "danger", "Transfer #"+transfer.invoice+" dibatalkan oleh sistem (Tidak ada item yang dikirim).", transfer_path(id: transfer.id)
      return redirect_to transfer_path(id: transfer.id)
    else
      return redirect_success transfer_path(id: transfer.id), "Transfer "+transfer.invoice+" telah dikirim"
    end
  end

  def receive
    return redirect_back_data_error transfers_path, "Data Transfer Tidak Ditemukan" unless params[:id].present?
    @transfer = Transfer.find params[:id]
    return redirect_back_data_error transfers_path, "Data Transfer Tidak Ditemukan" unless @transfer.present?
    return redirect_back_data_error transfers_path, "Data Transfer Tidak Valid" if @transfer.date_approve.nil? || @transfer.date_picked.nil?|| @transfer.status.present?
    @transfer_items = TransferItem.where(transfer_id: @transfer.id)
  end

  def received
    return redirect_back_data_error transfers_path, "Data Transfer Tidak Ditemukan" unless params[:id].present?
    transfer = Transfer.find params[:id]
    return redirect_back_data_error transfers_path, "Data Transfer Tidak Ditemukan" if transfer.nil?
    return redirect_back_data_error transfers_path, "Data Transfer Tidak Valid (R1)" if transfer.from_store_id == current_user.store.id
    return redirect_back_data_error transfers_path, "Data Transfer Tidak Valid (R2)" if transfer.date_picked.nil? || transfer.date_approve.nil? || transfer.status.present?
    receive_items params[:id]
    transfer.status = DateTime.now
    transfer.confirmed_by = current_user
    transfer.save!
    return redirect_success transfer_path(id: transfer.id), "Transfer Telah Diterima"
  end

  def destroy
    return redirect_back_data_error transfers_path, "Transfer Telah Diterima" unless params[:id].present?
    transfer = Transfer.find params[:id]
    return redirect_back_data_error transfers_path, "Data Transfer Tidak Ditemukan" unless transfer.present?
    return redirect_back_data_error transfers_path, "Data Transfer Tidak Ditemukan" if transfer.date_approve.present?
    TransferItem.where(transfer_id: params[:id]).destroy_all
    transfer.destroy
    return redirect_success transfer_path(id: transfer.id), "Transfer Telah Dihapus"
  end

  def show
    return redirect_back_data_error transfers_path, "Data Transfer Tidak Ditemukan" unless params[:id].present?
    @transfer = Transfer.find_by_id params[:id]
    @transfer_items = TransferItem.where(transfer: @transfer)
    @item = Item.page param_page
    return redirect_back_data_error transfers_path, "Data Transfer Tidak Ditemukan" unless @transfer.present?
    respond_to do |format|
      format.html
      format.pdf do
        if @transfer.approved_by.nil?
          @recap_type = "req_transfer"
        elsif @transfer.picked_by.present?
          @recap_type = "send_transfer"
        end
        render pdf: @transfer.invoice,
          layout: 'pdf_layout.html.erb',
          template: "transfers/print.html.slim"
      end
    end
  end

  private
    def filter_search params, r_type
      results = []
      @transfers = Transfer.all
      if r_type == "html"
        @transfers = @transfers.page param_page
      end
      @transfers = @transfers.where("to_store_id = ? OR from_store_id= ?" , current_user.store.id, current_user.store.id) if  !["owner", "super_admin", "finance"].include? current_user.level
      @search = ""
      if params["search"].present?
        @search += "Pencarian "+params["search"]
        search = params["search"].downcase
        @transfers =@transfers.where("invoice like ?", "%"+ search+"%")
      end

      before_months = params["months"].to_i
      if before_months != 0
        @search += before_months.to_s + " bulan terakhir "
        start_months = (DateTime.now - before_months.months).beginning_of_month.beginning_of_day 
        @transfers = @transfers.where("created_at >= ?", start_months)
      end

      store_name = "SEMUA TOKO"
      if params["store_id"].present?
        store = Store.find_by(id: params["store_id"])
        if store.present?
          @transfers = @transfers.where("from_store_id = ? OR to_store_id = ?", store.id, store.id)
          store_name = store.name
          @search += "Pencarian" if @search==""
          @search += " di Toko '"+store.name+"'"
        else
          @search += "Pencarian" if @search==""
          @search += " di Semua Toko"
        end
      end

      @transfers = @transfers.order("created_at DESC")
      
      results << @search
      results << @transfers
      results << store_name
      return results
    end

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

        # next if store_item.stock <= 0
        if store_item.present?
          if transfer_item.request_quantity < qty
            qty = transfer_item.request_quantity
          end
          status = true 
        else
          qty = 0
        end
            
        transfer_item.sent_quantity = qty
        transfer_item.save!
        new_stock = store_item.stock.to_i - qty
        store_item.stock = new_stock

        store_item.save!


        if store_item.stock <= store_item.min_stock
          set_notification current_user, current_user, "warning", store_item.item.name + " berada dibawah limit", warning_items_path
        end
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
        qty = item[1].to_f.abs
        transfer_item.receive_quantity = qty
        store_item = StoreItem.find_by(item: transfer_item.item, store_id: current_user.store.id)
      
        if store_item.nil?
          StoreItem.create store: current_user.store, item_id: item[0], stock: qty
        else
          sent_qty = transfer_item.sent_quantity
          new_stock = store_item.stock.to_f + qty
          store_item.stock = new_stock
          store_item.save!
          transfer_item.save!
        end
      end
    end

    def param_page
      params[:page]
    end

end
