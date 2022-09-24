class LossesController < ApplicationController
  before_action :require_login
  before_action :screening
  

  def index
  	@losses = Loss.page param_page
    @losses = @losses.order("created_at DESC")
  end

  def create
    return redirect_back_data_error losses_path, "Tidak Memilik Hak Akses" if current_user.store.store_type != "warehouse" 
  	invoice = "LOSS-" + Time.now.to_i.to_s
    losses_items = get_loss_items
    return redirect_back_data_error new_loss_path, "Data Item Tidak Valid (Tidak Boleh Kosong)" if losses_items.empty?
    total_item = losses_items.size

    loss = Loss.create invoice: invoice,
    	user: current_user,
    	store: current_user.store,
    	total_item: total_item

    losses_items.each do |loss_item|
    	item = Item.find loss_item[0]
    	store_item = StoreItem.find_by(store: current_user.store, item: item)
    	if store_item.nil?
    		LossItem.where(loss: loss).delete_all
    		loss.delete
    		return redirect_back_data_error new_loss_path, "Barang "+item.name+" tidak tersedia di toko. Silahkan memasukkan data dengan benar"
    	end
    	qty = loss_item[4].to_i
    	description = loss_item[5]
    	create_loss_item = LossItem.create item: item, quantity: qty, loss: loss, description: description
    	if create_loss_item.id.nil?
    		LossItem.where(loss: loss).delete_all
    		loss.delete
    		return redirect_back_data_error new_loss_path, "Silahkan mengisi semua field (jumlah dan deskripsi)"
    	end
    	store_item.stock = store_item.stock - qty
    	store_item.save!
      item.counter -= qty
      item.save!
      loss.create_activity :create, owner: current_user

      if store_item.stock <= store_item.min_stock
        set_notification current_user, current_user, "warning", item.name + " berada dibawah limit", warning_items_path
      end
    end
          

    return redirect_success loss_path(id: loss.id), "Laporan Barang Loss Berhasil Disimpan." 
  end

  def show
  	return redirect_back_data_error orders_path, "Data Barang Loss Tidak Ditemukan" unless params[:id].present?
    @loss = Loss.find_by(id: params[:id])
    return redirect_back_data_error orders_path, "Data Barang Loss Tidak Ditemukan" unless @loss.present?
    @loss_items = LossItem.where(loss: @loss)
    
    respond_to do |format|
      format.html
      format.pdf do
        render pdf: @loss.invoice,
          layout: 'pdf_layout.html.erb',
          template: "losses/print.html.slim"
      end
    end
  end

  def new
    return redirect_back_data_error losses_path, "Tidak Memilik Hak Akses" if current_user.store.store_type != "warehouse" 
  end

  private
  	def param_page
  		params[:page]
  	end

  	def get_loss_items
      items = []
      if params[:order][:order_items].present?
        params[:order][:order_items].each do |item|
          items << item[1].values
        end
      end
      items
    end
end