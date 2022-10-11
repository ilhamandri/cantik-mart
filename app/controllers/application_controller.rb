class ApplicationController < ActionController::Base
  require "browser"
  protect_from_forgery
  include Clearance::Controller
  include PublicActivity::StoreController 
  before_action :weather

  def dataFilter
    store = nil
    store = current_user.store if ["super_admin", "finance", "owner", "developer"].exclude? current_user.level
        
    return store
  end
  
  # def authorize *authorized_level
  #   return not_found_path unless authorized_level.include? current_user.level
  # end

  # def not_authorize *level
  #   return not_found_path if level.include? current_user.level
  # end

  # def validate_access_only methods
  #   return methods.include?(action_name.to_sym)
  # end

  def weather
    @weather = {}

    url = "http://api.weatherapi.com/v1/current.json?key=e4a2290877b44fc79f5140927221109&q=-6.6413273,107.3890488&aqi=no"
    response = Net::HTTP.get(URI.parse(url))
    json_response = JSON.parse(response)
    if json_response["error"].nil?
      weather_data = json_response["current"]
      @weather["temp"] = weather_data["temp_c"]
      @weather["condition"] = weather_data["condition"]["text"]
      @weather["icon"] = weather_data["condition"]["icon"]
    end
  end

  def screening           
    if current_user.present?
      can_access = false
      return not_found_path if !current_user.active
      return if ["owner", "super_admin", "developer"].include? current_user.level
        
      if request.controller_class.to_s != "SessionsController"
        can_access = authorization
        redirect_back_data_error root_path, 'Tidak memiliki hak akses' if !can_access
      end
    end
  end

  def redirect_back_data_error current_path, message
    redirect_back fallback_location: current_path, flash: { error: message }
  end

  def redirect_success current_path, message
    redirect_to current_path, flash: { success: message }
  end

  def authorization
    extracted_path = nil
    begin
      extracted_path = Rails.application.routes.recognize_path(request.url, method: request.env["REQUEST_METHOD"]) 
      # request.original_fullpath
    rescue
      begin
        extracted_path = Rails.application.routes.recognize_path request.original_fullpath
      rescue
        puts "---------------------------------------->  PATH_RECG   2"
        return false
      end
      puts "---------------------------------------->  PATH_RECG   1"
      return false
    end
    
    controller_name = extracted_path[:controller].to_sym
    method_name = extracted_path[:action].to_sym

    title_actions = {"index"=>"data", "show"=>"detail"}
    title_action = method_name.to_s.gsub("_"," ")
    title_action = title_actions[title_action] if title_actions[title_action].present?
    @method = title_action.camelize

    titles = {"send back"=>"Kirim BS", "item cat"=>"sub department", "warning item"=>"empty stock"}
    title = controller_name.to_s.gsub("_"," ").singularize
    title = titles[title] if titles[title].present?
    @title = title.camelize
    
    # return if ['received', 'pays', 'errors'].any? { |word| request.original_fullpath.include?(word) }

    return authentication controller_name, method_name
  end

  def authentication controller_name, method_name

    controller = Controller.find_by(name: controller_name.to_s)
    return true if ["notifications", "absents"].include? controller.name

    find_method = ControllerMethod.find_by(controller: controller, name: method_name.to_s)
    get_access = UserMethod.find_by(user_level: current_user.level, controller_method: find_method)
    return true if get_access.present?
    return false
  end

  def set_notification from_user, to_user, m_type, message, link
    Notification.create from_user: from_user, to_user: to_user, m_type: m_type,
      message: message, link: link, date_created: DateTime.now
  end
end
