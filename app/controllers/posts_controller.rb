class PostsController < ApplicationController
	protect_from_forgery with: :null_session
	skip_before_action :verify_authenticity_token, :if => Proc.new { |c| c.request.format == 'application/json' }
	
	@@point = 10000
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
					trx_total_for_point = 0
					trx_items_datas.each do |trx_item|
						trx_item.delete("id")
						trx_item["transaction_id"] = trx.id
						new_trx_item = TransactionItem.create trx_item 
						
						item = new_trx_item.item
						if !["CIGARETTE", "IBU HAMIL"].include? item.item_cat.name 
							trx_total_for_point += new_trx_item.price
						end

						if new_trx_item.reason.present?
							if new_trx_item.reason.include? "PROMO-"
								promotion = Promotion.find_by(promo_code: new_trx_item.reason)
								promotion.hit = promotion.hit+1
								promotion.save!
							end
						end

						store_stock = StoreItem.find_by(store: trx.user.store, item: new_trx_item.item)
					    next if store_stock.nil?
					    store_stock.stock = store_stock.stock.to_i - new_trx_item.quantity.to_i
					    store_stock.save!
					end
					new_point = trx_total_for_point / @@point
					trx.point = new_point
					trx.save!
					
					if trx.member_card.present?
						member = Member.find_by(card_number: trx.member_card)
						next if member.nil?
						member.point = member.point + new_point
						member.save!
					end
				end
				json_trx_data3.each do |data|
					start_date = data["created_at"].to_datetime.beginning_of_day
					end_date = data["created_at"].to_datetime.end_of_day
					
					absent = Absent.where(user_id: data["user_id"]).where("created_at >= ? AND created_at <= ?", start_date, end_date).first
					
					if absent.nil?
						Absent.create data
					else
						absent.assign_attributes data
						absent.save!
					end
				end
			end	
		end
		
	end
end