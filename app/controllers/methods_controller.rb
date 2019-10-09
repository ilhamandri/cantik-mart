class MethodsController < ApplicationController
  before_action :require_login

  def index
    return redirect_back_data_error controllers_path, "Data Tidak Ditemukan" if params[:id].nil?
  	@methods = ControllerMethod.where(controller_id: params[:id]).order("name ASC").page param_page
  end

  def edit
  	return redirect_back_data_error controllers_path, "Data Tidak Ditemukan" unless params[:id].present?
    @method = ControllerMethod.find_by_id params[:id]
    return redirect_back_data_error controllers_path, "Data Tidak Ditemukan" unless @method.present?
  end

  def update
    return redirect_back_data_error controllers_path, "Data Tidak Ditemukan" unless params[:id].present?
    @method = ControllerMethod.find_by_id params[:id]
    return redirect_back_data_error controllers_path, "Data Tidak Ditemukan" unless @method.present?
    controller = @method.controller
    user_method = UserMethod.where(controller_method: @method)
    user_method.delete_all if user_method.present?
    UserMethod.create controller_method: @method, user_level: 'owner'
    UserMethod.create controller_method: @method, user_level: 'super_admin'
    if params[:method].nil?
      if @method.name == 'index'
        all_method_id = ControllerMethod.where(controller: controller).where.not(name: 'index').pluck(:id)
        all_user_access = UserMethod.where(controller_method_id: all_method_id).where.not(user_level: 'super_admin').where.not(user_level: 'owner')
        all_user_access.delete_all
      end
      urls = methods_path(id: @method.controller.id)
      return redirect_success urls , "Perubahan Hak Akses Gagal"
    end
    new_access_levels = params[:method][:access_levels]
    new_access_levels.each do |access_level|
      level = User.levels.key(access_level.to_i)
      next if level.nil?
      index_id = @method.controller.controller_methods.find_by(name: 'index')
      having_index_access = UserMethod.find_by(user_level: level, controller_method: index_id)
      # next if @method.name != 'index' && !having_index_access
      UserMethod.create controller_method: @method, user_level: level
    end
    urls = methods_path(id: @method.controller.id)
    return redirect_success urls, "Perubahan Hak Akses - (" + controller.name + " | " + @method.name + ") - Berhasil Disimpan"
  end

  private
  	def param_page
      params[:page]
    end
end