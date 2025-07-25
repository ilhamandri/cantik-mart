require 'chunky_png'
require 'barby'
require 'barby/barcode/code_128'    
require 'barby/outputter/png_outputter'  
class SendBacksController < ApplicationController
  before_action :require_login
  before_action :screening

  	def index
  		@send_backs = SendBack.order("created_at DESC").page param_page
  		
  		if current_user.store.store_type == "retail"
  			@send_backs = @send_backs.where(store: current_user.store)
  		end

  		@send_backs = @send_backs.includes(:user, :store, :received_by)

  		search = ""
  		if params[:search].present?
  			search += params[:search].downcase
  			s = "BS-"+params[:search].gsub("BS-", "")
  			@send_backs = @send_backs.search_by_invoice s
  		end

  		if params[:store_id].present? 
  			if params[:store_id] != "0"
					store = Store.find_by(id: params[:store_id])
					search += "di "+store.name+" " if store.present?
					@send_backs = @send_backs.where(store_id: params[:store_id])
  			end
  		end

  		if params[:type].present?
  			if params[:type] == "onprocess"
  				search += "dengan status SEDANG DALAM PROSES " 
  				@color="warning"
  				@send_backs = @send_backs.where("received_by is null")
  			elsif params[:type] == "success"
  				search += "dengan status SELESAI "
  				@color="success"
  				@send_backs = @send_backs.where("received_by is not null")
  			end	
  		end



  		search = "Pencarian "+search if search != ""
  		@search = search
  	end

  	def new
  	end

  	def create
  		items = item_params
  		invoice = "BS-"+DateTime.now.to_i.to_s
  		send_back = SendBack.create total_items: 0, invoice: invoice, user: current_user, store: current_user.store
  		item_total = 0
  		items.each do |ret_item|
	  		item = Item.find_by(id: ret_item["item_id"])
	  		quantity = ret_item["quantity"].to_i
	  		desc = ret_item["description"]
	  		desc = "-" if desc == ""
	  		send_back_item = SendBackItem.create item: item, 
	  			quantity: quantity, 
	  			description: desc,
	  			send_back: send_back, 
	  			receive: -1
	  		item_total += quantity
  		end
	  	send_back.total_items = item_total
	  	send_back.save!
	  	urls = send_back_path(id: send_back.id)
	  	users = User.where(store: Store.find_by(id: 1), level: User::SUPERVISI)
	    users.each do |user|
	        set_notification(current_user, user, 
	          Notification::INFO, "Terdapat barang BS yang akan dikirimkan oleh "+current_user.store.name + " ("+invoice+")", urls)
	    end
	  	return redirect_success urls, "Retur barang BS ke Gudang berhasil disimpan"
  	end

  	def show
	  	return redirect_back_data_error send_back_path , "Data Tidak Ditemukan" if params[:id].nil?
	  	@send_back = SendBack.find_by(id: params[:id])
	  	return redirect_back_data_error send_back_path , "Data Tidak Ditemukan" if @send_back.nil?
	  	return redirect_back_data_error send_back_path , "Data Tidak Ditemukan" unless checkAccessStore @send_back

	  	@send_back_items = @send_back.send_back_items.includes(:item)
	  	respond_to do |format|
	      format.html
	      format.pdf do
        	@barcode = barcode_output @send_back
        	@recap_type = "bs"
	        render pdf: DateTime.now.to_i.to_s,
	          layout: 'pdf_layout',
	          template: "send_backs/print", 
		        formats: [:html], 
		        disposition: :inline
	      end
	    end
  	end

  	def receive
  		return redirect_back_data_error send_back_path , "Data Tidak Ditemukan" if params[:id].nil?
	  	@send_back = SendBack.find_by(id: params[:id])
	  	return redirect_back_data_error send_back_path , "Data Tidak Ditemukan" if @send_back.nil?
	  	@send_back_items = @send_back.send_back_items.includes(:item)
	  	return redirect_back_data_error send_back_path(id: @send_back.id) , "Data Tidak Ditemukan" if @send_back.received_by.present?
	  	
  	end

  	def received
  		return redirect_back_data_error send_back_path(id: @send_back.id) , "Data Tidak Ditemukan" if params[:id].nil?
	  	@send_back = SendBack.find_by(id: params[:id])
	  	return redirect_back_data_error send_back_path(id: @send_back.id) , "Data Tidak Ditemukan" if @send_back.nil?
	  	return redirect_back_data_error send_back_path(id: @send_back.id) , "Data Tidak Ditemukan" if @send_back.received_by.present?
	  	
	  	items = received_item_params
	  	store = @send_back.store
	  	@send_back.send_back_items.update_all(receive: 0)
	  	items.each do |bs_item|
	  		send_back_item = @send_back.send_back_items.find_by(id: bs_item.first)
	  		item = send_back_item.item
	  		receive_qty = bs_item.second.to_i
	  		send_back_item.receive = receive_qty
	  		send_back_item.save!
		  	store_item = StoreItem.find_by(store: store, item: item)
		  	store_item.stock = store_item.stock.to_i - receive_qty
		  	warehouse_item = StoreItem.find_by(store: 1, item: item)
		  	warehouse_item.stock = warehouse_item.stock + receive_qty
		  	warehouse_item.save!
		  	store_item.save!
	  	end
	  	@send_back.received_by = current_user
	  	@send_back.date_receive = DateTime.now
	  	@send_back.save!
	  	urls = send_back_path(id: @send_back.id)
	  	message = "Retur Barang "+ @send_back.invoice.to_s + "\ntelah diterima oleh "+ current_user.name.to_s + " ( " + @send_back.date_receive.to_s + " )"
	  	set_notification(current_user, @send_back.user, 
	          Notification::INFO, message, urls)
		return redirect_success urls, "Retur barang BS ke Gudang telah diterima."
  	end

  	def destroy
  		return redirect_back_data_error send_back_path , "Data Tidak Ditemukan" if params[:id].nil?
	  	@send_back = SendBack.find_by(id: params[:id])
	  	return redirect_back_data_error send_back_path , "Data Tidak Ditemukan" if @send_back.nil?
	  	send_back = @send_back
	  	SendBackItem.where(send_back: send_back).delete_all
	  	@send_back.delete
	  	urls = send_backs_path
	  	return redirect_success urls, "Retur barang BS ke Gudang berhasil dihapus"
  	end

  	private
	    def barcode_output transfer
	      barcode_string = transfer.invoice      
	      barcode = Barby::Code128B.new(barcode_string)

	      # PNG OUTPUT
	      data = barcode.to_image(height: 15, margin: 5) .to_data_url
	      return data
	    end
	  	def param_page
	  		params[:page]
	  	end

	  	def item_params
	  		items = params[:transfer][:transfer_items].values
	  		return items
	  	end

	  	def received_item_params
	  		params[:send_back]
	  	end

end