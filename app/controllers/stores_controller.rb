class StoresController < ApplicationController
  before_action :require_login
  before_action :require_fingerprint
  def index
    @stores = Store.page param_page
    if params[:search].present?
      @search = "Pencarian '"+params[:search].upcase+"'"
      search = "%"+params[:search].downcase+"%"
      @stores = @stores.where("lower(name) like ? OR phone like ?", search, search)
    end
  end

  def new

  end

  def destroy
    return redirect_back_data_error stores_path, "Data Toko Tidak Ditemukan" unless params[:id].present?
    store = Store.find params[:id]
    return redirect_back_data_error stores_path, "Data Toko Tidak Ditemukan" unless store.present?
    if store.store_items.present? || store.users.present?
      return redirect_back_data_error stores_path, "Data Toko Tidak Ditemukan" unless store.present?
    else
      store.destroy
      return redirect_success stores_path, "Data Toko - " + store.name + " - Berhasil Dihapus"
    end
  end

  def create
    store = Store.new store_params
    store.name = params[:store][:name].camelize
    store.address = params[:store][:address].camelize
    store.save!
    store.create_activity :create, owner: current_user
    return redirect_success stores_path, "Toko - " + store.name + " - Berhasil Disimpan"
  end

  def edit
    return redirect_back_data_error stores_path, "Data Toko Tidak Ditemukan " unless params[:id].present?
    @store = Store.find_by_id params[:id]
    return redirect_success stores_path, "Toko - " + store.name + " - Berhasil Diubah" unless @store.present?
  end

  def update
    return redirect_back_data_error stores_path, "Data Toko Tidak Ditemukan " unless params[:id].present?
    store = Store.find_by_id params[:id]
    return redirect_back_data_error stores_path, "Data Toko Tidak Ditemukan " unless store.present?
    store.assign_attributes store_params
    store.name = params[:store][:name].camelize
    store.address = params[:store][:address].camelize
    changes = store.changes
    store.save! if store.changed?
    store.create_activity :edit, owner: current_user, parameters: changes
    return redirect_success stores_path, "Data Toko - " + store.name + " - Berhasil Diubah"
  end

  def show
    return redirect_back_data_error stores_path, "Data Toko Tidak Ditemukan" unless params[:id].present?
    @store = Store.find_by_id params[:id]
    return redirect_back_data_error stores_path, "Data Toko Tidak Ditemukan " unless @store.present?
  end

  private
    def store_params
      params.require(:store).permit(
        :name, :address, :phone, :store_type
      )
    end

    def param_page
      params[:page]
    end

end
