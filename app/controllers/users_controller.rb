class UsersController < ApplicationController
  before_action :require_login
  before_action :require_fingerprint
  def index
    
    # Grant.insert_access_grant
    # Grant.insert_user
    # InsertProdlist.cross_check "3-prodlist.xlsx"

    InsertProdlist.cross_check "1-prodlist.xlsx"
    InsertProdlist.cross_check "2-prodlist.xlsx"
    InsertProdlist.additional_file "3-additional.xlsx"

    @users = User.page param_page
    if params[:search].present?
      @search = params[:search].downcase
      search = "%"+@search+"%"
      @users = @users.where("lower(name) like ? OR phone like ?", search, search)
    end

  end

  def show
    return redirect_back_data_error users_path, "Data Pengguna Tidak Ditemukan" unless params[:id].present?
    @user = User.find_by_id params[:id]
    if !["owner", "super_admin", "finance"].include? current_user.level
      if @user != current_user
        return redirect_back_data_error users_path, "Data Pengguna Tidak Ditemukan" unless @user.present?
      end
    end
    return redirect_back_data_error users_path, "Data Pengguna Tidak Ditemukan" unless @user.present?
  end

  def new
    @stores = Store.all
  end

  def create
    user = User.new user_params
    return redirect_back_data_error new_user_path, "Data Pengguna Tidak Ditemukan" if user.invalid?
    user.save!
    user.create_activity :create, owner: current_user
    return redirect_success users_path, "Pengguna - " + user.name + " - Berhasil Ditambahkan"
  end

  def edit
    return redirect_back_data_error users_path, "Data Pengguna Tidak Ditemukan" unless params[:id].present?
    @user = User.find_by_id params[:id]
    if !["owner", "super_admin", "finance"].include? current_user.level
      if @user != current_user
        return redirect_back_data_error users_path, "Data Pengguna Tidak Ditemukan" unless @user.present?
      end
    end
    @stores = Store.all
    return redirect_back_data_error users_path, "Data Pengguna Tidak Ditemukan" unless @user.present?
  end

  def update
    return redirect_back_data_error users_path, "Data Pengguna Tidak Ditemukan" unless params[:id].present?
    file = params[:user][:image]
    upload_io = params[:user][:image]
    if file.present?
      filename = Digest::SHA1.hexdigest([Time.now, rand].join).to_s+File.extname(file.path).to_s
      File.open(Rails.root.join('public', 'uploads', 'profile_picture', filename), 'wb') do |file|
        file.write(upload_io.read)
      end
    end
    user = User.find_by_id params[:id]
    user.image = filename
    user.assign_attributes user_params
    changes = user.changes
    user.save! if user.changed?
    user.create_activity :edit, owner: current_user, parameters: changes
    return redirect_success user_path(id: user.id), "Data Pengguna - " + user.name + " - Berhasil Diubah"
  end

  def destroy
    return redirect_back_data_error users_path, "Data Tidak Valid" unless params[:id].present?
    user = User.find params[:id]
    return redirect_back_data_error users_path, "Data Tidak Valid" unless user.present?
    if user.level == "owner" || user.level == "super_admin"
      return redirect_back_data_error users_path, "Data Tidak Valid" 
    else 
      user.destroy
      return redirect_success users_path, "Data Pengguna - " + user.name + " - Berhasil Dihapus"
    end
  end

  private
    def user_params
      params.require(:user).permit(
        :name, :email, :password, :level, :phone, :sex, :store_id, :id_card, :address, :fingerprint, :salary
      )
    end

    def param_page
      params[:page]
    end
end
