class ControllersController < ApplicationController
  before_action :require_login
  before_action :screening

  def index

    # Item.all.each do |item|
    #   ItemPrice.create item: item, buy: item.buy, sell: item.sell, month: Date.today.month.to_i-1+12, year: Date.today.year.to_i-1, created_at: DateTime.now - 1.month
    # end
    check_new_controllers
    @controllers = Controller.order("name ASC").page param_page
  end

  def check_new_controllers
    datas = Hash.new
  	routes= Rails.application.routes.routes.map do |route|
  		controller_name = route.defaults[:controller]
  		next if controller_name.nil?
      next if controller_name.include? "admin"
      next if controller_name.include? "rails"
      next if controller_name.include? "active_storage"
	  	controller = Controller.find_by(name: controller_name)
	  	Controller.create name: controller_name if controller.nil?
      action_name = route.defaults[:action]
      datas[controller_name] = [action_name] if datas[controller_name].nil?
      datas[controller_name] << action_name if !datas[controller_name].include? action_name
	 end
   insert_new_method datas

  end

  def insert_new_method datas
    datas.each do |data|
      controller_name = data[0]
      methods_name = data[1]
      controller = Controller.find_by(name: controller_name)
      methods_name.each do |method_name|
        controller_method = ControllerMethod.find_by(controller: controller, name: method_name)
        controller_method = ControllerMethod.create controller: controller, name: method_name if controller_method.nil?
        insert_new_user_method controller_method
      end
    end
  end

  def insert_new_user_method new_method
    user_method = UserMethod.find_by(user_level: current_user.level, controller_method: new_method)
    return if user_method.present?
  end

  def show
    # return redirect_back_data_error controllers_path unless params[:id].present?
    # @controller = Controller.find_by_id params[:id]
    # return redirect_back_data_error controllers_path unless @controller.present?
    
    filename = "./report/access/"+DateTime.now.to_i.to_s+".xlsx"

    download_excel filename
    send_file(filename)
  end

  private
  	def param_page
      params[:page]
    end

    def download_excel filename
      p = Axlsx::Package.new
      wb = p.workbook

      controllers = Controller.all

      controllers.each do |controller|
        wb.add_worksheet(:name => controller.name) do |sheet|
          sheet.add_row ["METHOD", "LEVEL " + User::levels.keys.to_s]
          controller.controller_methods.each do |c_method|
            # sheet.add_row [c_method.name, UserMethod.where(controller_method: c_method).pluck(:user_level)]
            sheet.add_row [c_method.name]
          end
        end
      end

      p.serialize(filename)
    end
end