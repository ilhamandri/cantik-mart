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
    UserMethod.create controller_method: @method, user_level: User::SUPER_ADMIN
    UserMethod.create controller_method: @method, user_level: User::OWNER

    if params[:method].nil?
      if @method.name == 'index'
        all_method_id = ControllerMethod.where(controller: controller).where.not(name: 'index').pluck(:id)
        all_user_access = UserMethod.where(controller_method_id: all_method_id).where.not(user_level: 'super_admin').where.not(user_level: 'owner')
        all_user_access.delete_all
      end
      urls = methods_path(id: @method.controller.id)
      return redirect_success urls , "Perubahan Hak Akses Disimpan"
    end
    new_access_levels = params[:method][:access_levels]
    levels = []
    new_access_levels.each do |access_level|
      level = User.levels.key(access_level.to_i)
      next if level.nil?
      levels << level
      check_index @method, level
      UserMethod.create controller_method: @method, user_level: level

      if ["new", "create"].include? @method.name
        new_id = @method.controller.controller_methods.find_by(name: 'new')
        create_id = @method.controller.controller_methods.find_by(name: 'create')
        new_access = UserMethod.find_by(user_level: level, controller_method: new_id)
        create_access = UserMethod.find_by(user_level: level, controller_method: create_id)

        a = UserMethod.create controller_method: new_id, user_level: level if new_access.nil?
        s = UserMethod.create controller_method: create_id, user_level: level if create_access.nil?       
      end

      if ["edit", "update"].include? @method.name
        edit_id = @method.controller.controller_methods.find_by(name: 'edit')
        update_id = @method.controller.controller_methods.find_by(name: 'update')
        edit_access = UserMethod.find_by(user_level: level, controller_method: edit_id)
        update_access = UserMethod.find_by(user_level: level, controller_method: update_id)

        a = UserMethod.create controller_method: edit_id, user_level: level if edit_access.nil?
        s = UserMethod.create controller_method: update_id, user_level: level if update_access.nil?       
      end

      if ["index", "show"].include? @method.name
        index_id = @method.controller.controller_methods.find_by(name: 'index')
        show_id = @method.controller.controller_methods.find_by(name: 'show')
        have_index_access = UserMethod.find_by(user_level: level, controller_method: index_id)
        have_show_access = UserMethod.find_by(user_level: level, controller_method: show_id)
        
        a = UserMethod.create controller_method: index_id, user_level: level if have_index_access.nil?
        s = UserMethod.create controller_method: show_id, user_level: level if have_show_access.nil?        
      end


    end
    end_check @method, levels
    urls = methods_path(id: @method.controller.id)
    return redirect_success urls, "Perubahan Hak Akses - (" + controller.name + " | " + @method.name + ") - Berhasil Disimpan"
  end

  private
  	def param_page
      params[:page]
    end

    def check_index check_method, level
      if !["index", "show"].include? check_method.name
        index_id = check_method.controller.controller_methods.find_by(name: 'index')
        show_id = check_method.controller.controller_methods.find_by(name: 'show')
        have_index_access = UserMethod.find_by(user_level: level, controller_method: index_id)
        have_show_access = UserMethod.find_by(user_level: level, controller_method: show_id)
        
        a = UserMethod.create controller_method: index_id, user_level: level if have_index_access.nil?
        s = UserMethod.create controller_method: show_id, user_level: level if have_show_access.nil?        
      end
    end

    def end_check check_method, levels
      if ["index", "show"].include? check_method.name
        all_method_id = ControllerMethod.where(controller: check_method.controller).pluck(:id)
        all_user_access = UserMethod.where(controller_method_id: all_method_id).where.not(user_level: levels).where.not(user_level: 'super_admin').where.not(user_level: 'owner')
        all_user_access.delete_all
      end
    end

end