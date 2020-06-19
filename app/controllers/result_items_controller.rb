class ResultItemsController < ApplicationController
  	before_action :require_login
	def index
		return redirect_back_data_error items_path, "Data Tidak Valid" if params[:id].nil?
		id = params[:id]
		item = Item.find_by(id: id)
		return redirect_back_data_error items_path, "Data Tidak Ditemukan" if item.nil?
		 
	end
end