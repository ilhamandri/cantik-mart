class DepartmentsController < ApplicationController
  before_action :require_login
  before_action :require_fingerprint
  def index
    @departments = Department.page param_page
    if params[:search].present?
      @search = params[:search].downcase
      search = "%"+@search+"%"
      search_arr = search.split(":")
      if search_arr.size == 2
        @departments = @departments.where("lower(name) like ?", search)
      else
        @departments = @departments.where("lower(name) like ?", search)
      end
    end
  end

  def show
    return redirect_back_data_error departments_path unless params[:id].present?
    @department = Department.find_by_id params[:id]
    return redirect_back_data_error departments_path, "Data Dapartemen Tidak Ditemukan" if @department.nil?
    return redirect_to item_cats_path dept_id: @department.id
  end

  def new
    @departments = Department.all
  end

  def create
    department = Department.new department_params
    department_name = params[:department][:name].camelize
    department.name = department_name
    return redirect_back_data_error new_department_path, "Data Dapartemen Tidak Valid" if department.invalid?
    department.save!
    department.create_activity :create, owner: current_user
    urls = item_cats_path dept_id: department.id
    return redirect_success urls, "Data Dapartemen - " + department.name + " - Berhasil Disimpan"
  end

  def edit
    return redirect_back_data_error departments_path, "Data Dapartemen Tidak Ditemukan" unless params[:id].present?
    @department = Department.find_by_id params[:id]
    return redirect_back_data_error departments_path, "Data Dapartemen Tidak Ditemukan" unless @department.present?
  end

  def update
    return redirect_back_data_error departments_path, "Data Dapartemen Tidak Ditemukan" unless params[:id].present?
    department = Department.find_by_id params[:id]
    department.assign_attributes department_params
    item_name = params[:department][:name].camelize
    department.name = item_name
    changes = department.changes
    if department.changed?
      department.save! 
      department.create_activity :edit, owner: current_user, params: changes
    end
    urls = item_cats_path dept_id: department.id
    set_notification(User.last, current_user, Notification::PRIMARY, "Data Dapartemen - " + department.name + " - Berhasil Diubah", urls)
    return redirect_success urls, "Data Dapartemen - " + department.name + " - Berhasil Diubah"
  end

  def destroy
    return redirect_back_data_error departments_path, "Data Dapartemen Tidak Ditemukan" unless params[:id].present?
    department = Department.find params[:id]
    return redirect_back_data_error departments_path, "Data Dapartemen Tidak Ditemukan" unless department.present?
    return redirect_back_data_error departments_path, "Data Dapartemen Tidak Ditemukan" if department.item_cat.present?
    dept_name = department.name
    department.destroy
    return redirect_success departments_path, "Data Dapartemen - " + dept_name + " - Telah Dihapus"
  end

  private
    def department_params
      params.require(:department).permit(
        :name
      )
    end

    def param_page
      params[:page]
    end
end
