class GetsController < ApplicationController
	def index
		 json_result = {}
		 store = nil
		 if params[:type].present? || params[:from].present? || params[:to].present?
		 	store = Store.find_by(id: params[:store_id])
		 end
		 
		 if store.present?
		 	 # CANTIKMART.COM
			 from = params[:from].gsub("  "," +").to_time
			 to = params[:to].gsub("  "," +").to_time
			 # LOCALHOST
			 # from = params[:from].to_time
			 # to = params[:to].to_time 

			 render :json =>json_result if store.nil?
			 json_result["stores"] = Store.where("updated_at >= ? AND updated_at <= ?", from, to)
			 json_result["users"] = User.where("updated_at >= ? AND updated_at <= ?", from, to)
			 json_result["members"] = Member.where("updated_at >= ? AND updated_at <= ?", from, to)
			 json_result["departments"] = Department.where("updated_at >= ? AND updated_at <= ?", from, to)
			 json_result["item_cats"] = ItemCat.where("updated_at >= ? AND updated_at <= ?", from, to)
			 json_result["items"] = Item.where("updated_at >= ? AND updated_at <= ?", from, to)
			 json_result["stocks"] = StoreItem.where(store: store).where("updated_at >= ? AND updated_at <= ?", from, to)
			 json_result["grocers"] = GrocerItem.where("updated_at >= ? AND updated_at <= ?", from, to)
			 json_result["promotions"] = Promotion.where("updated_at >= ? AND updated_at <= ?", from, to)
		 	 json_result["exchange_points"] = ExchangePoint.where("updated_at >= ? AND updated_at <= ?", from, to)
		 	 json_result["vouchers"] = Voucher.where("updated_at >= ? AND updated_at <= ?", from, to)
		 	
		 end
		 render :json => json_result
	end
end