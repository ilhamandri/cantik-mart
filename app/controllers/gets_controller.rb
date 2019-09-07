class GetsController < ApplicationController
	def index
		 json_result = {}
		 render :json =>json_result if params[:type].nil? || params[:from].nil? || params[:to].nil?
		 store = Store.find_by(id: params[:type])
		 from = params[:from].to_datetime.strftime('%a, %d %b %Y %H:%M:%S')
		 to = params[:to].to_datetime.strftime('%a, %d %b %Y %H:%M:%S')
		 render :json =>json_result if store.nil?
		 json_result["stores"] = Store.where("updated_at >= ? AND updated_at <= ?", from, to)
		 json_result["users"] = User.where("updated_at >= ? AND updated_at <= ?", from, to)
		 json_result["departments"] = Department.where("updated_at >= ? AND updated_at <= ?", from, to)
		 json_result["item_cats"] = ItemCat.where("updated_at >= ? AND updated_at <= ?", from, to)
		 json_result["items"] = Item.where("updated_at >= ? AND updated_at <= ?", from, to)
		 json_result["stocks"] = StoreItem.where("updated_at >= ? AND updated_at <= ?", from, to)
		 json_result["grocers"] = GrocerItem.where("updated_at >= ? AND updated_at <= ?", from, to)
		 render :json => json_result
	end
end