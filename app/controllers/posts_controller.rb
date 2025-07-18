class PostsController < ApplicationController
	protect_from_forgery with: :null_session
	skip_before_action :verify_authenticity_token, :if => Proc.new { |c| c.request.format == 'application/json' }
	
	@@point = 10000
	def index
		begin
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
					end_date = DateTime.now.end_of_day
					start_date = (end_date - 5.days).beginning_of_day
					json_trx_data1.each do |data|
						trx_data = JSON.parse(data[0])
						trx_items_datas = JSON.parse(data[1])
						trx_data.delete("id")
						member_data = trx_data.delete("member_card")
						check_trx = Transaction.where(invoice: trx_data["invoice"])
						next if check_trx.present?
						trx = Transaction.create trx_data
						member = nil
						if member_data.present?
							member = Member.find_by(id: member_data["id"])
							trx.member_card = member if member.present?
						end
						trx_total_for_point = 0
						hpp_totals = 0
						has_coin = false
						tax = 0
						pembulatan = 0
						profit = 0
						trx_items_datas.each do |trx_item|
							trx_item.delete("id")
							trx_item["transaction_id"] = trx.id
							new_trx_item = TransactionItem.create trx_item 
						    item = new_trx_item.item

							store_stock = StoreItem.find_by(store: trx.user.store, item: item)
							
							hpp_totals += new_trx_item.item.buy * new_trx_item.quantity

							if new_trx_item.reason.present?
								if new_trx_item.reason.include? "PROMO-"
									promotion = Promotion.find_by(promo_code: new_trx_item.reason)
									promotion.hit = promotion.hit+1
									promotion.save!
								end
							end

						    if store_stock.nil?
						    	StoreItem.create store: trx.user.store, item: item
						    end
						    
						    buy_qty = new_trx_item.quantity.to_f
						    decrease = new_trx_item.quantity.to_f
						    decrease = decrease.ceil.to_i if item.id != 6049
						    store_stock.stock = store_stock.stock.to_f - decrease
						    item.counter = item.counter + new_trx_item.quantity.to_i
						    item.save!
						    store_stock.save!

						    if new_trx_item.quantity > 1
						        grocer_item = GrocerItem.find_by(item: item, price: new_trx_item.price-new_trx_item.discount)
						        
						        if grocer_item.present?
						    		tax += grocer_item.ppn * new_trx_item.quantity.to_f
          							new_trx_item.ppn = grocer_item.ppn * new_trx_item.quantity
						          	pembulatan += grocer_item.selisih_pembulatan * new_trx_item.quantity.to_f
						        else
						    		tax += item.ppn * new_trx_item.quantity.to_f
        							new_trx_item.ppn = item.ppn * new_trx_item.quantity
						        	pembulatan += item.selisih_pembulatan * new_trx_item.quantity.to_f
						        end
						    else
						    	tax += item.ppn * new_trx_item.quantity.to_f
        						new_trx_item.ppn = item.ppn * new_trx_item.quantity
						        pembulatan += item.selisih_pembulatan * new_trx_item.quantity.to_f
						    end

						    new_trx_item.store = trx.store
						    item_suppliers = SupplierItem.where(item: new_trx_item.item)
						    new_trx_item.supplier = item_suppliers.first.supplier if item_suppliers.present?
						    new_trx_item.total = new_trx_item.quantity * (new_trx_item.price-new_trx_item.discount)
						    new_trx_item.profit = new_trx_item.total - new_trx_item.ppn - (new_trx_item.item.buy * new_trx_item.quantity)

						    new_trx_item.save!


						    if item.item_cat.id == 179
						        trx.has_coin = true
						        trx.grand_total_coin = trx.grand_total_coin + new_trx_item.total
						        trx.hpp_total_coin = trx.hpp_total_coin + (new_trx_item.item.buy * new_trx_item.quantity)
						        trx.profit_coin = trx.profit_coin + new_trx_item.profit
						        trx.quantity_coin = trx.quantity_coin + new_trx_item.quantity
						        trx.tax_coin = trx.tax_coin + new_trx_item.ppn
						        trx.save!
						    end
						    
						end
						trx.tax = tax
						trx.pembulatan = pembulatan

						trx.hpp_total = hpp_totals
						trx.save!

						voucher = Voucher.find_by(voucher_code: trx.voucher)
						if voucher.present?
							voucher.used = trx.created_at
							voucher.save!
							trx.voucher_id = voucher.id
							trx.save!
						end

						if member.present?
							member.point = member.point + trx.point

							Point.create member: member, point: trx.point, point_type: Point::GET, transaction_id: trx.id
							
							member.save!
						end
					end

					json_trx_data3.each do |data|
						start_date = data["created_at"].to_datetime.beginning_of_day
						end_date = data["created_at"].to_datetime.end_of_day
						absent = Absent.find_by(user_id: data["user_id"], created_at: start_date..end_date)

						data.delete("id")
						
						if absent.nil?
							absent = Absent.create data
						else
							absent.assign_attributes data
							absent.save!
						end
					end
				end	
			end
			render status: 200
		rescue Exception => e
			logger.error e.message
  			# e.backtrace.each { |line| logger.error line }
  			puts e.message
  			# binding.pry
			render status: 400
		end
	end
end