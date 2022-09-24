class PointsController < ApplicationController
  before_action :require_login
  before_action :screening

  def index
  	return redirect_back_data_error members_path, "Data tidak valid" if params[:id].nil?
  	@member = Member.find_by(id: params[:id])
  	return redirect_back_data_error members_path, "Data tidak valid" if @member.nil?
  	@points = Point.where(member: @member).page param_page
  end

  def new
    return redirect_back_data_error new_exchange_point_path, "Data Tidak Ditemukan" if params[:id].nil?
    @member = Member.find_by(id: params[:id])
    return redirect_back_data_error new_exchange_point_path, "Data Tidak Ditemukan" if @member.nil?
  end

  def create
    return redirect_back_data_error new_exchange_point_path, "Data Tidak Ditemukan" if params[:id].nil?
    member = Member.find_by(id: params[:id])
    return redirect_back_data_error new_exchange_point_path, "Data Tidak Ditemukan" if member.nil?
    exchange_point = ExchangePoint.find_by(id: params[:point][:exchange_point_id])
    return redirect_back_data_error new_exchange_point_path, "Data Tidak Valid" if exchange_point.nil?
    item = Item.find_by(code: exchange_point.name)
    voucher = nil
    if item.present?
      stock = StoreItem.where(item: item, store: current_user.store).first
      if stock.present?
        stock.stock = stock.stock - exchange_point.quantity
        stock.save!
      else
        return redirect_back_data_error new_exchange_point_path, "Barang yang Akan Ditukar Sudah Habis"
      end
    else
      ename = exchange_point.name
      if ename.downcase.include? "voucher"
        voucher = Voucher.create exchange_point: exchange_point, voucher_code: params[:point][:voucher_code]
      end
    end
    point = Point.new point_params
    point.member = member
    point.point = exchange_point.point
    point.point_type = Point::EXCHANGE
    point.voucher = voucher
    point.save!
    member.point = member.point - point.point
    member.save!


    return redirect_success points_path(id: member.id), "Penukaran Poin Berhasil Disimpan"
  
  end

  private
  	def param_page
  		params[:page]
  	end

    def point_params
      params.require(:point).permit(
        :exchange_point_id
      )
    end
end
