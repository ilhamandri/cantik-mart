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
				string_data1 = Base64.decode64(encrypted_data1.to_s)
				string_data2 = Base64.decode64(encrypted_data2.to_s)
				json_trx_data1 = JSON.parse(string_data1)
				json_trx_data2 = JSON.parse(string_data2)
				json_trx_data2.each do |data|
					data.delete("id")
					Member.create data
				end
				json_trx_data1.each do |data|
					trx_data = JSON.parse(data[0])
					trx_items_datas = JSON.parse(data[1])
					trx_data.delete("id")
					trx = Transaction.create trx_data
					trx_items_datas.each do |trx_item|
						trx_item.delete("id")
						trx_item["transaction_id"] = trx.id
						TransactionItem.create trx_item 
					end
				end
			elsif post_type == "member"
				
			end	
		end
		
	end
end