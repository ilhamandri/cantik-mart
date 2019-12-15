class DirectTransfersController < ApplicationController
  before_action :require_login
  before_action :require_fingerprint

  def new
    @stores = Store.where(store_type: 1)
    gon.inv_count = 2
  end

  def create
    invoice = "DTRF-" + Time.now.to_i.to_s
    items = transfer_items
    total_item = items.size
    to_store = params[:transfer][:store_id]
    store = current_user.store
    return redirect_back_data_error transfers_path, "Data Transfer Tidak Ditemukan" unless items.present?
    
    transfer = Transfer.create invoice: invoice,
      total_items: total_item,
      from_store_id: current_user.store.id,
      date_created: Time.now,
      to_store_id: to_store,
      user: current_user,
      approved_by: current_user,
      picked_by: current_user,
      date_approve: Time.now,
      date_picked: Time.now

    trf_status = false
    items.each do |item|
      check_item = Item.find item[0]
      next if check_item.nil?
      qty = item[1].to_i
      next if qty < 1
      TransferItem.create item_id: item[0], transfer_id: transfer.id, request_quantity: qty, sent_quantity: qty, description: item[2]
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
      items.each do |item|
	    check_item = Item.find item[0]
      	qty = item[1].to_i
	    store_item = StoreItem.find_by(store: store, item: check_item)
	    store_item.stock = store_item.stock - qty
	    store_item.save!
	  end
      users = User.where(store: transfer.to_store, level: User::SUPERVISI)
      users.each do |user|
        set_notification(current_user, user, 
          Notification::INFO, "Permintaan transfer"+transfer.invoice, urls)
      end
      return redirect_success urls, "Data Transfer - " + transfer.invoice + " - Berhasil Disimpan"
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

end