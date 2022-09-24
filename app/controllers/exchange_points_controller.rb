class ExchangePointsController < ApplicationController
  before_action :require_login
  before_action :screening

  def index
  	@EPoints = ExchangePoint.order("point ASC").page param_page
  end

  def new
  end

  def create
  	exchange_point = ExchangePoint.new exchange_points_params
  	if exchange_point.quantity <= 0 || exchange_point.point <= 0
    	return redirect_back_data_error new_exchange_point_path, "Poin / Jumlah barang yang diberikan harus lebih dari 0"
  	end
    return redirect_back_data_error new_exchange_point_path, "Data Tidak Lengkap" if exchange_point.invalid?
    exchange_point.save!
    exchange_point.create_activity :create, owner: current_user
    return redirect_success exchange_points_path, "Kriteria Penukaran Poin Berhasil Disimpan"
  end

  def edit
  	return redirect_back_data_error new_exchange_point_path, "Data Tidak Ditemukan" if params[:id].nil?
  	@point = ExchangePoint.find_by(id: params[:id])
  	return redirect_back_data_error new_exchange_point_path, "Data Tidak Ditemukan" if @point.nil?
  end

  def update
  	return redirect_back_data_error exchange_points_path, "Data Tidak Ditemukan" if params[:id].nil?
  	point = ExchangePoint.find_by(id: params[:id])
  	return redirect_back_data_error exchange_points_path, "Data Tidak Ditemukan" if point.nil?
  	point.assign_attributes exchange_points_params
  	changes = point.changes
  	if point.changed?
  		point.save! 
		point.create_activity :edit, owner: current_user, params: changes
    end
   	urls = exchange_points_path
    return redirect_success urls, "Perubahan Kriteria - "+point.name+" Berhasil Disimpan"
  end

  def destroy
  	return redirect_back_data_error exchange_points_path, "Data Tidak Ditemukan" if params[:id].nil?
  	point = ExchangePoint.find_by(id: params[:id])
  	return redirect_back_data_error exchange_points_path, "Data Tidak Ditemukan" if point.nil?
  	if point.hit == 0 
  		return redirect_back_data_error exchange_points_path, "Data Tidak Dapat Dihapus (DATA SUDAH PERNAH DIGUNAKAN)" if point.nil?
  	end
  	delete = point
  	point.delete
  	urls = exchange_points_path
    return redirect_success urls, "Kriteria - "+delete.name+" Berhasil Dihapus"
  end

  def set_on_off
    return redirect_back_data_error exchange_points_path, "Data Tidak Ditemukan" if params[:id].nil?
    point = ExchangePoint.find_by(id: params[:id])
    return redirect_back_data_error exchange_points_path, "Data Tidak Ditemukan" if point.nil?
    point.status = !point.status
    point.save!
    return redirect_success exchange_points_path, "Kriteria Penukaran Poin Berhasil Diubah"
  end

  private
  	def param_page
  		params[:page]
  	end

  	def exchange_points_params
      params.require(:point).permit(
        :point, :name, :quantity 
      )
    end
end
