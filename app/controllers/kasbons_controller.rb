class KasbonsController < ApplicationController
  before_action :require_login
  def index
    @kasbons = Kasbon.order("created_at DESC").page param_page
    if params[:kasbon].present?
      name = "%"+params[:kasbon][:name]+"%"
      users = User.where("lower(name) like ?", name)
      @kasbons = @kasbons.where(user: users)
    end
  end

  def new
    @users = User.all
  end

  def create
    curr_kasbon = Kasbon.find_by(user_id: params[:kasbon][:user_id])
    if curr_kasbon.present?
      curr_kasbon.nominal = curr_kasbon.nominal + params[:kasbon][:nominal].to_i
      curr_kasbon.save!
    else
      curr_kasbon = Kasbon.new kasbon_params
      return redirect_back_data_error new_kasbon_path, "Data Kasbon Tidak Valid" if curr_kasbon.invalid?
      curr_kasbon.save!
    end
    return redirect_success kasbons_path, "Data Kasbon - " + curr_kasbon.user.name + " - Berhasil Disimpan"
  end

  def destroy
    return redirect_back_data_error kasbons_path, "Data Dapartemen Tidak Ditemukan" unless params[:id].present?
    kasbon = Kasbon.find params[:id]
    return redirect_back_data_error kasbons_path, "Data Dapartemen Tidak Ditemukan" unless kasbon.present?
    user = kasbon.user
    kasbon.destroy
    return redirect_success kasbons_path, "Data Kasbon - " + user.name + " - Telah Dihapus"
  end

  private
    def kasbon_params
      params.require(:kasbon).permit(
        :user_id, :nominal
      )
    end

    def param_page
      params[:page]
    end
end
