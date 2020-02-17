class DiscountsController < ApplicationController
  before_action :require_login
  before_action :require_fingerprint
  
  def index
  	@discounts = Discount.page param_page
  	@discounts = @discounts.order("status DESC, start_date ASC")
  end

  def new
  	
  end

  def create
  	return redirect_back_data_error new_discount_path, "Kode barang tidak ditemukan" if params[:discount][:item_code].nil?
  	item = Item.find_by(code: params[:discount][:item_code])
  	return redirect_back_data_error new_discount_path, "Barang tidak ditemukan" if item.nil?
  	disc = params[:discount][:discount].to_i
  	start_date = params[:discount][:start].to_date
  	end_date = params[:discount][:end].to_date
  	return redirect_back_data_error new_discount_path, "Tanggal tidak boleh kosong" if start_date.nil? || end_date.nil?
  	code = "DSC-"+DateTime.now.to_i.to_s
  	discount = Discount.create code: code, item: item, discount: disc, start: start_date, end: end_date
  	discount.create_activity :create, owner: current_user
  	if Date.today >= start_date && Date.today <= end_date
  		item.discount = disc
  		item.save!
  	end
  	redirect_success discounts_path, "Promo Diskon telah disimpan"
  end

  def destroy
  	return redirect_back_data_error discounts_path, "Data tidak ditemukan" if params[:id].nil?
  	discount = Discount.find_by(id: params[:id])
  	return redirect_back_data_error discounts_path, "Data tidak ditemukan" if discount.nil?
  	item = discount.item
  	item.discount = 0
  	item.save!
  	discount.destroy
  	return redirect_success discounts_path, "Promo berhasil dihapus"
  end

  private
  	def param_page
  		params[:page]
  	end

end