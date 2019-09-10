class PostsController < ApplicationController
	protect_from_forgery with: :null_session
	skip_before_action :verify_authenticity_token, :if => Proc.new { |c| c.request.format == 'application/json' }
	
	def index
		if params[:type].nil?
		else
			post_type = params[:type]
			if post_type == "trx"
				encrypted_data1 = params[:trxs][1]
				encrypted_data2 = params[:trxs][3]
				encrypted_data3 = params[:trxs][5]
				string_data1 = Base64.decode64(encrypted_data1.to_s)
				string_data2 = Base64.decode64(encrypted_data2.to_s)
				string_data3 = Base64.decode64(encrypted_data3.to_s)
				json_trx_data1 = JSON.parse(string_data1)
				json_trx_data2 = JSON.parse(string_data2)
				json_trx_data3 = JSON.parse(string_data3)
				json_trx_data2.each do |data|
					data.delete("id")
					Member.create data
				end
				json_trx_data1.each do |data|
					trx_data = JSON.parse(data[0])
					trx_items_datas = JSON.parse(data[1])
					trx_data.delete("id")
					check_trx = Transaction.find_by(invoice: trx_data["invoice"])
					next if check_trx.present?
					trx = Transaction.create trx_data
					trx_items_datas.each do |trx_item|
						trx_item.delete("id")
						trx_item["transaction_id"] = trx.id
						new_trx_item = TransactionItem.create trx_item 

						store_stock = StoreItem.find_by(store: trx.user.store, item: new_trx_item.item)
					    next if store_stock.nil?
					    store_stock.stock = store_stock.stock.to_i - new_trx_item.quantity.to_i
					    store_stock.save!
					end
				end
				json_trx_data3.each do |data|
					# cari data absents
				end
			elsif post_type == "absents"
				
			end	
		end
		
	end
end